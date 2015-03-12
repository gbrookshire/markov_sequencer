/* Finchesizer

To use:
- Boot up the server.
- Change adrs_touchOSC to the IP address of the tablet.
    ("Local IP address" on TouchOSC
- Then execute the main block of code.

In TouchOSC (on the tablet), fix these settings:
Host: the IP address of the computer running SuperCollider.
Port (outgoing): 57120 (default for supercollider)
Port (incoming): 58100

*/

// Values sent back to TouchOSC need to be in the interval [0,1].

// Add phase arguments for modulation?
// Add pan?
// Also multiple ipads at once
// Preprogrammed syllables - gestures
//  -- Do this with separate SynthDefs
// Buttons that send to preset combinations of parameters
// Shift up bifurcation line

(
var adrs_touchOSC;
var active_synth, finch_defaults, n_synths, finch_param_arr;
var switch_control, update_touchosc_disp, update_synth_param;

n_synths = 4;
adrs_touchOSC = NetAddr("192.168.1.139", 58100);
active_synth = 0; // Which finch is being controlled by TouchOSC
finch_defaults = Dictionary[
	\pressure -> 0,
	\tension -> 0,
	\time_const -> 0,
	\volume -> 0,
	\pdepth -> 0,
	\prate -> 0,
	\tdepth -> 0,
	\trate -> 0
];
finch_param_arr = Array.fill(n_synths, {finch_defaults.copy});


///// Useful functions

// Update the parameter of a synth in the array and in the synth
update_synth_param = {arg pname, pval;
	// Update the array of parameters
	finch_param_arr[active_synth].put(pname, pval);
	// Update the synth
	x[active_synth].set(pname, pval);
};

// Change TouchOSC control to a new synth
switch_control = {arg new_synth;
	var old_synth, active_params;
	old_synth = active_synth;
	// Update active_synth
	active_synth = new_synth;
	// Update TouchOSC display to reflect new active synth
	active_params = finch_param_arr.at(new_synth);
	update_touchosc_disp.value(active_params);
};

// Update display on TouchOSC to show params of active synth
update_touchosc_disp = {arg param_dict;
	param_dict.keys.do({arg pname;
		var msg, val;
		case
		{pname == \volume} {msg = '/1/volume'}
		{pname == \time_const} {msg = '/1/time_const'}
		{or(pname == \pressure, pname == \tension)} {
			msg = '/1/xy';
			val = [param_dict[\pressure], param_dict[\pressure]];
		}
		{or(pname == \prate, pname == \pdepth)} {
			msg = '/1/pressure_mod';
			val = [param_dict[\prate], param_dict[\pdepth]];
		}
		{or(pname == \trate, pname == \tdepth)} {
			msg = '/1/tension_mod';
			val = [param_dict[\trate], param_dict[\tdepth]];
		}
		{true} {("Param " + pname + " not known.").postln;};
		if(val.isNil, {val = param_dict[pname]}, {});
		adrs_touchOSC.sendMsg(msg, *val);
	});
};


///// Finchesizer

SynthDef(\finch, {arg pressure=0, tension=0, time_const=0, volume=0,
	pdepth=0, prate=0, tdepth=0, trate=0;
	var sig, time_smooth;

	// All control values from TouchOSC vary between 0 and 1.
	// Adjust to meaningful values here.
	pressure = pressure - 0.02;
	tension = tension - 0.02;
	time_const = time_const.linexp(0, 1, 1000, 48000);
	volume = volume * 6;
	pdepth = pdepth * 0.2;
	prate = prate * 50;
	tdepth = tdepth * 0.2;
	trate = trate * 50;

	time_smooth = 0.05; // smooth changes in control vals

	sig = SyrinxL.ar(
		freq:22050,
		a: pressure.lag(time_smooth) + SinOsc.kr(prate, mul:pdepth),
		b: tension.lag(time_smooth) + SinOsc.kr(trate, mul:tdepth),
		g: time_const.lag(time_smooth),
		h: 0.00001, // ??
		mul: volume.lag(time_smooth));
	Out.ar(0, sig);
}).add;


///// Effects

SynthDef(\bitcrusher, {arg bit_depth=10, bit_rate=10000;
	var sig;
	sig = In.ar(0);
	// Reduce the sampling rate
	sig = Latch.ar(sig, SinOsc.ar(bit_rate));
	// Reduce the bit depth
	sig = ((sig * (2 ** bit_depth)).round) / (2 ** bit_depth);
	ReplaceOut.ar(0, sig);
}).add;

SynthDef(\verb, {arg mix=0.33, room=0.5, damp=0.5;
	var sig;
	sig = In.ar(0);
	sig = FreeVerb.ar(sig, mix:mix, room:room, damp:damp);
	ReplaceOut.ar(0, sig);
}).add;

///// OSC responders

OSCdef.new(
	\volume_resp,
	{|msg, time, addr, port|
		update_synth_param.(\volume, msg[1]);
	},
	'/1/volume'
);
OSCdef.new(
	\finch_resp,
	{|msg, time, addr, port|
		update_synth_param.(\tension, msg[1]);
		update_synth_param.(\pressure, msg[2]);
	},
	'/1/xy'
);
OSCdef.new(
	\timeconst_resp,
	{|msg, time, addr, port|
		update_synth_param.(\time_const, msg[1]);
	},
	'/1/time_const'
);
OSCdef.new(
	\pressure_mod_resp,
	{|msg, time, addr, port|
		update_synth_param.(\prate, msg[1]);
		update_synth_param.(\pdepth, msg[2]);
	},
	'/1/pressure_mod'
);
OSCdef.new(
	\tension_mod_resp,
	{|msg, time, addr, port|
		update_synth_param.(\trate, msg[1]);
		update_synth_param.(\tdepth, msg[2]);
	},
	'/1/tension_mod'
);

// Responders for selecting which finchesizer to control
(1..n_synths).do({arg n_finch;
	OSCdef.new(
		'finch_select' ++ n_finch.asString ++ '_resp',
		{|msg, time, addr, port|
			if (
				msg[1] == 1,
				{
					var new_synth;
					// Sorry...
					new_synth = msg[0].asString.at(18).asInt - 49;
					switch_control.(new_synth);
				},
				{}
			);
		},
		'/1/finch_select/1/' ++ n_finch.asString;
	);
});

OSCdef.new(
	\dump_resp,
	{|msg, time, addr, port|
		finch_param_arr[active_synth].postln
	},
	'/1/dump'
);


// Effects
OSCdef.new(
	\bc_on_resp,
	{|msg, time, addr, port|
		if (msg[1] == 1,
			{y = Synth.tail(s, \bitcrusher);},
			{y.free;});
	},
	'/1/bc_on'
);
OSCdef.new(
	\bc_depth_resp,
	{|msg, time, addr, port|
		var bd;
		bd = (msg[1] * 12).round + 3;
		y.set(\bit_depth, bd);
	},
	'/1/bc_depth'
);
OSCdef.new(
	\bc_rate_resp,
	{|msg, time, addr, port|
		y.set(\bit_rate, msg[1] * 20000);
	},
	'/1/bc_rate'
);


///// Rev up the finchesizers
Task({
	s.sync; // wait for the server
	// x = Synth.tail(s, \finch);
	// Eliminating the group like this makes it hard to apply bitcrushing
	x = Array.fill(n_synths, {Synth.new(\finch)});
}).play;

)

/*
// Test out the finchesizer
x = Synth.tail(s, \finch);
x[0].set(\pressure, 0.5);
x[0].set(\tension, 0.1);
x[0].set(\volume, 0.6);
x[0].free;

// Set up effects in a chain like this.
y = Synth.tail(s, \bitcrusher, [\bit_depth, 1, \bit_rate, 100]);
y.free;

z = Synth.tail(s, \verb);
z.set(\mix, 0.8);
z.set(\room, 0.1);
z.set(\damp, 0.6);
z.free;
*/

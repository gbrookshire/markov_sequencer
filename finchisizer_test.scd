/* Finchesizer

To use:
- Boot up the server.
- Change adrs_touchOSC to the IP address of the tablet.
("Local IP address" on TouchOSC)
- Then execute the main block of code.

In TouchOSC (on the tablet), fix these settings:
Host: the IP address of the computer running SuperCollider.
    - On a Mac, you can get that with "ifconfig en1" in Terminal,
      and taking the "inet" IP address, not "broadcast".
Port (outgoing): 57120 (default for supercollider)
Port (incoming): 58100

*/

// Values sent back to TouchOSC need to be in the interval [0,1].

// Volume knob.
// Implement functions for the preset buttons.
// Save to and from RAM, and then to and from disk w/ YAML.


// Add phase arguments for modulation?
// Add pan?
// Also multiple ipads at once
// Preprogrammed syllables - gestures
//  -- Do this with separate SynthDefs
// Buttons that send to preset combinations of parameters
// Shift up bifurcation line

(
var adrs_touchOSC;
var active_synth, finch_defaults, finch_param_arr, n_synths, n_presets;
var switch_control, update_touchosc_disp, update_synth_param;
var writingYAML, toYAML, fromYAML;
var preset_arr;
var save_synth_settings, load_synth_settings;
var save_all_settings, load_all_settings;

n_synths = 4;
n_presets = 5;
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
preset_arr = Array.fill(n_presets, {finch_param_arr.copy});


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

// Read and write as YAML files.
toYAML = {arg dict, fname;
	var file_pointer;
	file_pointer = File(fname, "w");
	dict.keys.do({arg param_name;
		var line;
		line = param_name ++ ": " ++ dict[param_name].asString ++ "\n";
		file_pointer.write(line);
	});
	file_pointer.close();
};

fromYAML = {arg fname;
	var raw_dict, cooked_dict;
	raw_dict = fname.parseYAMLFile;
	cooked_dict = Dictionary[];
	raw_dict.keys.do({arg param_name;
		cooked_dict[param_name.asSymbol] = raw_dict[param_name].asFloat;
	});
	cooked_dict
};

// Save to RAM
save_synth_settings = {arg voice, preset_loc;
	preset_arr[preset_loc][voice] = finch_param_arr[voice];
};
// Load from RAM
load_synth_settings = {arg voice, preset_loc;
	finch_param_arr[voice] = preset_arr[preset_loc][voice];
};
// Save all current to RAM
save_all_settings = {arg preset_loc;
	finch_param_arr.do({arg param_dict, i;
		save_synth_settings(i, preset_loc);
	});
};
// Load all current to RAM
load_all_settings = {arg preset_loc;
	finch_param_arr.do({arg param_dict, i;
		load_synth_settings(i, preset_loc);
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
	prate = prate.linexp(0, 1, 0.05, 50);
	tdepth = tdepth * 0.2;
	trate = trate.linexp(0, 1, 0.05, 50);

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

OSCdef.new(
	\verb_on_resp,
	{|msg, time, addr, port|
		if (msg[1] == 1,
			{z = Synth.tail(s, \verb);},
			{z.free;});
	},
	'/1/verb_on'
);
OSCdef.new(
	\verb_mix_resp,
	{|msg, time, addr, port|
		z.set(\mix, msg[1]);
	},
	'/1/verb_mix'
);
OSCdef.new(
	\verb_room_resp,
	{|msg, time, addr, port|
		z.set(\room, msg[1]);
	},
	'/1/verb_room'
);
OSCdef.new(
	\verb_damp_resp,
	{|msg, time, addr, port|
		z.set(\damp, msg[1]);
	},
	'/1/verb_room'
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

(
var home = "~/".standardizePath;
var fname = home ++ "Desktop/preset.txt";
var toYAML, fromYAML, finch_defaults;
finch_defaults = Dictionary[
	\pressure -> 111,
	\tension -> 1111,
	\time_const -> 0,
	\volume -> 0,
	\pdepth -> 0,
	\prate -> 0,
	\tdepth -> 0,
	\trate -> 0
];



toYAML.value(finch_defaults, fname);

d = fromYAML.value(fname);
)

(
var fname = "~/".standardizePath ++ "Desktop/preset.txt";
d = fname.parseYAMLFile;
d.postln;
)
d.at(\pressure) + 222



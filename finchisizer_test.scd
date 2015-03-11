/* Finchesizer

To use, first boot up the server.
Then execute the main block of code.

In TouchOSC (on the tablet):
Port (outgoing): 57120 (or whatever is given for NetAddr.langPort)
Port (incoming): 58100

*/

// Function to update the TouchOSC display -- not working!
// It seems to be taking the current value instead of the loaded value
// But this works:
(
var adrs_touchOSC, msg, val;
adrs_touchOSC = NetAddr("192.168.1.139", 58100);
msg = '/1/volume';
val = 0; // Specify value here
adrs_touchOSC.sendMsg(msg, val)
)

// Also multiple ipads at once
// Preprogrammed syllables - gestures
// Buttons that send to preset combinations of parameters
//  -- Do this with separate SynthDefs
// Shift up bifurcation line

s.boot;
(
var adrs_touchOSC;
var active_synth, finch_defaults, finch_param_names,
n_synths, finch_param_arr;
var switch_control, update_touchosc_disp, update_synth_param;

adrs_touchOSC = NetAddr("192.168.1.139", 58100);
active_synth = 0;
finch_defaults = Dictionary[
	\pressure -> 0,
	\tension -> 0,
	\time_const -> 500,
	\volume -> 0,
	\pdepth -> 0,
	\prate -> 0,
	\tdepth -> 0,
	\trate -> 0
];
finch_param_names = [
	\pressure,
	\tension ,
	\time_const,
	\volume,
	\pdepth,
	\prate,
	\tdepth,
	\trate
];
n_synths = 4;
finch_param_arr = Array.fill(n_synths, {finch_defaults});

///// Useful functions

// Change TouchOSC control to a new synth
// I think this isn't choosing the new parameters correctly.
switch_control = {arg i_synth;
	var old_synth, active_params;
	old_synth = active_synth;
	// Update active_synth
	active_synth = i_synth;
	// Update TouchOSC display to reflect new active synth
	active_params = finch_param_arr.at(i_synth);
	active_params.postln;
	update_touchosc_disp.value(active_params);
};

// Update display on TouchOSC to show params of active synth
update_touchosc_disp = {arg param_dict;
	var msg, val;
	msg = '/1/volume';
	val = param_dict[\volume];
	("New" ++ val.asString).postln;
	adrs_touchOSC.sendMsg(msg, val);
};

// Update the parameter of a synth in the array and in the synth
update_synth_param = {arg pname, pval;
	// Update the array of parameters
	finch_param_arr[active_synth].put(pname, pval);
	// Update the synth
	x[active_synth].set(pname, pval);
};


///// Finchesizer

SynthDef(\finch, {arg pressure=0, tension=0, time_const=24000, volume=0,
	pdepth=0, prate=0, tdepth=0, trate=0;
	var sig, time_smooth;
	time_smooth = 0.05; // smooth changes in control vals
	sig = SyrinxL.ar(
		freq:22050,
		a: pressure.lag(time_smooth) + SinOsc.kr(prate, mul:pdepth),
		b: tension.lag(time_smooth) + SinOsc.kr(trate, mul:tdepth),
		g: time_const.lag(time_smooth),
		h: 0.00001, // Should this be some other value?
		mul: 6 * volume.lag(time_smooth));
	Out.ar(0, sig);
}).add;

/*
// Get the parameters of the synth right now
~synth_val_poll; // variable for getting synth vals
get_synth_param = {arg synth, param_name;
	synth.get(param_name, {arg val; ~synth_val_poll = val});
	~synth_val_poll
};

get_finch_params = {arg n_synth, param_names=nil;
	// var out_dict;
	// n_synth.postln;
	// if (
	// 	param_names.isNil,
	// 	{param_names = finch_param_names},
	// 	{}
	// );
	// out_dict = Dictionary.new;
	// "\n".postln;
	// param_names.do({arg pname;
	// 	var prm;
	// 	prm = get_synth_param.value(x[n_synth], pname);
	// 	prm.postln;
	// 	out_dict.put(pname, prm);
	// 	// var prm;
	// 	// prm = x[n_synth].get(
	// 	// 	pname,
	// 	// 	{arg val;
	// 	// 		("\\" ++ pname ++ " -> " ++ val.asString ++ ",").postln;
	// 	// 		// out_dict.put(pname, val);
	// 	// 		// out_dict.add(pname -> val);
	// 	// 		// out_dict.postln;
	// 	// 		val.asInt
	// 	// 		out_dict.put(pname, prm);
	// 	//
	// 	// });
	// });
	// out_dict.postln;
	// // out_dict
};
*/
//
// update_ipad_disp = {arg param_dict;
// 	var msg, val;
// 	// params = get_finch_params(n_synth, finch_params.keys);
// 	// param_dict.keys.do({
// 	// 	msg_name =
// 	// 	adrs_touchOSC.sendMsg(touchOSC_msg[i], view.value);
// 	// });
// 	msg = '/1/volume';
// 	val = param_dict['volume'];
// 	adrs_touchOSC.sendMsg(msg, val);
// };

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
		var pres, tens;
		pres = msg[2] - 0.2;
		tens = msg[1] - 0.2;
		update_synth_param.(\pressure, pres);
		update_synth_param.(\tension, tens);
	},
	'/1/xy1'
);
OSCdef.new(
	\timeconst_resp,
	{|msg, time, addr, port|
		update_synth_param.(\time_const, 500 + (msg[1] * 48000));
	},
	'/1/time_const'
);
OSCdef.new(
	\pressure_mod_resp,
	{|msg, time, addr, port|
		// var pres, tens;
		// x[active_synth].set(\pdepth, msg[2] * 0.2);
		// x[active_synth].set(\prate, msg[1] * 50);
		update_synth_param.(\pdepth, msg[2] * 0.2);
		update_synth_param.(\prate, msg[1] * 50);
	},
	'/1/pressure_mod'
);
OSCdef.new(
	\tension_mod_resp,
	{|msg, time, addr, port|
		// var pres, tens;
		// x[active_synth].set(\tdepth, msg[2] * 0.2);
		// x[active_synth].set(\trate, msg[1] * 50);
		update_synth_param.(\tdepth, msg[2] * 0.2);
		update_synth_param.(\trate, msg[1] * 50);
	},
	'/1/tension_mod'
);

// Responders for selecting which finch to control
(1..4).do({arg n_finch;
	OSCdef.new(
		'finch_select' ++ n_finch.asString ++  '_resp',
		{|msg, time, addr, port|
			if (
				msg[1] == 1,
				{
					var new_active_synth;
					// Sorry...
					new_active_synth = msg[0].asString.at(18).asInt - 49;
					switch_control.(new_active_synth);
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
		finch_param_arr[active_synth].postln;
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
}).play



)






// Set lots of vals with a dictionary
(
var finch_params;
var set_finch_params, get_finch_params;

finch_params = Dictionary[
	\pressure -> 0.5,
	\tension -> 0.2,
	\time_const -> 24000,
	\amp -> 0.8,
	\pdepth -> 0.05,
	\prate -> 15,
	\tdepth -> 0.05,
	\trate -> 5
];

// A function to set the parameters of a synth in the synth array `x'.
set_finch_params = {arg n_synth, param_dict;
	param_dict.keys.do({arg pname;
		x[n_synth].set(pname, param_dict[pname]);
	});
};

// A function to get parameter values and do something with them.
get_finch_params = {arg n_synth, param_names;
	param_names.do({arg pname;
		x[n_synth].get(
			pname,
			// Do something! Adjust this function to change what's done.
			{arg val; ("\\" ++ pname ++ " -> " ++ val.asString ++ ",").postln}
		);
	});
};

set_finch_params.value(2, finch_params);
get_finch_params.value(2, finch_params.keys);

)






f.value(x[1]).postln;

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


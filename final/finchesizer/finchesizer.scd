/* Finchesizer

To use:
- Boot up the server (CMD-B).
- Change the variable adrs_touchOSC to the IP address of the tablet.
--- "Local IP address" on TouchOSC.
- Then execute the main block of code.
--- CMD-. in the main code, or in the toolbar: Language -> Evaluate File.

In TouchOSC (on the tablet), fix these settings:
Host: the IP address of the computer running SuperCollider.
- On a Mac, you can get that by entering "ifconfig en1" in Terminal,
---- and taking the "inet" IP address, not "broadcast".
Port (outgoing): 57120 (default for supercollider)
Port (incoming): 58100

To choose presets, change the variable called "presets" to have double-quoted
names of the preset files in square brackets. E.g. ["pre1.yaml", "pre2.yaml"];
The program will look for presets in the folder specified in preset_dir.
If these aren't entered correctly (case-sensitive), the program will puke.

To save presets, press 'save as preset' on the *Host computer* GUI.
This brings up a dialog box to save the current group to a YAML file.
Load presets by adding the filename to the "presets" array.

If everything gets confused, reboot the interpreter and the server.

*/

// Instead of changing the parameters from [0,1] to a useful range in the
//    SynthDef, this uses a function to change those values. That way, we
//    can save the meaningful values, instead of the TouchOSC parameters.
// This function is called when going from TouchOSC to the parameter dictionaries,
// which then get set into the synth. To go from preset dictionary values back
// to [0,1] for TouchOSC, call `descale' on the control value.
// Values sent back to TouchOSC need to be in the interval [0,1].

// Presets are loaded into the bank of presets in RAM.
// This is an array of arrays of dictionaries.
// Biggest array holds the presets available in RAM.
// Subarrays hold a group of synths.
// Each dict holds the settins for a single synth.

var adrs_touchOSC;
var active_synth, active_group, finch_defaults, n_synths, nPresets;
var switch_synth_control, switch_group_control;
var update_touchosc_disp, update_synth_param, update_synths_in_group;
var saveYAMLDict, saveYAML, loadYAML;
var load_preset_file, load_presets_dialog, save_presets_dialog, activate_preset_group;
var synthArr; // Array of active synths
var sourceGrp, fxGrp, outGrp; // Synth groups
var verbSynth, crushSynth, volSynth; // Effect synths
var finch_param_arr; // Array of dicts -- a group of synths
var preset_arr; // Array of Arrays of Dicts - preset synth groups
var win, btns;
var presets, preset_dir;
var rescale, descale;

// IP address of the iPad
adrs_touchOSC = NetAddr("10.150.103.182", 58100);

// Which presets to load on starting up the script
presets = [
	"blank.yaml", "oboe_c.yaml", "b-flat.yaml",
	"low_sound.yaml", "blips_1.yaml"];
preset_dir = thisProcess.nowExecutingPath.dirname  ++ "/presets/";

n_synths = 4;
nPresets = 6;
active_synth = 0; // Which finch is being controlled by TouchOSC
active_group = 0; // Which preset group is active now

finch_defaults = Dictionary[
	\pressure -> 0,
	\tension -> 0,
	\time_const -> 1000,
	\volume -> 0,
	\pdepth -> 0,
	\prate -> 0,
	\tdepth -> 0,
	\trate -> 0
];
finch_param_arr = Array.fill(n_synths, {finch_defaults.copy});
preset_arr = Array.fill(nPresets, {finch_param_arr.copy});


///// Useful functions

// Rescale parameters from [0,1] to a scale meaningful for the synth.
rescale = {arg pname, val;
	var scaling_funs;
	scaling_funs = Dictionary[
		\pressure -> {|x| x - 0.2},
		\tension -> {|x| x - 0.2},
		\time_const -> {|x| x.linexp(0, 1, 1000, 48000)},
		\volume -> {|x| x * 6},
		\pdepth -> {|x| x * 0.2},
		\prate -> {|x| x.linexp(0, 1, 0.05, 50)},
		\tdepth -> {|x| x * 0.2},
		\trate -> {|x| x.linexp(0, 1, 0.05, 50)}
	];
	scaling_funs[pname].value(val)
};
// Go from meaningful values to [0,1] for TouchOSC
descale = {arg pname, val;
	var scaling_funs;
	scaling_funs = Dictionary[
		\pressure -> {|x| x + 0.2},
		\tension -> {|x| x + 0.2},
		\time_const -> {|x| x.explin(1000, 48000, 0, 1)},
		\volume -> {|x| x / 6},
		\pdepth -> {|x| x / 0.2},
		\prate -> {|x| x.explin(0.05, 50, 0, 1)},
		\tdepth -> {|x| x / 0.2},
		\trate -> {|x| x.explin(0.05, 50, 0, 1)}
	];
	scaling_funs[pname].value(val)
};

// Update the parameter of a synth in the array and in the synth
update_synth_param = {arg pname, pval, rescale_vals=true;
	var new_val;
	if(rescale_vals,
		{new_val = rescale.(pname, pval)},
		{new_val = pval}
	);
	// Update the array of parameters
	finch_param_arr[active_synth].put(pname, new_val);
	// Update the synth
	synthArr[active_synth].set(pname.asSymbol, new_val);
};

update_synths_in_group = {
	var prev_active = active_synth;
	n_synths.do({arg n_synth; // Loop through synths in the group
		active_synth = n_synth;
		finch_param_arr[active_synth].keys.do({arg pname;
			update_synth_param.value(
				pname,
				finch_param_arr[n_synth][pname],
				rescale_vals:false);
		})
	});
	active_synth = prev_active;
};

// Change TouchOSC control to a new synth
switch_synth_control = {arg new_synth;
	var old_synth, active_params;
	old_synth = active_synth;
	// Update active_synth
	active_synth = new_synth;
	// Update TouchOSC display to reflect new active synth
	active_params = finch_param_arr.at(new_synth);
	update_touchosc_disp.value(active_params);
};

// Change to a different preset group
switch_group_control = {arg new_group;
	finch_param_arr = preset_arr[new_group];
	active_group = new_group;
	update_synths_in_group.value;
	// Activate LED to show which preset is being used.
	// Turn off other LEDs.
	// address: /2/led1 through /2/led6
	(1..6).do({|i|
		adrs_touchOSC.sendMsg('/2/led' ++ i.asSymbol, 0);
	});
	adrs_touchOSC.sendMsg('/2/led' ++ (new_group + 1).asSymbol, 1);

};

// Update display on TouchOSC to show params of active synth
update_touchosc_disp = {arg param_dict;
	var	snd, ds;
	snd = {|msg, val| adrs_touchOSC.sendMsg(msg, *val)};
	ds = {|pname| descale.value(pname, param_dict[pname])};

	snd.('/1/volume', ds.(\volume));
	snd.('/1/time_const', ds.(\time_const));
	snd.('/1/xy', [ds.(\tension), ds.(\pressure)]);
	snd.('/1/pressure_mod', [ds.(\prate), ds.(\pdepth)]);
	snd.('/1/tension_mod', [ds.(\trate), ds.(\tdepth)]);

};

// Read and write as YAML files.
saveYAMLDict = {arg file_pointer, dict;
	dict.keys.do({arg param;
		var line;
		line = "  " ++ param ++ ": " ++ dict[param].asString ++ "\n";
		file_pointer.write(line);
	});
};
saveYAML = {arg fname;
	var file_pointer;
	file_pointer = File(fname, "w");
	finch_param_arr.do({arg param_dict, i;
		file_pointer.write("- \n");
		saveYAMLDict.value(file_pointer, param_dict);
	});
	file_pointer.close();
};
loadYAML = {arg fname;
	var raw, cooked;
	raw = fname.parseYAMLFile;
	cooked = Array.fill(raw.size, {|i|
		var cooked_dict, raw_dict;
		raw_dict = raw[i];
		cooked_dict = Dictionary[];
		raw_dict.keys.do({arg param_name;
			cooked_dict[param_name.asSymbol] = raw_dict[param_name].asFloat;
		});
		cooked_dict
	});
};

load_preset_file = {arg fn;
	var file_cont, msg;
	if(not(File.existsCaseSensitive(fn)),
		{("Preset does not exist. Check file path.").error;},
		{}
	);
	file_cont = loadYAML.(fn);
	preset_arr[active_group] = file_cont;
	finch_param_arr = file_cont;
	// Set label to show filename
	// address: /2/label1 through /2/label6
	msg = '/2/label' ++ (active_group+1).asSymbol;
	adrs_touchOSC.sendMsg(msg, fn.asString.split($/).last);
	// Update all the synths in the group
	update_synths_in_group.value;
};

load_presets_dialog = {
	File.openDialog(
		"Load settings",
		{|fn| load_preset_file.value(fn)},
		{}
	);
};

save_presets_dialog = {
	File.saveDialog(
		"Save settings as preset",
		"X.yaml",
		{|fn| saveYAML.value(fn)},
		{}
	);
};


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
OSCdef.new(
	\time_smooth_resp,
	{|msg, time, addr, port|
		synthArr.do({|snth| snth.set(\time_smooth, msg[1])});
	},
	'/2/time_smooth'
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
					switch_synth_control.(new_synth);
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

// Presets
(1..nPresets).do({arg nPreset; // Switch to a new preset.
	OSCdef.new(
		'pm_select_' ++ nPreset.asString,
		{|msg, time, addr, port|
			switch_group_control.value(nPreset - 1);
		},
		'/2/preset_mult_bank/' ++ nPreset.asString ++ '/1';
	);
});


// Effects
OSCdef.new(
	\bc_on_resp,
	{|msg, time, addr, port|
		// if (msg[1] == 1,
		// 	{crushSynth = Synth.tail(s, \bitcrusher);},
		// {crushSynth.free;});
		crushSynth.set(\mix, msg[1]);
	},
	'/1/bc_on'
);
OSCdef.new(
	\bc_depth_resp,
	{|msg, time, addr, port|
		var bd;
		bd = (msg[1] * 12).round + 3;
		crushSynth.set(\bit_depth, bd);
	},
	'/1/bc_depth'
);
OSCdef.new(
	\bc_rate_resp,
	{|msg, time, addr, port|
		crushSynth.set(\bit_rate, msg[1] * 20000);
	},
	'/1/bc_rate'
);

// OSCdef.new(
// 	\verb_on_resp,
// 	{|msg, time, addr, port|
// 		if (msg[1] == 1,
// 			{verbSynth = Synth.tail(s, \verb);},
// 		{verbSynth.free;});
// 	},
// 	'/1/verb_on'
// );
OSCdef.new(
	\verb_mix_resp,
	{|msg, time, addr, port|
		verbSynth.set(\mix, msg[1]);
	},
	'/1/verb_mix'
);
OSCdef.new(
	\verb_room_resp,
	{|msg, time, addr, port|
		verbSynth.set(\room, msg[1]);
	},
	'/1/verb_room'
);
OSCdef.new(
	\verb_damp_resp,
	{|msg, time, addr, port|
		verbSynth.set(\damp, msg[1]);
	},
	'/1/verb_room'
);

OSCdef.new(
	\verb_damp_resp,
	{|msg, time, addr, port|
		verbSynth.set(\damp, msg[1]);
	},
	'/1/verb_room'
);

OSCdef.new(
	\master_vol_resp,
	{|msg, time, addr, port|
		volSynth.set(\vol, msg[1]);
	},
	'/1/master_vol'
);

// // Set up the GUI for saving and loading
// h = 50;
// win = GUI.window.new("finchesizer",
// Rect(100, 100, (h + 7) * 2, h + 10));
// win.view.decorator = FlowLayout(win.view.bounds);
// win.view.background = Color(0,0,0);
// win.front;
// btns = Array.newClear(2);
// b = Button(win, Rect(25, 25, 2*h, h));
// b.states = [["save as preset"]];
// b.action = {|val| save_presets_dialog.value};
// btns.put(1, b);


///// Rev up the finchesizers
Task({
	// Load the finchesizer synth def
	"finchesizer_synths.scd".loadRelative;

	s.sync; // wait for the server

	~sourceBus = Bus.audio(s, 2);
	~fxBus = Bus.audio(s, 2);

	sourceGrp = Group.new;
	fxGrp = Group.after(sourceGrp);
	outGrp = Group.after(fxGrp);

	Synth.new(\masterout, [in:~fxBus, out:0], outGrp);

	crushSynth = Synth.new(\bitcrusher, [in:~fxBus, out:~fxBus], fxGrp);
	verbSynth = Synth.new(\verb, [in:~fxBus, out:~fxBus], fxGrp);
	volSynth = Synth.new(\mastervolume, [in:~sourceBus,out:~fxBus], fxGrp);

	synthArr = Array.fill(n_synths, {|pan|
		Synth.new(
			\finch,
			[pan: pan.linlin(0, 3, -1, 1), out:~sourceBus],
			sourceGrp)
	});

	// Load presets
	presets.do({arg fname, i;
		switch_group_control.value(i);
		load_preset_file.value(preset_dir ++ fname);
	});
	switch_group_control.value(0);

}).play;

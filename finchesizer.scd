(
var run_finchesizer;

run_finchesizer = {arg //adrsTouchOSC,
	touchIP, touchPort,
	preset_dir, presets;
	var adrsTouchOSC, adrsTouchRecv;
	var active_synth, active_group, finch_defaults, n_synths, nPresets;
	var switch_synth_control, switch_group_control;
	var update_touchosc_disp, update_synth_param, update_synths_in_group;
	var saveYAMLDict, saveYAML, loadYAML;
	var load_preset_file, load_presets_dialog, save_presets_dialog, activate_preset_group;
	var finch_param_arr; // Array of dicts -- a group of synths
	var preset_arr; // Array of Arrays of Dicts - for holding preset synth groups in RAM
	var win, btns;
	// var presets, preset_dir;
	var rescale, descale;

	// var touchIP = 'FILLER';

	// IP address of the iPad
	adrsTouchOSC = NetAddr(touchIP, touchPort);
	// adrsTouchRecv = NetAddr(touchIP, 57120);
	// // Which presets to load on starting up the script
	// preset_dir = "/Users/gbrookshire/Documents/projects/music/sc/markov_sequencer/presets/";
	// presets = ["blank.yaml", "rumples.yaml", "sirens.yaml",
	// "oboe_c.yaml", "beginning_rumble.yaml", "beginning.yaml"];

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
		x[active_synth].set(pname.asSymbol, new_val);
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
			adrsTouchOSC.sendMsg('/2/led' ++ i.asSymbol, 0);
		});
		adrsTouchOSC.sendMsg('/2/led' ++ (new_group + 1).asSymbol, 1);

	};

	// Update display on TouchOSC to show params of active synth
	update_touchosc_disp = {arg param_dict;
		var	snd, ds;
		snd = {|msg, val| adrsTouchOSC.sendMsg(msg, *val)};
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
		adrsTouchOSC.sendMsg(msg, fn.asString.split($/).last);
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


	///// Finchesizer

	SynthDef(\finch, {arg pressure=0, tension=0, time_const=1000, volume=0,
		pdepth=0, prate=0, tdepth=0, trate=0, time_smooth=0, pan=0;
		var sig;
		time_smooth = time_smooth * 60; // smooth changes in control vals
		sig = SyrinxL.ar(
			freq: 22050,
			a: pressure.lag(time_smooth) + SinOsc.kr(prate, mul:pdepth),
			b: tension.lag(time_smooth) + SinOsc.kr(trate, mul:tdepth),
			g: time_const.lag(time_smooth),
			h: 0.00001,
			mul: volume.lag(time_smooth));
		Out.ar(0, Pan2.ar(sig, pan));
	}).add;


	///// Effects -- stereo

	SynthDef(\bitcrusher, {arg bit_depth=10, bit_rate=20000;
		var sigs;
		sigs = [In.ar(0), In.ar(1)];
		// Reduce the sampling rate
		sigs = Latch.ar(sigs, SinOsc.ar(bit_rate));
		// Reduce the bit depth
		sigs = ((sigs * (2 ** bit_depth)).round) / (2 ** bit_depth);
		ReplaceOut.ar(0, sigs);
	}).add;

	SynthDef(\verb, {arg mix=0, room=0, damp=0;
		var sigs;
		sigs = [In.ar(0), In.ar(1)];
		sigs = FreeVerb2.ar(sigs[0], sigs[1],
			mix: mix.lag(0.1),
			room: room.lag(0.1),
			damp: damp.lag(0.1));
		ReplaceOut.ar(0, sigs);
	}).add;

	SynthDef(\mastervolume, {arg vol=1;
		var sigs;
		sigs = [In.ar(0), In.ar(1)];
		sigs = sigs * vol.lag(0.2);
		ReplaceOut.ar(0, sigs);
	}).add;

	///// OSC responders

	OSCdef.new(
		\volume_resp ++ touchIP,
		{|msg, time, addr, port|
			update_synth_param.(\volume, msg[1]);
		},
		'/1/volume'
	);
	OSCdef.new(
		\finch_resp ++ touchIP,
		{|msg, time, addr, port|
			update_synth_param.(\tension, msg[1]);
			update_synth_param.(\pressure, msg[2]);
		},
		'/1/xy'
	);
	OSCdef.new(
		\timeconst_resp ++ touchIP,
		{|msg, time, addr, port|
			update_synth_param.(\time_const, msg[1]);
		},
		'/1/time_const'
	);
	OSCdef.new(
		\pressure_mod_resp ++ touchIP,
		{|msg, time, addr, port|
			update_synth_param.(\prate, msg[1]);
			update_synth_param.(\pdepth, msg[2]);
		},
		'/1/pressure_mod'
	);
	OSCdef.new(
		\tension_mod_resp ++ touchIP,
		{|msg, time, addr, port|
			update_synth_param.(\trate, msg[1]);
			update_synth_param.(\tdepth, msg[2]);
		},
		'/1/tension_mod'
	);
	OSCdef.new(
		\time_smooth_resp ++ touchIP,
		{|msg, time, addr, port|
			x.do({|snth| snth.set(\time_smooth, msg[1])});
		},
		'/2/time_smooth'
	);

	// Responders for selecting which finchesizer to control
	(1..n_synths).do({arg n_finch;
		OSCdef.new(
			'finch_select' ++ n_finch.asString ++ '_resp' ++ touchIP,
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
		\dump_resp ++ touchIP,
		{|msg, time, addr, port|
			finch_param_arr[active_synth].postln
		},
		'/1/dump'
	);

	// Presets
	(1..nPresets).do({arg nPreset; // Switch to a new preset.
		OSCdef.new(
			'pm_select_' ++ nPreset.asString ++ touchIP,
			{|msg, time, addr, port|
				switch_group_control.value(nPreset - 1);
			},
			'/2/preset_mult_bank/' ++ nPreset.asString ++ '/1';
		);
	});


	// Effects
	OSCdef.new(
		\bc_on_resp ++ touchIP,
		{|msg, time, addr, port|
			if (msg[1] == 1,
				{y = Synth.tail(s, \bitcrusher);},
				{y.free;});
		},
		'/1/bc_on'
	);
	OSCdef.new(
		\bc_depth_resp ++ touchIP,
		{|msg, time, addr, port|
			var bd;
			bd = (msg[1] * 12).round + 3;
			y.set(\bit_depth, bd);
		},
		'/1/bc_depth'
	);
	OSCdef.new(
		\bc_rate_resp ++ touchIP,
		{|msg, time, addr, port|
			y.set(\bit_rate, msg[1] * 20000);
		},
		'/1/bc_rate'
	);

	OSCdef.new(
		\verb_on_resp ++ touchIP,
		{|msg, time, addr, port|
			if (msg[1] == 1,
				{z = Synth.tail(s, \verb);},
				{z.free;});
		},
		'/1/verb_on'
	);
	OSCdef.new(
		\verb_mix_resp ++ touchIP,
		{|msg, time, addr, port|
			z.set(\mix, msg[1]);
		},
		'/1/verb_mix'
	);
	OSCdef.new(
		\verb_room_resp ++ touchIP,
		{|msg, time, addr, port|
			z.set(\room, msg[1]);
		},
		'/1/verb_room'
	);
	OSCdef.new(
		\verb_damp_resp ++ touchIP,
		{|msg, time, addr, port|
			z.set(\damp, msg[1]);
		},
		'/1/verb_room'
	);

	OSCdef.new(
		\verb_damp_resp ++ touchIP,
		{|msg, time, addr, port|
			z.set(\damp, msg[1]);
		},
		'/1/verb_room'
	);

	OSCdef.new(
		\master_vol_resp ++ touchIP,
		{|msg, time, addr, port|
			if (addr.ip == touchIP, {
				v.set(\vol, msg[1]);
			});
		},
		'/1/master_vol',
	);

	// Set up the GUI for saving and loading
	h = 50;
	win = GUI.window.new("finchesizer",
		Rect(100, 100, (h + 7) * 2, h + 10));
	win.view.decorator = FlowLayout(win.view.bounds);
	win.view.background = Color(0,0,0);
	win.front;
	btns = Array.newClear(2);
	b = Button(win, Rect(25, 25, 2*h, h));
	b.states = [["save as preset"]];
	b.action = {|val| save_presets_dialog.value};
	btns.put(1, b);



	///// Rev up the finchesizers
	Task({
		s.sync; // wait for the server

		x = Array.fill(n_synths, {|pan|
			Synth.new(\finch, [\pan, pan.linlin(0, 3, -1, 1)])
		});

		v = Synth.tail(s, \mastervolume);

		// Load presets
		presets.do({arg fname, i;
			switch_group_control.value(i);
			load_preset_file.value(preset_dir ++ fname);
		});
		switch_group_control.value(0);

	}).play;

	adrsTouchOSC.postln;

};

run_finchesizer.value(
	// NetAddr("192.168.1.139", 58100),
	"192.168.1.139", 58100,
	"/Users/gbrookshire/Documents/projects/music/sc/markov_sequencer/presets/",
	["blank.yaml", "beginning.yaml", "oboe_c.yaml"]
);


)


// Make sure the OSCDefs only pay attention to input from the TouchOSC IP address,
// And that they only send to that IP address.

run_finchesizer.value(
	NetAddr("192.168.1.139", 58100),
	"/Users/gbrookshire/Documents/projects/music/sc/markov_sequencer/presets/",
	["blank.yaml", "beginning.yaml", "oboe_c.yaml"]
);

~run_finchesizer.value(
	NetAddr("192.168.1.110", 58100),
	"/Users/gbrookshire/Documents/projects/music/sc/markov_sequencer/presets/",
	["blank.yaml", "beginning.yaml", "sirens.yaml",]
);


)

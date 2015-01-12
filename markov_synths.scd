(
var win;
var param_vals, param_names, param_ranges;

~node_functions = [55, 60, 65, 67, 70, 73, 75, 77];

param_names = ["fms", "fmd", "bit_click_rate"];
param_vals = [0, 0, 20/50];
param_ranges = [300, 100, 50];

// GUI to modulate parameters
win = GUI.window.new("Transition matrix",
	Rect(100, 100, 300, 120));
win.view.background = Color(0.15,0.15,0.1);
win.front;

param_names.do({|val, ind|
	var slide, text;
	text = GUI.staticText.new(win, Rect(10 + (40 * ind), 5, 30, 15));
	text.string = " " ++ val;
	text.background = Color.grey;

	slide = GUI.slider.new(win, Rect(10 + (40 * ind), 20, 30, 80));
	slide.knobColor_(Color(1,1,0.51));
	slide.background_(Color.grey);
	slide.value_(0);
	slide.action_({|view|
		param_vals[ind] = view.value;
	});
});

SynthDef(\singrain, { |freq = 440, amp = 0.2, sustain = 1,
	fms=100, fmd=100, bit_click_rate=10|
	var sig, env, freq_mod, out;

	freq_mod = LFNoise0.kr(freq:fms, mul:fmd);
	freq = freq + freq_mod;

	env = EnvGen.kr(Env.perc(0.01, sustain), doneAction:2);
	sig = SinOsc.ar(freq, mul:amp);
	sig = sig * LFNoise0.ar(bit_click_rate);
	out = sig * env;

	sig = FreeVerb.ar(out, mix:0.1);
	Out.ar(0, out ! 2);
}).add;

// Here's the function that gets triggered by the sequencer.
~ping = {|freq|
	x = Synth(\singrain,
		[freq:freq.midicps, amp:rrand(0.1, 0.5), sustain:2]);
	param_names.do({|val, ind|
		x.set(val, param_vals[ind] * param_ranges[ind]);
	})
};

)
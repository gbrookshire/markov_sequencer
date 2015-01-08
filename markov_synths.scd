(
var win;
var param_vals, param_names, param_ranges;

param_names = ["fms", "fmd", "bit_click_rate"];
param_vals = [0, 0, 20/50];
param_ranges = [100, 20, 50];

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
	var sig, env;
	var freq_mod;

	freq_mod = LFNoise0.kr(freq:fms, mul:fmd);

	env = EnvGen.kr(Env.perc(0.01, sustain), doneAction:2);
	sig = SinOsc.ar(freq + freq_mod, mul:amp);
	sig = sig * LFNoise0.ar(bit_click_rate);
	sig = sig * env;
	Out.ar(0, sig ! 2);
}).add;

~ping = {|freq|
	x = Synth(\singrain,
		[freq:freq, amp:rrand(0.1, 0.5), sustain:2]);
	param_names.do({|val, ind|
		x.set(val, param_vals[ind] * param_ranges[ind]);
	})
};

)
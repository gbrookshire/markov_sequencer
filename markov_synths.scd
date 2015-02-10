(

SynthDef(\singrain, { |freq = 440, amp = 0.2, sustain = 1,
	fms=100, fmd=100, bit_click_rate=10|
	var sig, env, freq_mod, out;
	var bit_depth;

	freq_mod = LFNoise0.kr(freq:fms, mul:fmd);
	freq = freq + freq_mod;

	env = EnvGen.kr(Env.perc(0.01, sustain), doneAction:2);
	sig = SinOsc.ar(freq, mul:amp);
	sig = sig * LFNoise0.ar(bit_click_rate);

	// Reduce the sampling rate
	sig = Latch.ar(sig, SinOsc.ar(LFNoise2.kr(freq:0.1, mul:5000, add:5000)));
	// Reduce the bit depth
	bit_depth = {10.rand + 1}.value;
	sig = ((sig * (2 ** bit_depth)).round) / (2 ** bit_depth);

	// Apply some reverb
	sig = FreeVerb.ar(sig, mix:0.1);

	out = sig * env;

	Out.ar(0, out ! 2);
}).add;
)

(
var win;
var param_vals, param_names, param_ranges;

~node_functions = [55, 60, 65, 67, 70, 73, 75, 77];

param_names = ["fms", "fmd", "bit_click_rate"];
param_vals = [0, 0, 0];
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

// Here's the function that gets triggered by the sequencer.
~ping = {|freq|
	x = Synth(\singrain,
		[freq:freq.midicps, amp:rrand(0.1, 0.5), sustain:2]);
	param_names.do({|val, ind|
		x.set(val, param_vals[ind] * param_ranges[ind]);
	})
};

)
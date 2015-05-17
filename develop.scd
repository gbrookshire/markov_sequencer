(
SynthDef(\twang, {arg
	freq=440, amp=1, rise_time=0.005, decay=1,
	mod_strength=10, mod_decay=0.25, wobble=0;

	var env, sig,
	freq_rise, freq_mod;

	freq_rise = Line.kr(0.01, 1, rise_time);
	freq = freq * (freq_rise / (1 + freq_rise));
	freq_mod = abs(LFNoise0.kr(100, mul:XLine.kr(mod_strength, 0.01, mod_decay), add:1));
	freq = freq * freq_mod;
	freq = freq + LFNoise0.kr(80, mul:wobble, add:1);

	env = EnvGen.kr(Env.perc(0.025, decay), doneAction:2);
	sig = SinOsc.ar(freq * [1, 4, 5, 8], mul:[0.9, 0.8, 0.7, 0.4]);
	sig = Mix.new(sig);
	sig = (sig * amp * 0.08);

	Out.ar(0, Pan2.ar(sig * env, LFNoise0.kr(0.5) ** 2));
}).add;

SynthDef(\sputter, {arg freq=440, wobble=0, resonate=0, decay=0.2, chaos=1.95, amp=1;
	var env, sig;

	env = EnvGen.kr(Env.perc(0.005, decay), doneAction:2);
	sig = Crackle.ar(chaos) + Crackle.ar(chaos) + Crackle.ar(chaos);
	sig = Ringz.ar(sig,
		[1, 3, 5] * freq + LFNoise1.kr(1, mul:wobble, add:1) + LFNoise0.kr(100, 100, 1),
		resonate.linlin(0, 1, 0.002, 0.1));
	sig = Mix.new(sig);
	sig = sig * ((1 - resonate + 0.1));
	sig = 0.06 * sig.softclip;
	sig = sig * amp;

	Out.ar(0, Pan2.ar(sig * env, LFNoise0.kr(0.5) ** 2));
}).add;
)


(
var goFunc1, nodeVals1;
var goFunc2, nodeVals2;
var timing_func;
var final_m, final_n, linear_mat;

~tempo = 1.1;
~scaler = 1; // Adjust this value to adjust the rest

~timing_func = {|jit, temp, divisor|
	// Returns a timing function, which returns a time difference
	// between this note and the following note.
	var fnc;
	fnc = {[1, 1, 2].choose * abs(rrand(1 - jit, 1 + jit)) * temp / divisor};
	fnc
};

// Functions for chain 1
goFunc1 = {|freq|
	Synth(\twang, [freq:freq.midicps,
		decay:((1 - ~scaler)**2) + 0.15,
		mod_strength:(~scaler * 10),
		mod_decay:(~scaler * 0.6),
		wobble: ~scaler * 100,
	])
};
nodeVals1 = [0, 10, 5, 15, -5, 0, -10, -5] + 48;
final_m = [
	0,1,0,0,0,0,0,0,
	0,0,1,0,0,0,0,0,
	0,0,0,1,0,5,5,0,
	1,0,0,0,1,0,0,0,
	0,0,0,0,0,1,0,0,
	0,0,1,0,0,0,1,0,
	0,0,0,0,0,1,0,1,
	1,0,0,0,0,1,0,0
];


// Functions for chain 2
goFunc2 = {|freq|
	Synth(\sputter, [freq:freq.midicps,
		decay: ((1 - ~scaler)**2) + 0.04,
		resonate: (1 - ~scaler)**2,
		wobble: ~scaler * 5,
		amp: (~scaler * 3) + 1
	])
};
nodeVals2 = [0, 6, 2, 10, -2, 8, -4] + 65;
final_n = [
	0,1,0,0,0,0,0,
	0,3,1,3,0,0,0,
	0,0,0,1,0,0,0,
	0,0,0,0,1,2,2,
	0,0,0,0,0,1,0,
	1,0,0,0,0,0,1,
	1,0,0,0,0,0,0,
];

m = MarkovSeq(goFunc1, nodeVals1);
n = MarkovSeq(goFunc2, nodeVals2);


// // A slider to change a bunch of parameters about the sound.
// OSCdef.new(
// 	\scaler_resp,
// 	{|msg, time, addr, port|
// 		~scaler = 1 - msg[1];
// 		~scaler.postln;
// 		~jitter = 2.0 * ~scaler;
// 		m.timing_func = timing_func.(~jitter, ~tempo, 4);
// 		n.timing_func = timing_func.(~jitter, ~tempo, 6);
// 	},
// 	'/1/scaler'
// );

// Start the chains
Task({
	s.sync; // wait for the server
	m.timing_func = ~timing_func.(2.0 * ~scaler, ~tempo, 2);
	n.timing_func = ~timing_func.(2.0 * ~scaler, ~tempo, 4);
	m.run;
	n.run;
}).play;

// Start developing from noisy to clean sounds
Task({
	var noise_strength, noise_mat, first;
	noise_strength = 6.0;
	first = true;

	loop {
		var delta = 1.0;
		noise_strength.postln;
		~scaler.postln;

		// Add the transition matrix to a matrix of noise
		m.transition_mat = Array2D.fromArray(
			nodeVals1.size,
			nodeVals1.size,
			Array.rand(nodeVals1.size**2, 0, noise_strength) + final_m);
		n.transition_mat = Array2D.fromArray(
			nodeVals2.size,
			nodeVals2.size,
			Array.rand(nodeVals2.size**2, 0, noise_strength) + final_n);

		m.timing_func = ~timing_func.(2.0 * ~scaler, ~tempo, 3);
		n.timing_func = ~timing_func.(2.0 * ~scaler, ~tempo, 4);

		// Don't make any changes at first
		if (first, {30.wait; first=false;}, {});

		noise_strength = noise_strength - 0.1;
		~scaler = ~scaler * 0.95;
		if (~scaler < 0, {~scaler = 0}, {});
		if (noise_strength < 0, {noise_strength = 0}, {});
		delta.yield;
	}
}).play;

Task({
	var dens = [2, 1.5, 1, 0.8, 0.6, 0.4, 0.2, 0.15, 0.3, 0.4, 0.25, 0.4, 0.7, 0.9, 1.2];
	dens = ~tempo * dens;
	10.wait;
	dens.do{|val|
		~tempo = val;
		m.timing_func = ~timing_func.(2.0 * ~scaler, ~tempo, 3);
		n.timing_func = ~timing_func.(2.0 * ~scaler, ~tempo, 6);
		5.wait;
	};
}).play;

)


m.pause;
m.transition_mat = Array2D.fromArray(7, 7, [
	9,1,0,0,0,0,0,
	9,1,2,0,0,0,0,
	9,0,0,1,0,0,0,
	9,0,0,0,1,1,2,
	9,0,0,0,0,1,0,
	9,0,0,0,0,0,1,
	9,0,0,0,0,0,0,
])









Synth(\sputter, [resonate:0.0, decay:0.04, amp:3])
Synth(\twang)

// Recording
Server.default.makeGui
s.prepareForRecord("/Users/gbrookshire/Desktop/markov_test.wav");
s.record;
s.stopRecording;

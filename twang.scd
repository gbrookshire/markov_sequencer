(
SynthDef(\twang, {arg
	freq=440, amp=1, rise_time=0.1, decay=1,
	mod_strength=10, mod_decay=0.25;

	var env, sig,
	freq_rise, freq_mod;

	freq_rise = Line.kr(0.01, 1, rise_time);
	freq = freq * (freq_rise / (1 + freq_rise));
	freq_mod = abs(LFNoise0.kr(100, mul:XLine.kr(mod_strength, 0.01, mod_decay), add:1));
	freq = freq * freq_mod;

	env = EnvGen.kr(Env.perc(0.05, decay), doneAction:2);
	sig = Saw.ar(freq);
	sig = LPF.ar(sig, freq=XLine.kr(15000, 100, decay));
	sig = (sig * amp * 0.3);

	Out.ar([0,1], sig * env);
}).add;

SynthDef(\sputter, {arg freq=440, resonate=0, decay=0.2, chaos=1.95;
	var env, sig;

	env = EnvGen.kr(Env.perc(0.005, decay), doneAction:2);
	sig = Crackle.ar(chaos) + Crackle.ar(chaos) + Crackle.ar(chaos);
	sig = Ringz.ar(sig,
		[1, 3, 5] * freq,
		resonate.linlin(0, 1, 0.002, 0.1));
	sig = Mix.new(sig);
	sig = sig * ((1 - resonate + 0.1));
	sig = 0.05 * sig;

	Out.ar([0, 1], sig * env);
}).add;
)

Synth(\sputter, [resonate:0.0, decay:0.2])
Synth(\twang)

(
var goFunc1, nodeVals1;
var goFunc2, nodeVals2;
var timing_func;
var final_m, final_n, linear_mat;

~tempo = 1;
~scaler = 1; // Adjust this value to adjust the rest

~decay = ((1 - ~scaler) * 2) + 0.1;
~mod_strength = 10;
~mod_decay = 0.25;

timing_func = {|jit, temp, divisor|
	// Returns a timing function, which returns a time difference
	// between this note and the following note.
	var fnc;
	fnc = {[0, 1, 2].choose * abs(rrand(1 - jit, 1 + jit)) * temp / divisor};
	fnc
};

// A slider to change a bunch of parameters about the sound.
OSCdef.new(
	\scaler_resp,
	{|msg, time, addr, port|
		~scaler = 1 - msg[1];
		~scaler.postln;
		~jitter = 2.0 * ~scaler;
		m.timing_func = timing_func.(~jitter, ~tempo, 4);
		n.timing_func = timing_func.(~jitter, ~tempo, 6);
	},
	'/1/scaler'
);

// Functions for chain 1
goFunc1 = {|freq|
	Synth(\twang, [freq:freq.midicps,
		decay:((1 - ~scaler) * 2) + 0.1,
		mod_strength:(~scaler * 10),
		mod_decay:(~scaler * 0.6),
	])
};
nodeVals1 = [0, 7, -5, 12, 0, 5, -12, -5] + 60;
final_m = [
	0,1,0,0,0,0,0,0,
	0,0,1,0,0,0,0,0,
	0,0,0,1,0,0,0,0,
	0,0,0,0,1,0,0,0,
	0,0,0,0,0,1,0,0,
	0,0,0,0,0,0,1,0,
	0,0,0,0,0,0,0,1,
	1,0,0,0,0,0,0,0
	];


// Functions for chain 2
goFunc2 = {|freq|
	Synth(\sputter, [freq:freq.midicps,
		amp:(1 - ~scaler)**2,
		decay:(1 - ~scaler) + 0.01,
		resonate:(1 - ~scaler),
	])
};
nodeVals2 = [0, 7, 2, 5, -3, -7, -5] + 65;
final_n = [
	0,1,0,0,0,0,0,
	0,1,2,0,0,0,0,
	0,0,0,1,0,0,0,
	0,0,0,0,1,0,0,
	0,0,0,0,0,1,0,
	1,0,0,0,0,0,1,
	1,0,0,0,0,0,0,
];

m = MarkovSeq(goFunc1, nodeVals1);
// m.initTouchOSC("192.168.1.139", 58100, '/1');
// m.createGUI;

n = MarkovSeq(goFunc2, nodeVals2);
// n.initTouchOSC("192.168.1.139", 58100, '/2');
// n.createGUI;

// linear_mat = [
// 	0,1,0,0,0,0,0,0,
// 	0,0,1,0,0,0,0,0,
// 	0,0,0,1,0,0,0,0,
// 	0,0,0,0,1,0,0,0,
// 	0,0,0,0,0,1,0,0,
// 	0,0,0,0,0,0,1,0,
// 	0,0,0,0,0,0,0,1,
// 	1,0,0,0,0,0,0,0
// ];

Task({
	s.sync; // wait for the server
	m.timing_func = timing_func.(2.0 * ~scaler, ~tempo, 4);
	n.timing_func = timing_func.(2.0 * ~scaler, ~tempo, 6);
	m.run;
	n.run;
}).play;



Task({
	var noise_strength, noise_mat, first;
	noise_strength = 2.0;
	first = true;

	loop {
		var delta = 1;
		noise_strength.postln;
		~scaler.postln;

		noise_mat = Array.rand(8**2, 0, noise_strength);

		m.transition_mat = Array2D.fromArray(
			nodeVals1.size,
			nodeVals1.size,
			noise_mat + final_m);
		n.transition_mat = Array2D.fromArray(
			nodeVals2.size,
			nodeVals2.size,
			noise_mat + final_n);

		m.timing_func = timing_func.(2.0 * ~scaler, ~tempo, 4);
		n.timing_func = timing_func.(2.0 * ~scaler, ~tempo, 6);

		if (first, {15.wait; first=false;}, {}); // Wait before iterating through params

		noise_strength = noise_strength / 3;
		~scaler = ~scaler - 0.02;
		if (~scaler < 0, {~scaler = 0}, {});
		delta.yield;
	}
}).play;

)

m.stop;
n.stop;

m.run;
m.timing_func = 0.333;
~scaler = 0;
m.transition_mat = Array2D.fromArray(7, 7, [
	0,1,0,0,0,0,0,
	0,0.5,1,0,0,0,0,
	0,0,0,1,0,0,0,
	0,0,0,0,1,0,0,
	0,0,0,0,0,1,0,
	1,0,0,0,0,0,1,
	1,0,0,0,0,0,0,
]);

Server.default.makeGui
s.prepareForRecord("/Users/gbrookshire/Desktop/markov_test.wav");
s.record;
s.stopRecording;

Mix
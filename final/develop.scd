var goFunc1, nodeVals1, mrkv1, final1;
var goFunc2, nodeVals2, mrkv2, final2;
var goFunc3, nodeVals3, mrkv3, final3;
var markovArr;
var projectDir;
var tempo;

tempo = 1.1;
projectDir = thisProcess.nowExecutingPath.dirname;

~devScaler = 1; // Adjust this value to adjust the sounds

~devTimeFunc = {|jit, temp, divisor|
	// Returns a timing function, which returns a time difference
	// between this note and the following note.
	var fnc;
	fnc = {
		// [1, 1, 2].choose * abs(rrand(1 - jit, 1 + jit)) * temp / divisor
		abs(rrand(1 - jit, 1 + jit)) * temp / divisor
	};
	fnc
};

// Functions for chain 1
goFunc1 = {|freq|
	Synth(\twang, [freq:freq.midicps,
		decay:((1 - ~devScaler) ** 2) + 0.15,
		mod_strength:(~devScaler * 10),
		// mod_decay:(~devScaler * 0.6),
		wobble: ~devScaler * 100,
	])
};
nodeVals1 = [0, 10, 5, 14, -5, 0, -10, -5] + 57 - (2 * 12);
final1 = [
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
		decay: ((1 - ~devScaler) ** 2) + 0.04,
		resonate: (1 - ~devScaler) ** 4,
		wobble: (~devScaler ** 1.5) * 10,
		amp: (~devScaler * 3) + 1
	])
};
nodeVals2 = [0, 5, 2, 11, -5, 9, 7] + 60;
final2 = [
	0,1,0,0,0,0,0,
	0,1,1,3,0,0,0,
	0,0,0,1,0,1,2,
	0,0,0,0,1,2,2,
	0,0,0,0,0,1,0,
	1,0,0,0,0,0,1,
	1,0,0,0,0,0,0,
];

goFunc3 = {|freq|
	Synth(\gendy, [freq:freq.midicps,
		decay: ((1 - ~devScaler)**2) + 0.025,
		ascale: (~devScaler ** 0.5) + 0.001,
		dscale: (~devScaler ** 0.5) + 0.001,
	])
};
// nodeVals3 = [0, 6, 2, 10, -2, 8, -4] + 53;
nodeVals3 = [0, 3, 10, 12, 7, -2, -5] + 57;
final3 = [
	0,1,0,0,1,0,1,
	0,0,1,0,0,0,0,
	0,0,0,1,1,0,1,
	0,0,0,0,1,0,0,
	1,0,1,0,0,1,0,
	0,0,0,0,0,0,1,
	1,0,1,0,0,0,0
];

mrkv1 = MarkovSeq(goFunc1, nodeVals1);
mrkv2 = MarkovSeq(goFunc2, nodeVals2);
mrkv3 = MarkovSeq(goFunc3, nodeVals3);


// Start the chains
Task({
	s.sync; // wait for the server
	mrkv1.timing_func = ~devTimeFunc.(2.0 * ~devScaler, tempo, 2);
	mrkv2.timing_func = ~devTimeFunc.(2.0 * ~devScaler, tempo, 2);
	mrkv3.timing_func = ~devTimeFunc.(2.0 * ~devScaler, tempo, 2);
	mrkv1.run;
	mrkv2.run;
	mrkv3.run;
}).play;


// Start developing from noisy to clean sounds
Task({
	var noise_strength, noise_mat, first;
	noise_strength = 6.0;
	first = true;

	loop {
		var delta = 1.0;
		noise_strength.postln;
		~devScaler.postln;

		// Add the transition matrix to a matrix of noise
		mrkv1.transition_mat = Array2D.fromArray(
			nodeVals1.size,
			nodeVals1.size,
		Array.rand(nodeVals1.size**2, 0, noise_strength) + final1);
		mrkv2.transition_mat = Array2D.fromArray(
			nodeVals2.size,
			nodeVals2.size,
		Array.rand(nodeVals2.size**2, 0, noise_strength) + final2);
		mrkv3.transition_mat = Array2D.fromArray(
			nodeVals3.size,
			nodeVals3.size,
		Array.rand(nodeVals2.size**2, 0, noise_strength) + final3);

		// mrkv1.timing_func = ~devTimeFunc.(2.0 * ~devScaler, tempo, 3);
		// mrkv2.timing_func = ~devTimeFunc.(2.0 * ~devScaler, tempo, 4);
		// mrkv3.timing_func = ~devTimeFunc.(2.0 * ~devScaler, tempo, 6);

		// Don't make any changes at first
		if (first, {30.wait; first=false;}, {});

		noise_strength = noise_strength - 0.1;
		~devScaler = ~devScaler * 0.95;
		if (~devScaler < 0, {~devScaler = 0}, {});
		if (noise_strength < 0, {noise_strength = 0}, {});
		delta.yield;
	}
}).play;

// Change the density of notes by varying the timing function.
Task({
	var dens;
	dens = [
		2, 1.5, 1, 0.8, 0.6, 0.4,
		0.2, 0.15, 0.3, 0.4, 0.25,
	0.4, 0.7, 0.9, 1.2];
	dens = tempo * dens;
	10.wait;
	dens.do{|val|
		tempo = val;
		mrkv1.timing_func = ~devTimeFunc.(2.0 * ~devScaler, tempo, 3);
		mrkv2.timing_func = ~devTimeFunc.(2.0 * ~devScaler, tempo, 4);
		mrkv3.timing_func = ~devTimeFunc.(2.0 * ~devScaler, tempo, 4);

		5.wait;
	};
}).play;

// A slider in TouchOSC to change the sound.
OSCdef.new(
	\scaler_resp,
	{|msg, time, addr, port|
		~devScaler = 1 - msg[1];
		~devScaler.postln;
		~jitter = 2.0 * ~devScaler;
		mrkv1.timing_func = ~devTimeFunc.(2.0 * ~devScaler, ~tempo, 4);
		mrkv2.timing_func = ~devTimeFunc.(2.0 * ~devScaler, ~tempo, 6);
	},
	'/1/scaler'
);

// // TESTING
// ~devScaler = 0.000001;
// mrkv1.transition_mat = Array2D.fromArray(
// 	nodeVals1.size,
// 	nodeVals1.size,
// final1);
// mrkv2.transition_mat = Array2D.fromArray(
// 	nodeVals2.size,
// 	nodeVals2.size,
// final2);
// mrkv3.transition_mat = Array2D.fromArray(
// 	nodeVals3.size,
// 	nodeVals3.size,
// final3);
//
//
//
//
//

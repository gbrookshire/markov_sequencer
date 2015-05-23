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
	var dens;
	dens = [
		2, 1.5, 1, 0.8, 0.6, 0.4,
		0.2, 0.15, 0.3, 0.4, 0.25,
		0.4, 0.7, 0.9, 1.2];
	dens = ~tempo * dens;
	10.wait;
	dens.do{|val|
		~tempo = val;
		m.timing_func = ~timing_func.(2.0 * ~scaler, ~tempo, 3);
		n.timing_func = ~timing_func.(2.0 * ~scaler, ~tempo, 6);
		5.wait;
	};
}).play;

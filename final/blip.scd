// Markov process
// Start sparse, with individual unpitched clicks.
// Over time, increase variance so that clicks move toward shushing noise.
// Also increase variance of pitchedness.
// Pitches follow a markov process

var goFunc1, nodeVals1;
~scaler = 0;

goFunc1 = {arg freq;
	var cf, br, rt;
	cf = exprand(10, ~scaler.linexp(0, 1, 10, 1000));
	br = exprand(50, ~scaler.linexp(0, 1, 10, 1000));
	rt = ~scaler.linexp(0, 1, 0.001, 0.35);
	rt = rrand(0.01, rt);
	Synth(\crackle,
		[bitRate: br,
			clickFreq: cf,
			clickVar: 1,
			ringFreq: freq.midicps,
			ringTime: rt,
			mix: ~scaler.linlin(0, 1, 0, 0.9),
			pan: rrand(-1.0,1.0) ** 1.5,
			decay: rrand(3.0, 7.0)
		]
	);
};
nodeVals1 = [57, 60, 67, 69, 64];

m = MarkovSeq(goFunc1, nodeVals1);
m.loadTransMat(thisProcess.nowExecutingPath.dirname ++ "/blip.csv");


/*
// test the noise
Synth(\crackle,
	[bitRate:1000,
		clickFreq:exprand(10, 1000),
		clickVar:1,
		ringFreq:exprand(100, 1000),
		ringTime:0.001,
		mix:0.9,
		pan:rrand(-1.0,1.0)]
);
*/

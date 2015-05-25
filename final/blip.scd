// Markov process
// Start sparse, with individual unpitched clicks.
// Over time, increase variance so that clicks move toward shushing noise.
// Also increase variance of pitchedness.
// Pitches follow a markov process

var goFunc1, nodeVals1;
var homeDir = thisProcess.nowExecutingPath.dirname;

~blipScaler = 0;

goFunc1 = {arg freq;
	var cf, br, rt;
	cf = exprand(10, ~blipScaler.linexp(0, 1, 10, 1000));
	br = exprand(50, ~blipScaler.linexp(0, 1, 10, 1000));
	rt = ~blipScaler.linexp(0, 1, 0.001, 0.35);
	rt = rrand(0.01, rt);
	Synth(\crackle,
		[bitRate: br,
			clickFreq: cf,
			clickVar: 1,
			ringFreq: freq.midicps,
			ringTime: rt,
			mix: ~blipScaler.linlin(0, 1, 0, 0.9),
			pan: rrand(-1.0,1.0),
			decay: rrand(3.0, 7.0)
		]
	);
};
nodeVals1 = [57, 60, 67, 69, 64];

~blipMarkov = MarkovSeq(goFunc1, nodeVals1);
~blipMarkov.loadTransMat(homeDir ++ "/blip.csv");

// A slider to change a bunch of parameters about the sound.
OSCdef.new(
	\scaler_resp,
	{|msg, time, addr, port| ~blipScaler = msg[1]},
	'/3/fader1'
);

// A button to trigger a step
OSCdef.new(
	\step_resp,
	{|msg, time, addr, port|
		if (msg[1] == 1, {~blipMarkov.step}, {});
	},
	'/3/push1'
);

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

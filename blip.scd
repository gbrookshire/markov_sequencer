(
// Blipping noises.
// Add a resonating filter, so that these can ring like bells.
SynthDef(\crackle, {arg bitRate=100, clickFreq=10, clickVar=0,
	ringFreq=400, ringTime=0, mix=0, pan=0, amp=1, decay=5;
	var sig, env, ring;
	env = EnvGen.kr(Env.perc(5, decay), doneAction:2);
	sig = Latch.ar(
		LFNoise0.ar(LFNoise2.kr(10, mul:clickFreq*clickVar, add:clickFreq)),
		Impulse.ar(bitRate));
	sig = HPF.ar(sig, freq:15, mul:0.7);
	ring = Ringz.ar(sig,
		freq:LFNoise1.kr(1, mul:ringFreq/40, add:ringFreq)*(1..8),
		decaytime:LFNoise0.kr(1!8, ringTime/2, ringTime));
	ring = Mix(ring);
	ring = ring * ringTime.linexp(0, 1, 1, 0.005) * clickFreq.linexp(10, 1000, 1, 0.05);
	sig = Mix([sig * (1 - mix), ring * mix]);
	sig = sig * 0.25;
	sig = sig.range(-0.5, 0.5);
	Out.ar(0, Pan2.ar(sig * env, pan));
}).add;
)

( // test the noise
Synth(\crackle,
	[bitRate:1000,
		clickFreq:exprand(10, 1000),
		clickVar:1,
		ringFreq:exprand(100, 1000),
		ringTime:0.001,
		mix:0.9,
		pan:rrand(-1.0,1.0)]
);
)

// Markov process
// Start sparse, with individual unpitched clicks.
// Over time, increase variance so that clicks move toward shushing noise.
// Also increase variance of pitchedness.
// Pitches follow a markov process
~scaler = 0;
(
var goFunc1, nodeVals1;

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
m.loadTransMat("/Users/gbrookshire/Documents/projects/music/sc/markov_sequencer/blip.csv");
)

(
// A slider to change a bunch of parameters about the sound.
OSCdef.new(
	\scaler_resp,
	{|msg, time, addr, port| ~scaler = msg[1]},
	'/1/fader1'
);

// A button to trigger a step
OSCdef.new(
	\step_resp,
	{|msg, time, addr, port| m.step},
	'/1/push1'
);
)

// To change scaler values and trigger steps manually:
~scaler = 0.2;
m.step




s.prepareForRecord("/Users/gbrookshire/Desktop/new_sounds.wav");
s.record;
s.stopRecording;

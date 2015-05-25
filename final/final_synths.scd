// Synth defs for the final performance

// Synths for 'develop.scd', the markov chain that's
// inspired by finch vocal development.

SynthDef(\twang, {arg
	freq=440, amp=1, decay=1,
	mod_strength=10, mod_decay=0.25, wobble=0;

	var env, sig, freq_mod;
	env = EnvGen.kr(Env.perc(0.025, decay), doneAction:2);

	freq_mod = LFNoise0.kr(
		freq:200,
		mul:XLine.kr(mod_strength, 0.01, 1),
		add:1);
	freq = freq * freq_mod;

	sig = SinOsc.ar(
		freq: freq * [1, 2, 4, 6, 8],
		mul: [0.6, 0.9, 0.1, 0.1, 0.1]
	);
	sig = Mix.new(sig);
	sig = sig + SinOsc.ar(freq);
	sig = (sig * amp * 0.08);

	Out.ar(0, Pan2.ar(sig * env, LFNoise0.kr(0.5) ** 2));
}).add;

SynthDef(\sputter, {arg freq=440, wobble=0, resonate=0, decay=0.2, chaos=1.95, amp=1;
	var env, sig, freqWobble;

	env = EnvGen.kr(Env.perc(0.005, decay), doneAction:2);
	sig = Crackle.ar(chaos) + Crackle.ar(chaos) + Crackle.ar(chaos);
	sig = Ringz.ar(sig,
		[1, 3, 5] * freq + LFNoise1.kr(1, mul:wobble, add:1),
		resonate.linlin(0, 1, 0.002, 0.15));
	sig = Mix.new(sig);
	sig = sig * ((1 - resonate + 0.1));
	sig = 0.06 * sig.distort;
	sig = sig * amp;
	sig = sig * LFNoise0.ar(100, mul:0.4, add:0.6);

	Out.ar(0, Pan2.ar(sig * env, LFNoise0.kr(0.5) ** 2));
}).add;

SynthDef(\gendy, {arg freq=440, decay=0.25, ascale=0.5, dscale=0.5;
	var sig, env;
	env = EnvGen.kr(Env.perc(0.005, decay), doneAction:2);
	sig = Gendy3.ar(
		durdist: 2,
		ampdist: 5,
		adparam: 0.001,
		ddparam: 0.001,
		freq: freq,
		ampscale: ascale,
		durscale: dscale,
		mul: 0.1
	);
	sig = Mix.new(sig);
	sig = LPF.ar(sig, XLine.kr(10000, freq * 3, decay));
	sig = sig.softclip;
	Out.ar(0, Pan2.ar(sig * env, LFNoise0.kr(0.5) ** 2));
}).add;


// Synths for blip, start with LF square noise and apply
// a resonating filter to sound like strings being tapped.
SynthDef(\crackle, {arg bitRate=100, clickFreq=10, clickVar=0,
	ringFreq=400, ringTime=0, mix=0, pan=0, amp=1, decay=5;
	var sig, env, ring;
	env = EnvGen.kr(Env.perc(5, decay), doneAction:2);
	sig = Latch.ar(
		LFNoise0.ar(LFNoise2.kr(10, mul:clickFreq*clickVar, add:clickFreq)),
		Impulse.ar(bitRate));
	sig = HPF.ar(sig, freq:15, mul:0.7);
	sig = sig.softclip;
	ring = Ringz.ar(sig,
		freq:LFNoise1.kr(1, mul:ringFreq/40, add:ringFreq)*(1..8),
		decaytime:LFNoise0.kr(1!8, ringTime/2, ringTime));
	ring = Mix(ring);
	ring = ring * 0.1;
	sig = Mix([sig * (1 - mix), ring * mix]);
	sig = sig * 0.5;
	sig = sig.range(-0.5, 0.5);
	Out.ar(0, Pan2.ar(sig * env, pan));
}).add;

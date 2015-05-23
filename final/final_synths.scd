// Synth defs for the final performance

// Synths for 'develop.scd', the markov chain that's
// inspired by finch vocal development.

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

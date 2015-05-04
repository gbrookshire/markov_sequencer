(
// Echoing thump, modulated by mouse position
SynthDef(\thump, {arg p1=1, p2=100; // p1: MouseX, p2: MouseY
	var nse, env, kic;
	kic = tanh(Ringz.ar(LPF.ar(Trig.ar(1, SampleDur.ir), 1000), 30, 0.25, 7).sin * 2);
	env = Env.perc(0.05, 1, 1, -4);
	nse = BrownNoise.ar(2) + PinkNoise.ar(0.5)  * EnvGen.kr(env, doneAction: 2);

	nse = Mix.ar(BPF.ar(nse, [100,1200,80,40,20], MouseX.kr(0,1), [1,0.2,1,1,1]));
	nse = LPF.ar(nse + kic, MouseY.kr(100,1000));
	Out.ar(0, nse!2);
}).add;

// simple bass drum
SynthDef(\kick, {|out = 0, bRelease = 1, b_freq = 10|
	var env_body, env_pop, env_click,
	bass, body, pop, click,
	body_freq, pop_speed;

	env_body = EnvGen.kr(Env.perc(0.005, bRelease, 1, -1), 1, doneAction:2);
	body_freq = b_freq + (50 * (Saw.kr(1 / bRelease, add:0.5) ** 20));
	body = SinOsc.ar(body_freq);

	pop_speed = 0.08;
	env_pop = EnvGen.kr(Env.perc(0.001, 0.15, 1, 1));
	pop = HPF.ar(SinOsc.ar(Saw.kr(1/pop_speed, 150, 200), mul:0.01), 100);

	env_click = EnvGen.kr(Env.perc(0.001, 0.002, 1, -3));
	click = WhiteNoise.ar(0.05);

	bass = (click * env_click) + (pop * env_pop) + (body * env_body);

	bass * 0.2;

	Out.ar([0, 1], bass);
}).add;

// simple clicking noise
SynthDef(\click, {|out = 0, freq=440, decay=0.01, parm=1|
	var env, sound, sig;
	env = EnvGen.kr(Env.perc(0.005, decay), doneAction:2);
	// sound = WhiteNoise.ar(0.2);
	sig = Ringz.ar(WhiteNoise.ar(0.05), freq + LFNoise2.kr(100, 50), parm);
	sig = sig * Crackle.ar(2.0);
	Out.ar([0, 1], sig * env);
}).add;
)


Synth(\thump);
Synth(\kick, [\bRelease, 1, \b_freq, 10]);
Synth(\click, [\freq, rrand(220, 880), \parm, rrand(0.5, 5)]);



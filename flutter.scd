(
// simple kick drum
SynthDef(\kick, {|bRelease=1, bFreq=10, vol=1|
	var env_body, env_pop, env_click,
	bass, body, pop, click,
	body_freq, pop_speed;

	env_body = EnvGen.kr(Env.perc(0.005, bRelease, 1, -1), 1, doneAction:2);
	body_freq = bFreq + (50 * (Saw.kr(1 / bRelease, add:0.5) ** 20));
	body = SinOsc.ar(body_freq);

	pop_speed = 0.08;
	env_pop = EnvGen.kr(Env.perc(0.001, 0.15, 1, 1));
	pop = HPF.ar(SinOsc.ar(Saw.kr(1/pop_speed, 150, 200), mul:0.01), 100);

	env_click = EnvGen.kr(Env.perc(0.001, 0.002, 1, -3));
	click = WhiteNoise.ar(0.05);

	bass = (click * env_click) + (pop * env_pop) + (body * env_body);
	bass = bass * vol;
	Out.ar([0, 1], bass);
}).add;
)

(
~flutter = {arg vol=1;
	var tsk;
	tsk = Task({
		var delta = exprand(0.01, 0.08);
		loop {
			Synth(\kick, [
				\bRelease, rrand(0.2, 0.5),
				\bFreq, rrand(20, 40),
				\vol, rrand(0.8 * vol, 1 * vol) ** 2]);
			delta = delta * rrand(1.0 - (0.2 * ~flutterSpeed), 1.3);
			if (delta > 0.3, {tsk.stop}, {});
			if (delta < 0.04, {delta = 0.04}, {});
			delta.yield;
		}
	}).play;
};

)
~flutter.(0.8)
~flutterSpeed = 0;
~flutterVol = 0;

(
// A button to trigger the flutter
OSCdef.new(
	\flutter_resp,
	{|msg, time, addr, port| ~flutter.value(~flutterVol)},
	'/1/push3'
);

OSCdef.new( // Volume
	\scaler_resp,
	{|msg, time, addr, port| ~flutterVol = msg[1]},
	'/1/fader3'
);

OSCdef.new( // Speed
	\scaler_resp,
	{|msg, time, addr, port| ~flutterSpeed = msg[1]},
	'/1/fader4'
);

)

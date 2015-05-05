(
SynthDef(\ping, { |freq = 440|
	var sig, env, out;
	env = EnvGen.kr(Env.perc(0.005, 1), doneAction:2);
	sig = SinOsc.ar(
		freq: freq * [1, 2, 4, 6] + LFNoise1.kr(5, mul:3),
		mul: 0.4 * [1, 0.3, 0.1, 0.05]);
	sig = Mix.new(sig);
	out = sig * env;
	Out.ar(0, out ! 2);
}).add;
)

(
var goFunc, nodeVals;

goFunc = {|freq|
	Synth(\ping, [\freq, freq.midicps]);
};

nodeVals = [55, 60, 65, 67, 70, 72, 77, 79] - 5;

m = MarkovSeq(goFunc, nodeVals);
m.timing_func = 1;
m.initTouchOSC("10.0.1.3", 58100, '/1');
m.createGUI;

OSCdef.new(
	\tempo_resp,
	{|msg, time, addr, port|
		var tm = ((1.0 - msg[1]) ** 2) + 0.1;
		m.timing_func = tm;
	},
	'/1/tempo'
);

)
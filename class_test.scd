(
SynthDef(\ping, { |freq = 440|
	var sig, env, out;
	env = EnvGen.kr(Env.perc(0.01, 1), doneAction:2);
	sig = SinOsc.ar(freq);
	out = sig * env;
	Out.ar(0, out ! 2);
}).add;
)

(
var goFunc, nodeVals;

goFunc = {|freq|
	Synth(\ping, [\freq, freq.midicps]);
};
nodeVals = [55, 60, 65, 67, 70, 72, 77, 79];

m = MarkovSeq(goFunc, nodeVals);
m.initTouchOSC("192.168.1.139", 58100, '/1');
m.createGUI;

m.timing_func = {((0..4)/4).choose};

)

m.transition_mat

m.step;
m.run(0.25)
m.run({((0..4)/4).choose});
m.stop;

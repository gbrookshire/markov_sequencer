(
SynthDef(\ping, { |freq = 440|
	var sig, env, out;
	env = EnvGen.kr(Env.perc(0.01, 1), doneAction:2);
	sig = SinOsc.ar(freq, mul:0.4);
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

n = MarkovSeq(goFunc, nodeVals);
n.timing_func ={((0..4)/3).choose};
n.initTouchOSC("192.168.1.139", 58100, '/2');
n.createGUI;

)


(
var goFunc1, nodeVals1;
var goFunc2, nodeVals2;

// goFunc1 = {|freq| Synth(\click, [\freq, freq, \decay, exprand(0.001, 0.25)])};
// nodeVals1 = [400, 600, 800];

goFunc1 = {|val| Synth(\click, [\freq, rrand(300, 1000), \decay, val])};
nodeVals1 = [0.001, 0.005, 0.05];

m = MarkovSeq(goFunc1, nodeVals1);
m.timing_func = 0.5 / 3;
m.transition_mat = Array2D.fromArray(nodeVals1.size, nodeVals1.size,
[1,1,0, 1,0,1, 1,0,0]);
m.createGUI;
m.initTouchOSC("10.150.97.79", 58100, '/1');


goFunc2 = {|freq| Synth(\kick, [\bRelease, 0.8, \b_freq, freq])};
nodeVals2 = [50, 80, 120];
n = MarkovSeq(goFunc2, nodeVals2);
n.timing_func = {((0..4)/4).choose};
n.transition_mat = Array2D.fromArray(3, 3, [5,0,1, 1,2,0, 0,1,0]);


m.run;
n.run;



)

m.timing_func = 0.125;

m.transition_mat
m.timing_func = 0.2;

m.step;
m.timing_func = {((0..4)/4).choose};
m.run;
m.run;
m.stop;

exprand(0.001, 0.5)
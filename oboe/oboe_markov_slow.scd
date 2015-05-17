/*
Separate Markov chains play chords together

Is it possible to make this clearer using patterns?
- Pfunc or Prout?
Like this:
(
SynthDef(\ping, {arg note=0, decay=0.25, wobbleDepth=0, wobbleRate=10;
	var env, sig, freq;
	env = EnvGen.kr(Env.perc(0.025, decay), doneAction:2);
	freq = LFNoise1.kr(wobbleRate, wobbleDepth, (note + 60).midicps);
	sig = SinOsc.ar(freq);
	Out.ar(0, sig * env);
}).add;

m = MarkovSeq({|val| val.postln; val}, [0,1,2]);
m.transition_mat = Array2D.fromArray(3, 3, [1,1,0, 0,0,1, 1,0,0]);

p = Pbind(
	\instrument, \ping,
	\note, Pfunc({m.step}),
	\dur, 0.25
);
p.play;
)



*/

(
// Synth defs
SynthDef(\playBuf, {|bufnum=0, rate=1, wobbleDepth=0, wobbleRate=1, pan=0 |
	var scaledRate, player, env;
	scaledRate = rate *  BufRateScale.kr(bufnum);
	scaledRate = scaledRate * LFNoise1.kr(wobbleRate, wobbleDepth, 1);

	player = PlayBuf.ar(1, bufnum, scaledRate, doneAction:2);

	Out.ar(0, Pan2.ar(player, pan))
}).add;

SynthDef(\verb, {arg mix=0.2, room=0.6, damp=1;
	var sigs;
	sigs = [In.ar(0), In.ar(1)];
	sigs = FreeVerb2.ar(sigs[0], sigs[1],
		mix: mix.lag(0.1),
		room: room.lag(0.1),
		damp: damp.lag(0.1));
	ReplaceOut.ar(0, sigs);
}).add;

~wobbleDepth = 0.005;
~wobbleRate = 2;

)

(
// Load the sample buffers
var dir = "/Users/gbrookshire/Documents/projects/music/sc/markov_sequencer/oboe/long_tones/";
var noteVals;

noteVals = (58..83);
~bufferDict = Dictionary.new;
noteVals.do{|note|
	var fname;
	fname = dir ++ note ++ "-ff.wav";
	~bufferDict.put(note, Buffer.read(s, fname));
};
)

Synth(\playBuf, [bufnum: ~bufferDict[70].bufnum, rate:0.5]);

(
// Get the Markov processes ready
var goFunc1, nodeVals1, timingFunc1, transitions1;
var goFunc2, nodeVals2, timingFunc2, transitions2;
var dir = "/Users/gbrookshire/Documents/projects/music/sc/markov_sequencer/oboe/";


// Chain 1
timingFunc1 = {5};
nodeVals1 = (58..70);
goFunc1 = {|note|
	Synth(\playBuf,
		[
			bufnum: ~bufferDict[note].bufnum,
			rate: 0.5,
			wobbleDepth: ~wobbleDepth,
			wobbleRate: ~wobbleRate
		]
	)
};
m = MarkovSeq(goFunc1, nodeVals1);
m.timing_func = timingFunc1;
m.loadTransMat(dir ++ "long_1.csv");

nodeVals2 = (68..80);
n = MarkovSeq(goFunc1, nodeVals2);
n.timing_func = timingFunc1;
n.loadTransMat(dir ++ "long_1.csv");

o = MarkovSeq(goFunc1, (64..76));
o.timing_func = timingFunc1;
o.loadTransMat(dir ++ "long_1.csv");

// Add effects
Synth.tail(s, \verb)

)

(
m.run;
n.run;
o.run;
)


(
Task({
	loop {
		var delta;
		m.step;
		n.step;
		o.step;
		delta = rrand(3.0, 6.0);
		delta.yield;
	}
}).play;
)



// .range allows you to adjust the range of a signal



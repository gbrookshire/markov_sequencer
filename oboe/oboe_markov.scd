(
// Synth defs
SynthDef(\playBuf, {|bufnum=0, rate=1, pitch=1, wobbleDepth=0, wobbleRate=1, pan=0 |
	var scaledRate, player, env;
	scaledRate = rate *  BufRateScale.kr(bufnum);
	scaledRate = scaledRate * LFNoise1.kr(wobbleRate, wobbleDepth, 1);

	player = PlayBuf.ar(1, bufnum, scaledRate, doneAction:2);
	player = PitchShift.ar(player, pitchRatio:pitch);
	player = player * 4;
	Out.ar(0, Pan2.ar(player, pan))
}).add;
)

(
// Load the sample buffers
var dir = "/Users/gbrookshire/Documents/projects/music/sc/markov_sequencer/oboe/";
~buf_arr = (dir++"samples/*.wav").pathMatch.collect{|fname| Buffer.read(s, fname)};
~buf_arr.collect(_.bufnum);
)

~rate = 8;
~depth = 0.0;

(
// Get the Markov processes ready
var goFunc1, nodeVals1, timing_func, transitions;
var dir = "/Users/gbrookshire/Documents/projects/music/sc/markov_sequencer/oboe/";

transitions = CSVFileReader.read(dir ++ "tm_1.csv");
transitions = transitions.collect(_.collect(_.asFloat)); // Change to numbers

~tempo = 1.1;

~timing_func = {|jit, temp, divisor|
	// Returns a timing function, which returns a time difference
	// between this note and the following note.
	var fnc;
	fnc = {[1, 1, 2].choose * abs(rrand(1 - jit, 1 + jit)) * temp / divisor};
	fnc
};

// Functions for chain 1
goFunc1 = {|nSound|
	nSound.postln;
	if (nSound == 9,
		{},
		{Synth(\playBuf,
			[
				bufnum: ~buf_arr[nSound].bufnum,
				wobbleDepth: ~depth,
				wobbleRate: ~rate
				// pitch: rrand(0.667, 1.5)
			]
		)}
	);
};
nodeVals1 = (0..9);
m = MarkovSeq(goFunc1, nodeVals1);
m.timing_func = {0.2};
m.transition_mat = Array2D.fromArray(nodeVals1.size, nodeVals1.size, transitions.flat);
)

m.transition_mat
m.run;

s.prepareForRecord("/Users/gbrookshire/Desktop/oboe_sample_test.wav");
s.record;
s.stopRecording;


(
~tempo = 1;
SynthDef(\playBuf, {|bufnum=0, rate=1, pitch=1, pan=0 |
	var scaledRate, player, env;
	scaledRate = rate * LFNoise1.kr(1, 0.025, 1) * BufRateScale.kr(bufnum);
	player = PlayBuf.ar(1, bufnum, scaledRate, doneAction:2);
	player = PitchShift.ar(player, pitchRatio:pitch);
	Out.ar(0, Pan2.ar(player, pan))
}).add;
)

(
var goFunc, nodeVals;
var samp_dir, buf_arr;

samp_dir = "/Users/gbrookshire/Documents/projects/music/sc/markov_sequencer/sounds/short/*";
buf_arr = [];
buf_arr = samp_dir.pathMatch.collect{|fname| Buffer.read(s, fname)};

goFunc = {|buf|
	if (buf <= size(buf_arr),
		{Synth(\playBuf, [bufnum:buf_arr[buf].bufnum, rate:1, pitch:1])},
		{'No soundfiles at this location'.postln;}
	);
};
nodeVals = (0..7);

(buf_arr.size.asString + "soundfiles loaded.").postln;

m = MarkovSeq(goFunc, nodeVals);
m.timing_func = ~tempo / 4;
m.initTouchOSC("192.168.1.139", 58100, '/1');
m.createGUI;
)

(
var goFunc, nodeVals;
var samp_dir, buf_arr;

samp_dir = "/Users/gbrookshire/Documents/projects/music/sc/markov_sequencer/sounds/long/*";
buf_arr = [];
buf_arr = samp_dir.pathMatch.collect{|fname| Buffer.read(s, fname)};

goFunc = {|buf|
	if (buf <= size(buf_arr),
		{Synth(\playBuf, [bufnum:buf_arr[buf].bufnum, rate:1, pitch:1])},
		{'No soundfiles at this location'.postln;}
	);
};
nodeVals = (1..buf_arr.size)-1;

n = MarkovSeq(goFunc, nodeVals);
n.timing_func = ~tempo / 3;
// n.transition_mat = Array2D.fromArray(3, 3,
// 	1 + [0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0]
// );
n.initTouchOSC("192.168.1.139", 58100, '/2');
n.createGUI;
)
n.step
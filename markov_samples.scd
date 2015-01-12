(
var samp_dir, fnames;
~node_functions = (0..5);

fnames = ['clang1', 'clang2', 'clang3',
	'clang4', 'clang5', 'click1', 'flap1'];

samp_dir = '/Users/gbrookshire/Documents/projects/music/sc/sampler/cage_sounds/';

~buffer_array = [];

fnames.do({|name|
	~buffer_array = ~buffer_array ++ Buffer.read(s, samp_dir ++ name ++ ".wav");
});

SynthDef(\playBuf, {| out = 0, bufnum = 0, rate = 0.7 |
	var scaledRate, player, trigs;
	scaledRate = rate * BufRateScale.kr(bufnum);
	player = PlayBuf.ar(1, bufnum, scaledRate, doneAction:2);
	Out.ar(out, player)
}).add;

~ping = {|x|
	Synth(\playBuf, [bufnum:~buffer_array[x].bufnum]);
};
)

Synth(\playBuf, [bufnum:~buffer_array[3].bufnum]);
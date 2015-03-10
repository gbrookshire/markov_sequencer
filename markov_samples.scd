(
var samp_dir, fnames;
// samp_dir = '/Users/gbrookshire/Documents/projects/music/sc/sampler/cage_sounds/';
samp_dir = '/Users/gbrookshire/Desktop/cage_noise/clipped/';

fnames = ['clang_2', 'clang_3', 'clang_4', 'clang_5', 'clang_6',
	'flutter_clatter_1', 'flutter_1', 'flutter_5'];
~node_functions = (0..(fnames.size-1));

~buffer_array = [];
fnames.do({|name|
	var path_name = samp_dir ++ name ++ ".wav";
	~buffer_array = ~buffer_array ++ Buffer.read(s, path_name);
});

SynthDef(\playBuf, {| out = 0, bufnum = 0, rate = 0.5 |
	var scaledRate, player, trigs;
	scaledRate = rate * BufRateScale.kr(bufnum);
	player = 0.6 * PlayBuf.ar(1, bufnum, scaledRate, doneAction:2);
	Out.ar(out, player!2)
}).add;

~goFunc = {|x|
	Synth(\playBuf, [bufnum:~buffer_array[x].bufnum]);
};
)

Synth(\playBuf, [bufnum:~buffer_array[3].bufnum]);

fnames.length

s.options
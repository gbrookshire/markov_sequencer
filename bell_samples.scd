(
var samp_dir, fnames, playback_rates, buf_arr;
~node_functions = (0..7);

// 8 pitches in one whole step, starting at 0.25 of normal playback.
~playback_rates = 1 * (2 ** (((1..8) / 8) * 200 / 1200));

fnames = ['1', '2'];
samp_dir = '/Users/gbrookshire/Documents/projects/music/sc/sampler/bell/';
buf_arr = [];
fnames.do({|name|
	buf_arr = buf_arr ++ Buffer.read(s, samp_dir ++ name ++ ".wav");
});

SynthDef(\playBuf, {|bufnum = 0, attack = 0.001, rate = 1, pan = 0 |
	var scaledRate, player, env;
	scaledRate = rate * BufRateScale.kr(bufnum);
	env = EnvGen.kr(
		Env(levels:[0,1,0], times:[attack, 7 * attack], curve:'lin'),
		doneAction:2);
	attack = Line.kr(0, 1, attack);
	player = PlayBuf.ar(1, bufnum, scaledRate);
	Out.ar(0, Pan2.ar(env * player, pan))
}).add;

~ping = {|x|
	var buf, attack, pan;
	buf = coin(0.5).asInt; // Randomly choose a sample
	attack = exprand(0.01, 1);// Randomly choose attach time
	pan = sum3rand(1);
	Synth(\playBuf,
		[bufnum:buf_arr[buf].bufnum,
			attack:attack,
			rate:~playback_rates[x],
			pan:pan]);
}
)

~ping.value(0)
~ping.value(7)

s.prepareForRecord('Users/gbrookshire/Desktop/markov_synth_example.wav');
s.record;
s.stopRecording;

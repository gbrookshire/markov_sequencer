// For more details on how to alter ongoing synths online:
// https://www.youtube.com/watch?v=ZVTbRNu2BI0


(

SynthDef(\crushed, { |bit_depth=12, bit_rate=22000|
	var sig, env, freq, out;

	freq = (50 + (LFNoise0.kr(1.5, mul:3).round * 5)).midicps;

	// env = EnvGen.kr(Env.adsr(0.05, 0.1, 0.5, 3), gate:0);
	// env = EnvGen.kr(Env.perc(0.01, 10), doneAction:2);
	sig = SinOsc.ar(freq, mul:0.6);

	// Reduce the sampling rate
	sig = Latch.ar(sig, SinOsc.ar(bit_rate));

	// Reduce the bit depth
	sig = ((sig * (2 ** bit_depth)).round) / (2 ** bit_depth);

	// out = sig * env;

	out = sig;
	Out.ar(0, out ! 2);
}).add;

)

x = Synth.new(\crushed);
x.set(\bit_depth, 5000);
x.free;


(
OSCdef.new(
	\finchisizer_resp,
	{|msg, time, addr, port|
		x.set(\bit_depth, ((msg[1]*10).round + 1));
		x.set(\bit_rate, (msg[2]*22000));
	},
	'/2/xy1'
);
)
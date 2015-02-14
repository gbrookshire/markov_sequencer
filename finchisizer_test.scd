// For more details on how to alter ongoing synths online:
// https://www.youtube.com/watch?v=ZVTbRNu2BI0
(

SynthDef(\finch, {arg pressure=0, tension=0, time_const=24000;
	var sig;
	sig = SyrinxL.ar(
		freq:22050,
		a:pressure,
		b:tension,
		g:time_const,
		h:0.00001);
	Out.ar(0, sig);
}).add;

SynthDef(\bitcrusher, {arg bit_depth=10, bit_rate=10000;
	var sig;
	sig = In.ar(0);
	// Reduce the sampling rate
	sig = Latch.ar(sig, SinOsc.ar(bit_rate));
	// Reduce the bit depth
	sig = ((sig * (2 ** bit_depth)).round) / (2 ** bit_depth);

	ReplaceOut.ar(0, sig);
}).add;


///// OSC responders

OSCdef.new(
	\on_resp,
	{|msg, time, addr, port|
		msg.postln;
		if (msg[1] == 1,
			{x = Synth.tail(s, \finch);},
			{x.free;});
	},
	'/1/toggle1'
);
OSCdef.new(
	\finch_resp,
	{|msg, time, addr, port|
		x.set(\pressure, msg[1]);
		x.set(\tension, msg[2]);
	},
	'/1/xy1'
);
OSCdef.new(
	\timeconst_resp,
	{|msg, time, addr, port|
		x.set(\time_const, msg[1] * 48000);
	},
	'/1/time_const'
);

// Effects
OSCdef.new(
	\bc_on_resp,
	{|msg, time, addr, port|
		if (msg[1] == 1,
			{y = Synth.tail(s, \bitcrusher);},
			{y.free;});
	},
	'/1/bc_on'
);
OSCdef.new(
	\bc_depth_resp,
	{|msg, time, addr, port|
		var bd;
		bd = (msg[1] * 12).round + 3;
		y.set(\bit_depth, bd);
	},
	'/1/bc_depth'
);
OSCdef.new(
	\bc_rate_resp,
	{|msg, time, addr, port|
		y.set(\bit_rate, msg[1] * 20000);
	},
	'/1/bc_rate'
);

)

// Test out the finchesizer
x = Synth.tail(s, \finch);
x.set(\pressure, 0.2);
x.set(\tension, 0.2);
x.free;

// Set up effects in a chain like this.
y = Synth.tail(s, \bitcrusher, [\bit_depth, 1, \bit_rate, 100]);
y.free;

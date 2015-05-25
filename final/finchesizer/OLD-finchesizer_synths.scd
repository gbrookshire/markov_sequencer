SynthDef(\finch, {
	arg out, pressure=0, tension=0, time_const=1000, volume=0,
	pdepth=0, prate=0, tdepth=0, trate=0, time_smooth=0, pan=0;
	var sig;
	time_smooth = time_smooth * 60; // smooth changes in control vals
	sig = SyrinxL.ar(
		freq: 22050,
		a: pressure.lag(time_smooth) + SinOsc.kr(prate, mul:pdepth),
		b: tension.lag(time_smooth) + SinOsc.kr(trate, mul:tdepth),
		g: time_const.lag(time_smooth),
		h: 0.00001,
		mul: volume.lag(time_smooth));
	Out.ar(0, Pan2.ar(sig, pan));
}).add;

///// Effects -- stereo

SynthDef(\bitcrusher, {arg in, out=0, bit_depth=10, bit_rate=20000;
	var sigs;
	sigs = [In.ar(0), In.ar(1)];
	// Reduce the sampling rate
	sigs = Latch.ar(sigs, SinOsc.ar(bit_rate));
	// Reduce the bit depth
	sigs = ((sigs * (2 ** bit_depth)).round) / (2 ** bit_depth);
	ReplaceOut.ar(0, sigs);
}).add;

SynthDef(\verb, {arg mix=0, room=0, damp=0;
	var sigs;
	sigs = [In.ar(0), In.ar(1)];
	sigs = FreeVerb2.ar(sigs[0], sigs[1],
		mix: mix.lag(0.1),
		room: room.lag(0.1),
		damp: damp.lag(0.1));
	ReplaceOut.ar(0, sigs);
}).add;

SynthDef(\mastervolume, {arg vol=0;
	var sigs;
	sigs = [In.ar(0), In.ar(1)];
	sigs = sigs * (vol.lag(0.2) ** 2);
	ReplaceOut.ar(0, sigs);
}).add;
SynthDef(\finch, {arg
	// out, pressure=0, tension=0, time_const=1000, volume=0,
	// pdepth=0, prate=0, tdepth=0, trate=0, time_smooth=0, pan=0;

	// Noisy defaults for testing
	out, pressure=0.2, tension=0.2, time_const=20000, volume=1,
	pdepth=0.1, prate=10, tdepth=0.1, trate=15, time_smooth=0, pan=0;

	var sig;
	time_smooth = time_smooth * 60; // smooth changes in control vals
	sig = SyrinxL.ar(
		freq: 22050,
		a: pressure.lag(time_smooth) + SinOsc.kr(prate, mul:pdepth),
		b: tension.lag(time_smooth) + SinOsc.kr(trate, mul:tdepth),
		g: time_const.lag(time_smooth),
		h: 0.00001,
		mul: volume.lag(time_smooth));
	Out.ar(out, Pan2.ar(sig, pan));
}).add;

///// Effects

SynthDef(\bitcrusher, {arg in, out, mix=0, bit_depth=10, bit_rate=20000;
	var dry, wet, sig;
	dry = In.ar(in, 2);
	// Reduce the sampling rate
	wet = Latch.ar(dry, SinOsc.ar(bit_rate));
	// Reduce the bit depth
	wet = ((wet * (2 ** bit_depth)).round) / (2 ** bit_depth);
	// Mix them
	mix = mix.clip(0, 1);
	sig = (wet * mix) + (dry * (1 - mix));
	ReplaceOut.ar(out, sig)
}).add;

SynthDef(\verb, {arg in, out, mix=0, room=0, damp=0;
	var sig;
	sig = In.ar(in, 2);
	// sig = sig * (masterVol.lag(0.2) ** 2);
	sig = FreeVerb.ar(sig,
		mix: mix.lag(0.1),
		room: room.lag(0.1),
		damp: damp.lag(0.1));
	ReplaceOut.ar(out, sig);
}).add;

SynthDef(\mastervolume, {arg in, out=0, vol=0;
	var sig;
	sig = In.ar(in, 2);
	sig = sig * (vol.lag(0.2) ** 2);
	ReplaceOut.ar(out, sig);
}).add;

SynthDef(\masterout, {arg in, out=0;
	var sig;
	sig = In.ar(in, 2);
	Out.ar(out, sig);
}).add;

/*
// Here's how to do this using buses and groups to keep effects organized.
~sourceBus = Bus.audio(s, 2);
~fxBus = Bus.audio(s, 2);
(
var sourceGrp, fxGrp, outGrp;
sourceGrp = Group.new;
fxGrp = Group.after(sourceGrp);
outGrp = Group.after(fxGrp);

Synth.new(\masterout, [in: ~fxBus, out:0], outGrp);

Synth.new(\bitcrusher,
	[in: ~fxBus, out: ~fxBus, bit_depth: 8, bit_rate: 1000],
target: fxGrp, addAction: \addToTail);
Synth.new(\verb, [in: ~sourceBus, out: ~fxBus, mix: 0.5, room: 0.5], fxGrp);

Synth.new(\finch, [out: ~sourceBus], sourceGrp);

// And here's a finchesizer that's not routed through the effects.
Synth.new(\finch, [out: 0, pressure: 0.8]);

)
*/
// For help on effect-chaining:
// http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/Effect-chaining-and-Turning-effects-on-and-off-td7116352.html

(

SynthDef(\bitcrusher, {arg bit_depth=10, bit_rate=10000;
	var sig;
	sig = In.ar(0);
	// Reduce the sampling rate
	sig = Latch.ar(sig, SinOsc.ar(bit_rate));
	// Reduce the bit depth
	sig = ((sig * (2 ** bit_depth)).round) / (2 ** bit_depth);

	ReplaceOut.ar(0, sig);
}).add;

SynthDef(\verb, {arg mix=0.33, room=0.5, damp=0.5;
	var sig;
	sig = In.ar(0);
	sig = FreeVerb.ar(sig, mix:mix, room:room, damp:damp);
	ReplaceOut.ar(0, sig);
}).add;

// To make this a real arpeggiator, select from a list of offset pitches.
SynthDef(\arpeggiate, {arg rate=2;
	var sig, pitch_offset;
	sig = In.ar(0);
	pitch_offset = LFSaw.kr(freq:rate, mul:100);
	sig = PitchShift.ar(sig,
		windowSize:0.01,
		pitchRatio:pitch_offset,
		timeDispersion:0.02);
	ReplaceOut.ar(0, sig);
}).add;

// Processable delay line
SynthDef(\delay, {arg delay=0.333, feedback=0.5, mix=0.5;
	// Delay using feedback
	var input, fbLoopIn, fbLoopOut, procs;

	// Delay time can be modulated like this
	// delay = LFNoise2.kr(1, mul:1, add:1);

	input = In.ar(0);
	fbLoopIn = LocalIn.ar(1); // Entering the delay loop

	// Process the signal here
	procs = DelayN.ar(fbLoopIn, 3, delay, mul:feedback);
	procs = Mix.ar([0.1 * procs, 0.9 * LPF.ar(procs, freq:440)]);
	procs = input + procs;

	fbLoopOut = LocalOut.ar(procs); // Looped back into fbLoopIn

	ReplaceOut.ar(0, procs);
}).add;

// Try to clone the EarthQuaker Afterneath pedal.
// This will be lots of very short delays.
SynthDef(\afterneath, {arg length=0.5, diffuse=0.5, dampen=0.5,
	drag=0.5, reflect=0.5, mix=0.5;
	var input, fbLoopIn, fbLoopOut, procs, feedback;
	feedback = 0.5;

	input = In.ar(0);
	fbLoopIn = LocalIn.ar(1); // Entering the delay loop

	// Process the signal here
	procs = DelayN.ar(fbLoopIn, 3, 0.1, mul:feedback);

	procs = input + procs;

	fbLoopOut = LocalOut.ar(procs); // Looped back into fbLoopIn

	procs = Limiter.ar(procs, 0.8);

	ReplaceOut.ar(0, procs);
}).add;

)

(
p = Pbind(
    \instrument, \playBuf,
	\bufnum, ~buffer_array[3].bufnum,
    \dur, Pseq([3, 2], inf)
).play;
)
p.stop;

// Set up effects in a chain like this.
y = Synth.tail(s, \bitcrusher, [\bit_depth, 10, \bit_rate, 1000]);
y.free;

z = Synth.tail(s, \verb, [\room:1]);
z.free;

w = Synth.tail(s, \arpeggiate);
w = Synth.tail(s, \delay);
w = Synth.tail(s, \afterneath);
w.set(\delay, 0.2, \feedback, 0.5);
w.free;

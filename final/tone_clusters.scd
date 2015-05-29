/*
Separate Markov chains play chords together

2 ipads, each with different chains.
Buttons to trigger the chains.
2 sliders to mess with the playback rate modulation depth and freq.

Different chains on each ipad

*/

(
// Synth def
SynthDef(\playBuf, {|bufnum=0, rate=1, wobbleDepth=0, wobbleRate=1, out=0|
	var scaledRate, player, env;
	scaledRate = rate *  BufRateScale.kr(bufnum);
	scaledRate = scaledRate * LFNoise1.kr(wobbleRate, wobbleDepth, 1);
	player = PlayBuf.ar(1, bufnum, scaledRate, doneAction:2);
	Out.ar(out, Pan2.ar(player, LFNoise1.kr(0.1)))
}).add;

SynthDef(\mc3verb, {arg in, out, mix=0, room=0, damp=0;
	var sig;
	sig = In.ar(in, 2);
	// sig = sig * (masterVol.lag(0.2) ** 2);
	sig = FreeVerb.ar(sig,
		mix: mix.lag(0.1),
		room: room.lag(0.1),
		damp: damp.lag(0.1));
	ReplaceOut.ar(out, sig);
}).add;

)

// Array version
//
// Dictionary of instruments.
//    Each of those holds a dictionary of samples
(
var nodeVals, voiceArr, markovArr, bufferDict, playRates;
var makeGoFunc;
var wobbleDepth, wobbleRate;
var sourceBus, fxBus, sourceGrp, fxGrp;
var crushSynth, verbSynth;
var currDir = thisProcess.nowExecutingPath.dirname;
wobbleDepth = 0;
wobbleRate = 0;


// Function to make a go function for a markov chain
// takes a name of a voice.
makeGoFunc = {|voice, playbackRate|
	{|note|
		Synth(\playBuf,
			[
				bufnum: bufferDict[voice][note].bufnum,
				rate: playbackRate,
				wobbleDepth: ~clusterWobbleDepth,
				wobbleRate: ~clusterWobbleRate,
				out: sourceBus
			],
			sourceGrp
		);
		(voice + note).postln;
	};
};

nodeVals = (0..12); // Chromatic tones
voiceArr = ["oboe", "crotale", "horn", "crotale"];
playRates = [1/2, 1, 1, 1/2];

// Make the Markov models
// Load transition matrices
// Make OSC responders for each model
markovArr = voiceArr.collect({arg voice, ind;
	var mrkv, oscAddr, pth;
	oscAddr = '/4/push' ++ (ind + 1);
	mrkv = MarkovSeq(makeGoFunc.(voice, playRates[ind]), nodeVals);
	mrkv.loadTransMat(currDir ++ "/tone_clusters/1/tm" ++ ind ++ ".csv");
	OSCdef.new('markov3_step' ++ ind ++ '_resp',
		{|msg, time, addr, port|
			if (msg[1] == 1)
			{mrkv.step;}
			{}
		},
		oscAddr
	);
	mrkv
});


// An OSC responder to change the sound and adjust transitions
OSCdef.new(
	\markov3_wobble_depth_resp,
	{|msg, time, addr, port|
		~clusterWobbleDepth = (msg[1] * 0.1) + 0.0005;
	},
	'/4/fader1'
);
OSCdef.new(
	\markov3_wobble_rate_resp,
	{|msg, time, addr, port|
		~clusterWobbleRate = ((msg[1] + 0.05) ** 2) * 200;
	},
	'/4/fader2'
);


// Load the samples into a buffer
// Dict of dicts -- dict for each voice, holds notes
// Notes indexed by 0
bufferDict = Dictionary.new;
voiceArr.do({arg voice, voiceInd;
	var fileStem = currDir++'/samples/'++voice++'/';
	bufferDict.put(
		voice,
		Array.fill(13, {|i| Buffer.read(s, fileStem++i++'.wav')})
	);
});


// Create the effect groups
sourceBus = Bus.audio(s, 2);
fxBus = Bus.audio(s, 2);

sourceGrp = Group.new;
fxGrp = Group.after(sourceGrp);

verbSynth = Synth.new(
	\mc3verb,
	[in:sourceBus, out:0, mix:0.3, room:0.2],
	fxGrp);

)
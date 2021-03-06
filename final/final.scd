// Calls all the scripts for the final presentation.
// Execute these lines one by one at the appropriate times

Server.all.do(_.freeAll)

(
s.options.numInputBusChannels = 2;
s.options.numOutputBusChannels = 4;
s.boot;
// s.plotTree;
s.meter;
)

// Set up
(
"finchesizer/finchesizer.scd".loadRelative;
"final_synths.scd".loadRelative; // Load non-finchesizer synths
"blip.scd".loadRelative; // Prepare markov chain piece w/ ringing noise
"develop.scd".loadRelative; // Markov chain 2
)


// Run the markov chain piece that starts with LF square noise,
// and moves towards pitched stuff that sounds like tapping on strings.
// "blip.scd"
// Eval these lines to change scaler values and trigger steps manually:
// (it'll be easier to use the TouchOSC GUI)
~blipScaler = 0.1;
~blipMarkov.step;


// Run the markov chain piece that is inspired by vocal development.
// These lines change the values (but use the GUI if possible).
~devScaler = 1; // Reduce to 0 for more pitched sounds
~markovArr.collect({arg chain; chain.run});
~markovArr.collect({arg chain; chain.pause});
(
var tempo = 1.0; // Smaller tempo means a more dense sound.
~markovArr.collect({arg chain;
	chain.timing_func = ~devTimeFunc.(2.0 * ~devScaler, tempo, 3);
});
)

// Load the synths for the final markov tone cluster section

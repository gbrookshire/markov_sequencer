// Calls all the scripts for the final presentation.
// Execute these lines one by one at the appropriate times

(
s.options.numInputBusChannels = 2;
s.options.numOutputBusChannels = 4;
s.boot;
s.plotTree;
s.meter;
)

// Set up
(
"finchesizer/finchesizer.scd".loadRelative;
"final_synths.scd".loadRelative; // Load non-finchesizer synths
"blip.scd".loadRelative; // Prepare markov chain piece w/ ringing noise
)

// Run the markov chain piece that is inspired by vocal development.
"develop.scd".loadRelative;

// Run the markov chain piece that starts with LF square noise,
// and moves towards pitched stuff that sounds like tapping on strings.
// "blip.scd"
// Eval these lines to change scaler values and trigger steps manually:
~blipScaler = 0.1;
~blipMarkov.step;


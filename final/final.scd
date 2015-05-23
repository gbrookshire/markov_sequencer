// A file that includes all the non-finchesizer
// stuff for the final presentation.

// Load the synths
"final_synths.scd".loadRelative;

// Run the markov chain piece that is inspired by vocal development.
"develop.scd".loadRelative;

// Run the markov chain piece that starts with LF square noise,
// and moves towards pitched stuff that sounds like tapping on strings.
"blips.scd".loadRelative;
// Eval these lines to change scaler values and trigger steps manually:
~scaler = 0.1;
m.step


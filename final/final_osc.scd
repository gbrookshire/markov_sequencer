
/////////////
// develop //
/////////////

// A slider to change a bunch of parameters about the sound.
OSCdef.new(
	\scaler_resp,
	{|msg, time, addr, port|
		~scaler = 1 - msg[1];
		~scaler.postln;
		~jitter = 2.0 * ~scaler;
		m.timing_func = timing_func.(~jitter, ~tempo, 4);
		n.timing_func = timing_func.(~jitter, ~tempo, 6);
	},
	'/1/scaler'
);


//////////
// blip //
//////////

// A slider to change a bunch of parameters about the sound.
OSCdef.new(
	\scaler_resp,
	{|msg, time, addr, port| ~scaler = msg[1]},
	'/1/fader1'
);

// A button to trigger a step
OSCdef.new(
	\step_resp,
	{|msg, time, addr, port| m.step},
	'/1/push1'
);
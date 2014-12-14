/*
A Markovian sequencer. The grid of buttons shows a transition matrix.
Push buttons multiple times to give higher probabilities.
*/

(
var trans_matrix, node_functions;
var win;
var button_width, button_spacing, window_size, button_states;

node_functions = [60, 65, 67, 70, 75, 80];
n = node_functions.size;
~transition_mat = Array2D.fromArray(n, n, Array.fill(n * n, 0));

///////////////////////// Set up GUI
button_width = 40;
button_spacing = 6;
window_size = (button_width + button_spacing + 1) * n;
win = GUI.window.new("Transition matrix",
	Rect(100, 100, window_size, window_size));
win.view.background = Color(0.15,0.15,0.1);
win.front;

// Buttons have multiple states, corresponding to transition probabilities.
button_states = [[" ", Color.white, Color.black],
	[" ", Color.white, Color.grey(0.4)],
	[" ", Color.white, Color.grey(0.7)],
	[" ", Color.white, Color.white]];

(n * n).do({arg i;
	var col, row, xpos, ypos;
	row = floor(i / n);
	col = mod(i, n);
	xpos = col * (button_width + button_spacing) + button_spacing;
	ypos = row * (button_width + button_spacing) + button_spacing;
	b = GUI.button.new(win, Rect(xpos, ypos, button_width, button_width));
	b.states = button_states;
	b.action = {|b|
		var old_val, new_val;
		old_val = ~transition_mat.at(row, col);
		new_val = mod(old_val + 1, button_states.size);
		~transition_mat.put(row, col, new_val);
	};
});

///////////////////////// Set up the synth
SynthDef(\singrain, { |freq = 440, amp = 0.2, sustain = 1|
	var sig, env;
	env = EnvGen.kr(Env.perc(0.01, sustain), doneAction: 2);
	sig = SinOsc.ar(freq, 0, amp) * env;
	Out.ar(0, sig ! 2);
}).add;
~ping = {|freq|
	Synth(\singrain,
		[freq: freq, amp: rrand(0.1, 0.5), sustain: 2])
};

///////////////////////// Run the sequencer
t = Task({
	var delta, current_state, next_state, probs, freq, pass;
	current_state = 0;
	loop {
		delta = 0.5;
		freq = node_functions[current_state].midicps;
		probs = ~transition_mat.rowAt(current_state);

		// If there are no transitions here, stop the sequence.
		if (probs == Array.fill(probs.size, 0),
			{pass = true}, {pass = false});

		// Calculate probabilities and choose sound.
		probs = probs / sum(probs);
		next_state = (0..(n - 1)).wchoose(probs);
		current_state = next_state;
		if (pass,
			{
				'empty'.postln;
				current_state = 0;
				t.pause;
			}, {
				~ping.value(freq)
			}
		);
		delta.yield; // Time until the next iteration
	}
});
)

t.play; // Execute to run
t.pause; // Execute to stop
t.stop;
~transition_mat;

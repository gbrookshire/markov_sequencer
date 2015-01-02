/*
A Markovian sequencer. The grid of buttons shows a transition matrix.
Push buttons multiple times to give higher probabilities.
*/

(
var trans_matrix, node_functions;
var win, window_size;
var ind_size, inds; // indicator buttons
var play_button;
var b_width, b_space, b_states; // button variables

var net = NetAddr("127.0.0.1", 9000); // Send OSC to Processing here.

node_functions = [55, 60, 65, 67, 70, 75];
n = node_functions.size;
net.sendMsg("s_new", \n_elem, n);
~transition_mat = Array2D.fromArray(n, n, Array.fill(n * n, 0));

///////////////////////// Set up the synths
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

///////////////////////// Set up GUI
b_width = 40;
b_space = 6;
ind_size = 18;
window_size = ind_size + b_space + ((b_width + b_space + 1) * n);
win = GUI.window.new("Transition matrix",
	Rect(100, 100, window_size, window_size));
win.view.background = Color(0.15,0.15,0.1);
win.front;

// Make a function button
play_button = GUI.button.new(win,
	Rect(b_width,
		3, ind_size, ind_size));
play_button.states = [[">", Color.black, Color.grey],
	["||", Color.white, Color.black]];
play_button.action = {
	if (play_button.value == 0,
		{t.stop;},
		{t.play;}
)};

// // Make indicator buttons
// inds = Array.fill(n, {|i|
// 	var xpos, ypos;
// 	xpos = 3;
// 	ypos = (i * (b_width + b_space)) + (0.8 * b_width);
// 	b = GUI.button.new(win, Rect(xpos, ypos, ind_size, ind_size));
// 	b.states = [[" ", Color.white, Color.black],
// 	[" ", Color.white, Color.white]];
// 	b.action = {|b, i| ~ping.value(node_functions[i])};
// });

// Buttons have multiple states, corresponding to transition probabilities.
b_states = [[" ", Color.white, Color.black],
	[" ", Color.white, Color.grey(0.4)],
	[" ", Color.white, Color.grey(0.7)],
	[" ", Color.white, Color.white]];

(n * n).do({arg i;
	var col, row, xpos, ypos;
	row = floor(i / n);
	col = mod(i, n);
	xpos = (col * (b_width + b_space)) + b_space + ind_size + b_space;
	ypos = (row * (b_width + b_space)) + b_space + ind_size + b_space;
	b = GUI.button.new(win, Rect(xpos, ypos, b_width, b_width));
	b.states = b_states;
	b.action = {|b|
		var old_val, new_val;
		var tmat_size = 0;
		old_val = ~transition_mat.at(row, col);
		new_val = mod(old_val + 1, b_states.size);
		~transition_mat.put(row, col, new_val);
		// Send the size of the transition matrix to processing
		// net.sendMsg("s_new", \length, tmat_size);
	};
});

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
				~ping.value(freq); // Play sound
				net.sendMsg("s_new", \next_state, next_state)
			}
		);
		delta.yield; // Time until the next iteration
	}
});
)

t.play; // Execute to run
t.pause; // Execute to stop
t.stop;
~transition_mat.;

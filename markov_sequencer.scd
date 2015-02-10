/*
A Markovian sequencer. The grid of buttons shows a transition matrix.
Push buttons multiple times to give higher probabilities.

On TouchOSC on the iPad:
Port (outgoing): 57120
Port (incoming): 58100

To do:
- Change to use the safer OSCFunc, instead of OSCResponderNode.

*/

NetAddr.localAddr
NetAddr.langPort

(
var trans_matrix;
var win, window_size;
var ind_size, inds; // indicator buttons
var play_button;
var b_width, b_space, b_states, button_grid; // button variables

var adrs_P5 = NetAddr("127.0.0.1", 9000); // Send OSC to Processing.
var adrs_touchOSC = NetAddr("169.254.170.86", 58100); // Receive from TouchOSC
var responders, trig_responder, touchOSC_msg, msg_in, msg_out;
var current_state, next_state;

current_state = 0;
n = ~node_functions.size;
button_grid = Array.newClear(n ** 2);
responders = Array.newClear(n ** 2);
touchOSC_msg = Array.newClear(n ** 2);
msg_in = Array.newClear(n ** 2);
msg_out = Array.newClear(n ** 2);
~transition_mat = Array2D.fromArray(n, n, Array.fill(n ** 2, 0));

// Send the num of active elements to Processing
adrs_P5.sendMsg("s_new", \n_nodes, n);


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

// Buttons have multiple states, corresponding to transition probabilities.
b_states = [[" ", Color.white, Color.black],
	[" ", Color.white, Color.grey(0.4)],
	[" ", Color.white, Color.grey(0.7)],
	[" ", Color.white, Color.white]];

// Loop through and create the grid of buttons
(n ** 2).do({arg i;
	var col, row, xpos, ypos;
	row = floor(i / n);
	col = mod(i, n);

	// Create the messages.
	// The TouchOSC example had two messages, but they look identical...?
	// msg_in.put(i,
	// ("/transmat/" ++ (row + 1).asString ++ "/" ++ (col + 1).asString));
	msg_out.put(i,
		('/transmat/' ++ (row + 1).asString ++ '/' ++ (col + 1).asString));

	xpos = (col * (b_width + b_space)) + b_space + ind_size + b_space;
	ypos = (row * (b_width + b_space)) + b_space + ind_size + b_space;
	b = GUI.button.new(win, Rect(xpos, ypos, b_width, b_width));
	b.states = b_states;
	b.action = {|view|
		var old_val, new_val;
		var tmat_size = 0;
		old_val = ~transition_mat.at(row, col);
		new_val = mod(old_val + 1, b_states.size);
		~transition_mat.put(row, col, new_val);

		// Send the updated value to TouchOSC
		// adrs_touchOSC.sendMsg(msg_in[i], view.value);
		adrs_touchOSC.sendMsg(msg_out[i], view.value);
	};
	button_grid.put(i, b);

	// Initialize the responder nodes
	responders.put(i,
		OSCdef.new(
			'receiver'++msg_out[i],
			{|msg, time, addr, port|
				{button_grid[i].value = msg[1]}.defer;
				// ~transition_mat.put(ROWNUM, COLNUM, msg[1]);
			},
			msg_out[i]
		);
	);

});

// Step through the transitions with p.value
p = {|x|
	var tmat_str, out_val, probs, pass;

	// Send a string of the transition matrix to Processing
	// Format: "1,2,3;4,5,6;7,8,9;"
	tmat_str = "";
	~transition_mat.rowsDo({|subarray|
		tmat_str = tmat_str ++ subarray.join(',') ++ ';'});
	adrs_P5.sendMsg("s_new", \trans_mat, tmat_str);

	out_val = ~node_functions[current_state];
	probs = ~transition_mat.rowAt(current_state);

	// If there are no transitions here, do something
	if (probs == Array.fill(probs.size, 0),
		{pass = true}, {pass = false});

	// Calculate probabilities and choose sound.
	probs = probs / sum(probs);
	next_state = (0..(n - 1)).wchoose(probs);
	current_state = next_state;
	if (pass,
		{
			'No transitions from this state.'.postln;
			current_state = 0;
			t.pause;
		}, {
			~ping.value(out_val); // Play sound
			adrs_P5.sendMsg("s_new", \next_state, next_state);
		}
	);
};

// Set up trigger responder
// OSCresponderNode(nil,
// 	"/advance",
// 	{|t, r, msg|
// 		if (msg[1] == 1, {{p.value}.defer;}, {} );
// }).add;

OSCdef.new(
	\advance_resp,
	{|msg, time, addr, port|
		if (msg[1] == 1, {{p.value}.defer;}, {} );
	},
	'/advance'
);


// To automatically step through the matrix, call t.play.
t = Task({
	var delta;
	delta = 60 / 200; // Time until next iteration
	loop {
		p.value;
		delta.yield;
	}
});


// Remove responders when closing the window
win.onClose_({
	(responders.size).do({|i| responders[i].remove;});
	t.stop;
});

)

t.play; // Execute to run
t.pause; // Execute to stop

// Listen for OSC triggers.
(
f = { |msg, time, addr|
	if((msg[0] == '/start') && (msg[1] == 1)) {
        "yep".postln;
    }
};
thisProcess.addOSCRecvFunc(f);
);

// stop posting.
thisProcess.removeOSCRecvFunc(f);


OSCFunc.trace(true); // Turn posting on
OSCFunc.trace(false);

~transition_mat

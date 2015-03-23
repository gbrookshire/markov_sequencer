/*
A Markovian sequencer. The grid of buttons shows a transition matrix.
Push buttons multiple times to give higher probabilities.

In a separate file, define a function ~goFunc that gets called at each
step through the matrix -- this is what makes the sound.
Also set a variable ~node_functions that contains arguments that
will be passed to ~goFunc, determining the different

In TouchOSC (on the tablet):
Port (outgoing): 57120 (NetAddr.langPort)
Port (incoming): 58100

The transition matrix on TouchOSC starts counting at 1 instead of 0,
and row 1 is the bottom row, instead of the top as in this script.

*/

(
var adrs_P5 = NetAddr("127.0.0.1", 9000); // Send OSC to Processing.
var adrs_touchOSC = NetAddr("192.168.1.139", 58100); // Send to TouchOSC

var win, window_size;
var b_width, b_space, b_states, button_grid; // button variables

var responders, touchOSC_msg;
var current_state, next_state;

current_state = 0;
n = ~node_functions.size;
button_grid = Array.newClear(n ** 2);
responders = Array.newClear(n ** 2);
touchOSC_msg = Array.newClear(n ** 2);
~transition_mat = Array2D.fromArray(n, n, Array.fill(n ** 2, 0));

// Send the num of active elements to Processing
adrs_P5.sendMsg("s_new", \n_nodes, n);

///////////////////////// Set up GUI
b_width = 40;
b_space = 6;
window_size = (2 * (b_space)) + ((b_width + b_space + 1) * n);
win = GUI.window.new("",
	Rect(100, 100, window_size, window_size));
win.view.background = Color(0.15,0.15,0.1);
win.front;

// Buttons have multiple states, corresponding to transition probabilities.
b_states = [[" ", Color.white, Color.black],
	[" ", Color.white, Color.grey(0.4)],
	[" ", Color.white, Color.grey(0.7)],
	[" ", Color.white, Color.white]];

// Loop through and create the grid of buttons
(n ** 2).do({arg i;
	var col, row, row_touchosc, xpos, ypos;
	row = floor(i / n);
	row_touchosc = n - row;
	col = mod(i, n);

	// Create the messages.
	touchOSC_msg.put(i,
		('/transmat/' ++ row_touchosc.asString ++ '/' ++ (col + 1).asString));

	xpos = (col * (b_width + b_space)) + b_space  + b_space;
	ypos = (row * (b_width + b_space)) + b_space  + b_space;
	b = GUI.button.new(win, Rect(xpos, ypos, b_width, b_width));
	b.states = b_states;
	b.action = {|view|
		var old_val, new_val;
		old_val = ~transition_mat.at(row, col);
		new_val = mod(old_val + 1, b_states.size);
		~transition_mat.put(row, col, new_val);
		// Send updated value to TouchOSC
		adrs_touchOSC.sendMsg(touchOSC_msg[i], view.value);
	};
	button_grid.put(i, b);

	// Initialize the responder nodes
	responders.put(i,
		OSCdef.new(
			'receiver' ++ touchOSC_msg[i],
			{|msg, time, addr, port|
				// Update button grid in sclang and transition matrix
				{button_grid[i].value = msg[1]}.defer;
				~transition_mat.put(row, col, msg[1]);
			},
			touchOSC_msg[i]
		);
	);

});

// Function to step through the transitions
~stepFunc = {|x|
	var tmat_str, out_val, probs, pass;

	// Send a string of the transition matrix to Processing
	// Format: "1,2,3;4,5,6;7,8,9;"
	tmat_str = "";
	~transition_mat.rowsDo({|subarray|
		tmat_str = tmat_str ++ subarray.join(',') ++ ';'});
	adrs_P5.sendMsg("s_new", \trans_mat, tmat_str);

	out_val = ~node_functions[current_state];
	probs = ~transition_mat.rowAt(current_state);

	// If there are no transitions here, pass...
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
			~goFunc.value(out_val); // Play sound
			adrs_P5.sendMsg("s_new", \next_state, next_state);
		}
	);
};

// To automatically step through the matrix, call t.play.
t = Task({
	var delta;
	delta = 60 / 150; // Time until next iteration
	loop {
		~stepFunc.value;
		delta.yield;
	}
});


////////// Set up OSC responders

// Push to go one step
OSCdef.new(
	\advance_resp,
	{|msg, time, addr, port|
		if (msg[1] == 1, {{~stepFunc.value}.defer;}, {} );
	},
	'/advance'
);

// Push and hold to run through the matrix
OSCdef.new(
	\start_resp,
	{|msg, time, addr, port|
		if (msg[1] == 1,
			{{t.play}.defer;},
			{{t.stop}.defer;}
		);
	},
	'/start'
);

// Remove responders when closing the window
win.onClose_({
	(responders.size).do({|i| responders[i].remove;});
	t.stop;
});

)



t.play; // Execute to run
t.pause; // Execute to stop

OSCFunc.trace(true); // Post all OSC signals
OSCFunc.trace(false);

~transition_mat
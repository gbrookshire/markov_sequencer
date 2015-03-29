// Rewriting the Markov chain sequencer as a self-contained class.

MarkovSeq{
	var go_func, node_values, n_nodes,
	<transition_mat, responders,
	current_state, next_state,
	run_task,
	adrsTouchOSC, adrsP5;
	/*
	*/

	*new{arg exec_func, node_vals;
		^super.new.init(exec_func, node_vals);
	}

	init{arg exec_func, node_vals;
		go_func = exec_func;
		node_values = node_vals;
		n_nodes = node_vals.size;
		transition_mat = Array2D.fromArray(
			n_nodes,
			n_nodes,
			Array.fill(n_nodes ** 2, 0)
		);
		// responders = Array.newClear(node_vals ** 2);
		current_state = 0;
		next_state = 0;
	}

	createGUI{
		var b_width, b_space, b_states, btn,
		window_size, win;

		b_width = 40;
		b_space = 6;
		window_size = (2 * (b_space)) + ((b_width + b_space + 1) * n_nodes);
		win = GUI.window.new("",
			Rect(100, 100, window_size, window_size));
		win.view.background = Color(0.15,0.15,0.1);
		win.front;

		// Different colors for each level.
		// Increase number of colors to make more probability steps.
		// TouchOSC only supports binary -- on/off.
		b_states = [
			[" ", Color.white, Color.black],
			[" ", Color.white, Color.white]];

		// Create the grid of buttons
		(n_nodes ** 2).do({arg i;
			var col, row, rowTouch, xpos, ypos, msgTouch;
			row = floor(i / n_nodes);
			rowTouch = n_nodes - row;
			col = mod(i, n_nodes);

			// // Create the OSC messages
			// touchOSC_msg.put(
			// 	i,
			// 	('/transmat/' ++
			// 		row_touchosc.asString ++ '/' ++
			// 	(col + 1).asString)
			// );
			msgTouch = '/transmat/' ++ rowTouch.asString ++ '/' ++ (col + 1).asString;

			xpos = (col * (b_width + b_space)) + b_space  + b_space;
			ypos = (row * (b_width + b_space)) + b_space  + b_space;
			btn = GUI.button.new(win, Rect(xpos, ypos, b_width, b_width));
			btn.states = b_states;
			btn.action = {|view|
				var old_val, new_val;
				old_val = transition_mat.at(row, col);
				new_val = mod(old_val + 1, b_states.size);
				transition_mat.put(row, col, new_val);
				// Send updated value to TouchOSC
				// adrs_touchOSC.sendMsg(touchOSC_msg[i], view.value);
			};
			// button_grid.put(i, btn);

			// // Initialize the OSC responder nodes so that
			// // the GUI updates when you change things in TouchOSC.
			// responders.put(i,
			// 	OSCdef.new(
			// 		// 'receiver' ++ touchOSC_msg[i],
			// 		'receiver' ++ msgTouch,
			// 		{|msg, time, addr, port|
			// 			// Update button grid in sclang and transition matrix
			// 			// {button_grid[i].value = msg[1]}.defer;
			// 			{btn.value = msg[1]}.defer;
			// 			// transition_mat.put(row, col, msg[1]);
			// 		},
			// 		// touchOSC_msg[i]
			// 		msgTouch
			// 	);
			// );
		});
	}

	setProb{arg prob, current, next;
		transition_mat[current, next] = prob;
	}


	step{
		// Take a step through the Markov chain
		var tmat_str, out_val, probs, pass;
		// Send a string of the transition matrix to Processing
		// Format: "1,2,3;4,5,6;7,8,9;"
		tmat_str = "";
		transition_mat.rowsDo({|subarray|
			tmat_str = tmat_str ++ subarray.join(',') ++ ';'
		});
		// adrs_P5.sendMsg("s_new", \trans_mat, tmat_str);

		out_val = node_values[current_state];
		probs = transition_mat.rowAt(current_state);

		// If there are no transitions from the current state,
		// randomly select the next state.
		if (probs == Array.fill(probs.size, 0),
			{
				'No transitions from this state.'.postln;
				current_state = (0..(n_nodes - 1)).choose;
			},{
				probs = probs / sum(probs);
				next_state = (0..(n_nodes - 1)).wchoose(probs);
				current_state = next_state;
				go_func.value(out_val); // Play sound
				// adrs_P5.sendMsg("s_new", \next_state, next_state);
			}
		);
	}

	run{arg delta;
		// Let the chain run.
		// delta : the amount of time between each cycle
		//         Can be a function or a number.
		run_task = Task({
			loop {
				this.step;
				if(delta.isNumber,
					{delta.yield},
					{delta.value.yield});
			}
		});
		run_task.play;
	}

	pause{
		run_task.pause;
	}

	stop{
		run_task.stop;
	}

	sendTouchOSC{
	}

	sendProcessing{
	}
}
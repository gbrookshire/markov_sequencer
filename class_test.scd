(
var goFunc, nodeVals;
goFunc = {|x|
	x.postln;
};
nodeVals = [1, 3, 5, 7, 9];

m = MarkovSeq(goFunc, nodeVals);
m.createGUI;

)

m.transition_mat

m.step;
m.run(0.25)
m.run({((0..4)/4).choose});
m.stop;

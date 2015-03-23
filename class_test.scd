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
m.run;
m.stop;
(0..(3-1)) / (3-1)


Color.new(*[1.0,1,1] * 0.2)
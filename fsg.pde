/*
To rotate the screen, look up translate() and rotate().
This will be useful: 
  http://natureofcode.com/book/chapter-10-neural-networks/
 */

import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;

ArrayList<Node> nodes = new ArrayList<Node>();

void setup() {
  size(400, 400);
  oscP5 = new OscP5(this, 9000);
  myRemoteLocation = new NetAddress("127.0.0.1", 9000);
}

void draw() {
  
  // Writing a blank rectangle makes everything leave a trail.
  stroke(0);
  fill(0, 0, 0, 30);
  rect(0, 0, width, height);

  //  if (mousePressed) {
  //    nodes.add(new Node(random(width), random(height)));
  //  }

  for (int i = 0; i < nodes.size (); i++) {
    Node node = nodes.get(i);
    node.update();
    node.display();
  }
}

class Node {
  int r;
  int g;
  int b;
  float initX;
  float initY;
  float xpos;
  float ypos;
  boolean active;

  Node(float tempX, float tempY) {
    r = 255;
    g = 255;
    b = 255;
    initX = tempX;
    initY = tempY;
    xpos = initX;
    ypos = initY;
    active = false;
  }

  void update() {
    
    // Constrained wiggle.
    xpos = constrain(xpos + random(-1, 1), initX - 3, initX + 3);
    ypos = constrain(ypos + random(-1, 1), initY - 3, initY + 3);

    if (active) {
      r = 255;
      g = 255;
      b = 255;
      active = false;
    } else {
      r = r / 5 * 4;
      g = g / 5 * 4;
      b = b / 10 * 9;
    }
  }

  void display() {
    stroke(255);
    fill(r, g, b);
    ellipse(xpos, ypos, 30, 30);
  }
}

void oscEvent(OscMessage theOscMessage) {
  String address = theOscMessage.get(0).toString();

  if ("next_state".equals(address)) {
    // Activate the next node.
    Node active_node;
    active_node = nodes.get(theOscMessage.get(1).intValue());
    active_node.active = true;
  } else if ("n_elem".equals(address)) {
    // Populate the graph in a circle.
    int n_nodes;
    n_nodes = theOscMessage.get(1).intValue();
    for (int i = 0; i < n_nodes; i++) {
      float angle;
      int hypotenuse = 80;
      float newx;
      float newy;
      angle = i * (2 * PI / n_nodes);
      newx = (width / 2) + hypotenuse * sin(angle);
      newy = (height / 2) + hypotenuse * cos(angle);
      nodes.add(new Node(newx, newy));
    }
  }
}


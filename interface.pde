void interfaceSetup() {
  // Interface
  push();
  noFill();
  stroke(255);
  strokeWeight(1);
  textSize(48);
  text("Simulation", 10, 46);
  line(0, 54, 0, 1079);
  line(0, 54, 1025, 54);
  line(0, 1079, 1025, 1079);
  line(1025, 54, 1025, 1079);
  text("Parameters", 1090, 46);
  rect(1079, 54, 840, 484);
  text("Statistics", 1090, 586);
  rect(1079, 594, 840, 484);
  pop();
}

void interfaceDraw() {
  // Parameters
  // Pause
  push();
  stroke(192);
  strokeWeight(2);
  if (playing) {
    fill(0);
  } else {
    fill(192);
  }

  rect(1100, 90, 20, 20);
  textSize(32);
  fill(255);
  text("Pause (space)", 1140, 110);
  pop(); // Fin pause

  // Début record
  push();
  stroke(255);
  strokeWeight(2);
  fill(recording ? 128 : 0);

  rect(1100, 130, 20, 20);
  textSize(32);
  fill(255);
  text("Record", 1140, 150);
  pop();
  // Fin record

  // Début load state
  push();
  stroke(255);
  strokeWeight(2);
  fill(0);

  rect(1100, 170, 20, 20);
  textSize(32);
  fill(255);
  text("Load state", 1140, 190);
  pop();
  // Fin load State

  push();
  rect(interfaceBoxPauseX, interfaceBoxPauseY, interfaceBoxSize, interfaceBoxSize);
  textSize(interfaceTextSize);
  fill(128);
  strokeWeight(0);
  textAlign(LEFT, CENTER);
  text("Pause (space)", interfaceBoxPauseX + interfaceBoxSize + 12, interfaceBoxPauseY, textWidth("Pause (space)")+1, interfaceBoxSize);
  pop();

  // Couleur
  push();
  fill(192);
  textSize(interfaceTextSize);
  text("0", interfaceBoxPauseX, interfaceBoxPauseY+interfaceBoxSize+24, textWidth("0")+1, interfaceBoxSize);
  text("1", interfaceBoxPauseX+780, interfaceBoxPauseY+interfaceBoxSize+24, textWidth("0")+1, interfaceBoxSize);
  for (int x = 0; x < 720; x++) {
    color colorLine = getColorPixel(x/720.);
    stroke(colorLine);
    line(interfaceBoxPauseX+x+40, interfaceBoxPauseY+interfaceBoxSize+24, interfaceBoxPauseX+x+40, interfaceBoxPauseY+interfaceBoxSize+52);
  }
  stroke(192);
  line(interfaceBoxPauseX+40, interfaceBoxPauseY+interfaceBoxSize+24, interfaceBoxPauseX+40, interfaceBoxPauseY+interfaceBoxSize+52);
  line(interfaceBoxPauseX+40, interfaceBoxPauseY+interfaceBoxSize+24, interfaceBoxPauseX+40+720, interfaceBoxPauseY+interfaceBoxSize+24);
  line(interfaceBoxPauseX+760, interfaceBoxPauseY+interfaceBoxSize+24, interfaceBoxPauseX+760, interfaceBoxPauseY+interfaceBoxSize+52);
  line(interfaceBoxPauseX+40, interfaceBoxPauseY+interfaceBoxSize+52, interfaceBoxPauseX+40+720, interfaceBoxPauseY+interfaceBoxSize+52);
  pop();

  // Statistics

}

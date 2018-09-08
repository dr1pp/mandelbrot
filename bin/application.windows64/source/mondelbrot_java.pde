import interfascia.*;

PGraphics m;                         // Mandelbrot set graphic
PGraphics UI;                        // UI graphic
PImage colourRange;                  // Colour grading image
float zoomX1;                    // Top-left zoom x coordinate
float zoomY1;                    // Top-left zoom y coordinate
float zoomX2;                    // Top-right zoom x coordinate
float zoomY2;                    // Top-right zoom y coordinate
double upperReal = 1;                // Upper bound along real axis (1)
double lowerReal = -2.7;            // Lower bound along real axis (-2.25)
double upperImag = 1.11;                // Upper bound along imaginary axis (1)
double lowerImag = -1.11;               // Lower bound along imaginary axis (-1)
JSONObject settings;

double prevLowerReal = lowerReal;    // Previous lower bound along real axis for zoom out
double prevUpperReal = upperReal;    // Previous upper bound along real axis for zoom out
double prevLowerImag = lowerImag;    // Previous lower bound along imaginary axis for zoom out
double prevUpperImag = upperImag;    // Previous upper bound  along imaginary axis for zoom out
int zoomFactor = 10;                 // Factor to multiply by for zooming in
double zoomLevel = 1;                // Current zoom level

IFLookAndFeel theme;
GUIController GUI;
IFButton save, reset, getcoords;
IFTextField iterationBox;

int N;
float supersample = 1;
int R;
int threads;            

GUIController c;
float percent = 0;

//////////////

void setup() {
  size(1600, 900);
  complex test = new complex(3,-2);
  println(test.squared_modulus());
  settings = loadJSONObject("settings.json");
  N = settings.getInt("N");
  R = settings.getInt("escape value");
  println(width + "x" + height + " @" + N + "i");
  println("-----");
  background(0);
  colorMode(RGB);
  cursor(CROSS);
  loadPixels();
  
  m = createGraphics(width, height);
  UI = createGraphics(width, height);
  m.beginDraw();
  m.background(0);
  m.endDraw();
  
  GUI = new GUIController (this);
  theme = new IFLookAndFeel(this, IFLookAndFeel.DEFAULT);
  theme.baseColor = color(0);
  theme.borderColor = color(50);
  theme.textColor = color(255);
  theme.highlightColor = color(50);
  theme.activeColor = color(0);
  
  GUI.setLookAndFeel(theme);
  
  save = new IFButton ("Save", 204, 1, 60, 19);
  reset = new IFButton ("Reset", 268, 1, 60, 19);
  getcoords = new IFButton("Get Coordinates", 385, 1, 100, 19);
  iterationBox = new IFTextField("N", 331, 1, 50, Integer.toString(N));
  iterationBox.setHeight(19);
  
  save.addActionListener(this);
  reset.addActionListener(this);
  getcoords.addActionListener(this);
  iterationBox.addActionListener(this);
  
  GUI.add(save);
  GUI.add(reset);
  GUI.add(getcoords);
  GUI.add(iterationBox);

  colourRange = loadImage("colours.png");
  colourRange.loadPixels();
  //image(colourRange, 0, 0);
  zoomX1 = 0;
  zoomY1 = 0;
  zoomX2 = width;
  zoomY2 = height;
  thread("renderSet");
}


void draw() {
  image(m, 0, 0, width, height);
  rectMode(CENTER);
  drawUI();
  m.updatePixels();
}

int thread = 0;

public void renderSet() {
  int total = width*height;
  int i = 0;
    for (int y = 0; y < m.height; y++) {
      for (int x = 0; x < m.width; x++) {
        i = drawPoint(x, y, i);
        if (i % (total/width) == 0) {
          percent += 1/width;
        }
      }
    }
  i = 0;
}

double eps = 0.1;

int drawPoint(int x, int y, int count) {
  double real = doubleMap(x, 0, m.width, lowerReal, upperReal);
  double imag = doubleMap(y, 0, m.height, upperImag, lowerImag);
  complex c = new complex(real, imag);
  complex z = new complex(0, 0);
  complex der = new complex(1, 0);
  int n = 0;
  color colour = color(0);
  while (n < N) { 
    if (der.squared_modulus() < eps * eps){
      colour = color(0);
      break;
    }
    if (z.squared_modulus() > (R*R)){
      colour = findColour(n);
      println(n);
      break;
    } 
    der = (der.mult(2)).mult(z);
    z = calculate(z, c);
    println(z.real, z.imaginary);
    n++;
  }
  m.pixels[x+(y*m.width)] = colour; // Colours pixel
  count += 1;
  return count;
}


color findColour(int i) {
  i = floor(map(i, 0, N, 0, colourRange.width-1));
  color colour = colourRange.pixels[i];
  return colour;
}

color smoothColour(int i) {
  colorMode(HSB, 255);
  color colour;
  if (i != N) {
    colour = color(map(i, 0, N, 0, 255), 255, 255);
  } else {
    colour = color(0, 0, 0);
  }
  return colour;
}


complex calculate(complex z, complex c) {
  return z.square().add(c);
}

void drawUI() {
  stroke(0);
  strokeWeight(3);
  noFill();
  rect(mouseX, mouseY, 19.2*zoomFactor, 10*zoomFactor); // Zoom box
  stroke(255);
  strokeWeight(1);
  rect(mouseX, mouseY, 19.2*zoomFactor, 10*zoomFactor);
  stroke(255);
  fill(255);
  text(doubleMap(mouseX, 0, width, lowerReal, upperReal) + "+" + doubleMap(mouseY, 0, (double)height, upperImag, lowerImag) + "i", mouseX + 5, mouseY + 14); // Complex coordinates
  text((mouseX + ", " + mouseY), mouseX + 5, mouseY + 26); // Window coordinates
  text(frameRate, width-30, 20); // Framerate
  rectMode(CORNER);
  fill(255);
  stroke(0);
  rect((mouseX - (19.2*zoomFactor)/2), (mouseY - (10*zoomFactor)/2-17), (19.2*zoomFactor), 17);
  fill(0);
  text(floor((float)zoomLevel) + "x", (mouseX - (19.2*zoomFactor)/2 + 5), (mouseY - (10*zoomFactor)/2 -3));
  fill(get(mouseX, mouseY)); // Get colour under cursor
  ellipse((mouseX + (19.2 * zoomFactor) / 2 - 8), (mouseY - (10 * zoomFactor) / 2 - 8), 13, 13);  // Draw eye-dropper
  fill(0);
  rect(0, 0, 202, 22);
  image(colourRange, 1, 1, 200, 20);
}

void mousePressed() {
  if (mouseX < 200 && mouseY < 22) {
    selectInput("Select custom grandient", "gradientSelected");
  }
  if (mouseX < 486 && mouseY < 23){
    return;
  }
  if (mouseButton == LEFT) {
    zoomX1 = mouseX-((19.2*zoomFactor)/2);
    zoomY1 = mouseY-((10.8*zoomFactor)/2);
    zoomX2 = mouseX+((19.2*zoomFactor)/2);
    zoomY2 = mouseY+(10.8*zoomFactor)/2;
    prevLowerReal = lowerReal;
    prevUpperReal = upperReal;
    prevLowerImag = lowerImag;
    prevUpperImag = upperImag;
    upperReal = doubleMap(zoomX2, 0, m.width, prevLowerReal, prevUpperReal);
    lowerReal = doubleMap(zoomX1, 0, m.width, prevLowerReal, prevUpperReal);
    upperImag = doubleMap(zoomY1, 0, m.height, prevUpperImag, prevLowerImag);
    lowerImag = doubleMap(zoomY2, 0, m.height, prevUpperImag, prevLowerImag);
    zoomLevel = 3.25/(upperReal - lowerReal);
    thread("renderSet");
  } else if (mouseButton == RIGHT) {
    upperReal = prevUpperReal;
    lowerReal = prevLowerReal;
    upperImag = prevUpperImag;
    lowerImag = prevLowerImag;
    thread("renderSet");
  }
}

void mouseWheel(MouseEvent event) {
  float scroll = event.getCount();
  if ((zoomFactor + -scroll) != 0) {
    zoomFactor += -scroll;
  }
}


//void keyPressed() {
//  } else if (key == 'r' || key == 'R') {
//    resetView();
//  } else if (key == 'o' || key == 'O') {
//    selectInput("Select a custom colour grandient with black as the last pixel", "gradientSelected");
//  } else if (key == ' ') {
//    double currentReal = doubleMap(mouseX, 0, width, lowerReal, upperReal);
//    double currentImag = doubleMap(mouseY, 0, (double)height, upperImag, lowerImag);
//    println(currentReal + " + " + currentImag + "i, " + zoomLevel + "x");
//  }
//}

void saveView(){
  String timeString = hour() + "-" + minute() + "-" + second() + " " + day() + "-" + month() + "-" + year();
  String filename = Integer.toString(N) + "i " + Integer.toString(width) + "x" + Integer.toString(height) + " " + timeString + ".png";
  m.save(filename);
  println("File saved");
}

void resetView(){
  upperReal = 1;
  lowerReal = -2.7;
  upperImag = 1.11;
  lowerImag = -1.11;
  thread("renderSet");
  println("Reset view");
}

void actionPerformed (GUIEvent e) {
  if (e.getSource() == save) {
    saveView();
  } else if (e.getSource() == reset) {
    resetView();
  } else if (e.getSource() == getcoords){
    double currentReal = doubleMap(mouseX, 0, width, lowerReal, upperReal);
    double currentImag = doubleMap(mouseY, 0, (double)height, upperImag, lowerImag);
    println(currentReal + " + " + currentImag + "i, " + zoomLevel + "x");
  } else if (e.getMessage().equals("Completed")) {
    N = Integer.parseInt(iterationBox.getValue());
    thread("renderSet");
  }
}

void gradientSelected(File gradient) {
  if (gradient == null) {
    print("no file selected");
  } else {
    println("User selected " + gradient.getAbsolutePath());
    colourRange = loadImage(gradient.getAbsolutePath());
    renderSet();
  }
}


void stats(int total, float time, int N) {
  println("-----");
  println("Finished");
  println("Computed", total, "pixels");
  println("Took", time, "seconds");
  println("[JAVA]", time + "s for", width + "x" + height, "@", N + "i");
}

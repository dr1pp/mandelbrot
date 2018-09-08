import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import interfascia.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class mondelbrot_java extends PApplet {



PGraphics m;                         // Mandelbrot set graphic
PGraphics UI;                        // UI graphic
PImage colourRange;                  // Colour grading image
float zoomX1;                    // Top-left zoom x coordinate
float zoomY1;                    // Top-left zoom y coordinate
float zoomX2;                    // Top-right zoom x coordinate
float zoomY2;                    // Top-right zoom y coordinate
double upperReal = 1;                // Upper bound along real axis (1)
double lowerReal = -2.7f;            // Lower bound along real axis (-2.25)
double upperImag = 1.11f;                // Upper bound along imaginary axis (1)
double lowerImag = -1.11f;               // Lower bound along imaginary axis (-1)
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

int iterations;
float supersample = 1;
int R;
int threads;            

GUIController c;
float percent = 0;

//////////////

public void setup() {
  
  settings = loadJSONObject("settings.json");
  iterations = settings.getInt("iterations");
  R = settings.getInt("escape value");
  println(width + "x" + height + " @" + iterations + "i");
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
  iterationBox = new IFTextField("Iterations", 331, 1, 50, Integer.toString(iterations));
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


public void draw() {
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

public int drawPoint(int x, int y, int count) {
  double real = doubleMap(x, 0, m.width, lowerReal, upperReal);
  double imag = doubleMap(y, 0, m.height, upperImag, lowerImag);
  complex c = new complex(real, imag);
  complex z = new complex(0, 0);
  int i = 0;
  while (i < iterations) { 
    if (z.real < R && z.imaginary < R) { 
      z = calculate(z, c); 
      i++;
    } else { 
      break; // Bail
    }
  }
  int colour = findColour(i); // Finds colour based on iterations
  m.pixels[x+(y*m.width)] = colour; // Colours pixel
  count += 1;
  return count;
}


public int findColour(int i) {
  i = floor(map(i, 0, iterations, 0, colourRange.width-1));
  int colour = colourRange.pixels[i];
  return colour;
}

public int smoothColour(int i) {
  colorMode(HSB, 255);
  int colour;
  if (i != iterations) {
    colour = color(map(i, 0, iterations, 0, 255), 255, 255);
  } else {
    colour = color(0, 0, 0);
  }
  return colour;
}


public complex calculate(complex z, complex c) {
  complex z2 = z.square();
  return add(z2, c);
}

public void drawUI() {
  stroke(0);
  strokeWeight(3);
  noFill();
  rect(mouseX, mouseY, 19.2f*zoomFactor, 10*zoomFactor); // Zoom box
  stroke(255);
  strokeWeight(1);
  rect(mouseX, mouseY, 19.2f*zoomFactor, 10*zoomFactor);
  stroke(255);
  fill(255);
  text(doubleMap(mouseX, 0, width, lowerReal, upperReal) + "+" + doubleMap(mouseY, 0, (double)height, upperImag, lowerImag) + "i", mouseX + 5, mouseY + 14); // Complex coordinates
  text((mouseX + ", " + mouseY), mouseX + 5, mouseY + 26); // Window coordinates
  text(frameRate, width-30, 20); // Framerate
  rectMode(CORNER);
  fill(255);
  stroke(0);
  rect((mouseX - (19.2f*zoomFactor)/2), (mouseY - (10*zoomFactor)/2-17), (19.2f*zoomFactor), 17);
  fill(0);
  text(floor((float)zoomLevel) + "x", (mouseX - (19.2f*zoomFactor)/2 + 5), (mouseY - (10*zoomFactor)/2 -3));
  fill(get(mouseX, mouseY)); // Get colour under cursor
  ellipse((mouseX + (19.2f * zoomFactor) / 2 - 8), (mouseY - (10 * zoomFactor) / 2 - 8), 13, 13);  // Draw eye-dropper
  fill(0);
  rect(0, 0, 202, 22);
  image(colourRange, 1, 1, 200, 20);
}

public void mousePressed() {
  if (mouseX < 200 && mouseY < 22) {
    selectInput("Select custom grandient", "gradientSelected");
  }
  if (mouseX < 486 && mouseY < 23){
    return;
  }
  if (mouseButton == LEFT) {
    zoomX1 = mouseX-((19.2f*zoomFactor)/2);
    zoomY1 = mouseY-((10.8f*zoomFactor)/2);
    zoomX2 = mouseX+((19.2f*zoomFactor)/2);
    zoomY2 = mouseY+(10.8f*zoomFactor)/2;
    prevLowerReal = lowerReal;
    prevUpperReal = upperReal;
    prevLowerImag = lowerImag;
    prevUpperImag = upperImag;
    upperReal = doubleMap(zoomX2, 0, m.width, prevLowerReal, prevUpperReal);
    lowerReal = doubleMap(zoomX1, 0, m.width, prevLowerReal, prevUpperReal);
    upperImag = doubleMap(zoomY1, 0, m.height, prevUpperImag, prevLowerImag);
    lowerImag = doubleMap(zoomY2, 0, m.height, prevUpperImag, prevLowerImag);
    zoomLevel = 3.25f/(upperReal - lowerReal);
    thread("renderSet");
  } else if (mouseButton == RIGHT) {
    upperReal = prevUpperReal;
    lowerReal = prevLowerReal;
    upperImag = prevUpperImag;
    lowerImag = prevLowerImag;
    thread("renderSet");
  }
}

public void mouseWheel(MouseEvent event) {
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

public void saveView(){
  String timeString = hour() + "-" + minute() + "-" + second() + " " + day() + "-" + month() + "-" + year();
  String filename = Integer.toString(iterations) + "i " + Integer.toString(width) + "x" + Integer.toString(height) + " " + timeString + ".png";
  m.save(filename);
  println("File saved");
}

public void resetView(){
  upperReal = 1;
  lowerReal = -2.7f;
  upperImag = 1.11f;
  lowerImag = -1.11f;
  thread("renderSet");
  println("Reset view");
}

public void actionPerformed (GUIEvent e) {
  if (e.getSource() == save) {
    saveView();
  } else if (e.getSource() == reset) {
    resetView();
  } else if (e.getSource() == getcoords){
    double currentReal = doubleMap(mouseX, 0, width, lowerReal, upperReal);
    double currentImag = doubleMap(mouseY, 0, (double)height, upperImag, lowerImag);
    println(currentReal + " + " + currentImag + "i, " + zoomLevel + "x");
  } else if (e.getMessage().equals("Completed")) {
    iterations = Integer.parseInt(iterationBox.getValue());
    thread("renderSet");
  }
}

public void gradientSelected(File gradient) {
  if (gradient == null) {
    print("no file selected");
  } else {
    println("User selected " + gradient.getAbsolutePath());
    colourRange = loadImage(gradient.getAbsolutePath());
    renderSet();
  }
}


public void stats(int total, float time, int iterations) {
  println("-----");
  println("Finished");
  println("Computed", total, "pixels");
  println("Took", time, "seconds");
  println("[JAVA]", time + "s for", width + "x" + height, "@", iterations + "i");
}
public class complex{
  
  private double real;
  private double imaginary;
  
  public complex(){
    real = 0.0f;
    imaginary = 0.0f;
  }
  
  public complex(double real, double imaginary){
    this.real = real;
    this.imaginary = imaginary;
  }
  
  public complex square(){
    double new_real = this.real * this.real - this.imaginary*this.imaginary;
    double new_imaginary = 2*this.real*this.imaginary;
    return new complex(new_real, new_imaginary);
  }
  
  public complex squared_modulus(){
    double abs_real = this.real * this.real;
    double abs_imag = this.imaginary * this.imaginary;
    return new complex(abs_real, abs_imag);
  }
}

public complex add(complex c1, complex c2){
  return new complex(c1.real + c2.real, c1.imaginary + c2.imaginary);
}
public double doubleMap(double value, double istart, double istop, double ostart, double ostop) {
    return ostart + (ostop - ostart) * ((value - istart) / (istop - istart));
}
  public void settings() {  size(1600, 900); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "mondelbrot_java" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}

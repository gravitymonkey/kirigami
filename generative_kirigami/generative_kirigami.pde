import peasy.*;
import processing.svg.*;

PeasyCam cam;

int unit = 15; // just display size for this
int numCols = 5; // should be an even number
int numRows = 10; //2X numcols, if you want a square
ArrayList<int[][]> allData = new ArrayList<int[][]>();

int mx = 0;
int my = 0;
int mz = 0;


void setup(){
  size(800,800, P3D);  
  
  cam = new PeasyCam(this, 100);
  cam.setMinimumDistance(50);
  cam.setMaximumDistance(500);
  
  allData.add(generateEdge());
  for (int w = 1; w < numCols - 1; w++){
    allData.add(generate());
  }
  allData.add(generateEdge());
}

void draw(){
  background(255);
  
  stroke(0,80);
  
  
  for (int w = 0; w < allData.size(); w++){
    int[][] data = allData.get(w);
    drawRow(w, data);
  }


}

void drawRow(int zpos, int[][] data){
  mx = 0;
  my = 0;

  for (int w = 0; w < data.length; w++){
    if ((w % 2) == 0){
      fill(0,0,200,100);
    } else {
      fill(0,0,80,100);
    }

    drawTile(data[w][0], data[w][1], zpos);
  }
}

void drawTile(int tx, int ty, int tz){
  int mz = unit * tz;
  beginShape();
  vertex(mx, my, mz);
  vertex(mx, my, mz + (unit - 2));
  vertex(mx + (tx * unit), my + (ty * unit), mz + (unit - 2));
  vertex(mx + (tx * unit), my + (ty * unit), mz);
  endShape();
  mx = mx + (tx * unit);
  my = my + (ty * unit);
}

int[][] generate(){
  int[][] data = new int[numRows][2];
  data[0] = new int[]{0,1};
  int numX = 0;
  int numY = 0;
  int counter = 1;
  int countMax = (numRows - 2)/2;
  while (counter < numRows - 1){
    if (numX == countMax){
      //useY
      data[counter] = new int[]{0,1};
      numY++;
    } else if (numY == countMax){
      //useX
      data[counter] = new int[]{1,0};
      numX++;
    } else {
      float r = abs(random(1.0f));
      if (r > 0.5f){
        data[counter] = new int[]{0,1};
        numY++;
      } else {
        data[counter] = new int[]{1,0};
        numX++;
      }
    }
    counter++;
  }
  data[numRows - 1] = new int[]{1,0};
  
  if (qualityCheck(data) == null){
    return generate();
  } else {
    return data;
  }
    
}



int[][] qualityCheck(int[][] data){
    //check for overflow
    int xpos = 0;
    int ypos = numRows;
    int edge_max = numRows;
   // println("***********");
    for (int w = 0; w < data.length; w++){
      int[] v = data[w];
      int mx = v[0];
      int my = v[1];
      xpos = xpos + mx;
      ypos = ypos - my;
    //  println(xpos + "," + ypos);
      if ((xpos + ypos) > edge_max){
      //  println("bad edge ");
        return null;
      }
    }
    return data;
}


int[][] generateEdge(){
  int[][] data = new int[numRows][2];
  for (int w = 0; w < (numRows/2); w++){
    data[w][0] = 0;
    data[w][1] = 1;
  }
  for (int w = (numRows/2); w < numRows; w++){
    data[w][0] = 1;
    data[w][1] = 0;
  }  
  return data;
}


void keyTyped() {
  println("typed " + int(key) + " " + keyCode);
  if (int(key) == 32){
    // do one thing if it's a space bar
    save("output.png");
    flatten();
  } else {
    // any other key, regen
    for (int w = 1; w < numCols - 1; w++){
      allData.set(w, generate());
    }
  }

  
}

void flatten(){
  int edge = 2;
  int nwidth = (numCols + 2) * unit;
  int nheight = (numRows + 2) * unit;
  PGraphics svg = createGraphics(nwidth, nheight, SVG, "output.svg");
  svg.beginDraw();
  //border
  svg.rect(unit, unit, numCols * unit, numRows * unit);
  
  //just run the data backward, which makes it easier to compare the image and the cut sheet
  ArrayList<int[][]> flipList = new ArrayList<int[][]>();
  for (int w = allData.size() - 1; w >= 0; w--){
    flipList.add(allData.get(w));
  }
  
  for (int rowCount = 0; rowCount < flipList.size(); rowCount++){
    int[][] data = flipList.get(rowCount);
    int prevX = 0;
    int prevY = 0;
    ArrayList<Integer> foldPoints = new ArrayList<Integer>();
    for (int w = 0; w < data.length; w++){
      int x = data[w][0];
      int y = data[w][1];
      println(prevX + ":" + prevY + "," + x + ":" + y);
      if (x == prevX && y == prevY){
        //don't do anything, it doesn't need an X cut
      } else {
        int xPos = ((rowCount + 1) * unit) + edge;
        int yPos = (w + 1) * unit;
        svg.line(xPos, yPos, xPos + unit - (edge * 2), yPos);
        println(xPos + "," + yPos + "," + (xPos + unit - (edge * 2)) + "," + yPos);        
        foldPoints.add(w);
      }
      prevX = x;
      prevY = y;
    }
    
  }
  
  
  svg.endDraw();
}

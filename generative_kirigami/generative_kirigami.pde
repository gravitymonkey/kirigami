import peasy.*;
import processing.svg.*;
PeasyCam cam;

int unit = 10; // just display size for this
int numCols = 4; // should be an even number? doen't have to be to work...
int numRows = 10; //2X numcols, if you want a square
ArrayList<int[][]> allData;
int edgeColumnDepth = 1; //this is the space on the sides

boolean invertFromMiddle = false;
boolean angleDrawing = false;
boolean arcDrawing = false;

int mx = 0;
int my = 0;
int mz = 0;

String filename = "output";
int num_iter = 0;

float score_floor = 0.9f;

void setup(){ 
  size(500,500, P3D);  
  
  cam = new PeasyCam(this, 300);
  cam.setMinimumDistance(200);
  cam.setMaximumDistance(600);
  cam.lookAt(-50,40,0);
  cam.rotateY(1.75);
  cam.rotateX(0.38);

  float score = 0.0f;
  while (score < score_floor){
    generateFullModel();    
    score = flatten(false);
    print("generate: score " + score);
  }
}

void generateFullModel(){
    allData = new ArrayList<int[][]>();
      //put a safe edge in first pos
    for (int w = 0; w < edgeColumnDepth; w++){
      allData.add(generateEdge());
    }
    
    if (!invertFromMiddle){
      //ok, not trying to make it symmetrical - just make a new one every time
      for (int w = edgeColumnDepth; w < numCols - edgeColumnDepth; w++){
        allData.add(generate());
      }
    } else {
      println("symm");
      //ok we are trying to make it symmettrical.
      ArrayList<Integer> pos = new ArrayList<Integer>(); 
      int midpoint = numCols/2;
      int oddeven = numCols % 2;
      
      for (int w = edgeColumnDepth; w < midpoint + oddeven; w++){
        allData.add(generate());
        if (w < midpoint){
          pos.add(w);
        }
      }      
      for (int w = midpoint + oddeven; w < numCols - edgeColumnDepth; w++){        
        int[][] dd = allData.get(pos.get(pos.size() - 1));
        pos.remove(pos.size() - 1);
        allData.add(dd);
        println(midpoint + ":" + oddeven + ":" + w);
      }
    }
    
    //put a safe edge in last pos
    for (int w = 0; w < edgeColumnDepth; w++){
      allData.add(generateEdge());
    }
}

void draw(){
  translate(50,-50,-50);
  background(240);
  
  stroke(0,180);
  
  
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
      fill(0,0,200,80);
    } else {
      fill(0,0,80,80);
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
  long rx = (long)abs(random(100000000.0f));
  filename = "" + rx;
  println("seed " + rx);
  randomSeed(rx);
  
  numCols = int(random(3.0f, 12.0f));
  numRows = numCols * 2;
  println(numCols);
  println(numRows);
  int[][] data = new int[numRows][2];
  data[0] = new int[]{0,1}; //first col is "blank"
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
  data[numRows - 1] = new int[]{1,0}; // last col is "blank"
  
  if (qualityCheck(data) == null){
    return generate();
  } else {
    num_iter++;
    return data;
  }
    
}



int[][] qualityCheck(int[][] data){
    //check for overflow
    int xpos = 0;
    int ypos = numRows;
    int edge_max = numRows;
    println("quality check ***********");
    for (int w = 0; w < data.length; w++){
      int[] v = data[w];
      int mx = v[0];
      int my = v[1];
      xpos = xpos + mx;
      ypos = ypos - my;
      //println(xpos + "," + ypos);
      if ((xpos + ypos) > edge_max){
        println("bad edge");
        return null;
      }
    }
    println("end quality check *****");
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
    save("output/" + filename + "_" + num_iter + ".png");
    flatten(true);
  } else if (int(key) == 105){
    invertFromMiddle = !invertFromMiddle;
    println("use invert/symmetry " + invertFromMiddle);
  } else {
    // any other keystroke, regen
    //reset the seed
    randomSeed((long)abs(random(100000000.0f)));
    float score = 0.0f;
    while (score < score_floor){
      generateFullModel();
      score = flatten(false);
      print("generate: score " + score);
    }

  }

  
}

float flatten(boolean write){
  println("begin output");
  int edge = 2;
  int nwidth = (numCols + 2) * unit;
  int nheight = (numRows + 2) * unit;
  PGraphics svg = null;
  float leftXEdge = 10000000.0f;
  
  if (write){
    svg = createGraphics(nwidth * 2, nheight * 2, SVG, "output/" + filename + "_" + num_iter + ".svg");
    svg.beginDraw();
    //border (maybe this should be optional)
    if (!angleDrawing){
      svg.rect(unit, unit, numCols * unit, numRows * unit);
    }
  }  
  
  //just run the data backward, which makes it easier to compare the image and the cut sheet
  ArrayList<int[][]> flipList = new ArrayList<int[][]>();
  for (int w = allData.size() - 1; w >= 0; w--){
    flipList.add(allData.get(w));
  }
  
  int[] firstHorz = new int[flipList.size()];
  int[] lastHorz = new int[flipList.size()];
  // now draw the horizontal lines,
  for (int rowCount = 0; rowCount < flipList.size(); rowCount++){
    int[][] data = flipList.get(rowCount);
    int prevX = 0;
    int prevY = 1;
    
    
    for (int w = 0; w < data.length; w++){
      int x = data[w][0];
      int y = data[w][1];
      //println(prevX + ":" + prevY + "," + x + ":" + y);
      if (x == prevX && y == prevY){
        //don't do anything, it doesn't need an X cut
      } else {
        int xPos = ((rowCount + 1) * unit) + edge;
        int yPos = (w + 1) * unit;
        
        if (write){
          float leftEdge = drawSvgLine(svg, xPos, yPos, xPos + unit - (edge * 2), yPos);
          if (leftEdge < leftXEdge){
            leftXEdge = leftEdge;
          }
        }
        if (firstHorz[rowCount] == 0){
          firstHorz[rowCount] = w;
        }
        lastHorz[rowCount] = w;
//        println(xPos + "," + yPos + "," + (xPos + unit - (edge * 2)) + "," + yPos);        
      }
      prevX = x;
      prevY = y;
    }
    
  }
  
  int[] sharedScore = new int[flipList.size() - 1];
    sharedScore[0] = 0;
  
  
  // now draw the vertical lines, but first we have to asses the relation 
  // of each column to the one next to it
  for (int rowCount = 0; rowCount < flipList.size() - 1; rowCount++){
    int[][] data = flipList.get(rowCount);
    int[][] next = flipList.get(rowCount + 1);
    int[] m_data = new int[2];
      m_data[0] = data[0][0];
      m_data[1] = data[0][1];
    int[] n_data = new int[2];
      n_data[0] = next[0][0];
      n_data[1] = next[0][1];
    int crossScore = 0;
    for (int w = 0; w < data.length; w++){
      int x = m_data[0] + data[w][0];
      int y = m_data[1] + data[w][1];
      int a = n_data[0] + next[w][0];
      int b = n_data[1] + next[w][1];
      String p = (m_data[0] + "," + m_data[1] + " " + x + "," + y);
      String q = (n_data[0] + "," + n_data[1] + " " + a + "," + b);
      //println("cutcount\t" + rowCount + ":" + w + "\t" + p + "\t" + q);
      if (!p.equals(q)){
        int xpos = (rowCount + 2) * unit;
        int ypos = (w + 1) * unit;
        if (write){
          drawSvgLine(svg, xpos, ypos, xpos, ypos + unit);        
        }
      } else {
        
        if (rowCount > 0 && rowCount < (flipList.size() - 2)){  
          if (w >= firstHorz[rowCount] && w < lastHorz[rowCount]){
            crossScore++;
          }
        }
      }
      m_data[0] = x;
      m_data[1] = y;
      n_data[0] = a;
      n_data[1] = b;
    }
    sharedScore[rowCount] = crossScore;
  }

  int sharedCols = 0;
  int sharedCells = 0;
  int maxSharedCols = 0;
  for (int w = edgeColumnDepth; w < sharedScore.length - edgeColumnDepth; w++){
    int score = sharedScore[w];
    if (score == 0){
//      println("NO SHARED");
    } else {
      sharedCols++;
    }
    sharedCells = sharedCells + score;
    maxSharedCols++;
  }
  println("connected cols " + sharedCols);
  println("shared cells " + sharedCells);
  println("max shared cols " + maxSharedCols);
    
  if (write){
    if (angleDrawing){
      svg.noFill();
      svg.rect(leftXEdge - 2, unit, numCols * unit, numRows * unit);
    }

    svg.endDraw();
    println("completed output");
  }
  
  float connectedCols =  (float)(sharedCols)/(float)(maxSharedCols);
  return connectedCols;
}

float drawSvgLine(PGraphics svg, float x1, float y1, float x2, float y2){
  if (angleDrawing){
    float totalHeight = numRows * unit;
    float startY = y1/totalHeight;
    float endY = y2/totalHeight;
    x1 = x1 + (((unit * edgeColumnDepth) * startY));
    x2 = x2 + (((unit * edgeColumnDepth) * endY));
  }
  if (arcDrawing && (y1 != y2)){    
    float a = unit/2;
    svg.bezier(x1, y1, x1 + a, y1, x2 + a, y2, x2, y2); 
  } else {
    svg.line(x1, y1, x2, y2);
  }
  return x1;
}

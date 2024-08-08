/* Variables de configuration */

// Si on veut charger les états en mémoire avant de les afficher. Rend une animation plus fluide au coût de plus de mémoire.
// N'a aucun impact sur le rendu final.
static final boolean PRE_LOAD_IN_MEMORY = false;

static int WORLD_DIMENSIONS = 512; // Les dimensions des côtés de la grille.

static final boolean FOLLOW_CENTROID = false; // La caméra va suivre le centre de masse (par exemple, une créature).

/* Fin des variables de configuration */

// Les tableaux suivants ont une dimension, mais représentent des matrices 2D dans l'ordre des colonnes dominantes.
// Les dimensions sont [image][canal][cellule]
ArrayList<float[][]> world = new ArrayList<float[][]>(); // Grille qui contient lenia.

boolean playing = false; // Si la simulation est en cours ou pas. Permet de faire pause.
boolean drag = false; //Si le déplacement est possible

// Déplacement
int deplacementX;
int deplacementY;

float zoom = 1;

int renderedFrameCount = 0;

LeniaFileReader fileManager;

void settings() {
  size(1024, 1024); // Dimensions de la fenêtre.
}

void setup() {
  selectFolder("", "loadDirectory");

  surface.setTitle("Lenia"); // Titre de la fenêtre.
  frameRate(24); // NOmbre d'images par secondes.
  colorMode(HSB, 360, 100, 100); // Gestion des couleurs.
  background(0); // Fond noir par défaut.

  deplacementX = 0;
  deplacementY = 0;
}

void loadDirectory(File file) {
  if (file != null) {
    fileManager = new LeniaFileReader(file);
  }

  if (PRE_LOAD_IN_MEMORY) {
    boolean isFrame = true;
    while (isFrame) {
      isFrame = fileManager.loadState();
    }
  }

  playing = true;
}

void draw() {
  if (fileManager == null) return;
  if (!playing) return;
  if (PRE_LOAD_IN_MEMORY) {
    if (renderedFrameCount >= world.size() - 1) exit();
  } else {
    if (!fileManager.loadState()) exit();
  }

  //Coloration des pixels de la fenêtre.
  int memoryIndex = getMemoryIndex();

  if (FOLLOW_CENTROID) {
    int centroidX = totalCentroidX(world.get(memoryIndex));
    int centroidY = totalCentroidY(world.get(memoryIndex));
    deplacementX = WORLD_DIMENSIONS/2 - centroidX;
    deplacementY = WORLD_DIMENSIONS/2 - centroidY;
  }

  loadPixels();
  for (int x = 0; x < WORLD_DIMENSIONS/zoom; x++)
    for (int y = 0; y < WORLD_DIMENSIONS/zoom; y++)
      for (int i = int(x*(zoom*1024/WORLD_DIMENSIONS)); i < int((x+1)*(zoom*1024/WORLD_DIMENSIONS)); i++)
        for (int j = int(y*(zoom*1024/WORLD_DIMENSIONS)); j < int((y+1)*(zoom*1024/WORLD_DIMENSIONS)); j++) {
          // Les axes de processing et les nôtres sont inversés.
          int positionPixel = Math.floorMod(x+WORLD_DIMENSIONS-deplacementX, WORLD_DIMENSIONS) * WORLD_DIMENSIONS + Math.floorMod(y+WORLD_DIMENSIONS-deplacementY, WORLD_DIMENSIONS);
          if (world.get(0).length == 1) {
            color pixelColor = getColorPixel(world.get(memoryIndex)[0][positionPixel]);
            pixels[(j)*width+i] = pixelColor;
          } else if (world.get(0).length > 1) {
            if (world.get(0).length == 2) {
              colorMode(RGB, 255);
              pixels[(j)*width+i] = color(world.get(memoryIndex)[0][positionPixel]*255, world.get(memoryIndex)[1][positionPixel]*255, 0);
            } else if (world.get(0).length == 3) {
              colorMode(RGB, 255);
              pixels[(j)*width+i] = color(world.get(memoryIndex)[0][positionPixel]*255, world.get(memoryIndex)[1][positionPixel]*255, world.get(memoryIndex)[2][positionPixel]*255);
            }
          }
        }
  updatePixels();

  renderedFrameCount++;

  if (mousePressed) {
    // Déplacement de la caméra.
    if ((mouseButton == RIGHT) && drag) {
      deplacementX += int((mouseX - pmouseX)*WORLD_DIMENSIONS/1024.0/zoom);
      deplacementY += int((mouseY - pmouseY)*WORLD_DIMENSIONS/1024.0/zoom);
    }
  }

  saveFrame("./rendu/frame-####.tif");
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  //Zoom in
  if (e==-1 && zoom<128) {
    zoom *= 2;
    deplacementX += e*(mouseX-1)/(zoom*1024/WORLD_DIMENSIONS);
    deplacementY += e*(mouseY-56)/(zoom*1024/WORLD_DIMENSIONS);
  }
  //Zoom out
  else if (e==1 && zoom>1) {
    zoom /= 2;
    deplacementX += e*(mouseX-1)/(2*zoom*1204/WORLD_DIMENSIONS);
    deplacementY += e*(mouseY-56)/(2*zoom*1024/WORLD_DIMENSIONS);
  }
}

void mousePressed() {
  //Déplacement de la simulation.
  drag = true;
}

void mouseReleased() {
  drag = false;
}

void keyPressed() {
  if (key == ' ')
    // Mettre en pause la simulation, ou repartir.
    playing = !playing;
}

int getMemoryIndex() {
  return PRE_LOAD_IN_MEMORY ? renderedFrameCount : 0 ;
}

color getColorPixel(float value) {
  color colorPixel;
  int nbColors = 3;

  float[][] colors = {
    {240, 100, 0},
    {360, 100, 67},
    {60, 100, 100}
  };
  float[] newColor = new float[3];
  if (value<=0.667) {
    newColor[0] = lerp(colors[0][0], colors[1][0], value/0.667);
    newColor[1] = lerp(colors[0][1], colors[1][1], value/0.667);
    newColor[2] = lerp(colors[0][2], colors[1][2], value/0.667);
    //colorPixel = lerpColor(colors[0], colors[1], value/0.667);
  } else {
    newColor[0] = lerp(colors[1][0], colors[2][0], 3*value-2);
    newColor[1] = lerp(colors[1][1], colors[2][1], 3*value-2);
    newColor[2] = lerp(colors[1][2], colors[2][2], 3*value-2);
    //colorPixel = lerpColor(colors[1], colors[2], 3*value-2);
  }
  colorPixel = color(newColor[0], newColor[1], newColor[2]);
  //colorPixel = lerpColor(color(240, 100, 0), color(360, 100, 67), 0.5);

  // colorPixel = color(300, 100, 33);
  //colorPixel = color(int(lerp(240, 420, value)) % 360, 100, 100*value);
  //colorPixel = color(int(lerp(240, 420, 0.333)) % 360, 100, 100*0.333);
  // colorMode(RGB);
  ////color colorPixel = color(int(255*3*value), int(128*value), int(128*value));
  //color colorPixel = color(int(255*3*value), int(128*value), int(128*value));
  //colorMode(HSB, 360, 100, 100); // Gestion des couleurs.
  //color colorPixel = color(int(lerp(240, 420, floor(100*value)/float(100))) % 360, 100, floor(100*value));
  return colorPixel;
}

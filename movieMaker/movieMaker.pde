/* Variables de configuration */

// Si on veut charger les états en mémoire avant de les afficher. Rend une animation plus fluide au coût de plus de mémoire.
// N'a aucun impact sur le rendu final.
static final boolean PRE_LOAD_IN_MEMORY = false;

static int WORLD_DIMENSIONS = 512; // Les dimensions des côtés de la grille.

static final boolean FOLLOW_CENTROID = false; // La caméra va suivre le centre de masse (par exemple, une créature).

static final boolean DRAW_ORIGIN = false; // Met un plus à l'origine du plan. Utile pour suivre les mouvements de caméra.

// Les paramètres de la platte de couleur. On utilise le système HSL, où on a un dégradé entre la première et la deuxième couleur.
// L'indice des tableaux correspond à celui d'un canal. S'il y a plus de paramètres de de canaux, ils sont ignorés.
// Hue est un point sur la roue de couleurs entre 0 et 360.
float[] hue1 = {0, 120, 240};
float[] hue2 = {0, 120, 240};
// 1 sens horaire, 0 sens anti-horaire.
float[] hueOrientation = {1, 1, 1};
// Les paramètres suivants sont entre 0 et 100.
float[] saturation1 = {100, 100, 100};
float[] saturation2 = {100, 100, 100};
float[] lightness1 = {0, 0, 0};
float[] lightness2 = {100, 100, 100};

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

  stroke(255);
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
    deplacementX = int(WORLD_DIMENSIONS/2/zoom) - centroidX;
    deplacementY = int(WORLD_DIMENSIONS/2/zoom) - centroidY;
  }

  loadPixels();
  for (int x = 0; x < WORLD_DIMENSIONS/zoom; x++)
    for (int y = 0; y < WORLD_DIMENSIONS/zoom; y++)
      for (int i = int(x*(zoom*1024/WORLD_DIMENSIONS)); i < int((x+1)*(zoom*1024/WORLD_DIMENSIONS)); i++)
        for (int j = int(y*(zoom*1024/WORLD_DIMENSIONS)); j < int((y+1)*(zoom*1024/WORLD_DIMENSIONS)); j++) {
          // Les axes de processing et les nôtres sont inversés.
          int positionPixel = Math.floorMod(x+WORLD_DIMENSIONS-deplacementX, WORLD_DIMENSIONS) * WORLD_DIMENSIONS + Math.floorMod(y+WORLD_DIMENSIONS-deplacementY, WORLD_DIMENSIONS);

          color pixelColor = getColorPixel(positionPixel);
          pixels[(j)*width+i] = pixelColor;
        }
  updatePixels();

  //Dessin d'un plus à l'origin du plan.
  if (DRAW_ORIGIN) {
    line(Math.floorMod(512+deplacementX, 1024)-4, Math.floorMod(512+deplacementY, 1024), Math.floorMod(512+deplacementX, 1024)+4, Math.floorMod(512+deplacementY, 1024));
    line(Math.floorMod(512+deplacementX, 1024), Math.floorMod(512+deplacementY, 1024)-4, Math.floorMod(512+deplacementX, 1024), Math.floorMod(512+deplacementY, 1024)+4);
  }

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

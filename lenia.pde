static final int GAUSSIAN_FUNCTION = 0;
static final int POLYNOMIAL_FUNCTION = 1;
static final int RECTANGULAR_FUNCTION = 2;
static final int EXPONENTIAL_FUNCTION = 4;

/* Variables de configuration */

static int WORLD_DIMENSIONS = 128; // Les dimensions des côtés de la grille.
static float dt = 0.1; // Le pas dans le temps à chaque itération.

// Les tableaux suivants ont une dimension, mais représentent des matrices 2D dans l'ordre des colonnes dominantes.
float[][] world = new float[2][WORLD_DIMENSIONS*WORLD_DIMENSIONS]; // Grille qui contient lenia.

Kernel[] kernels; //Sont initialisés dans setup();

/* Fin des vraiables de configuration */

float[][] buffer = new float[world.length][WORLD_DIMENSIONS*WORLD_DIMENSIONS]; // Grille qui permet de calculer la vitesse (dans les statistiques).
float[][] buffer2 = new float[world.length][WORLD_DIMENSIONS*WORLD_DIMENSIONS]; //Grille qui permet de calculer la vitesse angulaire (dans les statistiques)

// Valeurs d'un orbium
float[][] orbium = {{0, 0, 0, 0, 0, 0, 0.1, 0.14, 0.1, 0, 0, 0.03, 0.03, 0, 0, 0.3, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0.08, 0.24, 0.3, 0.3, 0.18, 0.14, 0.15, 0.16, 0.15, 0.09, 0.2, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0.15, 0.34, 0.44, 0.46, 0.38, 0.18, 0.14, 0.11, 0.13, 0.19, 0.18, 0.45, 0, 0, 0}, {0, 0, 0, 0, 0.06, 0.13, 0.39, 0.5, 0.5, 0.37, 0.06, 0, 0, 0, 0.02, 0.16, 0.68, 0, 0, 0}, {0, 0, 0, 0.11, 0.17, 0.17, 0.33, 0.4, 0.38, 0.28, 0.14, 0, 0, 0, 0, 0, 0.18, 0.42, 0, 0}, {0, 0, 0.09, 0.18, 0.13, 0.06, 0.08, 0.26, 0.32, 0.32, 0.27, 0, 0, 0, 0, 0, 0, 0.82, 0, 0}, {0.27, 0, 0.16, 0.12, 0, 0, 0, 0.25, 0.38, 0.44, 0.45, 0.34, 0, 0, 0, 0, 0, 0.22, 0.17, 0}, {0, 0.07, 0.2, 0.02, 0, 0, 0, 0.31, 0.48, 0.57, 0.6, 0.57, 0, 0, 0, 0, 0, 0, 0.49, 0}, {0, 0.59, 0.19, 0, 0, 0, 0, 0.2, 0.57, 0.69, 0.76, 0.76, 0.49, 0, 0, 0, 0, 0, 0.36, 0}, {0, 0.58, 0.19, 0, 0, 0, 0, 0, 0.67, 0.83, 0.9, 0.92, 0.87, 0.12, 0, 0, 0, 0, 0.22, 0.07}, {0, 0, 0.46, 0, 0, 0, 0, 0, 0.7, 0.93, 1, 1, 1, 0.61, 0, 0, 0, 0, 0.18, 0.11}, {0, 0, 0.82, 0, 0, 0, 0, 0, 0.47, 1, 1, 0.98, 1, 0.96, 0.27, 0, 0, 0, 0.19, 0.1}, {0, 0, 0.46, 0, 0, 0, 0, 0, 0.25, 1, 1, 0.84, 0.92, 0.97, 0.54, 0.14, 0.04, 0.1, 0.21, 0.05}, {0, 0, 0, 0.4, 0, 0, 0, 0, 0.09, 0.8, 1, 0.82, 0.8, 0.85, 0.63, 0.31, 0.18, 0.19, 0.2, 0.01}, {0, 0, 0, 0.36, 0.1, 0, 0, 0, 0.05, 0.54, 0.86, 0.79, 0.74, 0.72, 0.6, 0.39, 0.28, 0.24, 0.13, 0}, {0, 0, 0, 0.01, 0.3, 0.07, 0, 0, 0.08, 0.36, 0.64, 0.7, 0.64, 0.6, 0.51, 0.39, 0.29, 0.19, 0.04, 0}, {0, 0, 0, 0, 0.1, 0.24, 0.14, 0.1, 0.15, 0.29, 0.45, 0.53, 0.52, 0.46, 0.4, 0.31, 0.21, 0.08, 0, 0}, {0, 0, 0, 0, 0, 0.08, 0.21, 0.21, 0.22, 0.29, 0.36, 0.39, 0.37, 0.33, 0.26, 0.18, 0.09, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0.03, 0.13, 0.19, 0.22, 0.24, 0.24, 0.23, 0.18, 0.13, 0.05, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0, 0.02, 0.06, 0.08, 0.09, 0.07, 0.05, 0.01, 0, 0, 0, 0, 0}};

// Initialisation du temps simulé à 0.
float time = 0;

boolean playing = true; // Si la simulation est en cours ou pas. Permet de faire pause.
boolean recording = false; // Si l'enregistrement des états est en cours.
boolean drag = false; //Si le déplacement est possible

// Déplacement
int deplacementX;
int deplacementY;

float[][] growthMatrix = new float[world.length][world[0].length];
float[][] growthMatrixBuffer = new float[world.length][world[0].length]; //Pour calculer la vitesse dans les statistiques

float zoom = 1;

LeniaFileManager fileManager;

// Variables pour l'interface
static final float interfaceBoxSize = 28;
static final float interfaceTextSize = 28;
static final float interfaceBoxPauseX = 1100;
static final float interfaceBoxPauseY = 74;

void settings() {
  size(1920, 1080); // Dimensions de la fenêtre.
}

void setup() {
  surface.setTitle("Lenia"); // Titre de la fenêtre.
  frameRate(60); // NOmbre d'images par secondes.
  colorMode(HSB, 360, 100, 100); // Gestion des couleurs.
  background(0); // Fond noir par défaut.

  GPUInit();

  /**
   Le constructeur de l'objet noyau a pour paramètres, dans l'ordre:
   int: Le rayon de convolution.
   float[]: Un tableau contenant les hauteurs relatives des pics des anneaux du noyau.
   int: Le type de fonction de noyau. Des constantes sont fournies pour la lisibilité, comme POLYNOMIAL_FUNCTION.
   int: Le type de fonction pour la croissance. Comme le paramètre précédant.
   float: Le centre de la fonction de croissance (moyenne pour une fonction gaussienne).
   float: L'étallement de la fonction de croissance (écart-type pour une fonction gaussienne).
   int: Le canal d'entrée.
   int: Le canal de sortie.
   float: Le poids relatif du noyau sur le canal de sortie.
   boolean: Vrai si on souhaite utiliser fft pour la convolution, faux sinon.
   */
  kernels = new Kernel[]{
    new Kernel(13*8, new float[]{1}, EXPONENTIAL_FUNCTION, GAUSSIAN_FUNCTION, 0.14, 0.014, 0, 0, 1, true),
    new Kernel(13*8, new float[]{1}, EXPONENTIAL_FUNCTION, GAUSSIAN_FUNCTION, 0.14, 0.014, 1, 1, 1, true),
  };

  fileManager = new LeniaFileManager();

  // Affichage par défaut d'un orbium.
  int orbium_scaling_factor = 8; // Facteur de mise à l'échelle de l'orbium.
  for (int x = 0; x < orbium.length; x++)
    for (int y = 0; y < orbium[0].length; y++)
      for (int i = x*orbium_scaling_factor; i < (x+1)*orbium_scaling_factor; i++)
        for (int j = y*orbium_scaling_factor; j < (y+1)*orbium_scaling_factor; j++)
          world[0][j*WORLD_DIMENSIONS+i] = orbium[x][y];


  //for (int i = 0; i < world.length; i++) {
  //  for (int x = 0; x < WORLD_DIMENSIONS; x++) {
  //    for (int y = 0; y < WORLD_DIMENSIONS; y++) {
  //      world[i][x*WORLD_DIMENSIONS+y] = random(1);
  //    }
  //  }
  //}

  interfaceSetup();

  deplacementX = 0;
  deplacementY = 0;

  // Libération du GPU lorsque le programme se ferme.
  Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
    public void run() {
      for (int i = 0; i < kernels.length; i++) {
        kernels[i].finalize();
      }
      GPURelease();
    }
  }
  , "Shutdown-thread"));

  //Enregistrement de la première frame.
  fileManager.saveState();
}

void draw() {
  //println(frameCount/(millis()/1000.0));
  //Coloration des pixels de la fenêtre.
  loadPixels();
  for (int x = 0; x < WORLD_DIMENSIONS/zoom; x++)
    for (int y = 0; y < WORLD_DIMENSIONS/zoom; y++)
      for (int i = int(x*(zoom*1024/WORLD_DIMENSIONS)); i < int((x+1)*(zoom*1024/WORLD_DIMENSIONS)); i++)
        for (int j = int(y*(zoom*1024/WORLD_DIMENSIONS)); j < int((y+1)*(zoom*1024/WORLD_DIMENSIONS)); j++) {
          // Les axes de processing et les nôtres sont inversés.
          int positionPixel = Math.floorMod(x+WORLD_DIMENSIONS-deplacementX, WORLD_DIMENSIONS) * WORLD_DIMENSIONS + Math.floorMod(y+WORLD_DIMENSIONS-deplacementY, WORLD_DIMENSIONS);
          if (world.length == 1) {
            color pixelColor = getColorPixel(world[0][positionPixel]);
            pixels[(j+55)*width+i+1] = pixelColor;
          } else if (world.length > 1) {
            if (world.length == 2) {
              colorMode(RGB, 255);
              pixels[(j+55)*width+i+1] = color(world[0][positionPixel]*255, world[1][positionPixel]*255, 0);
            } else if (world.length == 3) {
              pixels[(j+55)*width+i+1] = color(world[0][positionPixel]*255, world[1][positionPixel]*255, world[2][positionPixel]*255);
            }
          }
        }
  updatePixels();

  if (mousePressed) {
    // Rendre une cellule vivante si on appuie sur le bouton gauche de la souris.
    if ((mouseButton == RIGHT) && drag) {
      deplacementX += int((1/zoom) * WORLD_DIMENSIONS/float(1080)*(mouseX - pmouseX));
      deplacementY += int((1/zoom) * WORLD_DIMENSIONS/float(1080)*(mouseY - pmouseY));
    } else if (mouseButton == LEFT && (mouseX > 0) && (mouseX < 1026) && (mouseY > 56) && (mouseY < 1080)) {
      //int positionPixel = Math.floorMod(mouseX +WORLD_DIMENSIONS-deplacementX, WORLD_DIMENSIONS) * WORLD_DIMENSIONS + Math.floorMod(mouseY-56+WORLD_DIMENSIONS-deplacementY, WORLD_DIMENSIONS);
      //world[positionPixel] = 1;
      //world[round((mouseX + deplacementX)/(1024/WORLD_DIMENSIONS))*WORLD_DIMENSIONS + round((mouseY-deplacementY-56)/(1024/WORLD_DIMENSIONS))] = 1;
    }
  }

  //  }
  //  // Rendre une cellule morte si on appuie sur le bouton droit de la souris.
  //  else if (mouseButton == RIGHT) {
  //    // world[round(mouseX/(width/WORLD_DIMENSIONS))*WORLD_DIMENSIONS + round(mouseY/(height/WORLD_DIMENSIONS))] = 0;
  //  }
  //}

  interfaceDraw();

  // Si la simulation n'est pas en cours, on arrête ici.
  if (!playing) return;

  if (recording) fileManager.saveState();

  //Avance dans le temps.
  runAutomaton(dt);
  time+=dt;

  //Afficher les statistiques
  showStatistics();
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
  if ((mouseButton == RIGHT) && (mouseX > 0) && (mouseX < 1026) && (mouseY > 56) && (mouseY < 1080)) {
    drag = true;
  }
  // Activer/désactiver le bouton « Pause »
  if (mouseButton == LEFT && (mouseX >= interfaceBoxPauseX) && (mouseX <= interfaceBoxPauseX+interfaceBoxSize) && (mouseY >= interfaceBoxPauseY) && (mouseY <= interfaceBoxPauseY+interfaceBoxSize)) {
    playing = !playing;
  }
  //Enregistrer les états.
  if (mouseButton == LEFT && (mouseX >= 1100) && (mouseX <= 1120) && (mouseY >= 130) && (mouseY <= 150)) {
    recording = !recording;
  }
  //Charger les états.
  if (mouseButton == LEFT && (mouseX >= 1100) && (mouseX <= 1120) && (mouseY >= 170) && (mouseY <= 190)) {
    playing = false;
    recording = false;
    selectInput("", "loadState");
  }
}

/**
 Callback pour selectInput() qui charge un état avec fileManager.
 */
void loadState(File file) {
  fileManager.loadState(file);
}

void mouseReleased() {
  drag = false;
}

void keyPressed() {
  if (key == 'r') {
    // Initialisation aléatoire de la grille.
    for (int i = 0; i < world[0].length; i++)
      for (int j = 0; j < world.length; j++)
        world[j][i] = random(1.);
    // Enregistrement des états dans un nouveau répertoire.
    fileManager = new LeniaFileManager();
    // Enregistrement de la première frame.
    fileManager.saveState();
  }

  if (key == ' ')
    // Mettre en pause la simulation, ou repartir.
    playing = !playing;

  if (key == 'c')
    // Réinitialisation de la grille à 0.
    for (int i = 0; i < world.length; i++)
      for (int j = 0; j < world[0].length; j++)
        world[i][j] = 0;
}

void runAutomaton(float dt) {
  for (int i = 0; i < world.length; i++) {
    for (int j = 0; j < world[i].length; j++) {
      growthMatrix[i][j] =0;
    }
  }
  int[] divisionIndex = new int [world.length];
  for (int i = 0; i < kernels.length; i++) {
    divisionIndex[kernels[i].getOutputChannel()] += kernels[i].getWeight();
  }
  for (int i = 0; i < kernels.length; i++) {
    float[] potential = kernels[i].convolve();

    for (int j = 0; j < world[0].length; j++) {
      growthMatrix[kernels[i].getOutputChannel()][j] += growth(potential[j], kernels[i].getGrowthFunction(), kernels[i].getMu(), kernels[i].getSigma())*kernels[i].getWeight()/divisionIndex[kernels[i].getOutputChannel()];
    }
  }
  for (int i = 0; i < world.length; i++) {
    for (int j = 0; j < world[0].length; j++) {
      world[i][j] = constrain(growthMatrix[i][j]*dt + world[i][j], 0, 1);
      buffer2[i][j] = buffer[i][j];
      buffer[i][j] = world[i][j];
    }
  }
}

void interfaceSetup() {
  // Interface

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
}

void interfaceDraw() {
  // Parameters
  // Pause

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
  // Fin pause

  // Début record

  stroke(255);
  strokeWeight(2);
  fill(recording ? 128 : 0);

  rect(1100, 130, 20, 20);
  textSize(32);
  fill(255);
  text("Record", 1140, 150);

  // Fin record

  // Début load state

  stroke(255);
  strokeWeight(2);
  fill(0);

  rect(1100, 170, 20, 20);
  textSize(32);
  fill(255);
  text("Load state", 1140, 190);

  // Fin load State


  rect(interfaceBoxPauseX, interfaceBoxPauseY, interfaceBoxSize, interfaceBoxSize);
  textSize(interfaceTextSize);
  fill(128);
  strokeWeight(0);
  textAlign(LEFT, CENTER);
  text("Pause (space)", interfaceBoxPauseX + interfaceBoxSize + 12, interfaceBoxPauseY, textWidth("Pause (space)")+1, interfaceBoxSize);


  // Couleur

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


  // Statistiques
}

/**
 Fonction de croissance.
 */
float growth (float potential, int growthFunction, float mu, float sigma) {
  if (growthFunction == 0) {
    return 2*exp(-pow((potential-mu), 2)/(2*sigma*sigma)) -1;
  } else if (growthFunction == 1) {
    if (potential > mu - 3*sigma && potential < mu + 3*sigma) {
      return  2*pow(1 - (pow(potential - mu, 2)/(9*sigma*sigma)), 4) -1;
    } else {
      return  -1;
    }
  } else if (growthFunction == 2) {
    if (potential > mu-sigma && potential < mu+sigma) {
      return 1;
    } else {
      return -1;
    }
  } else {
    return 0;
  }
}

/**
 Fonction du cœur du noyau de convolution.
 */
float kernelCore(float radius, int function) {
  if (function == 4) {
    return exp(4-4/(4*radius*(1-radius)));
  } else if (function == 1) {
    return pow(4*radius*(1-radius), 4);
  } else if (function == 2) {
    if (radius > 0.25 && radius < 0.75) {
      return 1;
    } else {
      return 0;
    }
  } else {
    return 0;
  }
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

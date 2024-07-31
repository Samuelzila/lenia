/* Variables de configuration */

static final int WORLD_DIMENSIONS = 512; // Les dimensions des côtés de la grille.
static final int R = 13*8; // Le rayon du noyeau de convolution.
//static final int R = 8; // Le rayon du noyeau de convolution.
static final float dt = 0.1; // Le pas dans le temps à chaque itération.
static final float MU = 0.14; // Centre de la fonction de noyeau.
static final float SIGMA = 0.014; // Étendue de la fonction de noyeau. Plus la valeur est petite, plus les pics sont importants.
static final float[] BETA = {1}; // Les hauteurs relatives des pics du noyeau de convolution.
static final boolean USE_FFT = false; // Si on veut utiliser FFT pour la convolution.

/* Fin des variables de configuration */

static final float dx = 1.0/R; // Taille d'une cellule, en une dimension, par rapport au voisinnage.
static final int KERNEL_SIZE = R * 2 + 1; // La taille du côté de la matrice qui contient le noyeau de convolution

// Valeurs d'un orbium
float[][] orbium = {{0, 0, 0, 0, 0, 0, 0.1, 0.14, 0.1, 0, 0, 0.03, 0.03, 0, 0, 0.3, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0.08, 0.24, 0.3, 0.3, 0.18, 0.14, 0.15, 0.16, 0.15, 0.09, 0.2, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0.15, 0.34, 0.44, 0.46, 0.38, 0.18, 0.14, 0.11, 0.13, 0.19, 0.18, 0.45, 0, 0, 0}, {0, 0, 0, 0, 0.06, 0.13, 0.39, 0.5, 0.5, 0.37, 0.06, 0, 0, 0, 0.02, 0.16, 0.68, 0, 0, 0}, {0, 0, 0, 0.11, 0.17, 0.17, 0.33, 0.4, 0.38, 0.28, 0.14, 0, 0, 0, 0, 0, 0.18, 0.42, 0, 0}, {0, 0, 0.09, 0.18, 0.13, 0.06, 0.08, 0.26, 0.32, 0.32, 0.27, 0, 0, 0, 0, 0, 0, 0.82, 0, 0}, {0.27, 0, 0.16, 0.12, 0, 0, 0, 0.25, 0.38, 0.44, 0.45, 0.34, 0, 0, 0, 0, 0, 0.22, 0.17, 0}, {0, 0.07, 0.2, 0.02, 0, 0, 0, 0.31, 0.48, 0.57, 0.6, 0.57, 0, 0, 0, 0, 0, 0, 0.49, 0}, {0, 0.59, 0.19, 0, 0, 0, 0, 0.2, 0.57, 0.69, 0.76, 0.76, 0.49, 0, 0, 0, 0, 0, 0.36, 0}, {0, 0.58, 0.19, 0, 0, 0, 0, 0, 0.67, 0.83, 0.9, 0.92, 0.87, 0.12, 0, 0, 0, 0, 0.22, 0.07}, {0, 0, 0.46, 0, 0, 0, 0, 0, 0.7, 0.93, 1, 1, 1, 0.61, 0, 0, 0, 0, 0.18, 0.11}, {0, 0, 0.82, 0, 0, 0, 0, 0, 0.47, 1, 1, 0.98, 1, 0.96, 0.27, 0, 0, 0, 0.19, 0.1}, {0, 0, 0.46, 0, 0, 0, 0, 0, 0.25, 1, 1, 0.84, 0.92, 0.97, 0.54, 0.14, 0.04, 0.1, 0.21, 0.05}, {0, 0, 0, 0.4, 0, 0, 0, 0, 0.09, 0.8, 1, 0.82, 0.8, 0.85, 0.63, 0.31, 0.18, 0.19, 0.2, 0.01}, {0, 0, 0, 0.36, 0.1, 0, 0, 0, 0.05, 0.54, 0.86, 0.79, 0.74, 0.72, 0.6, 0.39, 0.28, 0.24, 0.13, 0}, {0, 0, 0, 0.01, 0.3, 0.07, 0, 0, 0.08, 0.36, 0.64, 0.7, 0.64, 0.6, 0.51, 0.39, 0.29, 0.19, 0.04, 0}, {0, 0, 0, 0, 0.1, 0.24, 0.14, 0.1, 0.15, 0.29, 0.45, 0.53, 0.52, 0.46, 0.4, 0.31, 0.21, 0.08, 0, 0}, {0, 0, 0, 0, 0, 0.08, 0.21, 0.21, 0.22, 0.29, 0.36, 0.39, 0.37, 0.33, 0.26, 0.18, 0.09, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0.03, 0.13, 0.19, 0.22, 0.24, 0.24, 0.23, 0.18, 0.13, 0.05, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0, 0.02, 0.06, 0.08, 0.09, 0.07, 0.05, 0.01, 0, 0, 0, 0, 0}};

// Initialisation du temps simulé à 0.
float time = 0;

// Les tableaux suivants ont une dimension, mais représentent des matrices 2D dans l'ordre des colonnes dominantes.
float[] kernel; // Noyau de convolution.
float[] world = new float[WORLD_DIMENSIONS*WORLD_DIMENSIONS]; // Grille qui contient lenia.

boolean playing = true; // Si la simulation est en cours ou pas. Permet de faire pause.
boolean drag = false; //Si le déplacement est possible

// Déplacement
int deplacementX;
int deplacementY;

float zoom = 1;

// Une classe pour gérer les convolutions par FFT.
FFT fft;

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
  colorMode(RGB); // Gestion des couleurs.
  background(0); // Fond noir par défaut.

  // Calcul des poids du noyau de convolution.
  kernel = preCalculateKernel(BETA);

  //Initialisation du GPU.
  if (USE_FFT) {
    // Initialisation de l'instance FFT.
    fft = new FFT(kernel, world, WORLD_DIMENSIONS, true);
  } else {
    gpuInit();
  }

  // Libération du GPU lorsque le programme se ferme.
  Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
    public void run() {
      if (USE_FFT) {
        fft.finalize();
      } else {
        gpuRelease();
      }
    }
  }
  , "Shutdown-thread"));

  // Affichage par défaut d'un orbium.
  int orbium_scaling_factor = 8; // Facteur de mise à l'échelle de l'orbium.
  for (int x = 0; x < orbium.length; x++)
    for (int y = 0; y < orbium[0].length; y++)
      for (int i = x*orbium_scaling_factor; i < (x+1)*orbium_scaling_factor; i++)
        for (int j = y*orbium_scaling_factor; j < (y+1)*orbium_scaling_factor; j++)
          world[j*WORLD_DIMENSIONS+i] = orbium[x][y];

  for (int x = 0; x < WORLD_DIMENSIONS; x++) {
    for (int y = 0; y < WORLD_DIMENSIONS; y++) {
      // world[x*WORLD_DIMENSIONS+y] = random(1);
    }
  }

  interfaceSetup();

  deplacementX = 0;
  deplacementY = 0;
}

void draw() {
  println(frameCount/(millis()/1000.0));
  //Coloration des pixels de la fenêtre.
  loadPixels();
  for (int x = 0; x < WORLD_DIMENSIONS/zoom; x++)
    for (int y = 0; y < WORLD_DIMENSIONS/zoom; y++)
      for (int i = int(x*(zoom*1024/WORLD_DIMENSIONS)); i < int((x+1)*(zoom*1024/WORLD_DIMENSIONS)); i++)
        for (int j = int(y*(zoom*1024/WORLD_DIMENSIONS)); j < int((y+1)*(zoom*1024/WORLD_DIMENSIONS)); j++) {
          // Les axes de processing et les nôtres sont inversés.
          int positionPixel = Math.floorMod(x+WORLD_DIMENSIONS-deplacementX, WORLD_DIMENSIONS) * WORLD_DIMENSIONS + Math.floorMod(y+WORLD_DIMENSIONS-deplacementY, WORLD_DIMENSIONS);
          color pixelColor = getColorPixel(world[positionPixel]);
          pixels[(j+55)*width+i+1] = pixelColor;
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

  //Avance dans le temps.
  runAutomaton(MU, SIGMA, dt);
  time+=dt;
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  if (e==-1 && zoom<128) {
    zoom *= 2;
    deplacementX += e*(mouseX-1)/(zoom*2);
    deplacementY += e*(mouseY-56)/(zoom*2);
  } else if (e==1 && zoom>1) {
    zoom /= 2;
    deplacementX += e*(mouseX-1)/(4*zoom);
    deplacementY += e*(mouseY-56)/(4*zoom);
  }
}

void mousePressed() {
  if ((mouseButton == RIGHT) && (mouseX > 0) && (mouseX < 1026) && (mouseY > 56) && (mouseY < 1080)) {
    drag = true;
  }
  // Activer/désactiver le bouton « Pause »
  if (mouseButton == LEFT && (mouseX >= interfaceBoxPauseX) && (mouseX <= interfaceBoxPauseX+interfaceBoxSize) && (mouseY >= interfaceBoxPauseY) && (mouseY <= interfaceBoxPauseY+interfaceBoxSize)) {
    playing = !playing;
  }
}

void mouseReleased() {
  drag = false;
}

void keyPressed() {
  if (key == 'r')
    // Initialisation aléatoire de la grille.
    for (int i = 0; i < world.length; i++)
      world[i] = random(1.);

  if (key == ' ')
    // Mettre en pause la simulation, ou repartir.
    playing = !playing;

  if (key == 'c')
    // Réinitialisation de la grille à 0.
    for (int i = 0; i < world.length; i++)
      world[i] = 0;
}

/**
 Cette fonction retourne les poids du noyeau de convolution en fonction du paramètre bêta, qui détermine le nombre d'anneaux et leur importance.
 */
float[] preCalculateKernel(float[] beta) {
  float[] radius = getPolarRadiusMatrix(); // Matrice où chaque case contient sa distance par arpport au centre.

  float[] Br = new float[radius.length];
  for (int i = 0; i < radius.length; i++) {
    Br[i] = (beta.length) * radius[i];
  }

  float[] kernelShell = new float[radius.length];
  for (int i = 0; i < radius.length; i++) {
    if (radius[i] >= 1) kernelShell[i] = 0;
    else
      kernelShell[i] = beta[floor(Br[i])] * kernelCore(Br[i] % 1);
  }

  float kernelSum = 0;
  for (int i = 0; i < radius.length; i++) {
    kernelSum += kernelShell[i];
  }

  float[] kernel = new float[radius.length];
  for (int i = 0; i < radius.length; i++) {
    kernel[i] = kernelShell[i] / kernelSum;
  }

  return kernel;
}

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

void runAutomaton(float mu, float sigma, float dt) {

  float[] potential;
  if (USE_FFT) {
    fft.setImage(world);
    potential = fft.convolve();
  } else {
    potential = convolve(kernel, world);
  }

  float[] growthMatrix = new float[potential.length];
  for (int i = 0; i < potential.length; i++) {
    growthMatrix[i] = growth(potential[i]);
  }

  for (int i = 0; i < world.length; i++)
    world[i] = constrain(world[i] + dt*growthMatrix[i], 0, 1);
}

/**
 Fonction de croissance.
 */
float growth(float potential) {
  float growth = 2*exp(-pow((potential-MU)/SIGMA, 2)*0.5) -1;
  return(growth);
}

/**
 Cette fonction retourne une matrice de même dimensions que le noyau de convolution où chaque cellule contient sa distance euclidienne par rapport au centre.
 */
float[] getPolarRadiusMatrix() {
  float[] matrix = new float[KERNEL_SIZE*KERNEL_SIZE];
  for (int x = -R; x <= R; x++)
    for (int y = -R; y <= R; y++)
      matrix[(x + R) * KERNEL_SIZE + y + R] = sqrt(x*x + y*y) * dx;

  return matrix;
}

/**
 Fonction du cœur du noyeau de convolution.
 */
float kernelCore(float radius) {
  return exp(-(radius-0.5)*(radius-0.5)/0.15/0.15/2.);
}

color getColorPixel(float value) {
  push();
  colorMode(HSB, 360, 100, 100); // Gestion des couleurs.
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
  pop();
  return colorPixel;
}

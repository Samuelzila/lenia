// TODO
// Revoir alignement textes cases
// OK Vérifier style titre
// Simulation
//   (OK) Afficher automate dans simulation
//   (OK) Déplacement
//   (OK) Zoom
//   4. D'autres mondes sont possibles! (tore, monde infini, monde fini avec néant absolu)
// Réparer le pinceau (offset + erreur)

/* Variables de configuration */

static final int WORLD_DIMENSIONS = 1024; // Les dimensions des côtés de la grille.
static final int R = 13; // Le rayon du noyeau de convolution.
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

boolean playing = false; // Si la simulation est en cours ou pas. Permet de faire pause.
boolean drag = false; //Si le déplacement est possible

// Déplacement
int deplacementX;
int deplacementY;

int zoom = 1;

// Pinceaux
int r = 10;//Rayon de pinceau
boolean efface = false;
boolean aleatoire = false;
float b; //Valeur du pinceau
float p = 0.50; //Intensité d'état
boolean carre = false; //Pinceau carré

// Une classe pour gérer les convolutions par FFT.
FFT fft;

void settings() {
  fullScreen(2); // Dimensions de la fenêtre.
  //size(1920, 1080);
}

void setup() {
  surface.setTitle("Lenia"); // Titre de la fenêtre.
  frameRate(60); // NOmbre d'images par secondes.
  colorMode(HSB, 360, 100, 100); // Gestion des couleurs.
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
  //int orbium_scaling_factor = 8; // Facteur de mise à l'échelle de l'orbium.
  //for (int x = 0; x < orbium.length; x++)
  //  for (int y = 0; y < orbium[0].length; y++)
  //    for (int i = x*orbium_scaling_factor; i < (x+1)*orbium_scaling_factor; i++)
  //      for (int j = y*orbium_scaling_factor; j < (y+1)*orbium_scaling_factor; j++)
  //        //world[j*WORLD_DIMENSIONS+i] = orbium[x][y];

  //for (int x = 0; x < WORLD_DIMENSIONS; x++) {
  //  for (int y = 0; y < WORLD_DIMENSIONS; y++) {
  //   // world[x*WORLD_DIMENSIONS+y] = random(1);
  //  }
  //}

  interfaceSetup();

  deplacementX = 0;
  deplacementY = 0;
}

void draw() {

  //Coloration des pixels de la fenêtre.
  push();
  colorMode(HSB, 360, 100, 100); // Gestion des couleurs.
  loadPixels();
  for (int x = 0; x < WORLD_DIMENSIONS/zoom; x++)
    for (int y = 0; y < WORLD_DIMENSIONS/zoom; y++)
      for (int i = int(x*(zoom*1024/WORLD_DIMENSIONS)); i < int((x+1)*(zoom*1024/WORLD_DIMENSIONS)); i++)
        for (int j = int(y*(zoom*1024/WORLD_DIMENSIONS)); j < int((y+1)*(zoom*1024/WORLD_DIMENSIONS)); j++) {
          // Les axes de processing et les nôtres sont inversés.
          int positionPixel = Math.floorMod(x+WORLD_DIMENSIONS-deplacementX, WORLD_DIMENSIONS) * WORLD_DIMENSIONS + Math.floorMod(y+WORLD_DIMENSIONS-deplacementY, WORLD_DIMENSIONS);
          pixels[(j+55)*width+i+1] = color(int(lerp(240, 420, floor(100*world[positionPixel])/float(100))) % 360, 100, floor(100*world[positionPixel]));
        }
  updatePixels();
  pop();



  if (mousePressed) {
    // Rendre une cellule vivante si on appuie sur le bouton gauche de la souris.
    if ((mouseButton == RIGHT) && drag) {
      deplacementX += int((1/zoom) * WORLD_DIMENSIONS/float(1080)*(mouseX - pmouseX));
      deplacementY += int((1/zoom) * WORLD_DIMENSIONS/float(1080)*(mouseY - pmouseY));
    } else if (mouseButton == LEFT && (mouseX > 0) && (mouseX < 1026) && (mouseY > 56) && (mouseY < 1080)) {
      for (int x = -r; x<=r; x++) {
        for (int y = -r; y<=r; y++) {
          if (efface) {
            b = 0;
          } else if (aleatoire) {
            b = noise((mouseX+x)/50.0,(mouseY+y)/50.0);
          } else {
            b = p;
          }
          if (!carre) {
            if (dist(0, 0, x, y) <= r) {
              world[Math.floorMod(((((mouseX)/(1024/WORLD_DIMENSIONS))-(deplacementX*zoom)) / (zoom)+x), WORLD_DIMENSIONS)* WORLD_DIMENSIONS + Math.floorMod((((mouseY-56)/(1024/WORLD_DIMENSIONS)-(deplacementY*zoom)) / (zoom)+y), WORLD_DIMENSIONS)] = b;
            }
          } else {
            world[Math.floorMod(((((mouseX)/(1024/WORLD_DIMENSIONS))-(deplacementX*zoom)) / (zoom)+x), WORLD_DIMENSIONS)* WORLD_DIMENSIONS + Math.floorMod((((mouseY-56)/(1024/WORLD_DIMENSIONS)-(deplacementY*zoom)) / (zoom)+y), WORLD_DIMENSIONS)] = b;
          }
        }
      }
    }
  }

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
  if (mouseButton == LEFT && (mouseX >= 1100) && (mouseX <= 1120) && (mouseY >= 90) && (mouseY <= 110)) {
    playing = !playing;
  }
  if (mouseButton == LEFT && (mouseX >= 1310) && (mouseX <= 1330) && (mouseY >= 120) && (mouseY <= 140) && r > 1) {
    r = r - 1;
  }
  if (mouseButton == LEFT && (mouseX >= 1385) && (mouseX <= 1405) && (mouseY >= 120) && (mouseY <= 140)) {
    r = r + 1;
  }
  if (mouseButton == LEFT && (mouseX >= 1100) && (mouseX <= 1120) && (mouseY >= 150) && (mouseY <= 170)) {
    efface = !efface;
  }
  if (mouseButton == LEFT && (mouseX >= 1100) && (mouseX <= 1120) && (mouseY >= 180) && (mouseY <= 200)) {
    aleatoire = !aleatoire;
  }
  if (mouseButton == LEFT && (mouseX >= 1340) && (mouseX <= 1360) && (mouseY >= 200) && (mouseY <= 220) && p > 0.1) {
    p = p - 0.05;
  }
  if (mouseButton == LEFT && (mouseX >= 1420) && (mouseX <= 1440) && (mouseY >= 200) && (mouseY <= 220) && p < 1) {
    p = p + 0.05;
  }
  if (mouseButton == LEFT && (mouseX >= 1100) && (mouseX <= 1120) && (mouseY >= 240) && (mouseY <= 260)) {
    carre = !carre;
  }
}

void mouseReleased() {
  drag = false;
}

void keyPressed() {
  if (key == 'r')
    // Initialisation aléatoire avec du bruit de la grille.
    for (int i = 0; i < world.length; i++) {
      world[i] = noise((floor(i/WORLD_DIMENSIONS))/50.0, (i % WORLD_DIMENSIONS)/50.0);
    }

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
  stroke(255);
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
  push();  // Début pause
  stroke(255);
  strokeWeight(2);
  if (playing) {
    fill(0);
  } else {
    fill(128);
  }
  rect(1100, 90, 20, 20);
  if (efface) {
    fill(128);
  } else {
    fill(0);
  }
  rect(1100, 150, 20, 20);
  if (aleatoire) {
    fill(128);
  } else {
    fill(0);
  }
  rect(1100, 180, 20, 20);
  if (carre) {
    fill(128);
  } else {
    fill(0);
  }
  rect(1100, 240, 20, 20);
  textSize(32);
  fill(255);
  text("Pause (space)", 1140, 110);
  text("Efface", 1140, 170);
  text("Aléatoire", 1140, 200);
  text("Carré", 1140, 260);
  fill(0);
  stroke(0);
  rect(1340, 120, 30, 30);
  rect(1340, 200, 400, 30);
  fill(255);
  text("Rayon pinceau : <", 1095, 140);
  text(str(r), 1340, 140);
  text(">", 1385, 140);
  text("Intensité pinceau : <", 1095, 230);
  text(String.format("%.2f", p), 1365, 230);
  text(">", 1425, 230);
  pop(); // Début pause

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

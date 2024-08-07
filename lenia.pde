static final int GAUSSIAN_FUNCTION = 0;
static final int POLYNOMIAL_FUNCTION = 1;
static final int RECTANGULAR_FUNCTION = 2;
static final int EXPONENTIAL_FUNCTION = 3;

/* Variables de configuration */
static int WORLD_DIMENSIONS = 512; // Les dimensions des côtés de la grille.
static float dt = 0.1; // Le pas dans le temps à chaque itération.
// Si les bordures du monde sont connectées, comme sur un tore ou dans Pacman.
// Si faux, cela peut affecter négativement les performances lors d'une convolution classique, sans fft.
static final boolean isCyclicWorld = true;

// Les tableaux suivants ont une dimension, mais représentent des matrices 2D dans l'ordre des colonnes dominantes.
float[][] world = new float[1][WORLD_DIMENSIONS*WORLD_DIMENSIONS]; // Grille qui contient lenia.

Kernel[] kernels; //Sont initialisés dans setup();

/* Fin des vraiables de configuration */

float[][] buffer = new float[world.length][WORLD_DIMENSIONS*WORLD_DIMENSIONS]; // Grille qui permet de calculer la vitesse (dans les statistiques).
float[][] buffer2 = new float[world.length][WORLD_DIMENSIONS*WORLD_DIMENSIONS]; //Grille qui permet de calculer la vitesse angulaire (dans les statistiques)


// Initialisation du temps simulé à 0.
float time = 0;


boolean playing = false; // Si la simulation est en cours ou pas. Permet de faire pause.
boolean recording = false; // Si l'enregistrement des états est en cours.
boolean drag = false; //Si le déplacement est possible

// Déplacement
int deplacementX;
int deplacementY;



// Pinceaux
int r = 10;//Rayon de pinceau
boolean efface = false;
boolean aleatoire = false;
float b; //Valeur du pinceau
float p = 0.50; //Intensité d'état
boolean carre = false; //Pinceau carré
int canal = 0; //Canaux
boolean canaux = false; //Tous les canaux

// Étampes
int angle;

// Canaux
boolean one = true, two = true, three = true;


float[][] growthMatrix = new float[world.length][world[0].length];
float[][] growthMatrixBuffer = new float[world.length][world[0].length]; //Pour calculer la vitesse dans les statistiques

int zoom = 1;


LeniaFileManager fileManager;

// Variables pour l'interface
static final float interfaceBoxSize = 28;
static final float interfaceTextSize = 30;
static final float interfaceBoxPauseX = 1100;
static final float interfaceBoxPauseY = 74;

//Variables pour l'affichage des statistiques
int selectedChanelStat = 0;
int ecartStat = 30;
int indiceStat = 0;
int coordonneeXStat = 1140;
int initialYStat = 625;
boolean showCentroid = false;
boolean showGrowthCenter = false;

//Variables pour le changement des statistiques
int selectedKernel = 0;

void settings() {
  fullScreen(2); // Dimensions de la fenêtre.
  //size(1920, 1080);
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
   boolean (facultatif): Vrai si on veut utiliser un noyau asymetrique.
   */
  kernels = new Kernel[]{
    new Kernel(13*8, new float[]{1}, EXPONENTIAL_FUNCTION, GAUSSIAN_FUNCTION, 0.14, 0.014, 0, 0, 1, true),
  };

  fileManager = new LeniaFileManager();

  // Affichage par défaut d'un orbium.
  int orbium_scaling_factor = 8; // Facteur de mise à l'échelle de l'orbium.
  rotateMatrixI(64, orbium);
  for (int x = 0; x < orbium.length; x++) {
    for (int y = 0; y < orbium[0].length; y++) {
      for (int i = x*orbium_scaling_factor; i < (x+1)*orbium_scaling_factor; i++) {
        for (int j = y*orbium_scaling_factor; j < (y+1)*orbium_scaling_factor; j++) {
          world[canal][j*WORLD_DIMENSIONS+i] = orbium[x][y];
        }
      }
    }
  }

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

  showParameterChanges(selectedKernel);
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
            int a;
            int b;
            int c;
            if (one) {
              a = 255;
            } else {
              a = 0;
            }
            if (two) {
              b = 255;
            } else {
              b = 0;
            }
            if (three) {
              c = 255;
            } else {
              c = 0;
            }
            if (world.length == 2) {
              colorMode(RGB, 255);
              pixels[(j+55)*width+i+1] = color(world[0][positionPixel]*a, world[1][positionPixel]*b, 0);
            } else if (world.length == 3) {
              colorMode(RGB, 255);
              pixels[(j+55)*width+i+1] = color(world[0][positionPixel]*a, world[1][positionPixel]*b, world[2][positionPixel]*c);
            }
          }
        }
  updatePixels();


  if (mousePressed) {
    // Rendre une cellule vivante si on appuie sur le bouton gauche de la souris.
    if ((mouseButton == RIGHT) && drag) {
      deplacementX += int((mouseX - pmouseX)*WORLD_DIMENSIONS/1024.0/zoom);
      deplacementY += int((mouseY - pmouseY)*WORLD_DIMENSIONS/1024.0/zoom);
    } else if (mouseButton == LEFT && (mouseX > 0) && (mouseX < 1026) && (mouseY > 56) && (mouseY < 1080)) {
      for (int x = -r; x<=r; x++) {
        for (int y = -r; y<=r; y++) {
          if (!stamps) {
            if (canaux) {
              for (int i = 0; i < world.length; i++) {
                if (efface) {
                  b = 0;
                } else if (aleatoire) {
                  b = noise((mouseX+x)/50.0, (mouseY+y)/50.0);
                } else {
                  b = p;
                }
                if (!carre) {
                  if (dist(0, 0, x, y) <= r) {
                    world[(canal+i)%(world.length)][Math.floorMod(((((mouseX)/(1024/WORLD_DIMENSIONS))-(deplacementX*zoom)) / (zoom)+x), WORLD_DIMENSIONS)* WORLD_DIMENSIONS + Math.floorMod((((mouseY-56)/(1024/WORLD_DIMENSIONS)-(deplacementY*zoom)) / (zoom)+y), WORLD_DIMENSIONS)] = b;
                  }
                } else {
                  world[(canal+i)%(world.length)][Math.floorMod(((((mouseX)/(1024/WORLD_DIMENSIONS))-(deplacementX*zoom)) / (zoom)+x), WORLD_DIMENSIONS)* WORLD_DIMENSIONS + Math.floorMod((((mouseY-56)/(1024/WORLD_DIMENSIONS)-(deplacementY*zoom)) / (zoom)+y), WORLD_DIMENSIONS)] = b;
                }
              }
            } else {
              if (efface) {
                b = 0;
              } else if (aleatoire) {
                b = noise((mouseX+x)/50.0, (mouseY+y)/50.0);
              } else {
                b = p;
              }
              if (!carre) {
                if (dist(0, 0, x, y) <= r) {
                  world[canal][Math.floorMod(((((mouseX)/(1024/WORLD_DIMENSIONS))-(deplacementX*zoom)) / (zoom)+x), WORLD_DIMENSIONS)* WORLD_DIMENSIONS + Math.floorMod((((mouseY-56)/(1024/WORLD_DIMENSIONS)-(deplacementY*zoom)) / (zoom)+y), WORLD_DIMENSIONS)] = b;
                }
              } else {
                world[canal][Math.floorMod(((((mouseX)/(1024/WORLD_DIMENSIONS))-(deplacementX*zoom)) / (zoom)+x), WORLD_DIMENSIONS)* WORLD_DIMENSIONS + Math.floorMod((((mouseY-56)/(1024/WORLD_DIMENSIONS)-(deplacementY*zoom)) / (zoom)+y), WORLD_DIMENSIONS)] = b;
              }
            }
          }
        }
      }
    }
  }



  interfaceDraw();
  //Afficher les statistiques
  showStatistics();
  //Afficher les paramètres
  showParameterChanges(selectedKernel);

  // Si la simulation n'est pas en cours, on arrête ici.
  if (!playing) return;

  if (recording) fileManager.saveState();

  //Avance dans le temps.
  runAutomaton(dt);
  time+=dt;
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
  if (mouseButton == LEFT && (mouseX >= 1310) && (mouseX <= 1330) && (mouseY >= 270) && (mouseY <= 290) && r > 1) {
    r = r - 1;
  }
  if (mouseButton == LEFT && (mouseX >= 1377) && (mouseX <= 1397) && (mouseY >= 270) && (mouseY <= 290) && r < 99) {
    r = r + 1;
  }
  if (mouseButton == LEFT && (mouseX >= 1100) && (mouseX <= 1120) && (mouseY >= 180) && (mouseY <= 200)) {
    efface = !efface;
  }
  if (mouseButton == LEFT && (mouseX >= 1100) && (mouseX <= 1120) && (mouseY >= 210) && (mouseY <= 230)) {
    aleatoire = !aleatoire;
  }
  if (mouseButton == LEFT && (mouseX >= 1330) && (mouseX <= 1350) && (mouseY >= 300) && (mouseY <= 320) && p > 0.1) {
    p = p - 0.05;
  }
  if (mouseButton == LEFT && (mouseX >= 1415) && (mouseX <= 1435) && (mouseY >= 300) && (mouseY <= 320) && p < 1) {
    p = p + 0.05;
  }
  if (mouseButton == LEFT && (mouseX >= 1100) && (mouseX <= 1120) && (mouseY >= 240) && (mouseY <= 260)) {
    carre = !carre;
  }
  //Enregistrer les états.
  if (mouseButton == LEFT && (mouseX >= 1100) && (mouseX <= 1120) && (mouseY >= 120) && (mouseY <= 140)) {
    recording = !recording;
  }
  //Charger les états.
  if (mouseButton == LEFT && (mouseX >= 1100) && (mouseX <= 1120) && (mouseY >= 150) && (mouseY <= 170)) {
    playing = false;
    recording = false;
    selectInput("", "loadState");
  }
  if (mouseButton == LEFT && (mouseX >= 1530) && (mouseX <= 1550) && (mouseY >= 80) && (mouseY <= 110) && canal > 0) {
    canal = canal - 1;
  }
  if (mouseButton == LEFT && (mouseX >= 1570) && (mouseX <= 1590) && (mouseY >= 80) && (mouseY <= 110) && canal < world.length-1) {
    canal = canal + 1;
  }
  if (mouseButton == LEFT && (mouseX >= 1400) && (mouseX <= 1420) && (mouseY >= 90) && (mouseY <= 110)) {
    canaux = !canaux;
  }
  if (stamps && mouseButton == LEFT && (mouseX < 1026)) {
    int orbium_scaling_factor = 0;// Facteur de mise à l'échelle de l'orbium.
    if (WORLD_DIMENSIONS == 1024) {
      orbium_scaling_factor = 8;
    } else if (WORLD_DIMENSIONS == 512) {
      orbium_scaling_factor = 16;
    }
    rotateMatrix(angle, orbium);
    for (int x = 0; x < orbium.length; x++)
      for (int y = 0; y < orbium[0].length; y++)
        for (int i = x*orbium_scaling_factor*zoom; i < (x+1)*orbium_scaling_factor*zoom; i++)
          for (int j = y*orbium_scaling_factor*zoom; j < (y+1)*orbium_scaling_factor*zoom; j++)
            world[canal][Math.floorMod(((((mouseX + j)/(1024/WORLD_DIMENSIONS))-(deplacementX*zoom)) / (zoom)), WORLD_DIMENSIONS)* WORLD_DIMENSIONS + Math.floorMod((((mouseY-56+i)/(1024/WORLD_DIMENSIONS)-(deplacementY*zoom)) / (zoom)), WORLD_DIMENSIONS)] = orbium[x][y];
  }
  if (mouseButton == LEFT && (mouseX >= 1700) && (mouseX <= 1720) && (mouseY >= 90) && (mouseY <= 110)) {
    stamps = !stamps;
  }
  if (mouseButton == LEFT && (mouseX >= 1790) && (mouseX <= 1810) && (mouseY >= 120) && (mouseY <= 140)) {
    angle = Math.floorMod(angle - 30, 360);
  }
  if (mouseButton == LEFT && (mouseX >= 1860) && (mouseX <= 1880) && (mouseY >= 120) && (mouseY <= 140)) {
    angle = Math.floorMod(angle + 30, 360);
  }
  if (mouseButton == LEFT && (mouseX >= 1400) && (mouseX <= 1420) && (mouseY >= 120) && (mouseY <= 140)) {
    one = !one;
  }
  if (mouseButton == LEFT && (mouseX >= 1400) && (mouseX <= 1420) && (mouseY >= 150) && (mouseY <= 170)) {
    two = !two;
  }
  if (mouseButton == LEFT && (mouseX >= 1400) && (mouseX <= 1420) && (mouseY >= 180) && (mouseY <= 200)) {
    three = !three;
  }
  //Pour changer les canaux dans l'affichage des statistiques
  if (mouseButton == LEFT && (mouseX >= coordonneeXStat + 163) && (mouseX <= coordonneeXStat + 185) &&(mouseY <= initialYStat) && (mouseY >= initialYStat -20)  && selectedChanelStat > 0) {
    selectedChanelStat--;
  }
  if (mouseButton == LEFT && (mouseX >= coordonneeXStat + 220) && (mouseX <= coordonneeXStat + 250) &&(mouseY <= initialYStat) && (mouseY >= initialYStat -20)  && selectedChanelStat < world.length) {
    selectedChanelStat++;
  }

  //Pour afficher le centre de masse et le centre de croissance
  if (mouseButton == LEFT && mouseX >= 1100 && mouseX <= 1120 && mouseY >= ecartStat*10 + initialYStat - 20 && mouseY <=  ecartStat*10 + initialYStat) {
    showCentroid =! showCentroid;
  }
  if (mouseButton == LEFT && mouseX >= 1100 && mouseX <= 1120 && mouseY >= ecartStat*11 + initialYStat - 20 && mouseY <=  ecartStat*11 + initialYStat) {
    showGrowthCenter =! showGrowthCenter;
  }


  //Pour changer les paramètres des noyaux en cour de simulation

  //Changement du noyau sélectionné
  if (mouseButton == LEFT && mouseX >= 1565 && mouseX <= 1605 && mouseY >= 165 && mouseY <= 187 && !playing && selectedKernel > 0) {
    selectedKernel --;
  }
  if (mouseButton == LEFT && mouseX >= 1610&& mouseX <= 1650 && mouseY >= 165 && mouseY <=187 && !playing && selectedKernel < kernels.length-1) {
    selectedKernel ++;
  }

  //Changement du rayon du noyau
  if (mouseButton == LEFT && mouseX >= 1535 && mouseX <= 1590 && mouseY >= 190 && mouseY <= 207 && !playing && kernels[selectedKernel].getR() > 6 ) {
    decreaseRadius(selectedKernel);
  }
  if (mouseButton == LEFT && mouseX >= 1595 && mouseX <= 1740 && mouseY >= 190 && mouseY <= 207 && !playing) {
    increaseRadius(selectedKernel);
  }

  //Changement de mu
  if (mouseButton == LEFT && mouseX >= 1535 && mouseX <= 1575 && mouseY >= 210 && mouseY <= 227 && !playing && kernels[selectedKernel].getMu() >= 0.02) {
    decreaseMu(selectedKernel);
  }
  if (mouseButton == LEFT && mouseX >= 1585 && mouseX <= 1625 && mouseY >= 210 && mouseY <= 227 && !playing) {
    increaseMu(selectedKernel);
  }

  //Changement de sigma
  if (mouseButton == LEFT && mouseX >= 1545 && mouseX <= 1595 && mouseY >= 230 && mouseY <= 247 && !playing && kernels[selectedKernel].getSigma() >= 0.002) {
    decreaseSigma(selectedKernel);
  }

  if (mouseButton == LEFT && mouseX >= 1615 && mouseX <= 1655 && mouseY >= 230 && mouseY <= 247 && !playing) {
    increaseSigma(selectedKernel);
  }

  //Changement du canal d'entrée
  // rect(1695, 170, 40, 17);
  if (mouseButton == LEFT && mouseX >= 1745 && mouseX <= 1785 && mouseY >= 190 && mouseY <= 207 && !playing && kernels[selectedKernel].getinputchanel() > 0) {
    decreaseInput(selectedKernel);
  }
  if (mouseButton == LEFT && mouseX >= 1790 && mouseX <= 1830 && mouseY >= 190 && mouseY <= 207 && !playing && kernels[selectedKernel].getinputchanel() < kernels.length - 1) {
    increaseInput(selectedKernel);
  }

  //Changement du canal de sortie
  if (mouseButton == LEFT && mouseX >= 1740 && mouseX <= 1780 && mouseY >= 210 && mouseY <= 227 && !playing && kernels[selectedKernel].getOutputchanel() > 0) {
    decreaseOutput(selectedKernel);
  }
  if (mouseButton == LEFT && mouseX >= 1785 && mouseX <= 1825 && mouseY >= 210 && mouseY <= 227 && !playing && kernels[selectedKernel].getOutputchanel() < kernels.length - 1) {
    increaseOutput(selectedKernel);
  }

  //Changement du poids du noyau
  if (mouseButton == LEFT && mouseX >= 1740 && mouseX <= 1780 && mouseY >= 230 && mouseY <= 247 && !playing && kernels[selectedKernel].getWeight() > 0) {
    decreaseWeigth(selectedKernel);
  }
  if (mouseButton == LEFT && mouseX >= 1785 && mouseX <= 1825 && mouseY >= 230 && mouseY <= 247 && !playing) {
    increaseWeigth(selectedKernel);
  }

  //Changement de la fonction core
  if (mouseButton == LEFT && mouseX >= 1745 && mouseX <= 1795 && mouseY >= 250 && mouseY <= 267 && !playing) {
    changeCoreFunction(selectedKernel);
  }

  //Changement de la growth function
  if (mouseButton == LEFT && mouseX >= 1785 && mouseX <= 1835 && mouseY >= 270 && mouseY <= 287 && !playing) {
    changeGrowthFunction(selectedKernel);
  }

  //Application des changements
  //rect(1455, 270, 260, 23);
  if (mouseButton == LEFT && mouseX >= 1505 && mouseX <= 1765 && mouseY >= 290 && mouseY <= 313 && !playing) {
    kernels[selectedKernel].refresh();
  }
}

/**
 Callback pour selectInput() qui charge un état avec fileManager.
 */
void loadState(File file) {
  if (file != null) {
    fileManager.loadState(file);
  }
}

void mouseReleased() {
  drag = false;
}

void keyPressed() {
  if (key == 'r') {
    // Initialisation aléatoire avec du bruit de la grille.
    for (int j = 0; j < world.length; j++) {
      float offset = random(512);
      for (int i = 0; i < world[0].length; i++) {
        world[j][i] = noise((floor(i/WORLD_DIMENSIONS)+offset)/50.0, ((i % WORLD_DIMENSIONS)+offset)/50.0);
      }
    }
    // Enregistrement des états dans un nouveau répertoire.
    fileManager = new LeniaFileManager();
    // Enregistrement de la première frame.
    fileManager.saveState();
  }
  if (key == 'n') {
    for (int i = 0; i < world.length; i++) {
      for (int j = 0; j < world[i].length; j++) {
        world[i][j] = random(1);
      }
    }
  }
  if (key == ' ') {
    // Mettre en pause la simulation, ou repartir.
    playing = !playing;
  }

  if (key == 'c') {
    // Réinitialisation de la grille à 0.
    for (int i = 0; i < world.length; i++)
      for (int j = 0; j < world[0].length; j++)
        world[i][j] = 0;
  }
  if (key == 'o') {
    stamps = !stamps;
  }
}

void runAutomaton(float dt) {
  for (int i = 0; i < world.length; i++) {
    for (int j = 0; j < world[i].length; j++) {

      buffer2[i][j] = buffer[i][j];
      buffer[i][j] = world[i][j];
      growthMatrixBuffer [i][j] = growthMatrix[i][j];
      growthMatrix[i][j] =0;
    }
  }
  float[] divisionIndex = new float [world.length];
  for (int i = 0; i < kernels.length; i++) {
    divisionIndex[kernels[i].getOutputchanel()] += kernels[i].getWeight();
  }
  for (int i = 0; i < kernels.length; i++) {
    float[] potential = kernels[i].convolve();

    for (int j = 0; j < world[0].length; j++) {
      growthMatrix[kernels[i].getOutputchanel()][j] += growth(potential[j], kernels[i].getGrowthFunction(), kernels[i].getMu(), kernels[i].getSigma())*kernels[i].getWeight()/divisionIndex[kernels[i].getOutputchanel()];
    }
  }
  for (int i = 0; i < world.length; i++) {
    for (int j = 0; j < world[0].length; j++) {
      world[i][j] = constrain(growthMatrix[i][j]*dt + world[i][j], 0, 1);
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

  //Boîte cochable
  stroke(255);
  strokeWeight(2);
  //Pause
  if (playing) {
    fill(0);
  } else {
    fill(192);
  }
  rect(1100, 90, 20, 20);
  //Record
  fill(recording ? 192 : 0);
  rect(1100, 120, 20, 20);
  //Load state
  fill(0);
  rect(1100, 150, 20, 20);
  //Efface
  if (efface) {
    fill(192);
  } else {
    fill(0);
  }
  rect(1100, 180, 20, 20);
  //Aléatoire
  if (aleatoire) {
    fill(192);
  } else {
    fill(0);
  }
  rect(1100, 210, 20, 20);
  //Carré
  if (carre) {
    fill(192);
  } else {
    fill(0);
  }
  rect(1100, 240, 20, 20);
  //Couleur
  for (int x = 0; x < 720; x++) {
    color colorLine = getColorPixel(x/720.);
    stroke(colorLine);
    line(interfaceBoxPauseX+x+40, interfaceBoxPauseY+interfaceBoxSize+265, interfaceBoxPauseX+x+40, interfaceBoxPauseY+interfaceBoxSize+235);
  }
  stroke(255);
  line(interfaceBoxPauseX+40, interfaceBoxPauseY+interfaceBoxSize+232, interfaceBoxPauseX+40, interfaceBoxPauseY+interfaceBoxSize+268);
  line(interfaceBoxPauseX+40, interfaceBoxPauseY+interfaceBoxSize+232, interfaceBoxPauseX+40+720, interfaceBoxPauseY+interfaceBoxSize+232);
  line(interfaceBoxPauseX+760, interfaceBoxPauseY+interfaceBoxSize+232, interfaceBoxPauseX+760, interfaceBoxPauseY+interfaceBoxSize+268);
  line(interfaceBoxPauseX+40, interfaceBoxPauseY+interfaceBoxSize+268, interfaceBoxPauseX+40+720, interfaceBoxPauseY+interfaceBoxSize+268);
  //Canaux
  if (canaux) {
    fill(192);
  } else {
    fill(0);
  }
  rect(1400, 90, 20, 20);
  if (one) {
    fill(192);
  } else {
    fill(0);
  }
  rect(1400, 120, 20, 20);
  if (two) {
    fill(192);
  } else {
    fill(0);
  }
  rect(1400, 150, 20, 20);
  if (three) {
    fill(192);
  } else {
    fill(0);
  }
  rect(1400, 180, 20, 20);
  //Étampes
  if (stamps) {
    fill(192);
  } else {
    fill(0);
  }
  rect(1700, 90, 20, 20);

  //Text
  textSize(30);
  fill(255);
  text("Pause (space)", 1140, 110);
  text("Record", 1140, 140);
  text("Load state", 1140, 170);
  text("Efface", 1140, 200);
  text("Aléatoire", 1140, 230);
  text("Carré", 1140, 260);
  fill(0);
  stroke(0);
  rect(1340, 270, 30, 30);
  rect(1340, 300, 400, 30);
  rect(1550, 80, 20, 30);
  rect(1810, 110, 50, 30);
  fill(255);
  text("Rayon pinceau :    <", 1095, 290);
  text(str(r), 1340, 290);
  text(">", 1377, 290);
  text("Intensité pinceau : <", 1095, 320);
  text(String.format("%.2f", p), 1355, 320);
  text(">", 1420, 320);
  //Couleur
  text("0", 1100, interfaceBoxPauseY+interfaceBoxSize+240, textWidth("0")+1, interfaceBoxSize);
  text("1", interfaceBoxPauseX+780, interfaceBoxPauseY+interfaceBoxSize+240, textWidth("0")+1, interfaceBoxSize);
  text("Canal : <", 1440, 110);
  text(str(canal), 1550, 110);
  text(">", 1570, 110);
  text("1", 1440, 140);
  text("2", 1440, 170);
  text("3", 1440, 200);
  text("Étampes", 1735, 110);
  text("Angle : < " + String.format("%03d", angle) + " >", 1700, 140);

  //Statistiques
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
float kernelCore(float radius, int _function) {
  if (_function == 3) {
    return exp(4-4/(4*radius*(1-radius)));
  } else if (_function == 1) {
    return pow(4*radius*(1-radius), 4);
  } else if (_function == 2) {
    if (radius > 0.25 && radius < 0.75) {
      return 1;
    } else {
      return 0;
    }
  } else if (_function == 0) {
    return(2*exp(-pow(radius-0.14, 2)/(2*0.014*0.014)) - 1);
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

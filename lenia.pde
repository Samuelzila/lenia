// TODO
// - Optimisation couleurs (3 canaux : 2,2 fps)
//   - Mettre dans un tableau les valeurs de base?
//   - Choisir la couleur pour x,y et ne pas recalculer pour i,j?
// - Corriger pour WORLD_DIMENSION différent de 512

static final int GAUSSIAN_FUNCTION = 0;
static final int POLYNOMIAL_FUNCTION = 1;
static final int RECTANGULAR_FUNCTION = 2;
static final int EXPONENTIAL_FUNCTION = 3;

/* Variables de configuration */
static int WORLD_DIMENSIONS = 512; // Les dimensions des côtés de la grille.
static float dt = 0.1; // Le pas dans le temps à chaque itération.
static int NB_CHANNELS = 1; // Nombre de canaux.

// Les tableaux suivants ont une dimension, mais représentent des matrices 2D dans l'ordre des colonnes dominantes.
float[][] world = new float[NB_CHANNELS][WORLD_DIMENSIONS*WORLD_DIMENSIONS]; // Grille qui contient lenia.

// Si les bordures du monde sont connectées, comme sur un tore ou dans Pacman.
// Si faux, cela peut affecter négativement les performances lors d'une convolution classique, sans fft.
static final boolean isCyclicWorld = true;

Kernel[] kernels; //Sont initialisés dans setup();

/* Fin des vraiables de configuration */

float[][] buffer = new float[NB_CHANNELS][WORLD_DIMENSIONS*WORLD_DIMENSIONS]; // Grille qui permet de calculer la vitesse (dans les statistiques).
float[][] buffer2 = new float[NB_CHANNELS][WORLD_DIMENSIONS*WORLD_DIMENSIONS]; //Grille qui permet de calculer la vitesse angulaire (dans les statistiques)

// Les centres de masse précédents, où l'indice du tableau est celui du canal.
// On s'en sert pour que le centre de masse ne dépende pas de la grille.
int[] pOriginX;
int[] pOriginY;

// Initialisation du temps simulé à 0.
float time = 0;

boolean playing = true; // Si la simulation est en cours ou pas. Permet de faire pause
boolean recording = false; // Si l'enregistrement des états est en cours
boolean drag = false; //Si le déplacement est possible

// Déplacement et zoom
int deplacementX;
int deplacementY;
int zoom;

// Pinceaux
int rayonPinceau = 10;//Rayon de pinceau
boolean efface = false;
boolean aleatoire = false;
float valeurPinceau; //Valeur du pinceau
float intensitePinceau = 0.50; //Intensité d'état
boolean carre = false; //Pinceau carré
int canal = 0; //Canaux
boolean canaux = false; //Tous les canaux

// Étampes
int angle;

// Canaux
boolean showChannel0 = true;
boolean showChannel1 = true;
boolean showChannel2 = true;


float[][] growthMatrix = new float[world.length][world[0].length];
float[][] growthMatrixBuffer = new float[world.length][world[0].length]; //Pour calculer la vitesse dans les statistiques

LeniaFileManager fileManager;

// Variables pour les paramètres de la palette de couleurs
float[] colpalHue1 = new float[NB_CHANNELS];
float[] colpalHue2 = new float[NB_CHANNELS];
int[] colpalHueOri = new int[NB_CHANNELS];// 1 sens horaire; 0 sens anti-horaire
float[] colpalSat1 = new float[NB_CHANNELS];
float[] colpalSat2 = new float[NB_CHANNELS];
float[] colpalLight1 = new float[NB_CHANNELS];
float[] colpalLight2 = new float[NB_CHANNELS];


//Variables pour l'affichage des statistiques
int selectedchannelStat = 0;
int ecartStat = 30;
int indiceStat = 0;
int coordonneeXStat = 1140;
int initialYStat = 625;
boolean showCentroid = false;
boolean showGrowthCenter = false;
boolean showVector = false;

//Variables pour le changement des statistiques
int selectedKernel = 0;

void settings() {
  // fullScreen(2); // Dimensions de la fenêtre.
  size(1920, 1080);

  for (int i = 0; i < NB_CHANNELS; i = i+1) {
    colpalHue1[i] = 240;
    colpalHue2[i] = 60;
    colpalHueOri[i] = 1;  // 1 sens horaire; 0 sens anti-horaire
    colpalSat1[i] = 100;
    colpalSat2[i] = 100;
    colpalLight1[i] = 0;
    colpalLight2[i] = 100;
  }
}

void setup() {
  surface.setTitle("Lenia"); // Titre de la fenêtre.
  frameRate(60); // Nombre d'images par secondes.
  colorMode(HSB, 360, 100, 100); // Gestion des couleurs.
  background(0); // Fond noir par défaut.

  //Déplacement et zoom initial
  deplacementX = 0;
  deplacementY = 0;
  zoom = 1;

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
    new Kernel(13*8, new float[]{1}, EXPONENTIAL_FUNCTION, GAUSSIAN_FUNCTION, 0.14, 0.014, 0, 0, 3, true),
    new Kernel(13*8, new float[]{1}, EXPONENTIAL_FUNCTION, GAUSSIAN_FUNCTION, 0.14, 0.014, 1, 1, 3, true),
    new Kernel(13*8, new float[]{1}, EXPONENTIAL_FUNCTION, GAUSSIAN_FUNCTION, 0.14, 0.014, 2, 2, 3, true),
   /* new Kernel(13*8, new float[]{1}, EXPONENTIAL_FUNCTION, GAUSSIAN_FUNCTION, 0.14, 0.014, 0, 1, 2, true),
    new Kernel(13*8, new float[]{1}, EXPONENTIAL_FUNCTION, GAUSSIAN_FUNCTION, 0.14, 0.014, 1, 2, 2, true),
    new Kernel(13*8, new float[]{1}, EXPONENTIAL_FUNCTION, GAUSSIAN_FUNCTION, 0.14, 0.014, 2, 0, 2, true),*/
  };

  fileManager = new LeniaFileManager();

  // Affichage par défaut d'un orbium.
  int orbium_scaling_factor = 8; // Facteur de mise à l'échelle de l'orbium.
  rotateMatrixI(64, orbium);
  for (int x = 0; x < orbium.length; x++) {
    for (int y = 0; y < orbium[0].length; y++) {
      for (int i = x*orbium_scaling_factor; i < (x+1)*orbium_scaling_factor; i++) {
        for (int j = y*orbium_scaling_factor; j < (y+1)*orbium_scaling_factor; j++) {
          world[0][j*WORLD_DIMENSIONS+i] = orbium[x][y];
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

  // Affichage de l'interface
  interfaceSetup();

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

  //Mettre les centres de masse initiaux au centre de la grille.
  pOriginX = new int[world.length];
  pOriginY = new int[world.length];
  for (int i = 0; i< world.length; i++) {
    pOriginX[i] = WORLD_DIMENSIONS/2;
    pOriginY[i] = WORLD_DIMENSIONS/2;
  }

  showParameterChanges(selectedKernel);

  //Enregistrement de la première frame.
  fileManager.saveState();
}

void draw() {
  // Affichage dans la console du nombre d’images par seconde
  println(String.format("%.1f", frameCount/(millis()/1000.0)) + " FPS");

  // Coloration des pixels de la fenêtre.
  loadPixels();
  for (int x = 0; x < WORLD_DIMENSIONS/zoom; x++)
    for (int y = 0; y < WORLD_DIMENSIONS/zoom; y++)
      for (int i = int(x*(zoom*1024/WORLD_DIMENSIONS)); i < int((x+1)*(zoom*1024/WORLD_DIMENSIONS)); i++)
        for (int j = int(y*(zoom*1024/WORLD_DIMENSIONS)); j < int((y+1)*(zoom*1024/WORLD_DIMENSIONS)); j++) {
          int positionPixel = Math.floorMod(x+WORLD_DIMENSIONS-deplacementX, WORLD_DIMENSIONS) * WORLD_DIMENSIONS + Math.floorMod(y+WORLD_DIMENSIONS-deplacementY, WORLD_DIMENSIONS);
          pixels[(j+55)*width+i+1] = getColorPixel(positionPixel);
        }
  updatePixels();

  if (mousePressed) {
    // Rendre une cellule vivante si on appuie sur le bouton gauche de la souris.
    if ((mouseButton == RIGHT) && drag) {
      deplacementX += int((mouseX - pmouseX)*WORLD_DIMENSIONS/1024.0/zoom);
      deplacementY += int((mouseY - pmouseY)*WORLD_DIMENSIONS/1024.0/zoom);
    } else if (mouseButton == LEFT && (mouseX > 0) && (mouseX < 1026) && (mouseY > 56) && (mouseY < 1080)) {
      for (int x = -rayonPinceau; x<=rayonPinceau; x++) {
        for (int y = -rayonPinceau; y<=rayonPinceau; y++) {
          if (!stamps) {
            if (canaux) {
              for (int i = 0; i < world.length; i++) {
                if (efface) {
                  valeurPinceau = 0;
                } else if (aleatoire) {
                  valeurPinceau = noise((mouseX+x)/50.0, (mouseY+y)/50.0);
                } else {
                  valeurPinceau = intensitePinceau;
                }
                if (!carre) {
                  if (dist(0, 0, x, y) <= rayonPinceau) {
                    world[(canal+i)%(world.length)][Math.floorMod(((((mouseX)/(1024/WORLD_DIMENSIONS))-(deplacementX*zoom)) / (zoom)+x), WORLD_DIMENSIONS)* WORLD_DIMENSIONS + Math.floorMod((((mouseY-56)/(1024/WORLD_DIMENSIONS)-(deplacementY*zoom)) / (zoom)+y), WORLD_DIMENSIONS)] = valeurPinceau;
                  }
                } else {
                  world[(canal+i)%(world.length)][Math.floorMod(((((mouseX)/(1024/WORLD_DIMENSIONS))-(deplacementX*zoom)) / (zoom)+x), WORLD_DIMENSIONS)* WORLD_DIMENSIONS + Math.floorMod((((mouseY-56)/(1024/WORLD_DIMENSIONS)-(deplacementY*zoom)) / (zoom)+y), WORLD_DIMENSIONS)] = valeurPinceau;
                }
              }
            } else {
              if (efface) {
                valeurPinceau = 0;
              } else if (aleatoire) {
                valeurPinceau = noise((mouseX+x)/50.0, (mouseY+y)/50.0);
              } else {
                valeurPinceau = intensitePinceau;
              }
              if (!carre) {
                if (dist(0, 0, x, y) <= rayonPinceau) {
                  world[canal][Math.floorMod(((((mouseX)/(1024/WORLD_DIMENSIONS))-(deplacementX*zoom)) / (zoom)+x), WORLD_DIMENSIONS)* WORLD_DIMENSIONS + Math.floorMod((((mouseY-56)/(1024/WORLD_DIMENSIONS)-(deplacementY*zoom)) / (zoom)+y), WORLD_DIMENSIONS)] = valeurPinceau;
                }
              } else {
                world[canal][Math.floorMod(((((mouseX)/(1024/WORLD_DIMENSIONS))-(deplacementX*zoom)) / (zoom)+x), WORLD_DIMENSIONS)* WORLD_DIMENSIONS + Math.floorMod((((mouseY-56)/(1024/WORLD_DIMENSIONS)-(deplacementY*zoom)) / (zoom)+y), WORLD_DIMENSIONS)] = valeurPinceau;
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
  // Déplacement de la simulation.
  if ((mouseButton == RIGHT) && (mouseX > 0) && (mouseX < 1026) && (mouseY > 56) && (mouseY < 1080)) {
    drag = true;
  }
  // Interaction de la souris avec l'interface des paramètres
  interactionParameters();
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
    // Enregistrement des états dans un nouveau répertoire.
    fileManager = new LeniaFileManager();
    // Enregistrement de la première frame.
    fileManager.saveState();
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
  if (key == 'd') {
    zoom = 1;
    deplacementX = 0;
    deplacementY = 0;
  }

  if (key == 'a') {
    //Noyaux aléatoires
    for (int k = 0; k < kernels.length; k++) {
      kernels[k] = new Kernel(int(random(10, 21)), new float[]{1}, EXPONENTIAL_FUNCTION, GAUSSIAN_FUNCTION, random(1), random(0.1), 0, 0, 1, true);
    }
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
    divisionIndex[kernels[i].getOutputchannel()] += kernels[i].getWeight();
  }
  for (int i = 0; i < kernels.length; i++) {
    float[] potential = kernels[i].convolve();

    for (int j = 0; j < world[0].length; j++) {
      growthMatrix[kernels[i].getOutputchannel()][j] += growth(potential[j], kernels[i].getGrowthFunction(), kernels[i].getMu(), kernels[i].getSigma())*kernels[i].getWeight()/divisionIndex[kernels[i].getOutputchannel()];
    }
  }
  for (int i = 0; i < world.length; i++) {
    for (int j = 0; j < world[0].length; j++) {
      world[i][j] = constrain(growthMatrix[i][j]*dt + world[i][j], 0, 1);
    }
  }
}

/**
 Fonction de croissance.
 */
float growth(float potential, int growthFunction, float mu, float sigma) {
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

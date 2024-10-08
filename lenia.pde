static final int GAUSSIAN_FUNCTION = 0;
static final int POLYNOMIAL_FUNCTION = 1;
static final int RECTANGULAR_FUNCTION = 2;
static final int EXPONENTIAL_FUNCTION = 3;

/* Variables de configuration
 Configaration variables*/

static int WORLD_DIMENSIONS = 512; // Les dimensions des côtés de la grille. - Dimensions of each side of the grid.
static float dt = 0.1; // Le pas dans le temps à chaque itération. - The time step of each iteration
static int NB_CHANNELS = 1; // Nombre de canaux. - Number of channels

// Les tableaux suivants ont une dimension, mais représentent des matrices 2D dans l'ordre des colonnes dominantes.
//The following arrays are in one dimensions, but represent 2D matrixces in the order of dominent columns
float[][] world = new float[NB_CHANNELS][WORLD_DIMENSIONS*WORLD_DIMENSIONS]; // Grille qui contient lenia.

// Si les bordures du monde sont connectées, comme sur un tore ou dans Pacman.
// Si faux, cela peut affecter négativement les performances lors d'une convolution classique, sans fft.
// If the borders are conneced or not, like on a tore or in Pacman.
// If false, it can affect negativly the classical convolution (without fft) performances.
static final boolean isCyclicWorld = true;

Kernel[] kernels; //Sont initialisés dans setup(); - Are initialized in setuo();

/* Fin des vraiables de configuration
 End of the configuration variables*/


float[][] buffer = new float[NB_CHANNELS][WORLD_DIMENSIONS*WORLD_DIMENSIONS]; // Grille qui permet de calculer la vitesse (dans les statistiques). - Grid that is used to calculate the speed (in the statistics)
float[][] buffer2 = new float[NB_CHANNELS][WORLD_DIMENSIONS*WORLD_DIMENSIONS]; //Grille qui permet de calculer la vitesse angulaire (dans les statistiques) - Grid that is used to calculate the angular speed (in the statistics)

// Les centres de masse précédents, où l'indice du tableau est celui du canal.
// On s'en sert pour que le centre de masse ne dépende pas de la grille.
// The previous centroif, were the index of the array is the channel's.
// It is used so the centroid does not depend on the grid.
int[] pOriginX;
int[] pOriginY;

// Initialisation du temps simulé à 0.
// Initialisation of the time simulated to 0.
float time = 0;

boolean playing = true; // Si la simulation est en cours ou pas. Permet de faire pause - If the simulation is running or not. Pauses.
boolean recording = false; // Si l'enregistrement des états est en cours  - If the state saving is activated.
boolean drag = false; //Si le déplacement est possible - If the deplacement is possible

// Déplacement et zoom
// Deplacement and zoom
int deplacementX;
int deplacementY;
int zoom;

// Pinceaux
//Brushes
int rayonPinceau = 10;//Rayon de pinceau - Brush radius
boolean efface = false; //Erasor
boolean aleatoire = false; //Random
float valeurPinceau; //Valeur du pinceau - Value of the brush
float intensitePinceau = 0.50; //Intensité d'état - Intensity of state
boolean carre = false; //Pinceau carré - Squared brush
int canal = 0; //Canaux - Channels
boolean canaux = false; //Tous les canaux - All the channels

// Étampes
//Stamps
int angle;

// Canaux
//Channels
boolean showChannel0 = true;
boolean showChannel1 = true;
boolean showChannel2 = true;


float[][] growthMatrix = new float[world.length][world[0].length];
float[][] growthMatrixBuffer = new float[world.length][world[0].length]; //Pour calculer la vitesse dans les statistiques - Used to calculate the speed in the statistics

LeniaFileManager fileManager;

// Variables pour les paramètres de la palette de couleurs
//Variables for the color palette parameters
float[] colpalHue1 = new float[NB_CHANNELS];
float[] colpalHue2 = new float[NB_CHANNELS];
int[] colpalHueOri = new int[NB_CHANNELS];// 1 sens horaire; 0 sens anti-horaire - 1 clockwise; 0 anti-clockwise
float[] colpalSat1 = new float[NB_CHANNELS];
float[] colpalSat2 = new float[NB_CHANNELS];
float[] colpalLight1 = new float[NB_CHANNELS];
float[] colpalLight2 = new float[NB_CHANNELS];


//Variables pour l'affichage des statistiques
//Variables for the display of statistics
int selectedchannelStat = 0;
int ecartStat = 30;
int indiceStat = 0;
int coordonneeXStat = 1140;
int initialYStat = 625;
boolean showCentroid = false;
boolean showGrowthCenter = false;
boolean showVector = false;

//Variables pour le changement des statistiques
//Variables for the change of statistics
int selectedKernel = 0;

void settings() {
  size(1920, 1080);

  for (int i = 0; i < NB_CHANNELS; i = i+1) {
    colpalHue1[i] = 240;
    colpalHue2[i] = 60;
    colpalHueOri[i] = 1;  // 1 sens horaire; 0 sens anti-horaire - 1 clockwise; 0 anti-clockwise
    colpalSat1[i] = 100;
    colpalSat2[i] = 100;
    colpalLight1[i] = 0;
    colpalLight2[i] = 100;
  }
}

void setup() {
  surface.setTitle("Lenia"); // Titre de la fenêtre. - Title of the window
  frameRate(60); // Nombre d'images par secondes. - Number of image per seconds
  colorMode(HSB, 360, 100, 100); // Gestion des couleurs. - Management of colors
  background(0); // Fond noir par défaut. - Black background by default

  //Déplacement et zoom initial
  //Deplacement and final zoom
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
   ---
   The constructor of the kernel object has the following parameters, in order:
   int: The convolution radius.
   float[]: An array that contains the relative heights of the kernel's ring peaks.
   int: The kernel's type of function. Some constants are provided for the lisibility, like POLYNOMIAL_FUNCTION.
   int: The growth function type. As for the previous parameter.
   float: The center of the growth function (median for a gaussian function).
   float: The spread of the growth function (standart deviation for a gaussian function).
   int: The input channel.
   int: The output channel.
   float: The kernel's relative weigth in the output channel.
   boolean: True for a fft convolution.
   boolean (facultative): True for an asymmetrical kernel.
   */
  kernels = new Kernel[]{
    new Kernel(13*8, new float[]{1}, EXPONENTIAL_FUNCTION, GAUSSIAN_FUNCTION, 0.14, 0.014, 0, 0, 3, true),
    //new Kernel(13*8, new float[]{1}, EXPONENTIAL_FUNCTION, GAUSSIAN_FUNCTION, 0.14, 0.014, 1, 1, 3, true),
    //new Kernel(13*8, new float[]{1}, EXPONENTIAL_FUNCTION, GAUSSIAN_FUNCTION, 0.14, 0.014, 2, 2, 3, true),
   /* new Kernel(13*8, new float[]{1}, EXPONENTIAL_FUNCTION, GAUSSIAN_FUNCTION, 0.14, 0.014, 0, 1, 2, true),
    new Kernel(13*8, new float[]{1}, EXPONENTIAL_FUNCTION, GAUSSIAN_FUNCTION, 0.14, 0.014, 1, 2, 2, true),
    new Kernel(13*8, new float[]{1}, EXPONENTIAL_FUNCTION, GAUSSIAN_FUNCTION, 0.14, 0.014, 2, 0, 2, true),*/
  };

  fileManager = new LeniaFileManager();

  // Affichage par défaut d'un orbium.
  //Default display of an orbium
  int orbium_scaling_factor = 8; // Facteur de mise à l'échelle de l'orbium. - Scaling factor for the orbium
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


  // Affichage de l'interface
  //Display of the interface
  interfaceSetup();

  // Libération du GPU lorsque le programme se ferme.
  //GPU release when the program shuts down.
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
  //Saves the first state
  fileManager.saveState();
}

void draw() {
  // Affichage dans la console du nombre d’images par seconde
  // Display of the number of frame by second if the console
  //println(String.format("%.1f", frameCount/(millis()/1000.0)) + " FPS");

  // Coloration des pixels de la fenêtre.
  // Coloration of the window's pixels
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
    // Makes a cell alive if the left button of the mouse is pressed.
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
  //Displays the statistics
  showStatistics();

  //Afficher les paramètres
  //Displays the parameters
  showParameterChanges(selectedKernel);

  // Si la simulation n'est pas en cours, on arrête ici.
  // If the simulation is not running, we stop here.
  if (!playing) return;

  if (recording) fileManager.saveState();

  //Avance dans le temps.
  //Advances in time
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
  // Deplacement of the simulation
  if ((mouseButton == RIGHT) && (mouseX > 0) && (mouseX < 1026) && (mouseY > 56) && (mouseY < 1080)) {
    drag = true;
  }
  // Interaction de la souris avec l'interface des paramètres
  // Interaction of the mouse with the parameters interface.
  interactionParameters();
}

/**
 Callback pour selectInput() qui charge un état avec fileManager.
 Callback for selectInput() that loads a state with fileManager.
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
    //Random initialisation of the grid with Perlin noise 
    for (int j = 0; j < world.length; j++) {
      float offset = random(512);
      for (int i = 0; i < world[0].length; i++) {
        world[j][i] = noise((floor(i/WORLD_DIMENSIONS)+offset)/50.0, ((i % WORLD_DIMENSIONS)+offset)/50.0);
      }
    }
    // Enregistrement des états dans un nouveau répertoire.
    // Saves the states in a new repertory
    fileManager = new LeniaFileManager();
    // Enregistrement de la première frame.
    //Saves the first frame
    fileManager.saveState();
  }
  if (key == 'n') {
    for (int i = 0; i < world.length; i++) {
      for (int j = 0; j < world[i].length; j++) {
        world[i][j] = random(1);
      }
    }
    // Enregistrement des états dans un nouveau répertoire.
    // Savec the states in a new repertory
    fileManager = new LeniaFileManager();
    // Enregistrement de la première frame.
    // Saves the first frame
    fileManager.saveState();
  }
  if (key == ' ') {
    // Mettre en pause la simulation, ou repartir.
    // Pause or play the simulation
    playing = !playing;
  }

  if (key == 'c') {
    // Réinitialisation de la grille à 0.
    // Clears the grid to 0.
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
    //Random kernels
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
 Growth function
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
 Core function of the convolution kernel
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

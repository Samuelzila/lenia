/* Variables de configuration */

static final int WORLD_DIMENSIONS = 512;
static final int R = 13*8;
static final int T = 10;
static final float mu = 0.14;
static final float sigma = 0.014;
static final float[] beta = {1};

static final float dx = 1.0/R;
static final float dt = 1.0/T;
static final int KERNEL_SIZE = R * 2 + 1;

/* Fin des variables de configuration */

float[][] orbium = {{0, 0, 0, 0, 0, 0, 0.1, 0.14, 0.1, 0, 0, 0.03, 0.03, 0, 0, 0.3, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0.08, 0.24, 0.3, 0.3, 0.18, 0.14, 0.15, 0.16, 0.15, 0.09, 0.2, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0.15, 0.34, 0.44, 0.46, 0.38, 0.18, 0.14, 0.11, 0.13, 0.19, 0.18, 0.45, 0, 0, 0}, {0, 0, 0, 0, 0.06, 0.13, 0.39, 0.5, 0.5, 0.37, 0.06, 0, 0, 0, 0.02, 0.16, 0.68, 0, 0, 0}, {0, 0, 0, 0.11, 0.17, 0.17, 0.33, 0.4, 0.38, 0.28, 0.14, 0, 0, 0, 0, 0, 0.18, 0.42, 0, 0}, {0, 0, 0.09, 0.18, 0.13, 0.06, 0.08, 0.26, 0.32, 0.32, 0.27, 0, 0, 0, 0, 0, 0, 0.82, 0, 0}, {0.27, 0, 0.16, 0.12, 0, 0, 0, 0.25, 0.38, 0.44, 0.45, 0.34, 0, 0, 0, 0, 0, 0.22, 0.17, 0}, {0, 0.07, 0.2, 0.02, 0, 0, 0, 0.31, 0.48, 0.57, 0.6, 0.57, 0, 0, 0, 0, 0, 0, 0.49, 0}, {0, 0.59, 0.19, 0, 0, 0, 0, 0.2, 0.57, 0.69, 0.76, 0.76, 0.49, 0, 0, 0, 0, 0, 0.36, 0}, {0, 0.58, 0.19, 0, 0, 0, 0, 0, 0.67, 0.83, 0.9, 0.92, 0.87, 0.12, 0, 0, 0, 0, 0.22, 0.07}, {0, 0, 0.46, 0, 0, 0, 0, 0, 0.7, 0.93, 1, 1, 1, 0.61, 0, 0, 0, 0, 0.18, 0.11}, {0, 0, 0.82, 0, 0, 0, 0, 0, 0.47, 1, 1, 0.98, 1, 0.96, 0.27, 0, 0, 0, 0.19, 0.1}, {0, 0, 0.46, 0, 0, 0, 0, 0, 0.25, 1, 1, 0.84, 0.92, 0.97, 0.54, 0.14, 0.04, 0.1, 0.21, 0.05}, {0, 0, 0, 0.4, 0, 0, 0, 0, 0.09, 0.8, 1, 0.82, 0.8, 0.85, 0.63, 0.31, 0.18, 0.19, 0.2, 0.01}, {0, 0, 0, 0.36, 0.1, 0, 0, 0, 0.05, 0.54, 0.86, 0.79, 0.74, 0.72, 0.6, 0.39, 0.28, 0.24, 0.13, 0}, {0, 0, 0, 0.01, 0.3, 0.07, 0, 0, 0.08, 0.36, 0.64, 0.7, 0.64, 0.6, 0.51, 0.39, 0.29, 0.19, 0.04, 0}, {0, 0, 0, 0, 0.1, 0.24, 0.14, 0.1, 0.15, 0.29, 0.45, 0.53, 0.52, 0.46, 0.4, 0.31, 0.21, 0.08, 0, 0}, {0, 0, 0, 0, 0, 0.08, 0.21, 0.21, 0.22, 0.29, 0.36, 0.39, 0.37, 0.33, 0.26, 0.18, 0.09, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0.03, 0.13, 0.19, 0.22, 0.24, 0.24, 0.23, 0.18, 0.13, 0.05, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0, 0.02, 0.06, 0.08, 0.09, 0.07, 0.05, 0.01, 0, 0, 0, 0, 0}};

float time = 0;

float[] kernel;
float[] world = new float[WORLD_DIMENSIONS*WORLD_DIMENSIONS];

boolean playing = false;

void settings() {
  size(1024, 1024);
}

void setup() {
  frameRate(30);
  surface.setTitle("Lenia");
  colorMode(HSB, 360, 1, 1);
  background(0);
  kernel = pre_calculate_kernel(beta);

  gpuInit();

  //Release openCL elements when the program closes.
  Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
    public void run() {
      gpuRelease();
    }
  }
  , "Shutdown-thread"));

  //Stamp orbium
  int orbium_scaling_factor = 8;
  for (int x = 0; x < orbium.length; x++)
    for (int y = 0; y < orbium[0].length; y++)
      for (int i = x*orbium_scaling_factor; i < (x+1)*orbium_scaling_factor; i++)
        for (int j = y*orbium_scaling_factor; j < (y+1)*orbium_scaling_factor; j++)
          world[j*WORLD_DIMENSIONS+i] = orbium[x][y];
}

void draw() {
  loadPixels();
  for (int x = 0; x < WORLD_DIMENSIONS; x++)
    for (int y = 0; y < WORLD_DIMENSIONS; y++)
      for (int i = x*(width/WORLD_DIMENSIONS); i < (x+1)*(width/WORLD_DIMENSIONS); i++)
        for (int j = y*(height/WORLD_DIMENSIONS); j < (y+1)*(height/WORLD_DIMENSIONS); j++)
          //Axes are exchanged compared to the cells array.
          pixels[j*width+i] = color(int(lerp(240, 420, floor(100*world[x * WORLD_DIMENSIONS + y])/float(100))) % 360, 100, floor(100*world[x * WORLD_DIMENSIONS + y]));
  updatePixels();

  if (mousePressed) {
    //Make cell alive when mouse left button is pressed.
    if (mouseButton == LEFT) {
      world[round(mouseX/(width/WORLD_DIMENSIONS))*WORLD_DIMENSIONS + round(mouseY/(height/WORLD_DIMENSIONS))] = 1;
    }
    //Make a cell dead when right mouse button is pressed
    else if (mouseButton == RIGHT) {
      world[round(mouseX/(width/WORLD_DIMENSIONS))*WORLD_DIMENSIONS + round(mouseY/(height/WORLD_DIMENSIONS))] = 0;
    }
  }

  if (!playing) return;

  run_automaton(mu, sigma, dt);
  time+=dt;
}

void keyPressed() {
  if (key == 'r')
    for (int i = 0; i < world.length; i++)
      world[i] = random(1.);

  if (key == ' ')
    playing = !playing;

  if (key == 'c')
    for (int i = 0; i < world.length; i++)
      world[i] = 0;
}

float[] pre_calculate_kernel(float[] beta) {
  float[] radius = get_polar_radius_matrix();
  float[] Br = new float[radius.length];
  for (int i = 0; i < radius.length; i++) {
    Br[i] = (beta.length) * radius[i];
  }
  float[] kernel_shell = new float[radius.length];
  for (int i = 0; i < radius.length; i++) {
    if (radius[i] >= 1) kernel_shell[i] = 0;
    else
      kernel_shell[i] = beta[floor(Br[i])] * kernel_core(Br[i] % 1);
  }

  float kernel_sum = 0;
  for (int i = 0; i < radius.length; i++) {
    kernel_sum += kernel_shell[i];
  }

  float[] kernel = new float[radius.length];
  for (int i = 0; i < radius.length; i++) {
    kernel[i] = kernel_shell[i] / kernel_sum;
  }

  return kernel;
}

float[] potential = new float[world.length];
void run_automaton(float mu, float sigma, float dt) {
  convolve();

  float[] growth_map = new float[potential.length];
  for (int i = 0; i < potential.length; i++) {
    growth_map[i] = growth(potential[i]);
  }

  for (int i = 0; i < world.length; i++)
    world[i] = constrain(world[i] + dt*growth_map[i], 0, 1);
}

//Fonction de croissance
float growth(float potential) {
  float growth = 2*exp(-pow((potential-mu)/sigma, 2)*0.5) -1;

  return(growth);
}

float[] get_polar_radius_matrix() {
  float[] matrix = new float[KERNEL_SIZE*KERNEL_SIZE];
  for (int x = -R; x <= R; x++)
    for (int y = -R; y <= R; y++)
      matrix[(x + R) * KERNEL_SIZE + y + R] = sqrt(x*x + y*y) * dx;

  return matrix;
}

float kernel_core(float radius) {
  return exp(-(radius-0.5)*(radius-0.5)/0.15/0.15/2.);
}

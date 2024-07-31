class Kernel {
  private float[] kernel;

  private int R;
  private float[] beta;
  private int coreFunction;
  private int inputChannel; // Indice du canal d'entrée.
  private int outputChannel; // Indice du canal de sortie.
  private int kernelWeight;
  private boolean useFft;
  private int growthFunction;
  private float mu;
  private float sigma;

  private int kernelWidth;

  private FFT fft;
  private ElementWiseConvolution elementWiseConvolution;

  Kernel(int _R, float[] _beta, int _coreFunction, int _growthFunction, float _mu, float _sigma, int _inputChannel, int _outputChannel, int _kernelWeight, boolean _useFft) {
    R = _R;
    beta = _beta;
    coreFunction = _coreFunction;
    inputChannel = _inputChannel;
    outputChannel = _outputChannel;
    kernelWeight = _kernelWeight;
    useFft = _useFft;
    growthFunction = _growthFunction;
    mu = _mu;
    sigma = _sigma;

    kernelWidth = 2 * R + 1;

    kernel = preCalculateKernel();

    fft = new FFT(kernel, world[inputChannel], WORLD_DIMENSIONS, true);

    elementWiseConvolution = new ElementWiseConvolution(kernel, world[0], WORLD_DIMENSIONS);
  }

  public float[] convolve() {
    return elementWiseConvolution.convolve();
  }

  /**
   Cette fonction retourne les poids du noyeau de convolution en fonction du paramètre bêta, qui détermine le nombre d'anneaux et leur importance.
   */
  private float[] preCalculateKernel() {
    float[] radius = getPolarRadiusMatrix(); // Matrice où chaque case contient sa distance par rapport au centre.

    float[] Br = new float[radius.length];
    for (int i = 0; i < radius.length; i++) {
      Br[i] = (beta.length) * radius[i];
    }

    float[] kernelShell = new float[radius.length];
    for (int i = 0; i < radius.length; i++) {
      if (radius[i] >= 1) kernelShell[i] = 0;
      else
        kernelShell[i] = beta[floor(Br[i])] * kernelCore(Br[i] % 1, GAUSSIAN_FUNCTION);
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

  /**
   Cette fonction retourne une matrice de même dimensions que le noyau de convolution où chaque cellule contient sa distance euclidienne par rapport au centre.
   */
  private float[] getPolarRadiusMatrix() {
    float dx = 1./R;
    float[] matrix = new float[kernelWidth*kernelWidth];
    for (int x = -R; x <= R; x++)
      for (int y = -R; y <= R; y++)
        matrix[(x + R) * kernelWidth + y + R] = sqrt(x*x + y*y) * dx;

    return matrix;
  }

  public int getWeight() {
    return kernelWeight;
  }

  public int getOutputChannel() {
    return outputChannel;
  }

  public int getGrowthFunction() {
    return growthFunction;
  }

  public float getMu() {
    return mu;
  }

  public float getSigma() {
    return sigma;
  }
}

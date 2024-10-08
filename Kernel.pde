class Kernel {
  private float[] kernel;

  private int R;
  private float[] beta;
  private int coreFunction;
  private int inputchannel; // Indice du canal d'entrée. - Input channel index.
  private int outputchannel; // Indice du canal de sortie. - Output channel index.
  private float kernelWeight;
  private boolean useFft;
  private int growthFunction;
  private float mu;
  private float sigma;

  private int kernelWidth;

  private FFT fft;
  private ElementWiseConvolution elementWiseConvolution;

  private boolean asymetricKernel = true; //Si vrai, le noyau de convolution aura un dégradé appliqué de sorte que les valeurs près du haut ait plus d'importance. - If true, the convolution kernel will have a gradient so the top values are more important.


  /**
   Un noyau de convolution. Dans l'ordre, les paramètres sont:
   int: Le rayon de convolution.
   float[]: Un tableau contenant les hauteurs relatives des pics des anneaux du noyau.
   int: Le type de fonction de noyau. Des constantes sont fournies pour la lisibilité, comme POLYNOMIAL_FUNCTION.
   int: Le type de fonction pour la croissance. Comme le paramètre précédant.
   float: Le centre de la fonction de croissance (moyenne pour une fonction gaussienne).
   float: L'étallement de la fonction de croissance (écart-type pour une fonction gaussienne).
   int: Le canal d'entrée.
   int: Le canal de sortie.
   float: Le poid relatif du noyau sur le canal de sortie.
   boolean: Vrai si on souhaite utiliser fft pour la convolution, faux sinon.
   boolean (facultatif): Vrai si on veut utiliser un noyau asymetrique.
   ---
   A convolution kernel. In order, the parameters are : 
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
  Kernel(int _R, float[] _beta, int _coreFunction, int _growthFunction, float _mu, float _sigma, int _inputchannel, int _outputchannel, float _kernelWeight, boolean _useFft) {
    this(_R, _beta, _coreFunction, _growthFunction, _mu, _sigma, _inputchannel, _outputchannel, _kernelWeight, _useFft, false);
  }
  Kernel(int _R, float[] _beta, int _coreFunction, int _growthFunction, float _mu, float _sigma, int _inputchannel, int _outputchannel, float _kernelWeight, boolean _useFft, boolean _asymetric) {
    R = _R;
    beta = _beta;
    coreFunction = _coreFunction;
    inputchannel = min(_inputchannel, NB_CHANNELS - 1);
    outputchannel = min(_outputchannel, NB_CHANNELS - 1);
    kernelWeight = _kernelWeight;
    useFft = _useFft;
    growthFunction = _growthFunction;
    mu = _mu;
    sigma = _sigma;
    asymetricKernel = _asymetric;

    kernelWidth = 2 * R + 1;

    kernel = preCalculateKernel();

    fft = new FFT(kernel, world[inputchannel], WORLD_DIMENSIONS, isCyclicWorld);

    elementWiseConvolution = new ElementWiseConvolution(kernel, world[inputchannel], WORLD_DIMENSIONS);
  }
  
  /**
    Cela va recalculer les noyaux de convolution à partir des nouveaux paramètres.
    It will recalculate the convolution kernels with the new parameters.
  */
  public void refresh() {
    kernelWidth = 2 * R + 1;
    
    kernel = preCalculateKernel();

    fft = new FFT(kernel, world[inputchannel], WORLD_DIMENSIONS, isCyclicWorld);

    elementWiseConvolution = new ElementWiseConvolution(kernel, world[inputchannel], WORLD_DIMENSIONS);
  }

  public float[] convolve() {
    if (useFft) {
      fft.setImage(world[inputchannel]);
      return fft.convolve();
    }
    return elementWiseConvolution.convolve();
  }

  /**
   Cette fonction retourne les poids du noyau de convolution en fonction du paramètre bêta, qui détermine le nombre d'anneaux et leur importance.
   This function returns the weigth of the convolution kernel according to the beta parameter, that established the number of rings and their importance.
   */
  private float[] preCalculateKernel() {
    float[] radius = getPolarRadiusMatrix(); // Matrice où chaque case contient sa distance par rapport au centre. - Matrix were each box contains its distance to the center.

    float[] Br = new float[radius.length];
    for (int i = 0; i < radius.length; i++) {
      Br[i] = (beta.length) * radius[i];
    }

    float[] kernelShell = new float[radius.length];
    for (int i = 0; i < radius.length; i++) {
      if (radius[i] >= 1) kernelShell[i] = 0;
      else
        kernelShell[i] = beta[floor(Br[i])] * kernelCore(Br[i] % 1, coreFunction);
    }

    //Give values near the top more weight.
    if (asymetricKernel) {
      for (int i = 0; i < kernelWidth; i++) {
        for (int j = 0; j < kernelWidth; j++) {
          kernelShell[i*kernelWidth+j] *= log(j+1)/log(2);
        }
      }
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
   This function returns a matrix of same dimensiosn than the convolution kernel where each cell has its euclidian distance to the center.
   */
  private float[] getPolarRadiusMatrix() {
    float dx = 1./R;
    float[] matrix = new float[kernelWidth*kernelWidth];
    for (int x = -R; x <= R; x++)
      for (int y = -R; y <= R; y++)
        matrix[(x + R) * kernelWidth + y + R] = sqrt(x*x + y*y) * dx;

    return matrix;
  }

  /**
   Le destructeur libère le GPU.
   The destrucor releases the GPU.
   */
  public void finalize() {
    fft.finalize();
    elementWiseConvolution.finalize();
  }

  /** Accesseurs **/
  public float getWeight() {
    return kernelWeight;
  }
  public int getOutputchannel() {
    return outputchannel;
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
  public int getR() {
    return R;
  }
  public float[] getBeta() {
    return beta;
  }
  public int getCoreFunction() {
    return coreFunction;
  }
  public int getinputchannel() {
    return inputchannel;
  }
}

//Guide followed: https://www.codeproject.com/articles/86551/part-1-programming-your-graphics-card-gpu-with-jav

import org.jocl.*;
import java.util.Arrays;

class FFT {
  // Dimensions de travail du GPU.
  private long global_work_size[];
  private long local_work_size[];

  private cl_mem memObjects[] = new cl_mem[2];

  // Paramètres de l'objet.
  // Une matrice 2D dans l'ordre des colonnes dominantes qui contient l'image à convoluer.
  private float[] image;
  // Une matrice 2D dans l'ordre des colonnes dominantes qui contient le noyau de convolution sur lequel une transformation de Fourier a été faite.
  private float[] fourierKernel;
  // Largeur de la matrice sur laquelle on veut faire la convolution.
  private int imageWidth;
  // Hauteur de la matrice sur laquelle on veut faire la convolution.
  private int imageHeight;
  // Dimensions du noyeau de convolution, avant transformation de Fourier.
  private int kernelWidth;
  //Dimension de la matrice sur laquelle les transformation de Fourier auront lieu.
  private int convolutionSize;
  //Détermine le comportement de la convolution aux bordures.
  //Elle est vraie si les bordures sont connectées et fausse si ce qu'il y a au-delà des bordures est nul.
  private boolean circular;

  /**
   Le constructeur prend un noyeau de convolution ainsi que l'image sur laquelle la convolution aura lieu.
   La variable imageWidth correspond à la largeur voulue pour la matrice passée dans le paramètre image.
   La variable circular détermine le comportement de la convolution aux bordures.
   Elle est vraie si les bordures sont connectées et fausse si ce qu'il y a au-delà des bordures est nul.
   */
  FFT(float[] _kernel, float[] _image, int _imageWidth, boolean _circular) {
    // Initialisation des vraiables de l'instance.
    image = _image;
    imageWidth = _imageWidth;
    circular = _circular;
    fourierKernel = preCalculateFourierKernel(_kernel);
  }

  /**
   Cette fonction précalcule un noyau de convolution dans l'espace de Fourier et le retourne.
   */
  public float[] preCalculateFourierKernel(float[] inputKernel) {
    //Pour que la convolution fonctionne, nous devons ajouter des zéros à chaque dimension de sorte que la largeur
    //de la convolution soit la somme des largeurs du noyau et de la grille - 1.
    //Aussi, la grille et le noyau doivent avoir les mêmes dimensions, on ajoute donc des zéros au noyau pour compenser.
    //Finalement, l'implémentation actuelle de fft exige que les largeurs soient des puissances de deux.

    //Détermination des dimensions de la grille. Pour simplifier, nous voulons que le noyau soit carré.
    imageHeight = image.length / imageWidth;
    kernelWidth = (int)sqrt(inputKernel.length);
    if (!circular)
      convolutionSize = max(imageWidth, imageHeight) + kernelWidth - 1;
    else
      convolutionSize = max(imageWidth, imageHeight) + 2*(kernelWidth - 1);

    //On vérifie si les dimensions sont une puissance de deux.
    //Sinon, on change la dimension pour la puissance de deux suivante.
    if (!((convolutionSize & (convolutionSize - 1)) == 0)) {
      convolutionSize = (int)pow(2, (int)(log(convolutionSize)/log(2))+1);
    }

    //Tamponner le noyau de convolution et le convertir pour des nombres complexes
    float[] paddedKernel = new float[convolutionSize*convolutionSize * 2];
    for (int i = 0; i < inputKernel.length; i++) {
      paddedKernel[2*((i / kernelWidth)*convolutionSize + (i % kernelWidth))] = inputKernel[i];
    }

    //Création d'un tableau de sortie pour que le GPU y mette ses résultats.
    //Comme il s'agit de nombres complexes, chaque nombre prend deux fois plus de place dans un tableau.
    float[] GPUOutKernel = new float[convolutionSize * convolutionSize * 2];

    Pointer srcIn = Pointer.to(paddedKernel);
    Pointer srcOut = Pointer.to(GPUOutKernel);

    //Dimensions de travail du GPU.
    global_work_size = new long[]{convolutionSize};
    local_work_size = new long[]{min(32, convolutionSize)};

    //FFT sur les colonnes du noyau.
    //Attribuer la mémoire pour les données d'entrée et de sortie.
    memObjects[0] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_ONLY | CL.CL_MEM_COPY_HOST_PTR,
      Sizeof.cl_float * paddedKernel.length, srcIn, null);
    memObjects[1] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_WRITE,
      Sizeof.cl_float * GPUOutKernel.length, null, null);

    //Définir les arguments pour le noyau.
    CL.clSetKernelArg(fftColumnKernel, 0,
      Sizeof.cl_mem, Pointer.to(memObjects[0]));
    CL.clSetKernelArg(fftColumnKernel, 1,
      Sizeof.cl_mem, Pointer.to(memObjects[1]));

    //Éxecuter le noyau.
    CL.clEnqueueNDRangeKernel(commandQueue, fftColumnKernel, 1, null,
      global_work_size, local_work_size, 0, null, null);

    //Lire les données de sortie.
    CL.clEnqueueReadBuffer(commandQueue, memObjects[1], CL.CL_TRUE, 0,
      Sizeof.cl_float * GPUOutKernel.length, srcOut, 0, null, null);

    //Libérer la mémoire.
    CL.clReleaseMemObject(memObjects[0]);
    CL.clReleaseMemObject(memObjects[1]);

    //FFT sur les rangées du noyau.
    float[] rotatedPaddedKernel = GPUOutKernel.clone();
    srcIn = Pointer.to(rotatedPaddedKernel);

    //Attribuer la mémoire pour les données d'entrée et de sortie.
    memObjects[0] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_ONLY | CL.CL_MEM_COPY_HOST_PTR,
      Sizeof.cl_float * rotatedPaddedKernel.length, srcIn, null);
    memObjects[1] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_WRITE,
      Sizeof.cl_float * GPUOutKernel.length, null, null);

    //Définir les arguments pour le noyau.
    CL.clSetKernelArg(fftRowKernel, 0,
      Sizeof.cl_mem, Pointer.to(memObjects[0]));
    CL.clSetKernelArg(fftRowKernel, 1,
      Sizeof.cl_mem, Pointer.to(memObjects[1]));

    //Éxecuter le noyau.
    CL.clEnqueueNDRangeKernel(commandQueue, fftRowKernel, 1, null,
      global_work_size, local_work_size, 0, null, null);

    //Lire les données de sortie.
    CL.clEnqueueReadBuffer(commandQueue, memObjects[1], CL.CL_TRUE, 0,
      Sizeof.cl_float * GPUOutKernel.length, srcOut, 0, null, null);

    //Libérer la mémoire.
    CL.clReleaseMemObject(memObjects[0]);
    CL.clReleaseMemObject(memObjects[1]);

    return GPUOutKernel;
  }

  /**
   Cette fonction demande au GPU d'effectuer une convolution 2D sur image en utilisant l'algorithme FFT.
   */
  public float[] convolve() {
    //Tamponner l'image et convertir en nombres complexes.
    float[] paddedImage = new float[convolutionSize*convolutionSize * 2];
    for (int i = 0; i < image.length; i++) {
      paddedImage[2*((i / imageHeight)*convolutionSize + (i % imageHeight))] = image[i];
    }
    //Copie de valeurs aux bordures pour un comportement circulaire.
    if (circular) {
      //Copie des valeurs de gauche.
      for (int i = 0; i < kernelWidth - 1; i++)
        for (int j = 0; j < imageHeight; j++) {
          paddedImage[2*((i + imageWidth) * convolutionSize + j)] = image[i * imageHeight + j];
        }
      //Copie des valeurs de droite.
      for (int i = 0; i < kernelWidth - 1; i++)
        for (int j = 0; j < imageHeight; j++) {
          paddedImage[2*((i + convolutionSize - (kernelWidth - 1)) * convolutionSize + j)] = image[(i - (kernelWidth - 1) + imageWidth) * imageHeight + j];
        }
      //Copie des valeurs du haut.
      for (int i = 0; i < kernelWidth - 1; i++)
        for (int j = 0; j < imageWidth; j++) {
          paddedImage[2*(j * convolutionSize + i + imageHeight)] = image[j * imageHeight + i];
        }
      //Copie des valeurs du bas.
      for (int i = 0; i < kernelWidth - 1; i++)
        for (int j = 0; j < imageWidth; j++) {
          paddedImage[2*(j * convolutionSize + i + convolutionSize - (kernelWidth - 1))] = image[j * imageHeight + i - (kernelWidth - 1) + imageWidth];
        }
      //Copie d'un carré dans la diagonnale en bas à droite.
      for (int i = 0; i < kernelWidth - 1; i++)
        for (int j = 0; j < kernelWidth - 1; j++) {
          paddedImage[2*((i + imageWidth) * convolutionSize + j + imageHeight)] = image[i * imageHeight + j];
        }
      //Copie d'un carré dans la diagonnale en haut à gauche.
      for (int i = 0; i < kernelWidth - 1; i++)
        for (int j = 0; j < kernelWidth - 1; j++) {
          paddedImage[2*((i + convolutionSize - (kernelWidth - 1)) * convolutionSize + j + convolutionSize - (kernelWidth - 1))] = image[(i + imageWidth - (kernelWidth - 1)) * imageHeight + j + imageHeight - (kernelWidth - 1)];
        }
      //Copie d'un carré dans la diagonnale en bas à gauche.
      for (int i = 0; i < kernelWidth - 1; i++)
        for (int j = 0; j < kernelWidth - 1; j++) {
          paddedImage[2*((i + convolutionSize - (kernelWidth - 1)) * convolutionSize + j + imageHeight)] = image[(i + imageWidth - (kernelWidth - 1)) * imageHeight + j];
        }
      //Copie d'un carré dans la diagonnale en haut à droite.
      for (int i = 0; i < kernelWidth - 1; i++)
        for (int j = 0; j < kernelWidth - 1; j++) {
          paddedImage[2*((i + imageWidth) * convolutionSize + j + convolutionSize - (kernelWidth - 1))] = image[i * imageHeight + j + imageHeight - (kernelWidth - 1)];
        }
    }


    //Création d'un tableau de sortie pour que le GPU y mette ses résultats.
    //Comme il s'agit de nombres complexes, chaque nombre prend deux fois plus de place dans un tableau.
    float[] GPUOut = new float[convolutionSize * convolutionSize * 2];

    Pointer srcIn = Pointer.to(paddedImage);
    Pointer srcOut = Pointer.to(GPUOut);

    //Dimensions de travail du GPU.
    long global_work_size[] = new long[]{convolutionSize};
    long local_work_size[] = new long[]{min(32, convolutionSize)};

    //FFT sur les colonnes de l'entrée.
    //Allouer les objets de mémoire pour les données d'entrée et de sortie.
    memObjects[0] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_ONLY | CL.CL_MEM_COPY_HOST_PTR,
      Sizeof.cl_float * paddedImage.length, srcIn, null);
    memObjects[1] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_WRITE,
      Sizeof.cl_float * GPUOut.length, null, null);

    //Définir les arguments pour le noyau
    CL.clSetKernelArg(fftColumnKernel, 0,
      Sizeof.cl_mem, Pointer.to(memObjects[0]));
    CL.clSetKernelArg(fftColumnKernel, 1,
      Sizeof.cl_mem, Pointer.to(memObjects[1]));

    //Éxecuter le noyau.
    CL.clEnqueueNDRangeKernel(commandQueue, fftColumnKernel, 1, null,
      global_work_size, local_work_size, 0, null, null);

    //Lire les données de sortie.
    CL.clEnqueueReadBuffer(commandQueue, memObjects[1], CL.CL_TRUE, 0,
      Sizeof.cl_float * GPUOut.length, srcOut, 0, null, null);

    //Libération de la mémoire.
    CL.clReleaseMemObject(memObjects[0]);
    CL.clReleaseMemObject(memObjects[1]);

    //FFT sur les rangées de l'entrée.

    //Échange des pointeurs de tableaux.
    float[] tempArray = paddedImage;
    paddedImage = GPUOut;
    GPUOut = tempArray;

    srcIn = Pointer.to(paddedImage);
    srcOut = Pointer.to(GPUOut);

    //Allouer les objets de mémoire pour les données d'entrée et de sortie.
    memObjects[0] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_ONLY | CL.CL_MEM_COPY_HOST_PTR,
      Sizeof.cl_float * paddedImage.length, srcIn, null);
    memObjects[1] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_WRITE,
      Sizeof.cl_float * GPUOut.length, null, null);

    //Définir les arguments pour le noyau
    CL.clSetKernelArg(fftRowKernel, 0,
      Sizeof.cl_mem, Pointer.to(memObjects[0]));
    CL.clSetKernelArg(fftRowKernel, 1,
      Sizeof.cl_mem, Pointer.to(memObjects[1]));

    //Éxecuter le noyau.
    CL.clEnqueueNDRangeKernel(commandQueue, fftRowKernel, 1, null,
      global_work_size, local_work_size, 0, null, null);

    //Lire les données de sortie.
    CL.clEnqueueReadBuffer(commandQueue, memObjects[1], CL.CL_TRUE, 0,
      Sizeof.cl_float * GPUOut.length, srcOut, 0, null, null);

    //Libération de la mémoire.
    CL.clReleaseMemObject(memObjects[0]);
    CL.clReleaseMemObject(memObjects[1]);


    //Multiplier GPUOut par fourierKernel en tant que nombres complexes.
    for (int i = 0; i < GPUOut.length / 2; i++) {
      GPUOut[2*i] *= fourierKernel[2*i];
      GPUOut[2*i + 1] += fourierKernel[2*i + 1];
    }

    //FFT inverse sur les rangées.
    //Échange des pointeurs de tableaux.
    tempArray = paddedImage;
    paddedImage = GPUOut;
    GPUOut = tempArray;

    srcIn = Pointer.to(paddedImage);
    srcOut = Pointer.to(GPUOut);

    //Allouer les objets de mémoire pour les données d'entrée et de sortie.
    memObjects[0] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_ONLY | CL.CL_MEM_COPY_HOST_PTR,
      Sizeof.cl_float * paddedImage.length, srcIn, null);
    memObjects[1] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_WRITE,
      Sizeof.cl_float * GPUOut.length, null, null);

    //Définir les arguments pour le noyau
    CL.clSetKernelArg(ifftRowKernel, 0,
      Sizeof.cl_mem, Pointer.to(memObjects[0]));
    CL.clSetKernelArg(ifftRowKernel, 1,
      Sizeof.cl_mem, Pointer.to(memObjects[1]));

    //Éxecuter le noyau.
    CL.clEnqueueNDRangeKernel(commandQueue, ifftRowKernel, 1, null,
      global_work_size, local_work_size, 0, null, null);

    //Lire les données de sortie.
    CL.clEnqueueReadBuffer(commandQueue, memObjects[1], CL.CL_TRUE, 0,
      Sizeof.cl_float * GPUOut.length, srcOut, 0, null, null);

    //Libération de la mémoire.
    CL.clReleaseMemObject(memObjects[0]);
    CL.clReleaseMemObject(memObjects[1]);

    //Mise à l'échelle par 1/n.
    for (int i = 0; i < paddedImage.length/2; i++) {
      GPUOut[2*i] /= (float)convolutionSize;
    }

    //IFFT sur les colonnes.
    //Échange des pointeurs de tableaux.
    tempArray = paddedImage;
    paddedImage = GPUOut;
    GPUOut = tempArray;

    srcIn = Pointer.to(paddedImage);
    srcOut = Pointer.to(GPUOut);

    //Allouer les objets de mémoire pour les données d'entrée et de sortie.
    memObjects[0] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_ONLY | CL.CL_MEM_COPY_HOST_PTR,
      Sizeof.cl_float * paddedImage.length, srcIn, null);
    memObjects[1] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_WRITE,
      Sizeof.cl_float * GPUOut.length, null, null);

    //Définir les arguments pour le noyau.
    CL.clSetKernelArg(ifftColumnKernel, 0,
      Sizeof.cl_mem, Pointer.to(memObjects[0]));
    CL.clSetKernelArg(ifftColumnKernel, 1,
      Sizeof.cl_mem, Pointer.to(memObjects[1]));

    //Éxecuter le noyau.
    CL.clEnqueueNDRangeKernel(commandQueue, ifftColumnKernel, 1, null,
      global_work_size, local_work_size, 0, null, null);

    //Lire les données de sortie.
    CL.clEnqueueReadBuffer(commandQueue, memObjects[1], CL.CL_TRUE, 0,
      Sizeof.cl_float * GPUOut.length, srcOut, 0, null, null);

    //Libération de la mémoire.
    CL.clReleaseMemObject(memObjects[0]);
    CL.clReleaseMemObject(memObjects[1]);

    //Mise à l'échelle par 1/n.
    for (int i = 0; i < paddedImage.length/2; i++) {
      GPUOut[2*i] /= (float)convolutionSize;
    }

    //On convertit GPUout pour n'avoir que des nombres réelles et les mêmes dimensions que la grille initiale.
    float[] convolutionOutput = new float[image.length];
    for (int i = 0; i < convolutionOutput.length; i++) {
      convolutionOutput[i] = GPUOut[2*((i/imageHeight + kernelWidth/2) * convolutionSize + i%imageHeight + kernelWidth/2)];
    }

    image = convolutionOutput;
    return image;
  }

  public float[] getImage() {
    return image;
  }

  public void setImage(float[] _image) {
    image = _image;
  }

  /**
   Libère le GPU.
   */
  public void finalize() {
  }
}

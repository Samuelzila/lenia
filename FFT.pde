//Guide followed: https://www.codeproject.com/articles/86551/part-1-programming-your-graphics-card-gpu-with-jav

import org.jocl.*;
import java.util.Arrays;

class FFT {
  // Dimensions de travail du GPU.
  // Work dimensions of the GPU.
  private long global_work_size[];
  private long local_work_size[];

  private cl_mem memObjects[] = new cl_mem[2];

  // Paramètres de l'objet.
  // Une matrice 2D dans l'ordre des colonnes dominantes qui contient l'image à convoluer.
  // Object's parameters
  // A 2D matrix in the order of dominant columns that contains the image to convolve.
  private float[] image;
  // Une matrice 2D dans l'ordre des colonnes dominantes qui contient le noyau de convolution sur lequel une transformation de Fourier a été faite.
  // A 2D matrix in the order of dominant columns that contains the convolution kernel on wich a Fourier transform have been made.
  private float[] fourierKernel;
  // Largeur de la matrice sur laquelle on veut faire la convolution.
  // The width of the matrix on wich we want to do the convolution.
  private int imageWidth;
  // Hauteur de la matrice sur laquelle on veut faire la convolution.
  // The higth of th matrix on wich we want to do the convolution.
  private int imageHeight;
  // Dimensions du noyau de convolution, avant transformation de Fourier.
  // The dimensions of the convolution kernel, before the Fourier transform.
  private int kernelWidth;
  //Dimension de la matrice sur laquelle les transformations de Fourier auront lieu.
  //Dimension of the matrix on which the Fourier transforms will happen.
  private int convolutionSize;
  //Détermine le comportement de la convolution aux bordures.
  //Elle est vraie si les bordures sont connectées et fausse si ce qu'il y a au-delà des bordures est nul.
  //Establishes the behavior of the convolution at the borders.
  //It is true if the borders are connected and false if what is past the border is null.
  private boolean circular;

  /**
   Le constructeur prend un noyeau de convolution ainsi que l'image sur laquelle la convolution aura lieu.
   La variable imageWidth correspond à la largeur voulue pour la matrice passée dans le paramètre image.
   La variable circular détermine le comportement de la convolution aux bordures.
   Elle est vraie si les bordures sont connectées et fausse si ce qu'il y a au-delà des bordures est nul.
   ---
   The constructor takes a convolution kernel and the image on which the convolution will happen.
   The variable "imageWidth" is the wanted width for the matrix passed in the image parameter.
   The variable "circular" establishes the behavior of the convolution at the borders.
   //It is true if the borders are connected and false if what is past the border is null.
   */
  FFT(float[] _kernel, float[] _image, int _imageWidth, boolean _circular) {
    // Initialisation des vraiables de l'instance.
    // Initialisation of the instance variables.
    image = _image;
    imageWidth = _imageWidth;
    circular = _circular;
    fourierKernel = preCalculateFourierKernel(_kernel);
  }

  /**
   Cette fonction précalcule un noyau de convolution dans l'espace de Fourier et le retourne.
   This function precalculates a convolution kernel in the Fourier space and returns it.
   */
  public float[] preCalculateFourierKernel(float[] inputKernel) {
    //Pour que la convolution fonctionne, nous devons ajouter des zéros à chaque dimension de sorte que la largeur
    //de la convolution soit la somme des largeurs du noyau et de la grille - 1.
    //Aussi, la grille et le noyau doivent avoir les mêmes dimensions, on ajoute donc des zéros au noyau pour compenser.
    //Finalement, l'implémentation actuelle de fft exige que les largeurs soient des puissances de deux.
    //For the convolution to succeed, we have to add zeros in each dimensions so the width of the convolution
    //is the sum of the withds of the kernel and of the grid - 1.
    //Alse, the grid and the kernel should have the same dimensions, we add zeros to compensate.
    //Finally, the present implementation of fft needs the widths and heigths to be powers of two.

    //Détermination des dimensions de la grille. Pour simplifier, nous voulons que le noyau soit carré.
    //Establishes the dimensions of the grid. To simplify, we want the kernel to be squared.
    imageHeight = image.length / imageWidth;
    kernelWidth = (int)sqrt(inputKernel.length);
    if (!circular)
      convolutionSize = max(imageWidth, imageHeight) + kernelWidth - 1;
    else
      convolutionSize = max(imageWidth, imageHeight) + 2*(kernelWidth - 1);

    //On vérifie si les dimensions sont une puissance de deux.
    //Sinon, on change la dimension pour la puissance de deux suivante.
    //We verify if the dimensions are a power of two.
    //If not, we change the dimensions for the next power of two.
    if (!((convolutionSize & (convolutionSize - 1)) == 0)) {
      convolutionSize = (int)pow(2, (int)(log(convolutionSize)/log(2))+1);
    }

    //Tamponner le noyau de convolution et le convertir pour des nombres complexes
    //Pad the convolution kernel and convert it for complex numbers.
    float[] paddedKernel = new float[convolutionSize*convolutionSize * 2];
    for (int i = 0; i < inputKernel.length; i++) {
      paddedKernel[2*((i / kernelWidth)*convolutionSize + (i % kernelWidth))] = inputKernel[i];
    }

    //Création d'un tableau de sortie pour que le GPU y mette ses résultats.
    //Comme il s'agit de nombres complexes, chaque nombre prend deux fois plus de place dans un tableau.
    //Creation of a output array so that GPU puts its results.
    // As they are complex nombers each number take two times more place in the array.
    float[] GPUOutKernel = new float[convolutionSize * convolutionSize * 2];

    Pointer srcIn = Pointer.to(paddedKernel);
    Pointer srcOut = Pointer.to(GPUOutKernel);

    //Dimensions de travail du GPU.
    //Work dimensions of the GPU.
    global_work_size = new long[]{convolutionSize};
    local_work_size = new long[]{min(32, convolutionSize)};

    //FFT sur les colonnes du noyau.
    //Attribuer la mémoire pour les données d'entrée et de sortie.
    //FFT on the kernel's columns.
    //Attributes the memory for the input and output data.
    memObjects[0] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_ONLY | CL.CL_MEM_COPY_HOST_PTR,
      Sizeof.cl_float * paddedKernel.length, srcIn, null);
    memObjects[1] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_WRITE,
      Sizeof.cl_float * GPUOutKernel.length, null, null);

    //Définir les arguments pour le noyau.
    //Establishes the arguments for the kernel.
    CL.clSetKernelArg(fftColumnKernel, 0,
      Sizeof.cl_mem, Pointer.to(memObjects[0]));
    CL.clSetKernelArg(fftColumnKernel, 1,
      Sizeof.cl_mem, Pointer.to(memObjects[1]));

    //Éxecuter le noyau.
    //Executes the kernel.
    CL.clEnqueueNDRangeKernel(commandQueue, fftColumnKernel, 1, null,
      global_work_size, local_work_size, 0, null, null);

    //Lire les données de sortie.
    //Reads the output data.
    CL.clEnqueueReadBuffer(commandQueue, memObjects[1], CL.CL_TRUE, 0,
      Sizeof.cl_float * GPUOutKernel.length, srcOut, 0, null, null);

    //Libérer la mémoire.
    //Releases the memory
    CL.clReleaseMemObject(memObjects[0]);
    CL.clReleaseMemObject(memObjects[1]);

    //FFT sur les rangées du noyau.
    //FFT on the kernel's rows.
    float[] rotatedPaddedKernel = GPUOutKernel.clone();
    srcIn = Pointer.to(rotatedPaddedKernel);

    //Attribuer la mémoire pour les données d'entrée et de sortie.
    //Attributes the memory for the input and output data.
    memObjects[0] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_ONLY | CL.CL_MEM_COPY_HOST_PTR,
      Sizeof.cl_float * rotatedPaddedKernel.length, srcIn, null);
    memObjects[1] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_WRITE,
      Sizeof.cl_float * GPUOutKernel.length, null, null);

    //Définir les arguments pour le noyau.
    //Establishes the arguments for the kernel.
    CL.clSetKernelArg(fftRowKernel, 0,
      Sizeof.cl_mem, Pointer.to(memObjects[0]));
    CL.clSetKernelArg(fftRowKernel, 1,
      Sizeof.cl_mem, Pointer.to(memObjects[1]));

    //Éxecuter le noyau.
    //Executes the kernel.
    CL.clEnqueueNDRangeKernel(commandQueue, fftRowKernel, 1, null,
      global_work_size, local_work_size, 0, null, null);

    //Lire les données de sortie.
    //Reads the output data
    CL.clEnqueueReadBuffer(commandQueue, memObjects[1], CL.CL_TRUE, 0,
      Sizeof.cl_float * GPUOutKernel.length, srcOut, 0, null, null);

    //Libérer la mémoire.
    //Releases the memory
    CL.clReleaseMemObject(memObjects[0]);
    CL.clReleaseMemObject(memObjects[1]);

    return GPUOutKernel;
  }

  /**
   Cette fonction demande au GPU d'effectuer une convolution 2D sur image en utilisant l'algorithme FFT.
   The function requests to the GPU for a 2D convolution on image while using the FFT algorithm.
   */
  public float[] convolve() {
    //Tamponner l'image et convertir en nombres complexes.
    //Pads the image and converts in complex numbers.
    float[] paddedImage = new float[convolutionSize*convolutionSize * 2];
    for (int i = 0; i < image.length; i++) {
      paddedImage[2*((i / imageHeight)*convolutionSize + (i % imageHeight))] = image[i];
    }
    //Copie de valeurs aux bordures pour un comportement circulaire.
    //Copes the values at the border for a circular behavior
    if (circular) {
      //Copie des valeurs de gauche.
      //Copies the left values
      for (int i = 0; i < kernelWidth - 1; i++)
        for (int j = 0; j < imageHeight; j++) {
          paddedImage[2*((i + imageWidth) * convolutionSize + j)] = image[i * imageHeight + j];
        }
      //Copie des valeurs de droite.
      //Copies the rigth values
      for (int i = 0; i < kernelWidth - 1; i++)
        for (int j = 0; j < imageHeight; j++) {
          paddedImage[2*((i + convolutionSize - (kernelWidth - 1)) * convolutionSize + j)] = image[(i - (kernelWidth - 1) + imageWidth) * imageHeight + j];
        }
      //Copie des valeurs du haut.
      //Copies the top values
      for (int i = 0; i < kernelWidth - 1; i++)
        for (int j = 0; j < imageWidth; j++) {
          paddedImage[2*(j * convolutionSize + i + imageHeight)] = image[j * imageHeight + i];
        }
      //Copie des valeurs du bas.
      //Copies the bottom values
      for (int i = 0; i < kernelWidth - 1; i++)
        for (int j = 0; j < imageWidth; j++) {
          paddedImage[2*(j * convolutionSize + i + convolutionSize - (kernelWidth - 1))] = image[j * imageHeight + i - (kernelWidth - 1) + imageWidth];
        }
      //Copie d'un carré dans la diagonnale en bas à droite.
      //Copies a sqaure in the bottom right diagonal.
      for (int i = 0; i < kernelWidth - 1; i++)
        for (int j = 0; j < kernelWidth - 1; j++) {
          paddedImage[2*((i + imageWidth) * convolutionSize + j + imageHeight)] = image[i * imageHeight + j];
        }
      //Copie d'un carré dans la diagonnale en haut à gauche.
      //Copies a square in the top left diagonal.
      for (int i = 0; i < kernelWidth - 1; i++)
        for (int j = 0; j < kernelWidth - 1; j++) {
          paddedImage[2*((i + convolutionSize - (kernelWidth - 1)) * convolutionSize + j + convolutionSize - (kernelWidth - 1))] = image[(i + imageWidth - (kernelWidth - 1)) * imageHeight + j + imageHeight - (kernelWidth - 1)];
        }
      //Copie d'un carré dans la diagonnale en bas à gauche.
      //Copies a square in the bottom left diagnonal.
      for (int i = 0; i < kernelWidth - 1; i++)
        for (int j = 0; j < kernelWidth - 1; j++) {
          paddedImage[2*((i + convolutionSize - (kernelWidth - 1)) * convolutionSize + j + imageHeight)] = image[(i + imageWidth - (kernelWidth - 1)) * imageHeight + j];
        }
      //Copie d'un carré dans la diagonnale en haut à droite.
      //Copies a square in the up rigth diagonal.
      for (int i = 0; i < kernelWidth - 1; i++)
        for (int j = 0; j < kernelWidth - 1; j++) {
          paddedImage[2*((i + imageWidth) * convolutionSize + j + convolutionSize - (kernelWidth - 1))] = image[i * imageHeight + j + imageHeight - (kernelWidth - 1)];
        }
    }


    //Création d'un tableau de sortie pour que le GPU y mette ses résultats.
    //Comme il s'agit de nombres complexes, chaque nombre prend deux fois plus de place dans un tableau.
    //Creates an output array for the GPU to put its results in.
    //As they are complex nombers each number take two times more place in the array.
    float[] GPUOut = new float[convolutionSize * convolutionSize * 2];

    Pointer srcIn = Pointer.to(paddedImage);
    Pointer srcOut = Pointer.to(GPUOut);

    //Dimensions de travail du GPU.
    //Work dimensiosn of the GPU.
    long global_work_size[] = new long[]{convolutionSize};
    long local_work_size[] = new long[]{min(32, convolutionSize)};

    //FFT sur les colonnes de l'entrée.
    //Allouer les objets de mémoire pour les données d'entrée et de sortie.
    //FFT on the input columns.
    //Allocates the memory objects for the input and output values.
    memObjects[0] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_ONLY | CL.CL_MEM_COPY_HOST_PTR,
      Sizeof.cl_float * paddedImage.length, srcIn, null);
    memObjects[1] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_WRITE,
      Sizeof.cl_float * GPUOut.length, null, null);

    //Définir les arguments pour le noyau
    //Establishes the arguments for the kernel.
    CL.clSetKernelArg(fftColumnKernel, 0,
      Sizeof.cl_mem, Pointer.to(memObjects[0]));
    CL.clSetKernelArg(fftColumnKernel, 1,
      Sizeof.cl_mem, Pointer.to(memObjects[1]));

    //Éxecuter le noyau.
    //Executes the kernel.
    CL.clEnqueueNDRangeKernel(commandQueue, fftColumnKernel, 1, null,
      global_work_size, local_work_size, 0, null, null);

    //Lire les données de sortie.
    //Reads the output values.
    CL.clEnqueueReadBuffer(commandQueue, memObjects[1], CL.CL_TRUE, 0,
      Sizeof.cl_float * GPUOut.length, srcOut, 0, null, null);

    //Libération de la mémoire.
    //Releases the memory
    CL.clReleaseMemObject(memObjects[0]);
    CL.clReleaseMemObject(memObjects[1]);

    //FFT sur les rangées de l'entrée.
    //FFT on the input rows

    //Échange des pointeurs de tableaux.
    //Exchange of the array pointers
    float[] tempArray = paddedImage;
    paddedImage = GPUOut;
    GPUOut = tempArray;

    srcIn = Pointer.to(paddedImage);
    srcOut = Pointer.to(GPUOut);

    //Allouer les objets de mémoire pour les données d'entrée et de sortie.
    //Allocates the memory objects for the input and output data.
    memObjects[0] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_ONLY | CL.CL_MEM_COPY_HOST_PTR,
      Sizeof.cl_float * paddedImage.length, srcIn, null);
    memObjects[1] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_WRITE,
      Sizeof.cl_float * GPUOut.length, null, null);

    //Définir les arguments pour le noya
    //Establishes to arguments for the kernel.
    CL.clSetKernelArg(fftRowKernel, 0,
      Sizeof.cl_mem, Pointer.to(memObjects[0]));
    CL.clSetKernelArg(fftRowKernel, 1,
      Sizeof.cl_mem, Pointer.to(memObjects[1]));

    //Éxecuter le noyau.
    //Executes the kernel.
    CL.clEnqueueNDRangeKernel(commandQueue, fftRowKernel, 1, null,
      global_work_size, local_work_size, 0, null, null);

    //Lire les données de sortie.
    //Reads the output data.
    CL.clEnqueueReadBuffer(commandQueue, memObjects[1], CL.CL_TRUE, 0,
      Sizeof.cl_float * GPUOut.length, srcOut, 0, null, null);

    //Libération de la mémoire.
    //Liberation of the memory
    CL.clReleaseMemObject(memObjects[0]);
    CL.clReleaseMemObject(memObjects[1]);


    //Multiplier GPUOut par fourierKernel en tant que nombres complexes.
    //Multiplies GPUout by fourielKernel as complex numbers.
    for (int i = 0; i < GPUOut.length / 2; i++) {
      GPUOut[2*i] *= fourierKernel[2*i];
      GPUOut[2*i + 1] += fourierKernel[2*i + 1];
    }

    //FFT inverse sur les rangées.
    //Échange des pointeurs de tableaux.
    //Reverse FFT on rows.
    //Exchange of array pointers.
    tempArray = paddedImage;
    paddedImage = GPUOut;
    GPUOut = tempArray;

    srcIn = Pointer.to(paddedImage);
    srcOut = Pointer.to(GPUOut);

    //Allouer les objets de mémoire pour les données d'entrée et de sortie.
    //Allocates the memory objects for the input and output data
    memObjects[0] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_ONLY | CL.CL_MEM_COPY_HOST_PTR,
      Sizeof.cl_float * paddedImage.length, srcIn, null);
    memObjects[1] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_WRITE,
      Sizeof.cl_float * GPUOut.length, null, null);

    //Définir les arguments pour le noyau
    //Establishes the arguments for the kernel
    CL.clSetKernelArg(ifftRowKernel, 0,
      Sizeof.cl_mem, Pointer.to(memObjects[0]));
    CL.clSetKernelArg(ifftRowKernel, 1,
      Sizeof.cl_mem, Pointer.to(memObjects[1]));

    //Éxecuter le noyau.
    //Executes the kernel
    CL.clEnqueueNDRangeKernel(commandQueue, ifftRowKernel, 1, null,
      global_work_size, local_work_size, 0, null, null);

    //Lire les données de sortie.
    //Reads the output data
    CL.clEnqueueReadBuffer(commandQueue, memObjects[1], CL.CL_TRUE, 0,
      Sizeof.cl_float * GPUOut.length, srcOut, 0, null, null);

    //Libération de la mémoire.
    //Memory release
    CL.clReleaseMemObject(memObjects[0]);
    CL.clReleaseMemObject(memObjects[1]);

    //Mise à l'échelle par 1/n.
    //Scaling by 1/n.
    for (int i = 0; i < paddedImage.length/2; i++) {
      GPUOut[2*i] /= (float)convolutionSize;
    }

    //IFFT sur les colonnes.
    //Échange des pointeurs de tableaux.
    //IFFT on the columns
    //Exchange on array pointers
    tempArray = paddedImage;
    paddedImage = GPUOut;
    GPUOut = tempArray;

    srcIn = Pointer.to(paddedImage);
    srcOut = Pointer.to(GPUOut);

    //Allouer les objets de mémoire pour les données d'entrée et de sortie.
    //Allocates memory objects for the input and output data
    memObjects[0] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_ONLY | CL.CL_MEM_COPY_HOST_PTR,
      Sizeof.cl_float * paddedImage.length, srcIn, null);
    memObjects[1] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_WRITE,
      Sizeof.cl_float * GPUOut.length, null, null);

    //Définir les arguments pour le noyau.
    //Establishes the arguments for the kernel.
    CL.clSetKernelArg(ifftColumnKernel, 0,
      Sizeof.cl_mem, Pointer.to(memObjects[0]));
    CL.clSetKernelArg(ifftColumnKernel, 1,
      Sizeof.cl_mem, Pointer.to(memObjects[1]));

    //Éxecuter le noyau.
    //Executes the kernel
    CL.clEnqueueNDRangeKernel(commandQueue, ifftColumnKernel, 1, null,
      global_work_size, local_work_size, 0, null, null);

    //Lire les données de sortie.
    //Reads the output data.
    CL.clEnqueueReadBuffer(commandQueue, memObjects[1], CL.CL_TRUE, 0,
      Sizeof.cl_float * GPUOut.length, srcOut, 0, null, null);

    //Libération de la mémoire.
    //Memory release.
    CL.clReleaseMemObject(memObjects[0]);
    CL.clReleaseMemObject(memObjects[1]);

    //Mise à l'échelle par 1/n.
    //Scaling by 1/n.
    for (int i = 0; i < paddedImage.length/2; i++) {
      GPUOut[2*i] /= (float)convolutionSize;
    }

    //On convertit GPUout pour n'avoir que des nombres réelles et les mêmes dimensions que la grille initiale.
    //We convert GPUout so we only have real numbers and the same dimensions than the initial grid.
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
   Releases the GPU.
   */
  public void finalize() {
  }
}

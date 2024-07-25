//Guide followed: https://www.codeproject.com/articles/86551/part-1-programming-your-graphics-card-gpu-with-jav //<>//

import org.jocl.*;
import java.util.Arrays;

class FFT {
  // Variables relatives au GPU.
  private cl_platform_id platforms[] = new cl_platform_id[1];
  private cl_context_properties contextProperties;
  private cl_context context;
  private cl_command_queue commandQueue;
  private cl_mem memObjects[] = new cl_mem[2];
  private cl_program program;

  // Variables liées aux noyaux OpenCL.
  private cl_kernel fftColumnKernel;
  private cl_kernel fftRowKernel;
  private cl_kernel ifftColumnKernel;
  private cl_kernel ifftRowKernel;

  // Dimensions de travail du GPU.
  private long global_work_size[];
  private long local_work_size[];

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
   Ce programme OpenCL contient des noyaux pour faire des transformées de Fourier rapides en parallèle sur une matrice donnée.
   Il supporte des transformations directes et inverses sur les colonnes et les rangées.
   On assume une matrice dans l'ordre des colonnes dominantes.
   */
  private String programKernel =
  /**
   FFT sur les colonnes.
   */
    "__kernel void "+
    "fftColumn(            __global const float *in,"+
    "                __global float *out)"+
    "{"+

    "    int n = get_global_size(0);"+
    //L'identifiant global correspond à la colonne en cours.
    "    int gid = get_global_id(0);"+
    //Le décalage de la colonne dans la mémoire.
    "    int offset = gid * n;"+

    //Remplir les cases du tableau avec son indice.
    "      for (int i = 0; i < n; i++) {"+
    "        out[2*(i + offset)] = i;"+
    "        out[2*(i + offset) + 1] = 0;"+
    "      }"+
    //Remplir le tableau avec les indices interchangés pour la transformée de Fourier.
    "      for (int i = 2; i <= n; i*=2) {"+
    "        for (int j = i / 2; j < i; j++) {"+
    "          out[2*(j + offset)] = out[2*((j + offset) - i / 2)] + n / i;"+
    "        }"+
    "      }"+

    //Remplacer les indices par leur valeur correspondante.
    "    for (int k = 0; k < n; k++) {"+
    "      int index = (int)out[2*(k + offset)];"+
    "      out[2 * (k + offset)] = in[2*(index + offset)];"+
    "      out[2 * (k + offset) + 1] = in[2*(index + offset) + 1];"+
    "    }"+

    //La transformation de Fourier.
    "    for (int s = 1 ; s <= (int)log2((float)n) ; s++) {"+
    //m est la taille du tableau que nous aurions obtenu par la méthode récursive habituelle.
    "      int m = pow(2,(float)s);"+
    //Omega est l'angle entre chaque racine de l'unité.
    "      float omega = (-2*"+PI+")/m;"+

    "      for (int k = 0; k < n; k+=m) {"+
    //w est l'angle de la racine de l'unité actuelle. Il commence à 0 ce qui correspond à 1 + 0i.
    "        float w = 0;"+
    "        for (int j = 0; j < m/2 ; j++) {"+
    //t et u sont les termes de l'équation. m, a, r et i signifient module, argument, partie réelle et partie imaginaire.
    "          float ta = w + out[2*(k + j + m/2 + offset) + 1];"+
    "          float tm = out[2*(k + j + m/2 + offset)];"+
    "          float ua = out[2*(k + j + offset) + 1];"+
    "          float um = out[2*(k + j + offset)];"+

    "          float tr = tm*cos(ta);"+
    "          float ti = tm*sin(ta);"+
    "          float ur = um*cos(ua);"+
    "          float ui = um*sin(ua);"+

    "          out[2*(k + j + offset)] = sqrt(pow(tr + ur,2) + pow(ti + ui, 2));"+
    "          out[2*(k + j + offset) + 1] = atan2(ti + ui, tr + ur);"+

    "          out[2*(k + j + m/2 + offset)] = sqrt(pow(ur - tr, 2) + pow(ui - ti, 2));"+
    "          out[2*(k + j + m/2 + offset) + 1] = atan2(ui - ti, ur - tr);"+

    "          w += omega;"+
    "        }"+
    "      }"+
    "    }"+
    "}"+

  /**
   FFT sur les rangées.
   */
    "__kernel void "+
    "fftRow(            __global const float *in,"+
    "                __global float *out)"+
    "{"+

    "    int n = get_global_size(0);"+
    //L'identifiant global correspond à la colonne en cours.
    "    int gid = get_global_id(0);"+

    //Remplir les cases du tableau avec son indice.
    "      for (int i = 0; i < n; i++) {"+
    "        out[2*(i * n + gid)] = i;"+
    "        out[2*(i * n + gid) + 1] = 0;"+
    "      }"+

    //Remplir le tableau avec les indices interchangés pour la transformée de Fourier.
    "      for (int i = 2; i <= n; i*=2) {"+
    "        for (int j = i / 2; j < i; j++) {"+
    "          out[2*(j * n + gid)] = out[2*((j - i / 2) * n + gid)] + n / i;"+
    "        }"+
    "      }"+

    //Remplacer les indices par leur valeur correspondante.
    "    for (int k = 0; k < n; k++) {"+
    "      int index = (int)out[2*(k * n + gid)];"+
    "      out[2 * (k * n + gid)] = in[2*(index * n + gid)];"+
    "      out[2 * (k * n + gid) + 1] = in[2*(index * n + gid) + 1];"+
    "    }"+

    //La transformation de Fourier.
    "    for (int s = 1 ; s <= (int)log2((float)n) ; s++) {"+
    //m est la taille du tableau que nous aurions obtenu par la méthode récursive habituelle.
    "      int m = pow(2,(float)s);"+
    //Omega est l'angle entre chaque racine de l'unité.
    "      float omega = (-2*"+PI+")/m;"+

    "      for (int k = 0; k < n; k+=m) {"+
    //w est l'angle de la racine de l'unité actuelle. Il commence à 0 ce qui correspond à 1 + 0i.
    "        float w = 0;"+
    "        for (int j = 0; j < m/2 ; j++) {"+
    //t et u sont les termes de l'équation. m, a, r et i signifient module, argument, partie réelle et partie imaginaire.
    "          float ta = w + out[2*((k + j + m/2) * n + gid) + 1];"+
    "          float tm = out[2*((k + j + m/2) * n + gid)];"+
    "          float ua = out[2*((k + j) * n + gid) + 1];"+
    "          float um = out[2*((k + j) * n + gid)];"+

    "          float tr = tm*cos(ta);"+
    "          float ti = tm*sin(ta);"+
    "          float ur = um*cos(ua);"+
    "          float ui = um*sin(ua);"+

    "          out[2*((k + j) * n + gid)] = sqrt(pow(tr + ur,2) + pow(ti + ui, 2));"+
    "          out[2*((k + j) * n + gid) + 1] = atan2(ti + ui, tr + ur);"+

    "          out[2*((k + j + m/2) * n + gid)] = sqrt(pow(ur - tr, 2) + pow(ui - ti, 2));"+
    "          out[2*((k + j + m/2) * n + gid) + 1] = atan2(ui - ti, ur - tr);"+

    "          w += omega;"+
    "        }"+
    "      }"+
    "    }"+
    "}"+

  /**
   FFT inverse sur les colonnes. N'inclue pas le facteur de mise à l'échelle 1 / n.
   */
    "__kernel void "+
    "ifftColumn(            __global const float *in,"+
    "                __global float *out)"+
    "{"+

    "     int n = get_global_size(0);"+
    //L'identifiant global correspond à la colonne en cours.
    "    int gid = get_global_id(0);"+
    //Le décalage de la colonne dans la mémoire.
    "    int offset = gid * n;"+

    //Remplir les cases du tableau avec son indice.
    "      for (int i = 0; i < n; i++) {"+
    "        out[2*(i + offset)] = i;"+
    "        out[2*(i + offset) + 1] = 0;"+
    "      }"+
    //Remplir le tableau avec les indices interchangés pour la transformée de Fourier.
    "      for (int i = 2; i <= n; i*=2) {"+
    "        for (int j = i / 2; j < i; j++) {"+
    "          out[2*(j + offset)] = out[2*((j + offset) - i / 2)] + n / i;"+
    "        }"+
    "      }"+

    //Remplacer les indices par leur valeur correspondante.
    "    for (int k = 0; k < n; k++) {"+
    "      int index = (int)out[2*(k + offset)];"+
    "      out[2 * (k + offset)] = in[2*(index + offset)];"+
    "      out[2 * (k + offset) + 1] = in[2*(index + offset) + 1];"+
    "    }"+

    //La transformation de Fourier.
    "    for (int s = 1 ; s <= (int)log2((float)n) ; s++) {"+
    //m est la taille du tableau que nous aurions obtenu par la méthode récursive habituelle.
    "      int m = pow(2,(float)s);"+
    //Omega est l'angle entre chaque racine de l'unité.
    "      float omega = (2*"+PI+")/m;"+

    "      for (int k = 0; k < n; k+=m) {"+
    //w est l'angle de la racine de l'unité actuelle. Il commence à 0 ce qui correspond à 1 + 0i.
    "        float w = 0;"+
    "        for (int j = 0; j < m/2 ; j++) {"+
    //t et u sont les termes de l'équation. m, a, r et i signifient module, argument, partie réelle et partie imaginaire.
    "          float ta = w + out[2*(k + j + m/2 + offset) + 1];"+
    "          float tm = out[2*(k + j + m/2 + offset)];"+
    "          float ua = out[2*(k + j + offset) + 1];"+
    "          float um = out[2*(k + j + offset)];"+

    "          float tr = tm*cos(ta);"+
    "          float ti = tm*sin(ta);"+
    "          float ur = um*cos(ua);"+
    "          float ui = um*sin(ua);"+

    "          out[2*(k + j + offset)] = sqrt(pow(tr + ur,2) + pow(ti + ui, 2));"+
    "          out[2*(k + j + offset) + 1] = atan2(ti + ui, tr + ur);"+

    "          out[2*(k + j + m/2 + offset)] = sqrt(pow(ur - tr, 2) + pow(ui - ti, 2));"+
    "          out[2*(k + j + m/2 + offset) + 1] = atan2(ui - ti, ur - tr);"+

    "          w += omega;"+
    "        }"+
    "      }"+
    "    }"+

    "}"+

  /**
   FFT inverse sur les rangées. N'inclue pas le facteur de mise à l'échelle 1 / n.
   */
    "__kernel void "+
    "ifftRow(            __global const float *in,"+
    "                __global float *out)"+
    "{"+

    "    int n = get_global_size(0);"+
    //L'identifiant global correspond à la colonne en cours.
    "    int gid = get_global_id(0);"+

    //Remplir les cases du tableau avec son indice.
    "      for (int i = 0; i < n; i++) {"+
    "        out[2*(i * n + gid)] = i;"+
    "        out[2*(i * n + gid) + 1] = 0;"+
    "      }"+
    //Remplir le tableau avec les indices interchangés pour la transformée de Fourier.
    "      for (int i = 2; i <= n; i*=2) {"+
    "        for (int j = i / 2; j < i; j++) {"+
    "          out[2*(j * n + gid)] = out[2*((j - i / 2) * n + gid)] + n / i;"+
    "        }"+
    "      }"+

    //Remplacer les indices par leur valeur correspondante.
    "    for (int k = 0; k < n; k++) {"+
    "      int index = (int)out[2*(k * n + gid)];"+
    "      out[2 * (k * n + gid)] = in[2*(index * n + gid)];"+
    "      out[2 * (k * n + gid) + 1] = in[2*(index * n + gid) + 1];"+
    "    }"+

    //La transformation de Fourier.
    "    for (int s = 1 ; s <= (int)log2((float)n) ; s++) {"+
    //m est la taille du tableau que nous aurions obtenu par la méthode récursive habituelle.
    "      int m = pow(2,(float)s);"+
    //Omega est l'angle entre chaque racine de l'unité.
    "      float omega = (2*"+PI+")/m;"+

    "      for (int k = 0; k < n; k+=m) {"+
    //w est l'angle de la racine de l'unité actuelle. Il commence à 0 ce qui correspond à 1 + 0i.
    "        float w = 0;"+
    "        for (int j = 0; j < m/2 ; j++) {"+
    //t et u sont les termes de l'équation. m, a, r et i signifient module, argument, partie réelle et partie imaginaire.
    "          float ta = w + out[2*((k + j + m/2) * n + gid) + 1];"+
    "          float tm = out[2*((k + j + m/2) * n + gid)];"+
    "          float ua = out[2*((k + j) * n + gid) + 1];"+
    "          float um = out[2*((k + j) * n + gid)];"+

    "          float tr = tm*cos(ta);"+
    "          float ti = tm*sin(ta);"+
    "          float ur = um*cos(ua);"+
    "          float ui = um*sin(ua);"+

    "          out[2*((k + j) * n + gid)] = sqrt(pow(tr + ur,2) + pow(ti + ui, 2));"+
    "          out[2*((k + j) * n + gid) + 1] = atan2(ti + ui, tr + ur);"+

    "          out[2*((k + j + m/2) * n + gid)] = sqrt(pow(ur - tr, 2) + pow(ui - ti, 2));"+
    "          out[2*((k + j + m/2) * n + gid) + 1] = atan2(ui - ti, ur - tr);"+

    "          w += omega;"+
    "        }"+
    "      }"+
    "    }"+
    "}";

  /**
   Le constructeur prend un noyeau de convolution ainsi que l'image sur laquelle la convolution aura lieu.
   La variable imageWidth correspond à la largeur voulue pour la matrice passée dans le paramètre image.
   La variable circular détermine le comportement de la convolution aux bordures.
   Elle est vraie si les bordures sont connectées et fausse si ce qu'il y a au-delà des bordures est nul.
   */
  FFT(float[] _kernel, float[] _image, int _imageWidth, boolean _circular) {
    {  // Initialisation du GPU.
      long numBytes[] = new long[1];

      // Obtention des IDs de plateformes et initialisation des propriétés de contexte.
      CL.clGetPlatformIDs(platforms.length, platforms, null);
      contextProperties = new cl_context_properties();
      contextProperties.addProperty(CL.CL_CONTEXT_PLATFORM, platforms[0]);

      // Création d'un contexte OpenCL sur un GPU.
      context = CL.clCreateContextFromType(
        contextProperties, CL.CL_DEVICE_TYPE_GPU, null, null, null);

      if (context == null)
      {
        // Si le contexte n'a pas pu être créé sur un GPU,
        // On essaie de le créer sur un CPU.
        context = CL.clCreateContextFromType(
          contextProperties, CL.CL_DEVICE_TYPE_CPU, null, null, null);

        if (context == null)
        {
          System.out.println("Unable to create a context");
          return;
        }
      }

      // Activer les exceptions et, par la suite, omettre les contrôles d'erreur.
      CL.setExceptionsEnabled(true);

      // Obtenir la liste des GPUs associés au contexte.
      CL.clGetContextInfo(context, CL.CL_CONTEXT_DEVICES, 0, null, numBytes);

      // Obtenir l'identifiant cl_device_id du premier appareil
      int numDevices = (int) numBytes[0] / Sizeof.cl_device_id;
      cl_device_id devices[] = new cl_device_id[numDevices];
      CL.clGetContextInfo(context, CL.CL_CONTEXT_DEVICES, numBytes[0],
        Pointer.to(devices), null);

      // Créer une file d'attente de commandes
      commandQueue = CL.clCreateCommandQueueWithProperties(context, devices[0], null, null);

      // Créer le programme à partir du code source
      program = CL.clCreateProgramWithSource(context,
        1, new String[]{ programKernel }, null, null);

      // Compiller le programme.
      CL.clBuildProgram(program, 0, null, "-cl-mad-enable", null, null);

      // Création des noyeaux OpenCL.
      fftColumnKernel = CL.clCreateKernel(program, "fftColumn", null);
      fftRowKernel = CL.clCreateKernel(program, "fftRow", null);
      ifftColumnKernel = CL.clCreateKernel(program, "ifftColumn", null);
      ifftRowKernel = CL.clCreateKernel(program, "ifftRow", null);
    }

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
    // Release kernel, program, and memory objects
    CL.clReleaseKernel(fftColumnKernel);
    CL.clReleaseKernel(fftRowKernel);
    CL.clReleaseKernel(ifftColumnKernel);
    CL.clReleaseKernel(ifftRowKernel);
    CL.clReleaseProgram(program);
    CL.clReleaseCommandQueue(commandQueue);
    CL.clReleaseContext(context);
  }
}

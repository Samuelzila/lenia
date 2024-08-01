//Guide followed: https://www.codeproject.com/articles/86551/part-1-programming-your-graphics-card-gpu-with-jav

import org.jocl.*;
import java.util.Arrays;

//Variables relatives au GPU
private cl_platform_id platforms[] = new cl_platform_id[1];
private cl_context_properties contextProperties;
private cl_context context;
private cl_command_queue commandQueue;
private cl_program program;
private cl_program fftProgram;
private cl_kernel clKernel;

// Variables liées aux noyaux OpenCL ifft.
private cl_kernel fftColumnKernel;
private cl_kernel fftRowKernel;
private cl_kernel ifftColumnKernel;
private cl_kernel ifftRowKernel;

void GPUInit() {
  //TODO: Changer le noyau openCL pour accepter un rayon variable.
  int R = 13*8;

  String programKernel = "__kernel void "+
    "countNeighbours(__global const float *in,"+
    "                __global float *out,"+
    "                __global const float *convolutionKernel,"+
    "                const uint R)"+
    "{"+
"printf("%d",R)"+
    "    int id = get_global_id(0);"+

    "    out[id] = 0;"+
    "    for (int i = -R; i <= R; i++) {"+
    "      for(int j = -R; j <= R; j++) {"+
    "          int x = ((id / "+WORLD_DIMENSIONS+") + i + "+WORLD_DIMENSIONS+") % "+WORLD_DIMENSIONS+";"+
    "          int y = ((id % "+WORLD_DIMENSIONS+") + j + "+WORLD_DIMENSIONS+") % "+WORLD_DIMENSIONS+";"+

    "          out[id] += in[x*"+WORLD_DIMENSIONS+"+y]*convolutionKernel[(i+R)*(R*2+1)+j+R];"+
    "      }"+
    "    }"+
    "}";

  /**
   Ce programme OpenCL contient des noyaux pour faire des transformées de Fourier rapides en parallèle sur une matrice donnée.
   Il supporte des transformations directes et inverses sur les colonnes et les rangées.
   On assume une matrice dans l'ordre des colonnes dominantes.
   */
  String fftProgramKernel =
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


  // Création du noyeau OpenCL.
  clKernel = CL.clCreateKernel(program, "countNeighbours", null);

  // Créer le programme à partir du code source pour FFT
  fftProgram = CL.clCreateProgramWithSource(context,
    1, new String[]{ fftProgramKernel }, null, null);

  // Compiller le programme.
  CL.clBuildProgram(fftProgram, 0, null, "-cl-mad-enable", null, null);

  // Création des noyeaux OpenCL.
  fftColumnKernel = CL.clCreateKernel(fftProgram, "fftColumn", null);
  fftRowKernel = CL.clCreateKernel(fftProgram, "fftRow", null);
  ifftColumnKernel = CL.clCreateKernel(fftProgram, "ifftColumn", null);
  ifftRowKernel = CL.clCreateKernel(fftProgram, "ifftRow", null);
}

class ElementWiseConvolution {
  // Le nombre de cellules dans la grille.
  private int nbCells = WORLD_DIMENSIONS*WORLD_DIMENSIONS;

  private cl_mem memObjects[] = new cl_mem[3];

  // Pointeurs vers diverses valeurs qui seront utilisées par le GPU.
  private Pointer srcIn;
  private Pointer srcOut;
  private Pointer convolutionKernelPtr;

  // Dimensions de travail du GPU.
  private long global_work_size[] = new long[]{nbCells};
  private long local_work_size[] = new long[]{32};

  private float[] kernel;
  private float[] image;
  private int imageWidth;

  public ElementWiseConvolution(float[] _kernel, float[] _image, int _imageWidth) {
    kernel = _kernel;
    image = _image;
    imageWidth = _imageWidth;
  }

  /**
   Cette fonction fait une convolution de kernel sur world.
   */
  public float[] convolve() {
    float[] output = new float[image.length];

    // Initialisation des pointeurs.
    srcIn = Pointer.to(image);
    srcOut = Pointer.to(output);
    convolutionKernelPtr = Pointer.to(kernel);

    // Attribuer les objets de mémoire pour les données d'entrée et de sortie
    memObjects[0] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_ONLY | CL.CL_MEM_COPY_HOST_PTR,
      Sizeof.cl_float * nbCells, srcIn, null);
    memObjects[1] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_WRITE,
      Sizeof.cl_float * nbCells, null, null);
    memObjects[2] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_ONLY | CL.CL_MEM_COPY_HOST_PTR,
      Sizeof.cl_float * nbCells, convolutionKernelPtr, null);

    // Définir les arguments pour le noyau OpenCL
    CL.clSetKernelArg(clKernel, 0,
      Sizeof.cl_mem, Pointer.to(memObjects[0]));
    CL.clSetKernelArg(clKernel, 1,
      Sizeof.cl_mem, Pointer.to(memObjects[1]));
    CL.clSetKernelArg(clKernel, 2,
      Sizeof.cl_mem, Pointer.to(memObjects[2]));
    CL.clSetKernelArg(clKernel, 3,
      Sizeof.cl_uint, Pointer.to(new int[]{(int)(sqrt(kernel.length)-1)/2}));

    // Éxecution du noyau OpenCL.
    CL.clEnqueueNDRangeKernel(commandQueue, clKernel, 1, null,
      global_work_size, local_work_size, 0, null, null);

    // Lecture des donées de sortie.
    CL.clEnqueueReadBuffer(commandQueue, memObjects[1], CL.CL_TRUE, 0,
      nbCells * Sizeof.cl_float, srcOut, 0, null, null);

    // Libération de la mémoire.
    CL.clReleaseMemObject(memObjects[0]);
    CL.clReleaseMemObject(memObjects[1]);
    CL.clReleaseMemObject(memObjects[2]);

    return output;
  }

  /**
   Cette fonction libère le GPU initialisé via GPUInit().
   */
  public void finalize() {
  }
}

void GPURelease() {
  // Release kernel, program, and memory objects
  CL.clReleaseKernel(clKernel);
  CL.clReleaseProgram(program);
  CL.clReleaseCommandQueue(commandQueue);
  CL.clReleaseContext(context);

  CL.clReleaseKernel(fftColumnKernel);
  CL.clReleaseKernel(fftRowKernel);
  CL.clReleaseKernel(ifftColumnKernel);
  CL.clReleaseKernel(ifftRowKernel);
  CL.clReleaseProgram(fftProgram);
}

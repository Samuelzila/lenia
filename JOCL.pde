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

private cl_kernel clCyclicConvolutionKernel;
private cl_kernel clConvolutionKernel;

// Variables liées aux noyaux OpenCL ifft.
private cl_kernel fftColumnKernel;
private cl_kernel fftRowKernel;
private cl_kernel ifftColumnKernel;
private cl_kernel ifftRowKernel;

void GPUInit() {
  String convolutionProgramKernel = "__kernel void "+
    "cyclicConvolution(__global const float *in,"+
    "                __global float *out,"+
    "                __global const float *convolutionKernel,"+
    "                const int R)"+
    "{"+
    "    int id = get_global_id(0);"+

    "    out[id] = 0;"+
    "    for (int i = -R; i <= R; i++) {"+
    "      for(int j = -R; j <= R; j++) {"+
    "          int x = ((id / "+WORLD_DIMENSIONS+") + i + "+WORLD_DIMENSIONS+") % "+WORLD_DIMENSIONS+";"+
    "          int y = ((id % "+WORLD_DIMENSIONS+") + j + "+WORLD_DIMENSIONS+") % "+WORLD_DIMENSIONS+";"+

    "          out[id] += in[x*"+WORLD_DIMENSIONS+"+y]*convolutionKernel[(i+R)*(R*2+1)+j+R];"+
    "      }"+
    "    }"+
    "}"+
    
    "__kernel void "+
    "convolution(__global const float *in,"+
    "                __global float *out,"+
    "                __global const float *convolutionKernel,"+
    "                const int R)"+
    "{"+
    "    int id = get_global_id(0);"+

    "    out[id] = 0;"+
    "    for (int i = -R; i <= R; i++) {"+
    "      for(int j = -R; j <= R; j++) {"+
    "          int x = ((id / "+WORLD_DIMENSIONS+") + i);"+
    "          int y = ((id % "+WORLD_DIMENSIONS+") + j);"+
    
    "          if (x >= 0 && x < "+WORLD_DIMENSIONS+" && y >= 0 && y < "+WORLD_DIMENSIONS+") {"+    
    "              out[id] += in[x*"+WORLD_DIMENSIONS+"+y]*convolutionKernel[(i+R)*(R*2+1)+j+R];"+
    "          }"+
    "      }"+
    "    }"+
    "}";

  /**
   Ce programme OpenCL contient des noyaux pour faire des transformées de Fourier rapides en parallèle sur une matrice donnée.
   Il supporte des transformations directes et inverses sur les colonnes et les rangées.
   On assume une matrice dans l'ordre des colonnes dominantes.
   ---
   This OpenCL program contains kernel meant to do fast Fourrier transforms in parralel on a given matrix.
   It supports direct and inverse transformations on columns and rows.
   We assume a matrix in the order of dominant columns.
   */
  String fftProgramKernel =
  /**
   FFT sur les colonnes.
   FFT on the columns
   */
    "__kernel void "+
    "fftColumn(            __global const float *in,"+
    "                __global float *out)"+
    "{"+

    "    int n = get_global_size(0);"+
    //L'identifiant global correspond à la colonne en cours.
    //The global indentifier is the present column.
    "    int gid = get_global_id(0);"+
    //Le décalage de la colonne dans la mémoire.
    //The column gap in the memory
    "    int offset = gid * n;"+

    //Remplir les cases du tableau avec son indice.
    //Fill every array box with its index
    "      for (int i = 0; i < n; i++) {"+
    "        out[2*(i + offset)] = i;"+
    "        out[2*(i + offset) + 1] = 0;"+
    "      }"+
    //Remplir le tableau avec les indices interchangés pour la transformée de Fourier.
    //Fill the array with the switched indexes for the Fourier transform.
    "      for (int i = 2; i <= n; i*=2) {"+
    "        for (int j = i / 2; j < i; j++) {"+
    "          out[2*(j + offset)] = out[2*((j + offset) - i / 2)] + n / i;"+
    "        }"+
    "      }"+

    //Remplacer les indices par leur valeur correspondante.
    //Replaces the indexes by their corresponding value.
    "    for (int k = 0; k < n; k++) {"+
    "      int index = (int)out[2*(k + offset)];"+
    "      out[2 * (k + offset)] = in[2*(index + offset)];"+
    "      out[2 * (k + offset) + 1] = in[2*(index + offset) + 1];"+
    "    }"+

    //La transformation de Fourier.
    //The Fourier transform.
    "    for (int s = 1 ; s <= (int)log2((float)n) ; s++) {"+
    //m est la taille du tableau que nous aurions obtenu par la méthode récursive habituelle.
    //m is the size of the array that we would have by the usual recursive method.
    "      int m = pow(2,(float)s);"+
    //Omega est l'angle entre chaque racine de l'unité.
    //Omega is the angle between each root of the unity.
    "      float omega = (-2*"+PI+")/m;"+

    "      for (int k = 0; k < n; k+=m) {"+
    //w est l'angle de la racine de l'unité actuelle. Il commence à 0 ce qui correspond à 1 + 0i.
    //w is the angle of the root of the present unit. It starts at 0 which corresponds to 1+ + 0i.
    "        float w = 0;"+
    "        for (int j = 0; j < m/2 ; j++) {"+
    //t et u sont les termes de l'équation. m, a, r et i signifient module, argument, partie réelle et partie imaginaire.
    //t and u are the equation's terms. m, a, r and i mean module, argument, real part and imaginary part.
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
   FFT on the rows
   */
    "__kernel void "+
    "fftRow(            __global const float *in,"+
    "                __global float *out)"+
    "{"+

    "    int n = get_global_size(0);"+
    //L'identifiant global correspond à la colonne en cours.
    //The global indentifer is the present column
    "    int gid = get_global_id(0);"+

    //Remplir les cases du tableau avec son indice.
    //Fills all the array's boxes with its index.
    "      for (int i = 0; i < n; i++) {"+
    "        out[2*(i * n + gid)] = i;"+
    "        out[2*(i * n + gid) + 1] = 0;"+
    "      }"+

    //Remplir le tableau avec les indices interchangés pour la transformée de Fourier.
    //Fill the array with the switched indexes for the Fourier tranform.
    "      for (int i = 2; i <= n; i*=2) {"+
    "        for (int j = i / 2; j < i; j++) {"+
    "          out[2*(j * n + gid)] = out[2*((j - i / 2) * n + gid)] + n / i;"+
    "        }"+
    "      }"+

    //Remplacer les indices par leur valeur correspondante.
    //Replaces the indexes by their corresponding values.
    "    for (int k = 0; k < n; k++) {"+
    "      int index = (int)out[2*(k * n + gid)];"+
    "      out[2 * (k * n + gid)] = in[2*(index * n + gid)];"+
    "      out[2 * (k * n + gid) + 1] = in[2*(index * n + gid) + 1];"+
    "    }"+

    //La transformation de Fourier.
    //The fourier tranform
    "    for (int s = 1 ; s <= (int)log2((float)n) ; s++) {"+
    //m est la taille du tableau que nous aurions obtenu par la méthode récursive habituelle.
    //m is the size of the array that we would had obtained by the usual recursive method.
    "      int m = pow(2,(float)s);"+
    //Omega est l'angle entre chaque racine de l'unité.
    //Omega is the angle between each unit root.
    "      float omega = (-2*"+PI+")/m;"+

    "      for (int k = 0; k < n; k+=m) {"+
    //w est l'angle de la racine de l'unité actuelle. Il commence à 0 ce qui correspond à 1 + 0i.
    //w is the angle of the pressent unity'S root. It starts à 0 which corresponds to 1 + 0i.
    "        float w = 0;"+
    "        for (int j = 0; j < m/2 ; j++) {"+
    //t et u sont les termes de l'équation. m, a, r et i signifient module, argument, partie réelle et partie imaginaire.
    //t and u are the terms of the equation. m, a, r and i mean module, argument, real part and imaginary part.
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
   Inverse FFT on the columns. Does not include the scaling factor 1/n.
   */
    "__kernel void "+
    "ifftColumn(            __global const float *in,"+
    "                __global float *out)"+
    "{"+

    "     int n = get_global_size(0);"+
    //L'identifiant global correspond à la colonne en cours.
    //The global identifier is the present column.
    "    int gid = get_global_id(0);"+
    //Le décalage de la colonne dans la mémoire.
    //The gap of the column in the memory
    "    int offset = gid * n;"+

    //Remplir les cases du tableau avec son indice.
    //Fills all the array's boxes with its index.
    "      for (int i = 0; i < n; i++) {"+
    "        out[2*(i + offset)] = i;"+
    "        out[2*(i + offset) + 1] = 0;"+
    "      }"+
    //Remplir le tableau avec les indices interchangés pour la transformée de Fourier.
    //Fills the array with the switched indexes for the Fourier tranform.
    "      for (int i = 2; i <= n; i*=2) {"+
    "        for (int j = i / 2; j < i; j++) {"+
    "          out[2*(j + offset)] = out[2*((j + offset) - i / 2)] + n / i;"+
    "        }"+
    "      }"+

    //Remplacer les indices par leur valeur correspondante.
    //Replaces the indexes by their corresponding value.
    "    for (int k = 0; k < n; k++) {"+
    "      int index = (int)out[2*(k + offset)];"+
    "      out[2 * (k + offset)] = in[2*(index + offset)];"+
    "      out[2 * (k + offset) + 1] = in[2*(index + offset) + 1];"+
    "    }"+

    //La transformation de Fourier.
    //The Fourier transform.
    "    for (int s = 1 ; s <= (int)log2((float)n) ; s++) {"+
    //m est la taille du tableau que nous aurions obtenu par la méthode récursive habituelle.
    //m is the size of the array that we would had obtined by the usual recursive method.
    "      int m = pow(2,(float)s);"+
    //Omega est l'angle entre chaque racine de l'unité.
    //Omega is the angle between each unit's root.
    "      float omega = (2*"+PI+")/m;"+

    "      for (int k = 0; k < n; k+=m) {"+
    //w est l'angle de la racine de l'unité actuelle. Il commence à 0 ce qui correspond à 1 + 0i.
    //w est the angle of the present unity's root. It starts at 0 which coresponds to 1 + 0i.
    "        float w = 0;"+
    "        for (int j = 0; j < m/2 ; j++) {"+
    //t et u sont les termes de l'équation. m, a, r et i signifient module, argument, partie réelle et partie imaginaire.
    //t and u are the terms of the equation. m, a, r and i mean module, argument, real part and imaginary part.
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
   Inverse FFT on the row. Does not include the scaling factor 1/n.
   */
    "__kernel void "+
    "ifftRow(            __global const float *in,"+
    "                __global float *out)"+
    "{"+

    "    int n = get_global_size(0);"+
    //L'identifiant global correspond à la colonne en cours.
    //The global identifier is the present column.
    "    int gid = get_global_id(0);"+

    //Remplir les cases du tableau avec son indice.
    //Fills all the array's boxes with its index.
    
    "      for (int i = 0; i < n; i++) {"+
    "        out[2*(i * n + gid)] = i;"+
    "        out[2*(i * n + gid) + 1] = 0;"+
    "      }"+
    //Remplir le tableau avec les indices interchangés pour la transformée de Fourier.
    //Fills the array with the switched indexes for the Fourier tranform.
    "      for (int i = 2; i <= n; i*=2) {"+
    "        for (int j = i / 2; j < i; j++) {"+
    "          out[2*(j * n + gid)] = out[2*((j - i / 2) * n + gid)] + n / i;"+
    "        }"+
    "      }"+

    //Remplacer les indices par leur valeur correspondante.
    //Replaces the indexes by their corresponding value.
    "    for (int k = 0; k < n; k++) {"+
    "      int index = (int)out[2*(k * n + gid)];"+
    "      out[2 * (k * n + gid)] = in[2*(index * n + gid)];"+
    "      out[2 * (k * n + gid) + 1] = in[2*(index * n + gid) + 1];"+
    "    }"+

    //La transformation de Fourier.
    //The Fourier tranform
    "    for (int s = 1 ; s <= (int)log2((float)n) ; s++) {"+
    //m est la taille du tableau que nous aurions obtenu par la méthode récursive habituelle.
    //m is the size of the array that we would have by the usual recursive method.
    "      int m = pow(2,(float)s);"+
    //Omega est l'angle entre chaque racine de l'unité.
    //Omega is the angle between each unit's root.
    "      float omega = (2*"+PI+")/m;"+

    "      for (int k = 0; k < n; k+=m) {"+
    //w est l'angle de la racine de l'unité actuelle. Il commence à 0 ce qui correspond à 1 + 0i.
    //w is the angle of the present unit's root. It starts at 0 which coresponds to 1 + 0i.
    "        float w = 0;"+
    "        for (int j = 0; j < m/2 ; j++) {"+
    //t et u sont les termes de l'équation. m, a, r et i signifient module, argument, partie réelle et partie imaginaire.
    //t and u are the equation's terms. m, a, r and i mean module, argument, real part and imaginary part.
    
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
  // Obention of the IDs of platforms and initialisation of context property.
  CL.clGetPlatformIDs(platforms.length, platforms, null);
  contextProperties = new cl_context_properties();
  contextProperties.addProperty(CL.CL_CONTEXT_PLATFORM, platforms[0]);

  // Création d'un contexte OpenCL sur un GPU.
  // Creation of a context OpenCl on a GPU.
  context = CL.clCreateContextFromType(
    contextProperties, CL.CL_DEVICE_TYPE_GPU, null, null, null);

  if (context == null)
  {
    // Si le contexte n'a pas pu être créé sur un GPU,
    // On essaie de le créer sur un CPU.
    //If the context has not been created on a GPU,
    //We try to create one on a CPU.
    context = CL.clCreateContextFromType(
      contextProperties, CL.CL_DEVICE_TYPE_CPU, null, null, null);

    if (context == null)
    {
      System.out.println("Unable to create a context");
      return;
    }
  }

  // Activer les exceptions et, par la suite, omettre les contrôles d'erreur.
  // Actavates the excepltions and then omit the error controls.
  CL.setExceptionsEnabled(true);

  // Obtenir la liste des GPUs associés au contexte.
  // Obtains the list of associated to context GPUs.
  CL.clGetContextInfo(context, CL.CL_CONTEXT_DEVICES, 0, null, numBytes);

  // Obtenir l'identifiant cl_device_id du premier appareil
  // Obtains the indentifier cl_device_id of the first device.
  int numDevices = (int) numBytes[0] / Sizeof.cl_device_id;
  cl_device_id devices[] = new cl_device_id[numDevices];
  CL.clGetContextInfo(context, CL.CL_CONTEXT_DEVICES, numBytes[0],
    Pointer.to(devices), null);

  // Créer une file d'attente de commandes
  // Creates a command queue
  commandQueue = CL.clCreateCommandQueueWithProperties(context, devices[0], null, null);

  // Créer le programme à partir du code source
  // Creates the program form the source code.
  program = CL.clCreateProgramWithSource(context,
    1, new String[]{ convolutionProgramKernel }, null, null);

  // Compiler le programme.
  // Complies the program
  CL.clBuildProgram(program, 0, null, "-cl-mad-enable", null, null);


  // Création du noyau OpenCL.
  // Creation of the OpenCl kernel.
  clCyclicConvolutionKernel = CL.clCreateKernel(program, "cyclicConvolution", null);
  clConvolutionKernel = CL.clCreateKernel(program, "convolution", null);

  // Créer le programme à partir du code source pour FFT
  // Creates the program form source sode for FFT
  fftProgram = CL.clCreateProgramWithSource(context,
    1, new String[]{ fftProgramKernel }, null, null);

  // Compiler le programme.
  // Complies the program.
  CL.clBuildProgram(fftProgram, 0, null, "-cl-mad-enable", null, null);

  // Création des noyaux OpenCL.
  // Creates the OpenCL kernels.
  fftColumnKernel = CL.clCreateKernel(fftProgram, "fftColumn", null);
  fftRowKernel = CL.clCreateKernel(fftProgram, "fftRow", null);
  ifftColumnKernel = CL.clCreateKernel(fftProgram, "ifftColumn", null);
  ifftRowKernel = CL.clCreateKernel(fftProgram, "ifftRow", null);
}

void GPURelease() {
  // Release kernel, program, and memory objects
  CL.clReleaseKernel(clCyclicConvolutionKernel);
  CL.clReleaseKernel(clConvolutionKernel);
  CL.clReleaseProgram(program);
  CL.clReleaseCommandQueue(commandQueue);
  CL.clReleaseContext(context);

  CL.clReleaseKernel(fftColumnKernel);
  CL.clReleaseKernel(fftRowKernel);
  CL.clReleaseKernel(ifftColumnKernel);
  CL.clReleaseKernel(ifftRowKernel);
  CL.clReleaseProgram(fftProgram);
}

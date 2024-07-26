//Guide followed: https://www.codeproject.com/articles/86551/part-1-programming-your-graphics-card-gpu-with-jav

import org.jocl.*;
import java.util.Arrays;

// Le nombre de cellules dans la grille.
int nbCells = WORLD_DIMENSIONS*WORLD_DIMENSIONS;

// Pointeurs vers diverses valeurs qui seront utilisées par le GPU.
Pointer srcIn;
Pointer srcOut;
Pointer convolutionKernelPtr;

cl_platform_id platforms[] = new cl_platform_id[1];
cl_context_properties contextProperties;
cl_context context;
cl_command_queue commandQueue;
cl_mem memObjects[] = new cl_mem[3];
cl_program program;
cl_kernel clKernel;

// Dimensions de travail du GPU.
long global_work_size[] = new long[]{nbCells};
//long global_work_size[] = new long[]{544};
long local_work_size[] = new long[]{32};

/**
 Ce noyeau OpenCL s'occupe de faire une convolution de convolutionKernel sur in.
 */
private String programKernel =
  "__kernel void "+
  "countNeighbours(__global const float *in,"+
  "                __global float *out,"+
  "                __global const float *convolutionKernel)"+
  "{"+

  "    int id = get_global_id(0);"+

  "    out[id] = 0;"+
  "    for (int i = -"+R+"; i <= "+R+"; i++) {"+
  "      for(int j = -"+R+"; j <= "+R+"; j++) {"+
  "          int row = id / "+WORLD_DIMENSIONS+";"+
  "          int offsetY = row * "+WORLD_DIMENSIONS+" + (id + i + "+WORLD_DIMENSIONS+") % "+WORLD_DIMENSIONS+";"+
  "          int totalOffset = (offsetY + j * "+WORLD_DIMENSIONS+" + "+nbCells+") % "+nbCells+";"+

  "          out[id] += in[totalOffset]*convolutionKernel[(i+"+R+")*("+R+"*2+1)+j+"+R+"];"+
  "      }"+
  "    }"+
  "}";

/**
 Préparation du GPU.
 */
void gpuInit() {
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
}

/**
 Cette fonction fait une convolution de kernel sur world.
 */
public void convolve() {

  // Initialisation des pointeurs.
  srcIn = Pointer.to(world);
  srcOut = Pointer.to(potential);
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
}

/**
 Cette fonction libère le GPU initialisé via GPUInit().
 */
void gpuRelease() {
  // Release kernel, program, and memory objects
  CL.clReleaseKernel(clKernel);
  CL.clReleaseProgram(program);
  CL.clReleaseCommandQueue(commandQueue);
  CL.clReleaseContext(context);
}

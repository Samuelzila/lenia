class ElementWiseConvolution {
  // Le nombre de cellules dans la grille.
  //The number of cells in the grid
  private int nbCells = WORLD_DIMENSIONS*WORLD_DIMENSIONS;

  private cl_mem memObjects[] = new cl_mem[3];

  // Pointeurs vers diverses valeurs qui seront utilisées par le GPU.
  // Pointers on diverse values that will be used by the GPU.
  private Pointer srcIn;
  private Pointer srcOut;
  private Pointer convolutionKernelPtr;

  // Dimensions de travail du GPU.
  //Work dimensions of the GPU.
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
   This function makes a kernel convolution on world.
   */
  public float[] convolve() {
    float[] output = new float[image.length];

    // Initialisation des pointeurs.
    // Initialisation of the pointers.
    srcIn = Pointer.to(image);
    srcOut = Pointer.to(output);
    convolutionKernelPtr = Pointer.to(kernel);

    // Attribuer les objets de mémoire pour les données d'entrée et de sortie.
    // Attributes the memory objects for the input and output data.
    memObjects[0] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_ONLY | CL.CL_MEM_COPY_HOST_PTR,
      Sizeof.cl_float * nbCells, srcIn, null);
    memObjects[1] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_WRITE,
      Sizeof.cl_float * nbCells, null, null);
    memObjects[2] = CL.clCreateBuffer(context,
      CL.CL_MEM_READ_ONLY | CL.CL_MEM_COPY_HOST_PTR,
      Sizeof.cl_float * nbCells, convolutionKernelPtr, null);
      
    cl_kernel usedClKernel = isCyclicWorld ? clCyclicConvolutionKernel : clConvolutionKernel;

    // Définir les arguments pour le noyau OpenCL
    // Defines the arguments for the OpenCl kernel.
    CL.clSetKernelArg(usedClKernel, 0,
      Sizeof.cl_mem, Pointer.to(memObjects[0]));
    CL.clSetKernelArg(usedClKernel, 1,
      Sizeof.cl_mem, Pointer.to(memObjects[1]));
    CL.clSetKernelArg(usedClKernel, 2,
      Sizeof.cl_mem, Pointer.to(memObjects[2]));
    CL.clSetKernelArg(usedClKernel, 3,
      Sizeof.cl_int, Pointer.to(new int[]{(int)(sqrt(kernel.length)-1)/2}));

    // Éxecution du noyau OpenCL.
    //Execution of the OpenCl kernel.
      CL.clEnqueueNDRangeKernel(commandQueue, usedClKernel, 1, null,
        global_work_size, local_work_size, 0, null, null);

    // Lecture des donées de sortie.
    CL.clEnqueueReadBuffer(commandQueue, memObjects[1], CL.CL_TRUE, 0,
      nbCells * Sizeof.cl_float, srcOut, 0, null, null);

    // Libération de la mémoire.
    // Memory release
    CL.clReleaseMemObject(memObjects[0]);
    CL.clReleaseMemObject(memObjects[1]);
    CL.clReleaseMemObject(memObjects[2]);

    return output;
  }

  /**
   Cette fonction libère le GPU initialisé via GPUInit().
   This function releases the GPU that was initialised via GPUInit().
   */
  public void finalize() {
  }
}

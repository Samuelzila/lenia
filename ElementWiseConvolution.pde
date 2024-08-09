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
      
    cl_kernel usedClKernel = isCyclicWorld ? clCyclicConvolutionKernel : clConvolutionKernel;

    // Définir les arguments pour le noyau OpenCL
    CL.clSetKernelArg(usedClKernel, 0,
      Sizeof.cl_mem, Pointer.to(memObjects[0]));
    CL.clSetKernelArg(usedClKernel, 1,
      Sizeof.cl_mem, Pointer.to(memObjects[1]));
    CL.clSetKernelArg(usedClKernel, 2,
      Sizeof.cl_mem, Pointer.to(memObjects[2]));
    CL.clSetKernelArg(usedClKernel, 3,
      Sizeof.cl_int, Pointer.to(new int[]{(int)(sqrt(kernel.length)-1)/2}));

    // Éxecution du noyau OpenCL.
      CL.clEnqueueNDRangeKernel(commandQueue, usedClKernel, 1, null,
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

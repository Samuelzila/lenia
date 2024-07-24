//Guide followed: https://www.codeproject.com/articles/86551/part-1-programming-your-graphics-card-gpu-with-jav

import org.jocl.*;
import java.util.Arrays;

int nbCells = WORLD_DIMENSIONS*WORLD_DIMENSIONS;

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

// Set the work-item dimensions
long global_work_size[] = new long[]{nbCells};
long local_work_size[] = new long[]{32};

/**
 This kernel does a basic convolution to count the neighbouring value of a given cell.
 The term kernel refers to an openCL kernel, not a convolution kernel.
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
 A function that gives the weights to our convolution kernel
 */
float[] generateConvolutionKernel() { //Pour des noyaux multiples, il faut faire cette étape plusieurs fois
  //Every cell is filled in a way such that every element except the center one, which is 0, has the same value.
  //If every element of the kernel was multiplied by 1 and added together, we would get 1.
  int kernelSize = (int)pow(17, 2); //17x17 matrix.
  float[] kernel = new float[kernelSize];
  for (int i = 0; i < kernelSize; i++) {
    kernel[i] = 1.0/(kernelSize-1);
  }
  kernel[ceil(kernelSize/2)] = 0;
  return kernel;
}

/**
 Prepare the GPU for computing.
 */
void gpuInit() {
  long numBytes[] = new long[1];

  // Obtain the platform IDs and initialize the context properties
  CL.clGetPlatformIDs(platforms.length, platforms, null);
  contextProperties = new cl_context_properties();
  contextProperties.addProperty(CL.CL_CONTEXT_PLATFORM, platforms[0]);

  // Create an OpenCL context on a GPU device
  context = CL.clCreateContextFromType(
    contextProperties, CL.CL_DEVICE_TYPE_GPU, null, null, null);

  if (context == null)
  {
    // If no context for a GPU device could be created,
    // try to create one for a CPU device.
    context = CL.clCreateContextFromType(
      contextProperties, CL.CL_DEVICE_TYPE_CPU, null, null, null);

    if (context == null)
    {
      System.out.println("Unable to create a context");
      return;
    }
  }

  // Enable exceptions and subsequently omit error checks in this sample
  CL.setExceptionsEnabled(true);

  // Get the list of GPU devices associated with the context
  CL.clGetContextInfo(context, CL.CL_CONTEXT_DEVICES, 0, null, numBytes);

  // Obtain the cl_device_id for the first device
  int numDevices = (int) numBytes[0] / Sizeof.cl_device_id;
  cl_device_id devices[] = new cl_device_id[numDevices];
  CL.clGetContextInfo(context, CL.CL_CONTEXT_DEVICES, numBytes[0],
    Pointer.to(devices), null);

  // Create a command-queue
  commandQueue = CL.clCreateCommandQueueWithProperties(context, devices[0], null, null);

  // Create the program from the source code
  program = CL.clCreateProgramWithSource(context,
    1, new String[]{ programKernel }, null, null);

  // Build the program
  CL.clBuildProgram(program, 0, null, "-cl-mad-enable", null, null);

  // Create the kernel
  clKernel = CL.clCreateKernel(program, "countNeighbours", null); //Pour noyaux multiples
}

/**
 This function asks the GPU to do the convolution described in kernel on all elements of cells[] and puts the results into neighbourCount[].
 */
public void convolve() {
  
  srcIn = Pointer.to(world);
  srcOut = Pointer.to(potential);
  convolutionKernelPtr = Pointer.to(kernel);

  // Allocate the memory objects for the input- and output data
  memObjects[0] = CL.clCreateBuffer(context,
    CL.CL_MEM_READ_ONLY | CL.CL_MEM_COPY_HOST_PTR,
    Sizeof.cl_float * nbCells, srcIn, null);
  memObjects[1] = CL.clCreateBuffer(context,
    CL.CL_MEM_READ_WRITE,
    Sizeof.cl_float * nbCells, null, null);
  memObjects[2] = CL.clCreateBuffer(context,
    CL.CL_MEM_READ_ONLY | CL.CL_MEM_COPY_HOST_PTR,
    Sizeof.cl_float * nbCells, convolutionKernelPtr, null);

  // Set the arguments for the kernel
  CL.clSetKernelArg(clKernel, 0,
    Sizeof.cl_mem, Pointer.to(memObjects[0]));
  CL.clSetKernelArg(clKernel, 1,
    Sizeof.cl_mem, Pointer.to(memObjects[1]));
  CL.clSetKernelArg(clKernel, 2,
    Sizeof.cl_mem, Pointer.to(memObjects[2]));

  // Execute the kernel
  CL.clEnqueueNDRangeKernel(commandQueue, clKernel, 1, null,
    global_work_size, local_work_size, 0, null, null);

  // Read the output data
  CL.clEnqueueReadBuffer(commandQueue, memObjects[1], CL.CL_TRUE, 0,
    nbCells * Sizeof.cl_float, srcOut, 0, null, null);

  CL.clReleaseMemObject(memObjects[0]);
  CL.clReleaseMemObject(memObjects[1]);
  CL.clReleaseMemObject(memObjects[2]);
}

/**
 Releases the GPU.
 */
void gpuRelease() {
  // Release kernel, program, and memory objects
  CL.clReleaseKernel(clKernel);
  CL.clReleaseProgram(program);
  CL.clReleaseCommandQueue(commandQueue);
  CL.clReleaseContext(context);
}

//Guide followed: https://www.codeproject.com/articles/86551/part-1-programming-your-graphics-card-gpu-with-jav //<>//

import org.jocl.*;
import java.util.Arrays;

cl_platform_id platforms[] = new cl_platform_id[1];
cl_context_properties contextProperties;

cl_context context;

cl_command_queue commandQueue;

cl_mem memObjects[] = new cl_mem[2];

cl_program program;

cl_kernel fftColumnKernel;
cl_kernel fftRowKernel;
cl_kernel ifftColumnKernel;
cl_kernel ifftRowKernel;

/**
 This kernel does a basic convolution to count the neighbouring value of a given cell.
 The term kernel refers to an openCL kernel, not a convolution kernel.
 */
private String programKernel =
/**
 The instructions to calculate the surrounding aliveness value for each cell.
 */
  "__kernel void "+
  "fftColumn(            __global const float *in,"+
  "                __global float *out)"+
  "{"+

  "    int n = get_global_size(0);"+
  //The global id corresponds to the current column being processed.
  "    int gid = get_global_id(0);"+
  //The offset of the column in the input array.
  "    int offset = gid * n;"+

  //Fill out with indexes for next step.
  "      for (int i = 0; i < n; i++) {"+
  "        out[2*(i + offset)] = i;"+
  "        out[2*(i + offset) + 1] = 0;"+
  "      }"+
  //Find indexes for bit reverse.
  "      for (int i = 2; i <= n; i*=2) {"+
  "        for (int j = i / 2; j < i; j++) {"+
  "          out[2*(j + offset)] = out[2*((j + offset) - i / 2)] + n / i;"+
  "        }"+
  "      }"+

  //Fetch corresponding data in input and overwrite stack with it.
  "    for (int k = 0; k < n; k++) {"+
  "      int index = (int)out[2*(k + offset)];"+
  "      out[2 * (k + offset)] = in[2*(index + offset)];"+
  "      out[2 * (k + offset) + 1] = in[2*(index + offset) + 1];"+
  "    }"+

  //Perform the FFT itself
  "    for (int s = 1 ; s <= (int)log2((float)n) ; s++) {"+
  //m is the size of the array we would have gotten in the usual recursive way.
  "      int m = pow(2,(float)s);"+
  //Omega is the angle between each root of unity.
  "      float omega = (-2*"+PI+")/m;"+

  "      for (int k = 0; k < n; k+=m) {"+
  //w is the angle for the current root of unity. It starts at 0, for 1 + 0i.
  "        float w = 0;"+
  "        for (int j = 0; j < m/2 ; j++) {"+
  //t and u are the terms of the equation. m, a, r and i mean modulus, argument, real part and imaginary part.
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

  "__kernel void "+
  "fftRow(            __global const float *in,"+
  "                __global float *out)"+
  "{"+

  "    int n = get_global_size(0);"+
  //The global id corresponds to the current column being processed.
  "    int gid = get_global_id(0);"+
  //The offset of the column in the input array.

  //Fill out with indexes for next step.
  "      for (int i = 0; i < n; i++) {"+
  "        out[2*(i * n + gid)] = i;"+
  "        out[2*(i * n + gid) + 1] = 0;"+
  "      }"+
  
  //Find indexes for bit reverse.
  "      for (int i = 2; i <= n; i*=2) {"+
  "        for (int j = i / 2; j < i; j++) {"+
  "          out[2*(j * n + gid)] = out[2*((j - i / 2) * n + gid)] + n / i;"+
  "        }"+
  "      }"+
  
  //Fetch corresponding data in input and overwrite stack with it.
  "    for (int k = 0; k < n; k++) {"+
  "      int index = (int)out[2*(k * n + gid)];"+
  "      out[2 * (k * n + gid)] = in[2*(index * n + gid)];"+
  "      out[2 * (k * n + gid) + 1] = in[2*(index * n + gid) + 1];"+
  "    }"+

  //Perform the FFT itself
  "    for (int s = 1 ; s <= (int)log2((float)n) ; s++) {"+
  //m is the size of the array we would have gotten in the usual recursive way.
  "      int m = pow(2,(float)s);"+
  //Omega is the angle between each root of unity.
  "      float omega = (-2*"+PI+")/m;"+

  "      for (int k = 0; k < n; k+=m) {"+
  //w is the angle for the current root of unity. It starts at 0, for 1 + 0i.
  "        float w = 0;"+
  "        for (int j = 0; j < m/2 ; j++) {"+
  //t and u are the terms of the equation. m, a, r and i mean modulus, argument, real part and imaginary part.
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

  //This invere fft does not include the 1 / n scaling factor.
  "__kernel void "+
  "ifftColumn(            __global const float *in,"+
  "                __global float *out)"+
  "{"+

  "     int n = get_global_size(0);"+
  //The global id corresponds to the current column being processed.
  "    int gid = get_global_id(0);"+
  //The offset of the column in the input array.
  "    int offset = gid * n;"+

  //Fill out with indexes for next step.
  "      for (int i = 0; i < n; i++) {"+
  "        out[2*(i + offset)] = i;"+
  "        out[2*(i + offset) + 1] = 0;"+
  "      }"+
  //Find indexes for bit reverse.
  "      for (int i = 2; i <= n; i*=2) {"+
  "        for (int j = i / 2; j < i; j++) {"+
  "          out[2*(j + offset)] = out[2*((j + offset) - i / 2)] + n / i;"+
  "        }"+
  "      }"+

  //Fetch corresponding data in input and overwrite stack with it.
  "    for (int k = 0; k < n; k++) {"+
  "      int index = (int)out[2*(k + offset)];"+
  "      out[2 * (k + offset)] = in[2*(index + offset)];"+
  "      out[2 * (k + offset) + 1] = in[2*(index + offset) + 1];"+
  "    }"+

  //Perform the FFT itself
  "    for (int s = 1 ; s <= (int)log2((float)n) ; s++) {"+
  //m is the size of the array we would have gotten in the usual recursive way.
  "      int m = pow(2,(float)s);"+
  //Omega is the angle between each root of unity.
  "      float omega = (2*"+PI+")/m;"+

  "      for (int k = 0; k < n; k+=m) {"+
  //w is the angle for the current root of unity. It starts at 0, for 1 + 0i.
  "        float w = 0;"+
  "        for (int j = 0; j < m/2 ; j++) {"+
  //t and u are the terms of the equation. m, a, r and i mean modulus, argument, real part and imaginary part.
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
  
  //This invere fft does not include the 1 / n scaling factor.
  "__kernel void "+
  "ifftRow(            __global const float *in,"+
  "                __global float *out)"+
  "{"+

  "    int n = get_global_size(0);"+
  //The global id corresponds to the current column being processed.
  "    int gid = get_global_id(0);"+
  //The offset of the column in the input array.

  //Fill out with indexes for next step.
  "      for (int i = 0; i < n; i++) {"+
  "        out[2*(i * n + gid)] = i;"+
  "        out[2*(i * n + gid) + 1] = 0;"+
  "      }"+
  //Find indexes for bit reverse.
  "      for (int i = 2; i <= n; i*=2) {"+
  "        for (int j = i / 2; j < i; j++) {"+
  "          out[2*(j * n + gid)] = out[2*((j - i / 2) * n + gid)] + n / i;"+
  "        }"+
  "      }"+

  //Fetch corresponding data in input and overwrite stack with it.
  "    for (int k = 0; k < n; k++) {"+
  "      int index = (int)out[2*(k * n + gid)];"+
  "      out[2 * (k * n + gid)] = in[2*(index * n + gid)];"+
  "      out[2 * (k * n + gid) + 1] = in[2*(index * n + gid) + 1];"+
  "    }"+

  //Perform the FFT itself
  "    for (int s = 1 ; s <= (int)log2((float)n) ; s++) {"+
  //m is the size of the array we would have gotten in the usual recursive way.
  "      int m = pow(2,(float)s);"+
  //Omega is the angle between each root of unity.
  "      float omega = (2*"+PI+")/m;"+

  "      for (int k = 0; k < n; k+=m) {"+
  //w is the angle for the current root of unity. It starts at 0, for 1 + 0i.
  "        float w = 0;"+
  "        for (int j = 0; j < m/2 ; j++) {"+
  //t and u are the terms of the equation. m, a, r and i mean modulus, argument, real part and imaginary part.
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
  fftColumnKernel = CL.clCreateKernel(program, "fftColumn", null);
  fftRowKernel = CL.clCreateKernel(program, "fftRow", null);
  ifftColumnKernel = CL.clCreateKernel(program, "ifftColumn", null);
  ifftRowKernel = CL.clCreateKernel(program, "ifftRow", null);
}

/**
 This function pre-calculates a convolution kernel in fourier space and returns it. The input image parameter isn't used per say, but its dimensions are needed to know the output size.
 The sideLength parameter is used to now the input image's width.
 */
int kernelWidth;
public float[] preCalculateFourierKernel(float[] inputImage, float[] inputKernel, int sideLength) {
  //For the convolution to work, we need to add zeroes to every dimension such that the width of the convolution is the sum of the widths of the kernel and the grid - 1.
  //Also, the grid and kernel must have the same dimensions, although, 0 padding of the kernel is fine.
  //Lastly, the current implementation of fft requires the widths to be powers of two.

  //Finding the dimensions of the grid. For simplicity, we want the kernel to be square.
  int sideHeight = inputImage.length / sideLength;
  kernelWidth = (int)sqrt(inputKernel.length);
  int convolutionSize = max(sideLength, sideHeight) + kernelWidth - 1;

  //Check if it is a power of two, and pad it if not.
  if (!((convolutionSize & (convolutionSize - 1)) == 0)) {
    convolutionSize = (int)pow(2, (int)(log(convolutionSize)/log(2))+1);
  }

  //Pad convolution kernel and convert to complex numbers
  float[] paddedKernel = new float[convolutionSize*convolutionSize * 2];
  for (int i = 0; i < inputKernel.length; i++) {
    paddedKernel[2*((i / kernelWidth)*convolutionSize + (i % kernelWidth))] = inputKernel[i];
  }

  //Creating an output array for the GPU to put its results in.
  //Because we are dealing with complex numbers, each number takes twice as much space in an array.
  float[] GPUOutKernel = new float[convolutionSize * convolutionSize * 2];

  //Finding the work-item dimensions for the GPU.
  Pointer srcIn = Pointer.to(paddedKernel);
  Pointer srcOut = Pointer.to(GPUOutKernel);

  long global_work_size[] = new long[]{convolutionSize};
  long local_work_size[] = new long[]{min(32, convolutionSize)};

  //FFT on the columns of the kernel.
  // Allocate the memory objects for the input- and output data
  memObjects[0] = CL.clCreateBuffer(context,
    CL.CL_MEM_READ_ONLY | CL.CL_MEM_COPY_HOST_PTR,
    Sizeof.cl_float * paddedKernel.length, srcIn, null);
  memObjects[1] = CL.clCreateBuffer(context,
    CL.CL_MEM_READ_WRITE,
    Sizeof.cl_float * GPUOutKernel.length, null, null);

  // Set the arguments for the kernel
  CL.clSetKernelArg(fftColumnKernel, 0,
    Sizeof.cl_mem, Pointer.to(memObjects[0]));
  CL.clSetKernelArg(fftColumnKernel, 1,
    Sizeof.cl_mem, Pointer.to(memObjects[1]));

  // Execute the kernel
  CL.clEnqueueNDRangeKernel(commandQueue, fftColumnKernel, 1, null,
    global_work_size, local_work_size, 0, null, null);

  // Read the output data
  CL.clEnqueueReadBuffer(commandQueue, memObjects[1], CL.CL_TRUE, 0,
    Sizeof.cl_float * GPUOutKernel.length, srcOut, 0, null, null);

  CL.clReleaseMemObject(memObjects[0]);
  CL.clReleaseMemObject(memObjects[1]);

  //FFT on row of kernel
  float[] rotatedPaddedKernel = GPUOutKernel.clone();
  srcIn = Pointer.to(rotatedPaddedKernel);

  // Allocate the memory objects for the input- and output data
  memObjects[0] = CL.clCreateBuffer(context,
    CL.CL_MEM_READ_ONLY | CL.CL_MEM_COPY_HOST_PTR,
    Sizeof.cl_float * rotatedPaddedKernel.length, srcIn, null);
  memObjects[1] = CL.clCreateBuffer(context,
    CL.CL_MEM_READ_WRITE,
    Sizeof.cl_float * GPUOutKernel.length, null, null);

  // Set the arguments for the kernel
  CL.clSetKernelArg(fftRowKernel, 0,
    Sizeof.cl_mem, Pointer.to(memObjects[0]));
  CL.clSetKernelArg(fftRowKernel, 1,
    Sizeof.cl_mem, Pointer.to(memObjects[1]));

  // Execute the kernel
  CL.clEnqueueNDRangeKernel(commandQueue, fftRowKernel, 1, null,
    global_work_size, local_work_size, 0, null, null);

  // Read the output data
  CL.clEnqueueReadBuffer(commandQueue, memObjects[1], CL.CL_TRUE, 0,
    Sizeof.cl_float * GPUOutKernel.length, srcOut, 0, null, null);

  CL.clReleaseMemObject(memObjects[0]);
  CL.clReleaseMemObject(memObjects[1]);
  
  //Copy data into output array.
  return GPUOutKernel.clone();
}

/**
 This function asks the GPU to perform a 2D convolution using the GPU and the fft algorithm.
 The input is the grid on which the convolution is performed, kernel is the convolution kernel in fourier space (use preCalculateFourierKernel()) and sideLength is the width of the grid.
 */
public float[] fftConvolve2DGPU(float[] input, float[] convolutionKernel, int sideLength) {
  //For the convolution to work, we need to add zeroes to every dimension such that the width of the convolution is the sum of the widths of the kernel and the grid - 1.
  //Also, the grid and kernel must have the same dimensions, although, 0 padding of the kernel is fine.
  //Lastly, the current implementation of fft requires the widths to be powers of two.

  //Finding the dimensions of the grid. For simplicity, we want the kernel to be square.
  int sideHeight = input.length / sideLength;
  int convolutionSize = (int)sqrt(convolutionKernel.length/2);

  //Pad cells and convert to complex numbers
  float[] paddedCells = new float[convolutionSize*convolutionSize * 2];
  for (int i = 0; i < input.length; i++) {
    paddedCells[2*((i / sideHeight)*convolutionSize + (i % sideHeight))] = input[i];
  }

  //Creating an output array for the GPU to put its results in.
  //Because we are dealing with complex numbers, each number takes twice as much space in an array.
  float[] GPUOutCells = new float[convolutionSize * convolutionSize * 2];

  //Finding the work-item dimensions for the GPU.
  Pointer srcIn = Pointer.to(paddedCells);
  Pointer srcOut = Pointer.to(GPUOutCells);

  long global_work_size[] = new long[]{convolutionSize};
  long local_work_size[] = new long[]{min(32, convolutionSize)};

  //FFT on the columns of the input.
  // Allocate the memory objects for the input- and output data
  memObjects[0] = CL.clCreateBuffer(context,
    CL.CL_MEM_READ_ONLY | CL.CL_MEM_COPY_HOST_PTR,
    Sizeof.cl_float * paddedCells.length, srcIn, null);
  memObjects[1] = CL.clCreateBuffer(context,
    CL.CL_MEM_READ_WRITE,
    Sizeof.cl_float * GPUOutCells.length, null, null);

  // Set the arguments for the kernel
  CL.clSetKernelArg(fftColumnKernel, 0,
    Sizeof.cl_mem, Pointer.to(memObjects[0]));
  CL.clSetKernelArg(fftColumnKernel, 1,
    Sizeof.cl_mem, Pointer.to(memObjects[1]));

  // Execute the kernel
  CL.clEnqueueNDRangeKernel(commandQueue, fftColumnKernel, 1, null,
    global_work_size, local_work_size, 0, null, null);

  // Read the output data
  CL.clEnqueueReadBuffer(commandQueue, memObjects[1], CL.CL_TRUE, 0,
    Sizeof.cl_float * GPUOutCells.length, srcOut, 0, null, null);

  CL.clReleaseMemObject(memObjects[0]);
  CL.clReleaseMemObject(memObjects[1]);

  //FFT on row of input
  float[] rotatedPaddedCells = GPUOutCells.clone();
  srcIn = Pointer.to(rotatedPaddedCells);

  // Allocate the memory objects for the input- and output data
  memObjects[0] = CL.clCreateBuffer(context,
    CL.CL_MEM_READ_ONLY | CL.CL_MEM_COPY_HOST_PTR,
    Sizeof.cl_float * paddedCells.length, srcIn, null);
  memObjects[1] = CL.clCreateBuffer(context,
    CL.CL_MEM_READ_WRITE,
    Sizeof.cl_float * GPUOutCells.length, null, null);

  // Set the arguments for the kernel
  CL.clSetKernelArg(fftRowKernel, 0,
    Sizeof.cl_mem, Pointer.to(memObjects[0]));
  CL.clSetKernelArg(fftRowKernel, 1,
    Sizeof.cl_mem, Pointer.to(memObjects[1]));

  // Execute the kernel
  CL.clEnqueueNDRangeKernel(commandQueue, fftRowKernel, 1, null,
    global_work_size, local_work_size, 0, null, null);

  // Read the output data
  CL.clEnqueueReadBuffer(commandQueue, memObjects[1], CL.CL_TRUE, 0,
    Sizeof.cl_float * GPUOutCells.length, srcOut, 0, null, null);

  CL.clReleaseMemObject(memObjects[0]);
  CL.clReleaseMemObject(memObjects[1]);


  //Multiply GPUOutCells by fourierKernel as complex numbers
  for (int i = 0; i < GPUOutCells.length / 2; i++) {
    GPUOutCells[2*i] *= convolutionKernel[2*i];
    GPUOutCells[2*i + 1] += convolutionKernel[2*i + 1];
  }

  //Inverse FFT.
  //On rows
  //Here, our input and outputs are inverted because we did some operations on the output array, so we will go backwards.
  srcIn = Pointer.to(GPUOutCells);
  srcOut = Pointer.to(rotatedPaddedCells);

  // Allocate the memory objects for the input- and output data
  memObjects[0] = CL.clCreateBuffer(context,
    CL.CL_MEM_READ_ONLY | CL.CL_MEM_COPY_HOST_PTR,
    Sizeof.cl_float * paddedCells.length, srcIn, null);
  memObjects[1] = CL.clCreateBuffer(context,
    CL.CL_MEM_READ_WRITE,
    Sizeof.cl_float * GPUOutCells.length, null, null);

  // Set the arguments for the kernel
  CL.clSetKernelArg(ifftRowKernel, 0,
    Sizeof.cl_mem, Pointer.to(memObjects[0]));
  CL.clSetKernelArg(ifftRowKernel, 1,
    Sizeof.cl_mem, Pointer.to(memObjects[1]));

  // Execute the kernel
  CL.clEnqueueNDRangeKernel(commandQueue, ifftRowKernel, 1, null,
    global_work_size, local_work_size, 0, null, null);

  // Read the output data
  CL.clEnqueueReadBuffer(commandQueue, memObjects[1], CL.CL_TRUE, 0,
    Sizeof.cl_float * GPUOutCells.length, srcOut, 0, null, null);

  CL.clReleaseMemObject(memObjects[0]);
  CL.clReleaseMemObject(memObjects[1]);

  //Scale output by 1/n
  for (int i = 0; i < rotatedPaddedCells.length/2; i++) {
    rotatedPaddedCells[2*i] /= (float)convolutionSize;
  }

  //IFFT on columns.
  paddedCells = rotatedPaddedCells.clone();
  srcIn = Pointer.to(paddedCells);
  srcOut = Pointer.to(GPUOutCells);

  // Allocate the memory objects for the input- and output data
  memObjects[0] = CL.clCreateBuffer(context,
    CL.CL_MEM_READ_ONLY | CL.CL_MEM_COPY_HOST_PTR,
    Sizeof.cl_float * paddedCells.length, srcIn, null);
  memObjects[1] = CL.clCreateBuffer(context,
    CL.CL_MEM_READ_WRITE,
    Sizeof.cl_float * GPUOutCells.length, null, null);

  // Set the arguments for the kernel
  CL.clSetKernelArg(ifftColumnKernel, 0,
    Sizeof.cl_mem, Pointer.to(memObjects[0]));
  CL.clSetKernelArg(ifftColumnKernel, 1,
    Sizeof.cl_mem, Pointer.to(memObjects[1]));

  // Execute the kernel
  CL.clEnqueueNDRangeKernel(commandQueue, ifftColumnKernel, 1, null,
    global_work_size, local_work_size, 0, null, null);

  // Read the output data
  CL.clEnqueueReadBuffer(commandQueue, memObjects[1], CL.CL_TRUE, 0,
    Sizeof.cl_float * GPUOutCells.length, srcOut, 0, null, null);

  CL.clReleaseMemObject(memObjects[0]);
  CL.clReleaseMemObject(memObjects[1]);

  //Scale output by 1/n
  for (int i = 0; i < rotatedPaddedCells.length/2; i++) {
    GPUOutCells[2*i] /= (float)convolutionSize;
  }

  //GPUout is converted to only have real numbers and the dimensions of input.
  float[] convolutionOutput = new float[input.length];
  for (int i = 0; i < convolutionOutput.length; i++) {
    convolutionOutput[i] = GPUOutCells[2*((i/sideHeight + kernelWidth/2) * convolutionSize + i%sideHeight + kernelWidth/2)];
  }

  return convolutionOutput;
}

/**
 Releases the GPU.
 */
void gpuRelease() {
  // Release kernel, program, and memory objects
  CL.clReleaseKernel(fftColumnKernel);
  CL.clReleaseKernel(fftRowKernel);
  CL.clReleaseKernel(ifftColumnKernel);
  CL.clReleaseKernel(ifftRowKernel);
  CL.clReleaseProgram(program);
  CL.clReleaseCommandQueue(commandQueue);
  CL.clReleaseContext(context);
}

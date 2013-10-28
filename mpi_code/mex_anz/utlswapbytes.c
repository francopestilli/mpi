/* utlswapbytes.c : utility to swap bytes for Matlab.
 *
 *
 * UTLSWAPBYTES - swaps bytes of given data.
 * 
 * SV = UTLSWAPBYTES(V) swaps bytes of V and returns the result.
 * UTLSWAPBYTES(V) does the same thing but it will modify directly the original
 * data V without allocating additional memory for the result.
 * Input data V can be multi-dimesional, but its data class
 * must be 2bytes or 4bytes type, ie. int16/uint16/int32/uint32/single.
 *
 * Usage: sv = utlswapbytes(v,[verbose=0|1])
 * Notes: class of 'v' must be int16,uint16,int32,uint32,single.
 *      : if nargout==0, then swaps 'v' directly.
 * 
 * To compile,
 *   mex utlswapbytes.c
 *
 * VERSION :
 *   0.90 2005.05.31 Yusuke MURAYAMA @MPI  first release.
 *   0.91 2005.06.01 Yusuke MURAYAMA @MPI  if nargout==0, swaps the original.
 */

#include <stdio.h>
#include "matrix.h"
#include "mex.h"

// input arguments
#define DATA_IN      prhs[0]
#define VERBOSE_IN   prhs[1]

// output arguments
#define DATA_OUT     plhs[0]


// PROTOTYPES /////////////////////////////////////////////////////////
void swap_short(short *, int, int);
void swap_long(long *, int, int);



// FUNCTIONS /////////////////////////////////////////////////////////
void swap_short(unsigned char *ptr, int n, int verbose)
{
  unsigned char b0,b1;
  int i;

  for (i = 0; i < n; i++) {
    // b0-b1 --> b1-b0
    b0   = *ptr;
    b1   = *(ptr+1);
    *ptr     = b1;
    *(ptr+1) = b0;

    ptr = ptr + 2;
  }

  if (verbose)
    mexPrintf("[%d]: %02x %02x --> %02x %02x\n", n,b0,b1,b1,b0);
  
  return;
}

void swap_long(unsigned char *ptr, int n, int verbose)
{
  unsigned char b0,b1,b2,b3;
  int i;

  for (i = 0; i < n; i++) {
    // b0-b1-b2-b3 --> b3-b2-b1-b0
    b0 = *ptr;       b1 = *(ptr+1);
    b2 = *(ptr+2);   b3 = *(ptr+3);

    *ptr     = b3;  *(ptr+1) = b2;
    *(ptr+2) = b1;  *(ptr+3) = b0;

    ptr = ptr + 4;
  }

  if (verbose)
    mexPrintf("[%d]: %02x %02x %02x %02x --> %x %x %x %x\n", n,b0,b1,b2,b3,b3,b2,b1,b0);

  return;
}


// MAIN FUNCTION /////////////////////////////////////////////////////
void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
  char *datastr;
  int n, dataclass, verbose;

  if (nrhs == 0) {
    mexPrintf("Usage: sv = utlswapbytes(v,[verbose=0|1])\n");
    mexPrintf("Notes: class of 'v' must be int16,uint16,int32,uint32,single.\n");
    mexPrintf("     : if nargout==0, then swaps 'v' directly.\n");
    mexPrintf("                                     ver 0.91 Jun-2005 YM@MPI\n");
    return;
  }

  verbose = 0;
  if (nrhs > 1) {
    verbose = (int)mxGetScalar(VERBOSE_IN);
  }

  dataclass = mxGetClassID(DATA_IN);
  n = mxGetNumberOfElements(DATA_IN);

  if (nlhs > 0) {
    DATA_OUT = mxDuplicateArray(DATA_IN);
  }
  
  switch (dataclass) {
  case mxINT16_CLASS:
  case mxUINT16_CLASS:
    if (nlhs > 0) {
      swap_short((unsigned char *)mxGetData(DATA_OUT), n, verbose);
    } else {
      swap_short((unsigned char *)mxGetData(DATA_IN),  n, verbose);
    }
    break;
  case mxINT32_CLASS:
  case mxUINT32_CLASS:
  case mxSINGLE_CLASS:
    if (nlhs > 0) {
      swap_long((unsigned char *)mxGetData(DATA_OUT), n, verbose);
    } else {
      swap_long((unsigned char *)mxGetData(DATA_IN),  n, verbose);
    }
    break;
  default:
    mexPrintf("utlswapbytes: '%s' is an unacceptable data class, 'help class' for detail.\n",
              mxGetClassName(DATA_IN));
    mexErrMsgTxt("utlswapbytes: dataclass must be int16,uint16,int32,uint32,single.");
  }

  return;
}

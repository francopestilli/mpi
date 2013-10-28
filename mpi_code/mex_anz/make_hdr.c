/* This program creates an ANALYZE(TM) database header */
/*
* (c) Copyright, 1986-1995
* Biomedical Imaging Resource
* Mayo Foundation
*
* to compile:
*   cc -o make_hdr make_hdr.c
*
* to compile in Matlab:
*   mex make_hdr.c  -D_USE_IN_MATLAB
*
* 2005.05.31 Yusuke MURAYAMA @MPI  supports Matlab.
* 2005.06.01 Yusuke MURAYAMA @MPI  supports BRU2ANZ.
*
* for detail, see http://www.mayo.edu/bir/PDF/ANALYZE75.pdf
*/


#include <stdio.h>
#include <string.h>
#include "dbh.h"

#ifdef _USE_IN_MATLAB
#  include "matrix.h"
#  include "mex.h"
/* Input Arguments */
#  define	FILE_IN	     prhs[0]
#  define	WIDTH_IN	   prhs[1]
#  define	HEIGHT_IN	   prhs[2]
#  define DEPTH_IN     prhs[3]
#  define VOLUME_IN    prhs[4]
#  define DATATYPE_IN  prhs[5]
#  define GLMAX_IN     prhs[6]
#  define GLMIN_IN     prhs[7]
/* Output Arguments */
#  define	STATUS_OUT	 plhs[0]
#endif


// PROTOTYPES //////////////////////////////////////////////////////
int setup_header(struct dsr *, short, short, short, short, char *, int, int);


// FUNCTIONS //////////////////////////////////////////////////////
// setups the header with given parameters.
int setup_header(struct dsr *phdr,
                 short width, short height, short depth, short volume,
                 char *typestr, int glmax, int glmin)
{
  static char DataTypes[9][12] = {"UNKNOWN", "BINARY",
                                  "CHAR", "SHORT", "INT","FLOAT", "COMPLEX",
                                  "DOUBLE", "RGB"};
  static int DataTypeSizes[9] = {0,1,8,16,32,32,64,64,24};
  int i;

  memset(phdr,0, sizeof(struct dsr));

  for(i = 0;i < 8; i++)  phdr->dime.pixdim[i] = 0.0;
  phdr->dime.vox_offset = 0.0;
#ifdef BRU2ANZ
  phdr->dime.roi_scale = 0.00392157f;  // why 0.00392157f; ?????
#else
  phdr->dime.funused1   = 0.0;
#endif
  phdr->dime.funused2   = 0.0;
  phdr->dime.funused3   = 0.0;
  phdr->dime.cal_max    = 0.0;
  phdr->dime.cal_min    = 0.0;
  phdr->dime.datatype   = -1;
  for(i = 1; i <= 8; i++) {
    if(stricmp(typestr,DataTypes[i]) == 0)  {
      phdr->dime.datatype = (1<<(i-1));
      phdr->dime.bitpix = DataTypeSizes[i];
      break;
    }
  }

  phdr->dime.dim[0] = 4; // all Analyze images are taken as 4 dimensional
  phdr->hk.regular = 'r';
  phdr->hk.sizeof_hdr = sizeof(struct dsr);
  phdr->dime.dim[1] = width;  // slice width in pixels
  phdr->dime.dim[2] = height; // slice height in pixels
  phdr->dime.dim[3] = depth;  // volume depth in slices
  phdr->dime.dim[4] = volume; // number of volumes per file
  phdr->dime.glmax  = glmax;  // maximum voxel value
  phdr->dime.glmin  = glmin;  // minimum voxel value
  // Set the voxel dimension fields:
  // A value of 0.0 for these fields implies that the value is unknown.
  // Change these values to what is appropriate for your data
  // or pass additional command line arguments
  phdr->dime.pixdim[1] = 0.0; /* voxel x dimension */
  phdr->dime.pixdim[2] = 0.0; /* voxel y dimension */
  phdr->dime.pixdim[3] = 0.0; /* pixel z dimension, slice thickness */
  // Assume zero offset in .img file, byte at which pixel
  // data starts in the image file
  phdr->dime.vox_offset = 0.0;
  // Planar Orientation;
  // Movie flag OFF: 0 = transverse, 1 = coronal, 2 = sagittal
  // Movie flag ON:  3 = transverse, 4 = coronal, 5 = sagittal
  phdr->hist.orient = 0;

#ifdef BRU2ANZ
  // up to 3 characters for the voxels units label; i.e. mm., um., cm.
  strcpy(phdr->dime.vox_units," ");
  // up to 7 characters for the calibration units label; i.e. HU
  strcpy(phdr->dime.cal_units," ");
#endif

  // Calibration maximum and minimum values;
  // values of 0.0 for both fields imply that no
  // calibration max and min values are used
  phdr->dime.cal_max = 0.0;
  phdr->dime.cal_min = 0.0;

  return 0;
}




// MAIN FUNCTION /////////////////////////////////////////////////////
#ifdef _USE_IN_MATLAB
void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray*prhs[] )
{
  struct dsr hdr;
  FILE *fp;
  int status, i;
  short x,y,z,t;
  int glmax, glmin;
  char *filename, *datatype;

  if (nrhs == 0 || nrhs != 8) {
    mexPrintf("Usage: status = make_hdr(filename,width,height,depth,volume,datatype,max,min)\n");
    mexPrintf("Notes: datatype: BINARY,CHAR,SHORT,INT,FLOAT,COMPLEX,DOUBLE or RGB\n");
    mexPrintf("                               ver 0.91 Jun-2005 YM@MPI\n");
    return;
  }

  filename = NULL;  datatype = NULL;

  if (mxIsChar(FILE_IN) != 1 || mxGetM(FILE_IN) != 1) {
    mexErrMsgTxt("make_hdr: first arg must be a filename string.");
  }
  i = (mxGetM(FILE_IN) * mxGetN(FILE_IN)) + 1;
  filename = mxCalloc(i,sizeof(char));
  status = mxGetString(FILE_IN, filename, i);
  if (status != 0)
    mexWarnMsgTxt("make_hdr: not enough space, filename is truncated.");

  x = (short) mxGetScalar(WIDTH_IN);
  y = (short) mxGetScalar(HEIGHT_IN);
  z = (short) mxGetScalar(DEPTH_IN);
  t = (short) mxGetScalar(VOLUME_IN);
  glmax = (int) mxGetScalar(GLMAX_IN);
  glmin = (int) mxGetScalar(GLMIN_IN);

  if (mxIsChar(DATATYPE_IN) != 1 || mxGetM(DATATYPE_IN) != 1) {
    mexErrMsgTxt("make_hdr: 6th arg must be a datatype string.");
  }
  i = (mxGetM(DATATYPE_IN) * mxGetN(DATATYPE_IN)) + 1;
  datatype = mxCalloc(i,sizeof(char));
  status = mxGetString(DATATYPE_IN, datatype, i);
  if (status != 0)
    mexWarnMsgTxt("make_hdr: not enough space, datatype is truncated.");


  status = setup_header(&hdr,x,y,z,t,datatype,glmax,glmin);
  if(hdr.dime.datatype <= 0)  {
    mexPrintf("make_hdr: '%s' is an unacceptable datatype.\n", datatype);
    mexErrMsgTxt("make_hdr: datatype should be BINARY,CHAR,SHORT,INT,FLOAT,COMPLEX,DOUBLE or RGB.");
  }

  if((fp = fopen(filename,"wb")) == NULL)  {
    mexPrintf("make_hdr: filename='%s'\n",filename);
    mexErrMsgTxt("make_hdr: unable to create the file.");
  }
  i = fwrite(&hdr, sizeof(struct dsr),1,fp);
  fclose(fp);
#if 0
  if (i != 1) {
    mexPrintf("make_hdr: filename='%s'\n",filename);
    mexErrMsgTxt("make_hdr: failed to write the header.");
  }
#endif

  return;
}

#else
void usage(void)
{
  printf("usage: make_hdr name.hdr x y z t datatype max min \n\n");
  printf(" name.hdr = the name of the header file\n");
  printf(" x = width, y = height, z = depth, t = number of volumes\n");
  printf(" acceptable datatype values are: BINARY, CHAR, SHORT,\n");
  printf(" INT, FLOAT, COMPLEX, DOUBLE, and RGB\n");
  printf(" max = maximum voxel value, min = minimum voxel value\n");

  return;
}

int main(int argc,char **argv) /* file x y z t datatype max min */
{
  struct dsr hdr;
  FILE *fp;
  int status;
  short x,y,z,t;
  int glmax, glmin;

  if(argc != 9) {
    usage();
    exit(0);
  }
  
  x = (short)atoi(argv[2]); // slice width in pixels
  y = (short)atoi(argv[3]); // slice height in pixels
  z = (short)atoi(argv[4]); // volume depth in slices
  t = (short)atoi(argv[5]); // number of volumes per file
  glmax = atoi(argv[7]);    // maximum voxel value
  glmin = atoi(argv[8]);    // minimum voxel value

  status = setup_header(&hdr,x,y,z,t,argv[6],glmax,glmin);
  if(hdr.dime.datatype <= 0)  {
    printf("<%s> is an unacceptable datatype \n\n", argv[6]);
    usage();
    exit(0);
  }

  if((fp = fopen(argv[1],"wb")) == 0)  {
    printf("unable to create: %s\n",argv[1]);
    exit(0);
  }
  fwrite(&hdr,sizeof(struct dsr),1,fp);
  fclose(fp);

  return 1;
}

#endif

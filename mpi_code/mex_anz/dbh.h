/* ANALYZE(TM) Header File Format
*
* (c) Copyright, 1986-1995
* Biomedical Imaging Resource
* Mayo Foundation
*
* dbh.h
*
* databse sub-definitions
*
* 2005.05.31 Yusuke MURAYAMA @MPI :
*   changed "short int"-->"short".
*   adds _DBH_H_INCLUDED, __cplusplus and #pragma pack.
* 2005.06.01 Yusuke MURAYAMA @MPI :
*   modified "image_dimension" to make compatible to Bru2Anz.exe.
*/

#ifndef _DBH_H_INCLUDED
#define _DBH_H_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

#define BRU2ANZ


#pragma pack(1)
struct header_key /* header key */
{                      /* off + size */
  int  sizeof_hdr;     /*   0 +  4 */
  char data_type[10];  /*   4 + 10 */
  char db_name[18];    /*  14 + 18 */
  int  extents;        /*  32 +  4 */
  short session_error; /*  36 +  2 */
  char regular;        /*  38 +  1 */
  char hkey_un0;       /*  39 +  1 */
};                     /* total=40 bytes */


struct image_dimension
{                      /* off + size */
  short dim[8];        /*   0 + 16 */
#ifdef BRU2ANZ
  char  vox_units[4];  /*  16 +  4 */
  // up to 3 characters for the voxels units label; i.e. mm., um., cm.
  char  cal_units[8];  /*  20 +  8 */
  // up to 7 characters for the calibration units label; i.e. HU
#else
  short unused8;       /*  16 +  2 */
  short unused9;       /*  18 +  2 */
  short unused10;      /*  20 +  2 */
  short unused11;      /*  22 +  2 */
  short unused12;      /*  24 +  2 */
  short unused13;      /*  26 +  2 */
#endif
  short unused14;      /*  28 +  2 */
  short datatype;      /*  30 +  2 */
  short bitpix;        /*  32 +  2 */
  short dim_un0;       /*  34 +  2 */
  float pixdim[8];     /*  36 + 32 */
  /*
    pixdim[] specifies the voxel dimensitons:
    pixdim[1] - voxel width
    pixdim[2] - voxel height
    pixdim[3] - interslice distance
    ...etc
  */
  float vox_offset;    /*  68 +  4 */
#ifdef BRU2ANZ
  float roi_scale;     /*  72 +  4 */
#else
  float funused1;      /*  72 +  4 */
#endif
  float funused2;      /*  76 +  4 */
  float funused3;      /*  80 +  4 */
  float cal_max;       /*  84 +  4 */
  float cal_min;       /*  88 +  4 */
  float compressed;    /*  92 +  4 */
  float verified;      /*  96 +  4 */
  int   glmax,glmin;   /* 100 +  8 */
};                     /* total=108 bytes */


struct data_history
{                      /* off + size */
  char descrip[80];    /*   0 + 80 */
  char aux_file[24];   /*  80 + 24 */
  char orient;         /* 104 +  1 */
  char originator[10]; /* 105 + 10 */
  char generated[10];  /* 115 + 10 */
  char scannum[10];    /* 125 + 10 */
  char patient_id[10]; /* 135 + 10 */
  char exp_date[10];   /* 145 + 10 */
  char exp_time[10];   /* 155 + 10 */
  char hist_un0[3];    /* 165 +  3 */
  int  views;          /* 168 +  4 */
  int  vols_added;     /* 172 +  4 */
  int  start_field;    /* 176 +  4 */
  int  field_skip;     /* 180 +  4 */
  int  omax, omin;     /* 184 +  8 */
  int  smax, smin;     /* 192 +  8 */
};                     /* total=200 bytes */

struct dsr
{
  struct header_key hk;        /*   0 +  40 */
  struct image_dimension dime; /*  40 + 108 */
  struct data_history hist;    /* 148 + 200 */
};                             /* total= 348 bytes */

typedef struct
{
  float real;
  float imag;
} COMPLEX;

#pragma pack()


/* Acceptable values for datatype */
#define DT_NONE 0
#define DT_UNKNOWN 0
#define DT_BINARY 1
#define DT_UNSIGNED_CHAR 2
#define DT_SIGNED_SHORT 4
#define DT_SIGNED_INT 8
#define DT_FLOAT 16
#define DT_COMPLEX 32
#define DT_DOUBLE 64
#define DT_RGB 128
#define DT_ALL 255



#ifdef __cplusplus
}
#endif

#endif // end of _DBH_H_INCLUDED

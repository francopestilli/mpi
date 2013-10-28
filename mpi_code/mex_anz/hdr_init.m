function HDR = hdr_init(varargin)
%HDR_INIT - initializes ANALIZE(TM) header structure.
%  HDR = HDR_INIT() returns ANALIZE header structure.
%  HDR = HDR_INIT(NAME1,VALUE1,NAME2,VALUE2,...) returns
%  ANALYZE header initialized by given arguments.
%
%  EXAMPLE :
%    hdr = hdr_init;
%    hdr = hdr_init('dim',[4 256 256 1 148 0 0 0],'datatype',8);
%    hdr = hdr_init('dim',[4 256 256 1 148 0 0 0],'datatype','int32');
%    hdr = hdr_init('dim',[4 256 256 1 148 0 0 0],'datatype','_32BIT_SGN_INT');
%
%  VERSION :
%    0.90 01.06.05 YM  first release.
%    0.91 01.06.05 YM  modified for BRU2ANZ.
%    0.92 13.06.05 YM  accepts '_16BIT_SGN_INT' and '_32BIT_SGN_INT' as 'datatype'.
%    0.93 12.09.05 YM  set dime.roi_scale as 1 for safety.
%
%  See also HDR_READ, HDR_WRITE, DBH.H
%
% ANALYZE HEADER ===================================
% #pragma pack(1)
% struct header_key /* header key */
% {                      /* off + size */
%   long sizeof_hdr;     /*   0 +  4 */ <---- must be 384
%   char data_type[10];  /*   4 + 10 */
%   char db_name[18];    /*  14 + 18 */
%   long extents;        /*  32 +  4 */
%   short session_error; /*  36 +  2 */
%   char regular;        /*  38 +  1 */ <---- should be 'r' ????
%   char hkey_un0;       /*  39 +  1 */
% };                     /* total=40 bytes */
%
% struct image_dimension
% {                      /* off + size */
%   short dim[8];        /*   0 + 16 */
% #ifdef BRU2ANZ
%   char  vox_units[4];  /*  16 +  4 */
%   // up to 3 characters for the voxels units label; i.e. mm., um., cm.
%   char  cal_units[8];  /*  20 +  8 */
%   // up to 7 characters for the calibration units label; i.e. HU
% #else
%   short unused8;       /*  16 +  2 */
%   short unused9;       /*  18 +  2 */
%   short unused10;      /*  20 +  2 */
%   short unused11;      /*  22 +  2 */
%   short unused12;      /*  24 +  2 */
%   short unused13;      /*  26 +  2 */
% #endif
%   short unused14;      /*  28 +  2 */
%   short datatype;      /*  30 +  2 */
%   short bitpix;        /*  32 +  2 */
%   short dim_un0;       /*  34 +  2 */
%   float pixdim[8];     /*  36 + 32 */
%   /*
%     pixdim[] specifies the voxel dimensitons:
%     pixdim[1] - voxel width
%     pixdim[2] - voxel height
%     pixdim[3] - interslice distance
%     ...etc
%   */
%   float vox_offset;    /*  68 +  4 */
% #ifdef BRU2ANZ
%   float roi_scale;     /*  72 +  4 */
% #else
%   float funused1;      /*  72 +  4 */
% #endif
%   float funused2;      /*  76 +  4 */
%   float funused3;      /*  80 +  4 */
%   float cal_max;       /*  84 +  4 */
%   float cal_min;       /*  88 +  4 */
%   float compressed;    /*  92 +  4 */
%   float verified;      /*  96 +  4 */
%   long  glmax,glmin;   /* 100 +  8 */
% };                     /* total=108 bytes */
%
% struct data_history
% {                      /* off + size */
%   char descrip[80];    /*   0 + 80 */
%   char aux_file[24];   /*  80 + 24 */
%   char orient;         /* 104 +  1 */
%   char originator[10]; /* 105 + 10 */
%   char generated[10];  /* 115 + 10 */
%   char scannum[10];    /* 125 + 10 */
%   char patient_id[10]; /* 135 + 10 */
%   char exp_date[10];   /* 145 + 10 */
%   char exp_time[10];   /* 155 + 10 */
%   char hist_un0[3];    /* 165 +  3 */
%   long views;          /* 168 +  4 */
%   long vols_added;     /* 172 +  4 */
%   long start_field;    /* 176 +  4 */
%   long field_skip;     /* 180 +  4 */
%   long omax, omin;     /* 184 +  8 */
%   long smax, smin;     /* 192 +  8 */
% };                     /* total=200 bytes */
%
% struct dsr
% {
%   struct header_key hk;        /*   0 +  40 */
%   struct image_dimension dime; /*  40 + 108 */
%   struct data_history hist;    /* 148 + 200 */
% };                             /* total= 348 bytes */
%
% typedef struct
% {
%   float real;
%   float imag;
% } COMPLEX;
%
% #pragma pack()
%
% /* Acceptable values for datatype */
% #define DT_NONE 0
% #define DT_UNKNOWN 0
% #define DT_BINARY 1
% #define DT_UNSIGNED_CHAR 2
% #define DT_SIGNED_SHORT 4
% #define DT_SIGNED_INT 8
% #define DT_FLOAT 16
% #define DT_COMPLEX 32
% #define DT_DOUBLE 64
% #define DT_RGB 128
% #define DT_ALL 255
%

if nargin == 0 & nargout == 0,
  help hdr_init;
  return;
end

BRU2ANZ = 1;


% read "header_key"
HK.sizeof_hdr    = int32(348);
HK.data_type     = '';
HK.db_name       = '';
HK.extents       = zeros(1,1, 'int32');
HK.session_error = zeros(1,1, 'int16');
HK.regular       = 'r';
HK.hkey_un0      = zeros(1,1, 'int8');

% read "image_dimension"
DIME.dim         = zeros(1,8, 'int16');
if BRU2ANZ,
DIME.vox_units   = '';
DIME.cal_units   = '';
else
DIME.unused8     = zeros(1,1, 'int16');
DIME.unused9     = zeros(1,1, 'int16');
DIME.unused10    = zeros(1,1, 'int16');
DIME.unused11    = zeros(1,1, 'int16');
DIME.unused12    = zeros(1,1, 'int16');
DIME.unused13    = zeros(1,1, 'int16');
end
DIME.unused14    = zeros(1,1, 'int16');
DIME.datatype    = zeros(1,1, 'int16');
DIME.bitpix      = zeros(1,1, 'int16');
DIME.dim_un0     = zeros(1,1, 'int16');
DIME.pixdim      = zeros(1,8, 'single')';
DIME.vox_offset  = zeros(1,1, 'single');
if BRU2ANZ,
% 2005.09.12  set as 1 to be safe, 0.00392157=1/255
%DIME.roi_scale   = zeros(1,1, 'single');
%DIME.roi_scale   = single(0.00392157);	% why 0.00392157 ??? <--- 1/255
DIME.roi_scale   = single(1);
else
DIME.funused1    = zeros(1,1, 'single');
end
DIME.funused2    = zeros(1,1, 'single');
DIME.funused3    = zeros(1,1, 'single');
DIME.cal_max     = zeros(1,1, 'single');
DIME.cal_min     = zeros(1,1, 'single');
DIME.compressed  = zeros(1,1, 'single');
DIME.verified    = zeros(1,1, 'single');
DIME.glmax       = zeros(1,1, 'int32');
DIME.glmin       = zeros(1,1, 'int32');

% read "data_history"
HIST.descrip     = '';
HIST.aux_file    = '';
HIST.orient      = zeros(1,1, 'int8');
HIST.originator  = '';
HIST.generated   = '';
HIST.scannum     = '';
HIST.patient_id  = '';
HIST.exp_date    = '';
HIST.exp_time    = '';
HIST.hist_un0    = '';
HIST.views       = zeros(1,1, 'int32');
HIST.vols_added  = zeros(1,1, 'int32');
HIST.start_field = zeros(1,1, 'int32');
HIST.field_skip  = zeros(1,1, 'int32');
HIST.omax        = zeros(1,1, 'int32');
HIST.omin        = zeros(1,1, 'int32');
HIST.smax        = zeros(1,1, 'int32');
HIST.smin        = zeros(1,1, 'int32');


% set values if given.
for N = 1:2:nargin,
  vname  = varargin{N};
  vvalue = varargin{N+1};
  if strcmpi(vname,'datatype') & ischar(vvalue),
    switch lower(vvalue),
     case {'binary'}
      vvalue = 1;
     case {'uchar', 'uint8'}
      vvalue = 2;
     case {'short', 'int16', '_16bit_sgn_int'}
      vvalue = 4;
     case {'int', 'int32', 'long', '_32bit_sgn_int'}
      vvalue = 8;
     case {'float', 'single'}
      vvalue = 16;
     case {'complex'}
      vvalue = 32;
     case {'double'}
      vvalue = 64;
     case {'rgb'}
      vvalue = 128;
     otherwise
      error('\n ERROR %s: datatype ''%s'' not supported.\n',mfilename,vvalue);
    end
  end
  if isfield(HK,vname),   HK.(vname)   = vvalue;  end
  if isfield(DIME,vname), DIME.(vname) = vvalue;  end
  if isfield(HIST,vname), HIST.(vname) = vvalue;  end
end


% update DIME.bitpix according to DIME.datatype
switch DIME.datatype
 case 1
  DIME.bitpix =  1;
 case 2
  DIME.bitpix =  8;
 case 4
  DIME.bitpix = 16;
 case 8
  DIME.bitpix = 32;
 case 16
  DIME.bitpix = 32;
 case 32
  DIME.bitpix = 64;
 case 64
  DIME.bitpix = 64;
 case 128
  DIME.bitpix = 24;
end



% return the structure
HDR.hk   = HK;		% header_key
HDR.dime = DIME;    % image_dimension
HDR.hist = HIST;	% data_history


return;

function [IMG HDR] = anz_read(filename)
%ANZ_READ - reads ANALYZE image/header
%  [IMG HDR] = ANZ_READ(IMGFILE) reads ANALYZE(TM) image.
%
%  VERSION :
%    0.90 12.01.07 YM  pre-release
%    0.91 28.02.07 YM  use uigetfile()
%    0.92 06.08.07 YM  bug fix when big-endian
%    0.93 07.04.08 YM  filename can be as .raw
%
%  See also ANZ_WRITE HDR_READ UTLSWAPBYTES

if nargin == 0 & nargout == 0,  help anz_read; return;  end

IMG = [];  HDR = [];
if ~exist('filename','var'),  filename = '';  end

if isempty(filename),
  [tmpf,tmpp] = uigetfile({'*.img;*.hdr','ANALYZE data (*.img/*hdr)';'*.*','All Files (*.*)'},...
                          'Pick an ANALYZE file');
  if tmpf == 0,  return;  end
  filename = fullfile(tmpp,tmpf);
  clear tmpf tmpp;
end

[fp,fr,fe] = fileparts(filename);

if strcmpi(fe,'.hdr'),
  % filename as 'header' file.
  imgfile = fullfile(fp,sprintf('%s.img',fr));
else
  % filename as 'image' file, can be like *.raw or so.
  imgfile = fullfile(fp,sprintf('%s%s',fr,fe));
end
hdrfile = fullfile(fp,sprintf('%s.hdr',fr));


if ~exist(hdrfile,'file'),
  error('%s: ''%s'' not found.',mfilename,hdrfile);
end

HDR = hdr_read(hdrfile);
if isempty(HDR),  return;  end

% checks need to swap bytes or not
fid = fopen(hdrfile,'r');
hsize = fread(fid, 1, 'int32=>int32');
fclose(fid);
if hsize > hex2dec('01000000'),
  SWAP_BYTES = 1;
else
  SWAP_BYTES = 0;
end


if ~exist(imgfile,'file'),
  error('%s: ''%s'' not found.',mfilename,imgfile);
end

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
fid = fopen(imgfile,'rb');
if HDR.dime.datatype == 2,
  IMG = fread(fid,inf,'uint8=>uint8');
elseif HDR.dime.datatype == 4,
  IMG = fread(fid,inf,'int16=>int16');
  if SWAP_BYTES > 0,  IMG = utlswapbytes(IMG);  end
elseif HDR.dime.datatype == 8,
  IMG = fread(fid,inf,'int32=>int32');
  if SWAP_BYTES > 0,  IMG = utlswapbytes(IMG);  end
elseif HDR.dime.datatype == 16,
  IMG = fread(fid,inf,'float=>float');
  if SWAP_BYTES > 0,  IMG = utlswapbytes(IMG);  end
elseif HDR.dime.datatype == 64,
  IMG = fread(fid,inf,'double=>double');
else
  fprintf('\n %s: unsupported datatype(=%d).\n',mfilename,HDR.dime.datatype);
  IMG = NaN(HDR.dime.dim([1:HDR.dime.dim(1)]+1));
end
fclose(fid);


IMG = reshape(IMG,HDR.dime.dim([1:HDR.dime.dim(1)]+1));



return

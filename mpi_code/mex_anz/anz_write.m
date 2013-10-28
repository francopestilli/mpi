function varargout = anz_write(filename,HDR,IMGDAT)
%ANZ_WRITE - writes ANALYZE image/header
%  ANZ_WRITE(HDRFILE,HDR,IMGDAT) writes ANALYZE(TM) image.
%
%  VERSION :
%    0.90 27.02.07 YM  pre-release
%
%  See also ANZ_READ HDR_WRITE

if nargin == 0,  help anz_write; return;  end

if isempty(filename),
  fprintf('\n ERROR %s: no filename specified.\n',mfilename);
  return
end

[fp,fr,fe] = fileparts(filename);

imgfile = fullfile(fp,sprintf('%s.img',fr));
hdrfile = fullfile(fp,sprintf('%s.hdr',fr));


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

switch lower(HDR.dime.datatype)
 %case {1,'binary'}
 % ndatatype = 1;
 % wdatatype = 'int8';
 case {2,'uchar', 'uint8'}
  ndatatype = 2;
  wdatatype = 'uint8';
 case {4,'short', 'int16'}
  ndatatype = 4;
  wdatatype = 'int16';
 case {8,'int', 'int32', 'long'}
  ndatatype = 8;
  wdatatype = 'int32';
 case {16,'float', 'single'}
  ndatatype = 16;
  wdatatype = 'single';
 %case {32,'complex'}
 % ndatatype = 32;
 % wdatatype = 'complex';
 case {64,'double'}
  ndatatype = 64;
  wdatatype = 'double';
 case {128,'rgb'}
  ndatatype = 128;
  wdatatype = 'uint8';
 otherwise
  if ischar(HDR.dime.datatype),
    fprintf('\n %s: unsupported datatype(=%s).\n',mfilename,HDR.dime.datatype);
  else
    fprintf('\n %s: unsupported datatype(=%d).\n',mfilename,HDR.dime.datatype);
  end
  return
end

% check image size
imgdim = HDR.dime.dim([1:HDR.dime.dim(1)]+1);
nvox = prod(double(HDR.dime.dim([1:HDR.dime.dim(1)]+1)));
if ndatatype == 128,
  nvox = nvox*3;
end
if numel(IMGDAT) ~= nvox,
  fprintf('\n ERROR %s: dimensional mismatch, ');
  fprintf(' HDR.dime.dim = [');  fprintf(' %d',HDR.dime.dim([1:HDR.dime.dim(1)]+1));
  fprintf(' ],  size(IMGDAT)=['); fprintf(' %d',size(IMGDAT));
  fprintf(' ]\n');
  return
end



hdr_write(hdrfile,HDR);

fid = fopen(imgfile,'w');
fwrite(fid,IMGDAT,wdatatype);
fclose(fid);


return

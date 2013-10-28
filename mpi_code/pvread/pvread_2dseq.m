function varargout = pvread_2dseq(varargin)
%PVREAD_2DSEQ - Read ParaVision 2dseq data.
%  [IDATA,IMGP] = PVREAD_2DSEQ(FILENAME,...)
%  IDATA = PVREAD_2DSEQ(FILENAME,...)
%  IDATA = PVREAD_2DSEQ(SESSION,EXPNO,...) read ParaVision 2dseq data.
%
%  Supported options are...
%    'ImgCrop'   : cropping as [x,y,width,height], can be empty. x,y>=1.
%    'ImgSize'   : image size as [nx, ny, nslices, ntime], must not be empty.
%    'TimeCrop'  : cropping as [t,nt], can be empty.  t>=1.
%    'ByteOrder' : 'littleEndian' or 'bigEndian'
%    'WordType'  : '_16BIT_SGN_INT' or '_32BIT_SGN_INT'
%    'reco'      : reco sturcture returned by pvread_reco().
%    'acqp'      : acqp structure returned by pvread_acqp().
%    'imgp'      : image parameters returned by pv_imgpar().
%
%  Returned IDATA is NOT 'double', but 'WordType'.
%
%  VERSION :
%    0.90 07.03.07 YM  pre-release
%    0.91 16.04.07 YM  supports pvread_2dseq(Ses,ExpNo)
%    0.92 29.08.08 YM  supports both new csession and old getses.
%    0.93 18.09.08 YM  returns imgp instread of acqp/reco
%    0.94 23.09.08 YM  bug fix on RECO_transposition.
%
%  See also pv_imgpar pvread_acqp pvread_reco pvread_imnd pvread_method pvread_visu_pars

if nargin < 1,  eval(sprintf('help %s;',mfilename));  return;  end


if ischar(varargin{1}) & ~isempty(strfind(varargin{1},'2dseq')),
  % Called like pvread_2dseq(2DSEQFILE)
  imgfile = varargin{1};
  ivar = 2;
else
  % Called like pvread_2dseq(SESSION,ExpNo)
  if nargin < 2,
    error(' ERROR %s: missing 2nd arg. as ExpNo.\n',mfilename);
    return;
  end
  if exist('csession','class'),
    ses = csession(varargin{1});
    imgfile = ses.filename(varargin{2},'2dseq');
  else
    ses = goto(varargin{1});
    imgfile = catfilename(ses,varargin{2},'2dseq');
  end
  ivar = 3;
end


% check the file.
if ~exist(imgfile,'file'),
  error(' ERROR %s: ''%s'' not found.',mfilename,imgfile);
end

% SET OPTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ImgSize   = [];
ImgCrop   = [];
SliceCrop = [];
TimeCrop  = [];
ByteOrder = '';
WordType  = '_16BIT_SGN_INT';
reco      = [];
acqp      = [];
imgp      = [];
for N = ivar:2:length(varargin),
  switch lower(varargin{N}),
   case {'imgsize','imagesize'}
    ImgSize = varargin{N+1};
   case {'imgcrop','imagecrop'}
    ImgCrop = varargin{N+1};
   case {'slicrop','slicecrop'}
    SliceCrop = varargin{N+1};
   case {'timecrop','tcrop'}
    TimeCrop = varargin{N+1};
   case {'byteorder','endian','reco_byte_order'}
    ByteOrder = varargin{N+1};
   case {'wordtype','datatype','data type','reco_wordtype'}
    WordType = varargin{N+1};
   case {'reco'}
    reco = varargin{N+1};
   case {'acqp'}
    acqp = varargin{N+1};
   case {'imgpar','imgp','pvpar'}
    imgp = varargin{N+1};
  end
end

if nargout > 1 && isempty(imgp),
  imgp = pv_imgpar(imgfile,'acqp',acqp,'reco',reco);
end

% set image parameters from 'pv_imgpar'.
if ~isempty(imgp),
  if isempty(ImgSize)     ImgSize   = imgp.imgsize;          end
  if isempty(ByteOrder),  ByteOrder = imgp.RECO_byte_order;  end
  if isempty(WordType),   WordType  = imgp.RECO_wordtype;    end
end

% set image size if needed %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(ImgSize),
  if isempty(reco),  reco = pvread_reco(imgfile);  end
  if isempty(acqp),  acqp = pvread_acqp(imgfile);  end
  nx = reco.RECO_size(1);
  if length(reco.RECO_size) < 2,
    ny = 1;
  else
    ny = reco.RECO_size(2);
  end
  ns = acqp.NSLICES;
  nt = acqp.NR;
  if strncmpi(acqp.PULPROG,'<mdeft',5),
    if length(reco.RECO_size) > 2,
      ns = reco.RECO_size(3);
    end
    nt = acqp.NI;
  end
  ImgSize = [nx ny ns nt];
  % check transposition on reco
  transpos = 0;
  if isfield(reco,'RECO_transposition'),
    transpos = reco.RECO_transposition(1);
  elseif isfield(reco,'RECO_transpose_dim'),
    transpos = reco.RECO_transpose_dim(1);
  end
  if any(transpos),
    if transpos == 1,
      % (x,y,z) --> (y,x,z)
      tmpvec = [2 1 3];
    elseif transpos == 2,
      % (x,y,z) --> (x,z,y)
      tmpvec = [1 3 2];
    elseif transpos == 3,
      % (x,y,z) --> (z,y,x)
      tmpvec = [3 2 1];
    end
    ImgSize(1:3) = ImgSize(tmpvec);
  end
end

% check image crop %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(ImgCrop),
  % ImgCrop as [x,y,width,height]
  selx = [1:ImgCrop(3)] + ImgCrop(1) - 1;
  sely = [1:ImgCrop(4)] + ImgCrop(2) - 1;
  if min(selx) < 1 | max(selx) > ImgSize(1) | min(sely) < 1 | max(sely) > ImgSize(2),
    fprintf('\n ImgSize=['); fprintf(' %d',ImgSize);  fprintf(' ]');
    fprintf('\n ImgCrop=['); fprintf(' %d',ImgCrop);  fprintf(' ]');
    error('\n %s error: imgcrop is out of range.\n',mfilename);
  end
end

% check slice crop %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(SliceCrop),
  % SliceCrop as [s0, nslices]
  sels = [1:SliceCrop(2)] + SliceCrop(1) - 1;
  if min(sels) < 1 | max(sels) > ImgSize(3),
    fprintf('\n ImgSize=['); fprintf(' %d',ImgSize);  fprintf(' ]');
    fprintf('\n SliceCrop=['); fprintf(' %d',SliceCrop);  fprintf(' ]');
    error('\n %s error: slicecrop is out of range.\n',mfilename);
  end
end

% check time crop %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(TimeCrop),
  % TimeCrop as [t0, tlen]
  selt = [1:TimeCrop(2)] + TimeCrop(1) - 1;
  if min(selt) < 1 | max(selt) > ImgSize(4),
    fprintf('\n ImgSize=['); fprintf(' %d',ImgSize);  fprintf(' ]');
    fprintf('\n TimeCrop=['); fprintf(' %d',TimeCrop);  fprintf(' ]');
    error('\n %s error: timecrop is out of range.\n',mfilename);
  end
end


% set byte order %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(ByteOrder),
  if isempty(reco),  reco = pvread_reco(imgfile);  end
  ByteOrder = reco.RECO_byte_order;
end
switch lower(ByteOrder),
 case {'s','swap','b','big','bigendian','big-endian'}
  ByteOrder = 'ieee-be';
 case {'n','noswap','non-swap','l','little','littleendian','little-endian'}
  ByteOrder = 'ieee-le';
end


% set data type %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(WordType),
  if isempty(reco),  reco = pvread_reco(imgfile);  end
  WordType = reco.RECO_wordtype;
end
switch WordType,
 case {'_16_BIT','_16BIT_SGN_INT','int16'}
  WordType = 'int16=>int16';
 case {'_32_BIT','_32BIT_SGN_INT','int32'}
  WordType = 'int32=>int32';
 otherwise
  error(' %s error: unknown data type, ''%s''.',WordType,mfilename);
end


% READ DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fid = fopen(imgfile,'rb',ByteOrder);
IDATA = fread(fid,inf,WordType);
fclose(fid);

if isfield(reco,'RECO_image_type') & strcmp(reco.RECO_image_type, 'COMPLEX_IMAGE'),
  % According to ParaVision manual,
  % first all real data is written to 2dseq, then imaginary data is appended to it.
  IDATA = reshape(IDATA,length(IDATA)/2,2);
  IDATA = complex(IDATA(:,1),IDATA(:,2));
end

try,
  IDATA = reshape(IDATA,ImgSize);
catch
  fprintf('\n Num.elements=%d,',numel(IDATA));
  fprintf('\n expected ImgSize=['); fprintf(' %d',ImgSize);  fprintf(' ]');
  error('\n %s error: size mismatch.\n',mfilename);
end


% CROPPING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(ImgCrop),
  IDATA = IDATA(selx,sely,:,:);
end
if ~isempty(SliceCrop),
  IDATA = IDATA(:,:,sels,:);
end
if ~isempty(TimeCrop),
  IDATA = IDATA(:,:,:,selt);
end


% RETURN VALUES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout,
  varargout{1} = IDATA;
  if nargout > 1,
    varargout{2} = imgp;
  end
end


return;


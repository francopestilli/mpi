function varargout = bru2analyze(varargin)
%BRU2ANALYZE - dumps Brucker 2dseq as ANALIZE-7 format for SPM.
%  BRU2ANALYZE(2DSEQFILE,...)
%  BRU2ANALYZE(SESSION,EXPNO,...) dumps Brucker 2dseq as ANLYZE-7 format for SPM.
%    Optional setting can be given as a pair of the name and value, like,
%       BRU2ANALYZE(2dseqfile,'SaveDir','y:/temp/spm')  % save to 'y:/temp/spm'
%       BRU2ANALYZE(2dseqfile,'FlipDim',[2])            % flips Y
%    Supported optional arguments are
%      'ImageCrop'   : [x y width height]
%      'SliceCrop'   : [slice-start  num.slices]
%      'FlipDim'     : [1,2...] dimension(s) to flip, 1/2/3 as X/Y/Z
%      'ExportAs2D'  : 0/1 to export volumes 2D
%      'SplitInTime' : 0/1 to export time series to different files
%      'SaveDir'     : directory to save
%      'FileRoot'    : filename without extension
%      'Verbose'     : 0/1
%
%  EXAMPLE:
%    % exporting functional 2dseq for spm
%      >> bru2analyze('m02lx1',1)
%    % exporting 3D-MDEFT "WITH Y-AXIS FLIP" for BrainSight.
%      >> bru2analyze('//wks8/guest/D02.G01/5/pdata/1/2dseq','FlipDim',[2])
%    % exporting 3D-MDEFT as 2D images for photoshop etc.
%      >> bru2analyze('//wks8/guest/H03.BJ1/5/pdata/1/2dseq','SaveDir','../H03','ExportAs2D',1);
%
%  IMAGE ORIENTATION :
%    hdr.hist.orient:.
%       0 transverse unflipped (ANALYZE default)
%         +X=left, +Y=anterior, +Z=superior
%       1 coronal unflipped
%       2 sagittal unflipped
%       3 transverse flipped
%       4 coronal flipped
%       5 sagittal flipped
%
%  VERSION :
%    0.90 13.06.05 YM  pre-release
%    0.91 14.06.05 YM  bug fix, tested with 'm02lx1'
%    0.92 08.08.05 YM  checks reco.RECO_byte_order for machine format.
%    0.93 12.02.07 YM  bug fix on 3D-MDEFT
%    0.94 13.02.07 YM  supports FLIPDIM
%    0.95 21.02.07 YM  supports EXPORT_AS_2D
%    0.96 27.02.07 YM  supports SAVEDIR, hdr.dim.dim(1) as 4 always.
%    0.97 20.03.08 YM  supports 'FileRoot' as option.
%    0.98 08.04.08 YM  supports 'Verbose' as option.
%    0.99 14.09.09 YM  bug fix of RECO_transposition, help by MB.
%
%  See also HDR_INIT HDR_WRITE TCIMG2SPM SPM2TCIMG PVREAD_RECO PVREAD_ACQP

if nargin == 0,  help bru2analyze; return;  end

SAVEDIR = 'spmanz';

% GET FILENAME, CROPPING INFO. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
IMGCROP = [];  SLICROP = []; FLIPDIM = [2];
EXPORT_AS_2D = [];   SPLIT_IN_TIME = [];
FILE_ROOT = '';
VERBOSE = 1;
if ischar(varargin{1}) & ~isempty(strfind(varargin{1},'2dseq')),
  % called like BRU2ANALYZE(2DSEQFILE,varargin)
  TDSEQFILE = varargin{1};
  % parse inputs
  for N = 2:2:nargin,
    switch lower(varargin{N}),
     case {'imgcrop','imagecrop','image crop'}
      IMGCROP = varargin{N+1};
     case {'slicop','slicecrop','slice crop'}
      SLICROP = varargin{N+1};
     case {'flipdim','flip dim','flip dimension'}
      FLIPDIM = varargin{N+1};
     case {'exportas2d','export as 2d','export2d','export 2d'}
      EXPORT_AS_2D  = varargin{N+1};
     case {'splitintime','splittime','split in time','splite time','tsplit'}
      SPLIT_IN_TIME = varargin{N+1};
     case {'savedir','save dir','savedirectory','save directory'}
      SAVEDIR = varargin{N+1};
     case {'fileroot','file root','froot','savename','filename','fname'}
      FILE_ROOT = varargin{N+1};
     case {'verbose'}
      VERBOSE = varargin{N+1};
    end
  end
else
  % called like BRU2ANALYZE(SESSION,EXPNO,varargin)
  Ses = goto(varargin{1});
  ExpNo = varargin{2};
  if ~isnumeric(ExpNo) | length(ExpNo) ~= 1,
    fprintf('%s ERROR: 2nd arg. must be a numeric ExpNo.\n',mfilename);
    return;
  end
  if nargout,
    varargout = bru2analyze(catfilename(Ses,ExpNo,'2dseq'),varargin{:});
  else
    bru2analyze(catfilename(Ses,ExpNo,'2dseq'),varargin{:});
  end
  return
end
if isempty(EXPORT_AS_2D),   EXPORT_AS_2D  = 0;  end
if isempty(SPLIT_IN_TIME),  SPLIT_IN_TIME = 1;  end
if ~isempty(FLIPDIM) & ischar(FLIPDIM),
  % 'FLIPDIM' is given as a string like, 'Y' or 'XZ'
  tmpdim = [];
  for N=1:length(FLIPDIM),
    tmpidx = strfind('xyz',lower(FLIPDIM(N)));
    if ~isempty(tmpidx),  tmpdim(end+1) = tmpidx;  end
  end
  FLIPDIM = tmpdim;
  clear tmpdim tmpidx;
end


[fp,fr,fe] = fileparts(TDSEQFILE);
RECOFILE = fullfile(fp,'reco');
[fp,fr,fe] = fileparts(fileparts(fp));
ACQPFILE = fullfile(fp,'acqp');

if exist(TDSEQFILE,'file') == 0,
  fprintf(' %s ERROR: ''%s'' not found.\n',mfilename,TDSEQFILE);
  return;
end
if exist(RECOFILE,'file') == 0,
  fprintf(' %s ERROR: ''%s'' not found.\n',mfilename,RECOFILE);
  return;
end
if exist(ACQPFILE,'file') == 0,
  fprintf(' %s ERROR: ''%s'' not found.\n',mfilename,ACQPFILE);
  return;
end


% READ RECO/ACQP INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if VERBOSE > 0,
  fprintf(' %s: reading reco/acqp',mfilename);
end
reco = pvread_reco(RECOFILE);
acqp = pvread_acqp(ACQPFILE);

if length(reco.RECO_size) == 3,
  % likely mdeft
  nx = reco.RECO_size(1);
  ny = reco.RECO_size(2);
  nz = reco.RECO_size(3);
  xres = reco.RECO_fov(1) / reco.RECO_size(1) * 10;	  % 10 for cm -> mm
  yres = reco.RECO_fov(2) / reco.RECO_size(2) * 10;	  % 10 for cm -> mm
  zres = reco.RECO_fov(3) / reco.RECO_size(3) * 10;	  % 10 for cm -> mm
else
  % likely epi
  nx = reco.RECO_size(1);
  ny = reco.RECO_size(2);
  nz = acqp.NSLICES;
  xres = reco.RECO_fov(1) / reco.RECO_size(1) * 10;	  % 10 for cm -> mm
  yres = reco.RECO_fov(2) / reco.RECO_size(2) * 10;	  % 10 for cm -> mm
  if nz > 1,
    zres = acqp.ACQ_slice_sepn;
  else
    zres = acqp.ACQ_slice_thick;
  end
end

tmpfs  = dir(TDSEQFILE);
switch reco.RECO_wordtype,
 case {'_8BIT_UNSGN_INT'}
  dtype = 'uint8';
  nt = floor(tmpfs.bytes/nx/ny/nz);
 case {'_16BIT_SGN_INT'}
  dtype = 'int16';
  nt = floor(tmpfs.bytes/nx/ny/nz/2);
 case {'_32BIT_SGN_INT'}
  dtype = 'int32';
  nt = floor(tmpfs.bytes/nx/ny/nz/4);
end
if nt == 1,  SPLIT_IN_TIME = 0;  end
if strcmpi(reco.RECO_byte_order,'bigEndian'),
  machineformat = 'ieee-be';
else
  machineformat = 'ieee-le';
end


% check trasposition on reco
transpos = 0;
if isfield(reco,'RECO_transposition'),
  transpos = reco.RECO_transposition(1);
elseif isfield(reco,'RECO_transpose_dim'),
  transpos = reco.RECO_transpose_dim(1);
end
if any(transpos),
  if transpos == 1,
    % (x,y,z) --> (y,x,z)
    tmpx = nx;    tmpy = ny;
    nx   = tmpy;  ny   = tmpx;
    tmpx = xres;  tmpy = yres;
    xres = tmpy;  yres = tmpx;
  elseif transpos == 2,
    % (x,y,z) --> (x,z,y)
    tmpy = ny;    tmpz = nz;
    ny   = tmpz;  nz   = tmpy;
    tmpy = yres;  tmpz = zres;
    yres = tmpz;  zres = tmpy;
  elseif transpos == 3,
    % (x,y,z) --> (z,y,x)
    tmpx = nx;    tmpz = nz;
    nx   = tmpz;  nz   = tmpx;
    tmpx = xres;  tmpz = zres;
    xres = tmpz;  zres = tmpx;
  end
  clear tmpx tmpy tmpz
end


% READ IMAGE DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if VERBOSE > 0,
  fprintf('/2dseq[%dx%dx%d %d %s]...',nx,ny,nz,nt,dtype);
end
fid = fopen(TDSEQFILE,'rb',machineformat);
IMG = fread(fid,inf,sprintf('%s=>%s',dtype,dtype));
fclose(fid);
if nt > 1,
  IMG = reshape(IMG,[nx,ny,nz,nt]);
else
  IMG = reshape(IMG,[nx,ny,nz]);
end
RECOSZ = size(IMG);
if ~isempty(FLIPDIM),
  if VERBOSE > 0,
    tmpstr = 'XYZT';
    fprintf('flipping(%s)...',tmpstr(FLIPDIM));
  end
  for N = 1:size(FLIPDIM),
    IMG = flipdim(IMG,FLIPDIM(N));
  end
end
if ~isempty(IMGCROP),
  if VERBOSE > 0,
    fprintf('imgcrop[%d:%d %d:%d]...',...
            IMGCROP(1),IMGCROP(3)+IMGCROP(1)-1,...
            IMGCROP(2),IMGCROP(4)+IMGCROP(2)-1);
  end
  idx = [1:IMGCROP(3)] + IMGCROP(1) - 1;
  IMG = IMG(idx,:,:,:);
  idx = [1:IMGCROP(4)] + IMGCROP(2) - 1;
  IMG = IMG(:,idx,:,:);
end
if ~isempty(SLICROP),
  if VERBOSE > 0,
    fprintf('slicrop[%d:%d]',SLICROP(1),SLICROP(2)+SLICROP(1)-1);
  end
  idx = [1:SLICROP(2)] + SLICROP(1) - 1;
  IMG = IMG(:,:,idx,:);
end


% PREPARE HEADER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% use size() instead of nx/ny/nz/nt because of cropping
if nt > 1,
  % functional
  if SPLIT_IN_TIME > 0,
    if size(IMG,3) == 1 || EXPORT_AS_2D > 0,
      %dim = [2 size(IMG,1) size(IMG,2)];
      %pixdim = [2 xres yres];
      dim = [4 size(IMG,1) size(IMG,2) 1 1];
      pixdim = [3 xres yres zres];
    else
      dim = [4 size(IMG,1) size(IMG,2) size(IMG,3) 1];
      pixdim = [3 xres yres zres];
    end
  else
    if EXPORT_AS_2D & size(IMG,3) > 1,
      %dim = [3 size(IMG,1) size(IMG,2) size(IMG,4)];
      %pixdim = [2 xres yres];
      dim = [4 size(IMG,1) size(IMG,2) 1 size(IMG,4)];
      pixdim = [3 xres yres zres];
    else
      dim = [4 size(IMG,1) size(IMG,2) size(IMG,3) size(IMG,4)];
      pixdim = [3 xres yres zres];
    end
  end
else
  % anatomy
  if size(IMG,3) == 1 || EXPORT_AS_2D > 0,
    %dim = [2 size(IMG,1) size(IMG,2)];
    %pixdim = [2 xres yres];
    dim = [4 size(IMG,1) size(IMG,2) 1 1];
    pixdim = [3 xres yres zres];
  else
    %dim = [3 size(IMG,1) size(IMG,2) size(IMG,3)];
    dim = [4 size(IMG,1) size(IMG,2) size(IMG,3) 1];
    pixdim = [3 xres yres zres];
  end
end


HDR = hdr_init('dim',dim,'datatype',dtype,'pixdim',pixdim,'glmax',intmax('int16'));



% SET OUTPUTS, IF REQUIRED.  OTHERWISE SAVE TO FILES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout,
  varargout{1} = HDR;
  if nargout > 1,
    varargout{2} = IMG;
  end
else
  if VERBOSE > 0,
    fprintf(' saving to ''%s''(2D=%d,SplitInTime=%d)...',SAVEDIR,EXPORT_AS_2D,SPLIT_IN_TIME);
  end
  %if exist(fullfile(pwd,SAVEDIR),'dir') == 0,
  %  mkdir(pwd,SAVEDIR);
  %end
  if exist(SAVEDIR,'dir') == 0,
    mkdir(SAVEDIR);
  end
  if isempty(FILE_ROOT),
    if exist('Ses','var') & ~isempty(Ses),
      froot = sprintf('%s_%03d',Ses.name,ExpNo);
    else
      froot = subGetFileRoot(TDSEQFILE);
      if isempty(froot),
        froot = sprintf('anz');
      end
    end
  else
    froot = FILE_ROOT;
  end
  
  if nt > 1,
    subExportFunctional(SAVEDIR,froot,HDR,IMG,EXPORT_AS_2D,SPLIT_IN_TIME);
  else
    % anatomy
    if EXPORT_AS_2D > 0 & size(IMG,3) > 1,
      for S = 1:size(IMG,3),
        IMGFILE = sprintf('%s/%s_sl%03d.img',SAVEDIR,froot,S);
        HDRFILE = sprintf('%s/%s_sl%03d.hdr',SAVEDIR,froot,S);
        hdr_write(HDRFILE,HDR);
        fid = fopen(IMGFILE,'wb');
        fwrite(fid,IMG(:,:,S),class(IMG));
        fclose(fid);
      end
    else
      IMGFILE = sprintf('%s/%s.img',SAVEDIR,froot);
      HDRFILE = sprintf('%s/%s.hdr',SAVEDIR,froot);
      hdr_write(HDRFILE,HDR);
      fid = fopen(IMGFILE,'wb');
      fwrite(fid,IMG,class(IMG));
      fclose(fid);
    end
  end
  % write information as a text file
  subWriteInfo(SAVEDIR,froot,HDR,...
             TDSEQFILE,RECOSZ,[xres,yres,zres],EXPORT_AS_2D,SPLIT_IN_TIME,IMGCROP,SLICROP,FLIPDIM);
end


if VERBOSE > 0,
  fprintf(' done.\n');
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function froot = subGetFileRoot(TDSEQFILE)

try,
  tmpf = TDSEQFILE;
  for N=1:4, [tmpf scanno] = fileparts(tmpf);  end
  [tmpf,sesname,sesext] = fileparts(tmpf);
  sesname = sprintf('%s%s',sesname,sesext);
catch
  sesname = '';  scanno = '';
end

if ~isempty(scanno) & ~isempty(sesname),
  froot = sprintf('%s_scan%s',strrep(sesname,'.',''),scanno);
else
  froot = 'anz';
end

return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subExportFunctional(SAVEDIR,froot,HDR,IMG,EXPORT_AS_2D,SPLIT_IN_TIME)

if SPLIT_IN_TIME > 0,
  if EXPORT_AS_2D > 0 & size(IMG,3) > 1,
    for N = 1:size(IMG,4),
      for S = 1:size(IMG,3),
        IMGFILE = sprintf('%s/%s_%05d_sl%03d.img',SAVEDIR,froot,N,S);
        HDRFILE = sprintf('%s/%s_%05d_sl%03d.hdr',SAVEDIR,froot,N,S);
        hdr_write(HDRFILE,HDR);
        fid = fopen(IMGFILE,'wb');
        fwrite(fid,IMG(:,:,S,N),class(IMG));
        fclose(fid);
      end
    end
  else
    for N = 1:size(IMG,4),
      IMGFILE = sprintf('%s/%s_%05d.img',SAVEDIR,froot,N);
      HDRFILE = sprintf('%s/%s_%05d.hdr',SAVEDIR,froot,N);
      hdr_write(HDRFILE,HDR);
      fid = fopen(IMGFILE,'wb');
      fwrite(fid,IMG(:,:,:,N),class(IMG));
      fclose(fid);
    end
  end
else
  if EXPORT_AS_2D > 0 & size(IMG,3) > 1,
    for S = 1:size(IMG,3),
      IMGFILE = sprintf('%s/%s_sl%05d.img',SAVEDIR,froot,S);
      HDRFILE = sprintf('%s/%s_sl%05d.hdr',SAVEDIR,froot,S);
      hdr_write(HDRFILE,HDR);
      fid = fopen(IMGFILE,'wb');
      fwrite(fid,IMG(:,:,S,:),class(IMG));
      fclose(fid);
    end
  else
    IMGFILE = sprintf('%s/%s.img',SAVEDIR,froot);
    HDRFILE = sprintf('%s/%s.hdr',SAVEDIR,froot);
    hdr_write(HDRFILE,HDR);
    fid = fopen(IMGFILE,'wb');
    fwrite(fid,IMG(:,:,:,:),class(IMG));
    fclose(fid);
  end
end
  
  
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subWriteInfo(SAVEDIR,froot,HDR,TDSEQFILE,RECOSZ,XYZRES,EXPORT_AS_2D,SPLIT_IN_TIME,IMGCROP,SLICROP,FLIPDIM)

TXTFILE = sprintf('%s/%s_info.txt',SAVEDIR,froot);
fid = fopen(TXTFILE,'wt');
fprintf(fid,'date:     %s\n',datestr(now));
fprintf(fid,'program:  %s\n',mfilename);

fprintf(fid,'[input]\n');
fprintf(fid,'2dseq:    %s\n',TDSEQFILE);
fprintf(fid,'recosize: [');  fprintf(fid,' %d',RECOSZ); fprintf(fid,' ]\n');
fprintf(fid,'xyzres:   [');  fprintf(fid,' %g',XYZRES); fprintf(fid,' ] in mm\n');
fprintf(fid,'imgcrop:  [');
if ~isempty(IMGCROP),
  fprintf(fid,'%d %d %d %d',IMGCROP(1),IMGCROP(2),IMGCROP(3),IMGCROP(4));
end
fprintf(fid,'] as [x y w h]\n');
fprintf(fid,'slicrop:  [');
if ~isempty(SLICROP),
  fprintf(fid,'%d %d',SLICROP(1),SLICROP(2));
end
fprintf(fid,'] as [start n]\n');
fprintf(fid,'flipdim:  [');
if ~isempty(FLIPDIM),  fprintf(fid,' %d',FLIPDIM);  end
fprintf(fid,' ]\n');
fprintf(fid,'export_as_2d:  %d\n',EXPORT_AS_2D);
fprintf(fid,'split_in_time: %d\n',SPLIT_IN_TIME);

fprintf(fid,'[output]\n');
fprintf(fid,'dim:      [');  fprintf(fid,' %d',HDR.dime.dim(2:end));  fprintf(fid,' ]\n');
fprintf(fid,'pixdim:   [');  fprintf(fid,' %g',HDR.dime.pixdim(2:end));  fprintf(fid,' ] in mm\n');
fprintf(fid,'datatype: %d',HDR.dime.datatype);
switch HDR.dime.datatype
 case 1
  dtype =  'binary';
 case 2
  dtype =  'char';
 case 4
  dtype =  'int16';
 case 8
  dtype =  'int32';
 case 16
  dtype =  'float';
 case 32
  dtype =  'complex';
 case 64
  dtype =  'double';
 case 128
  dtype =  'rgb';
 otherwise
  dtype =  'unknown';
end
fprintf(fid,'(%s)\n',dtype);

fclose(fid);

return

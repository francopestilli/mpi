function varargout = pvread_visu_pars(varargin)
%PVREAD_VISU_PARS - Read ParaVision "visu_pars".
%  VISUPARS = PVREAD_VISU_PARS(VISUPARSFILE,...)
%  VISUPARS = PVREAD_VISU_PARS(2DSEQFILE,...)
%  VISUPARS = PVREAD_VISU_PARS(SESSION,EXPNO,...)  reads ParaVision's "visu_pars" and 
%  returns its contents as a structre, VISUPARS.
%  Unknown parameter will be returned as a string.
%
%  Supported options are
%    'verbose' : 0|1, verbose or not.
%
%  VERSION :
%    0.90 16.04.08 YM  pre-release, checked epi/mdeft/rare/flash of 7T.
%    0.91 18.09.08 YM  supports both new csession and old getses.
%
%  See also pv_imgpar pvread_2dseq pvread_acqp pvread_imnd pvread_method pvread_reco

if nargin == 0,  help pvread_visu_pars; return;  end


if ischar(varargin{1}) & ~isempty(strfind(varargin{1},'visu_pars')),
  % Called like pvread_visu_pars(VISUFILE)
  VISUFILE = varargin{1};
  ivar = 2;
elseif ischar(varargin{1}) & ~isempty(strfind(varargin{1},'2dseq')),
  % Called like pvread_visu_pars(2DSEQFILE)
  VISUFILE = fullfile(fileparts(varargin{1}),'visu_pars');
  ivar = 2;
else
  % Called like pvread_visu_pars(SESSION,ExpNo)
  if nargin < 2,
    error(' ERROR %s: missing 2nd arg. as ExpNo.\n',mfilename);
    return;
  end
  if exist('csession','class'),
    ses = csession(varargin{1});
    VISUFILE = ses.filename(varargin{2},'visu_pars');
  else
    ses = goto(varargin{1});
    VISUFILE = catfilename(ses,varargin{2},'visu_pars');
  end
  ivar = 3;
end


% SET OPTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
VERBOSE = 1;
for N = ivar:2:nargin,
  switch lower(varargin{N}),
   case {'verbose'}
    VERBOSE = varargin{N+1};
  end
end


if ~exist(VISUFILE,'file'),
  if VERBOSE,
    fprintf(' ERROR %s: ''%s'' not found.\n',mfilename,VISUFILE);
  end
  % SET OUTPUTS, IF REQUIRED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if nargout,
    varargout{1} = [];
    if nargout > 1,  varargout{2} = {};  end
  end
  return;
end


% READ TEXT LINES OF "VISU_PARS" %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
texts = {};
fid = fopen(VISUFILE,'rt');
while ~feof(fid),
  texts{end+1} = fgetl(fid);
  %texts{end+1} = fgets(fid);
end
fclose(fid);



% MAKE "visu" structure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
visu.filename  = VISUFILE;

visu.VisuVersion             = [];
visu.isuUid                  = '';
visu.VisuCreator             = '';
visu.VisuCreatorVersion      = '';
visu.VisuCreationDate        = '';
visu.VisuCoreFrameCount      = [];
visu.VisuCoreDim             = [];
visu.VisuCoreSize            = [];
visu.VisuCoreDimDesc         = '';
visu.VisuCoreExtent          = [];
visu.VisuCoreFrameThickness  = [];
visu.VisuCoreUnits           = '';
visu.VisuCoreOrientation     = [];
visu.VisuCorePosition        = [];
visu.VisuCoreDataMin         = [];
visu.VisuCoreDataMax         = [];
visu.VisuCoreDataOffs        = [];
visu.VisuCoreDataSlope       = [];
visu.VisuCoreFrameType       = '';
visu.VisuCoreWordType        = '';
visu.VisuCoreByteOrder       = '';
visu.VisuFGOrderDescDim      = [];
visu.VisuFGOrderDesc         = '';
visu.VisuGroupDepVals        = '';
visu.VisuSubjectName         = '';
visu.VisuSubjectId           = '';
visu.VisuSubjectBirthDate    = '';
visu.VisuSubjectSex          = '';
visu.VisuSubjectComment      = '';
visu.VisuStudyUid            = '';
visu.VisuStudyDate           = '';
visu.VisuStudyId             = '';
visu.VisuStudyNumber         = [];
visu.VisuSubjectWeight       = [];
visu.VisuStudyReferringPhysician = '';
visu.VisuStudyDescription    = '';
visu.VisuSeriesNumber        = [];
visu.VisuSubjectPosition     = '';
visu.VisuSeriesTypeId        = '';
visu.VisuAcqSoftwareVersion  = [];
visu.VisuInstitution         = '';
visu.VisuStation             = '';
visu.VisuAcqDate             = '';
visu.VisuAcqEchoTrainLength  = [];
visu.VisuAcqSequenceName     = '';
visu.VisuAcqNumberOfAverages = [];
visu.VisuAcqImagingFrequency = [];
visu.VisuAcqImagedNucleus    = '';
visu.VisuAcqRepetitionTime   = [];
visu.VisuAcqPhaseEncSteps    = [];
visu.VisuAcqPixelBandwidth   = [];
visu.VisuAcqFlipAngle        = [];
visu.VisuAcqSize             = [];
visu.VisuAcqImageSizeAccellerated = '';
visu.VisuAcqImagePhaseEncDir = '';
visu.VisuAcqEchoTime         = [];
visu.VisuAcquisitionProtocol = '';
visu.VisuAcqScanTime         = [];

% for MDEFT
visu.VisuCoreDiskSliceOrder  = '';
visu.VisuAcqInversionTime    = [];




% GET "visu_pars" VALUES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for N = 1:length(texts),
  if strncmpi(texts{N},'##$',3),
    % get the parameter name
    idx = strfind(texts{N},'=');
    tmpname = texts{N}(4:idx-1);
    % get the value(s)
    if isempty(strfind(texts{N},'=(')), 
      tmpval = texts{N}(idx+1:end);
      tmpdim = [];
    else
      s1 = strfind(texts{N},'(');
      s2 = strfind(texts{N},')');
      if isempty(s2),
        tmpdim = [];
        tmpval = texts{N}(s1:end);
      else
        % get dimension
        tmpdim = str2num(texts{N}(s1+1:s2-1));
        tmpval = '';
      end
      K = N;
      while ~strncmpi(texts{K+1},'##',2),
        K = K + 1;
      end
      % USE sprintf() since strcat remove blank...
      if isempty(tmpdim),
        tmpval = sprintf('%s',tmpval,texts{N+1:K});
      else
        tmpval = sprintf('%s ',tmpval,texts{N+1:K});
      end
      %tmpval = strcat(texts{N+1:K});
      N = K + 1;
    end

    % WHY?? THIS HAPPENS
    idx = strfind(tmpval,'$$');
    if ~isempty(idx),  tmpval = tmpval(1:idx-1);  end
    
    % set the value(s)
    tmpval = strtrim(tmpval);
    if isfield(visu,tmpname),
      if ischar(visu.(tmpname)),
        if any(tmpdim) && tmpval(1) ~= '<',
          visu.(tmpname) = subStr2CellStr(tmpval,tmpdim);
        else
          visu.(tmpname) = tmpval;
        end
      elseif isnumeric(visu.(tmpname)),
        visu.(tmpname) = str2num(tmpval);
        if length(tmpdim) > 1 & prod(tmpdim) == numel(visu.(tmpname)),
          visu.(tmpname) = reshape(visu.(tmpname),fliplr(tmpdim));
          visu.(tmpname) = permute(visu.(tmpname),length(tmpdim):-1:1);
        end
      else
        visu.(tmpname) = tmpval;
      end
    else
      visu.(tmpname) = tmpval;
    end
  end
end

% after care of some parameters....
%visu.xxxx = subStr2CellNum(visu.xxxx);

% remove empty members
fields = fieldnames(visu);
IDX = zeros(1,length(fields));
for N = 1:length(fields),  IDX(N) = isempty(visu.(fields{N}));  end
visu = rmfield(visu,fields(find(IDX)));




% SET OUTPUTS, IF REQUIRED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout,
  varargout{1} = visu;
  if nargout > 1,
    varargout{2} = texts;
  end
end

return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCITON to make a cell string from a 'space' or '()' separeted string
function val = subStr2CellStr(str,dim)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(str) || iscell(str),
  val = str;
  return;
end

if nargin < 2, dim = [];  end

val = {};

if str(1) == '(',
  idx1 = strfind(str,'(');
  idx2 = strfind(str,')');
  for N = 1:length(idx1),
    val{N} = strtrim(str(idx1(N)+1:idx2(N)-1));
  end
else
  % 'space' separated
  [token, rem] = strtok(str,' ');
  while ~isempty(token),
    val{end+1} = token;
    [token, rem] = strtok(rem,' ');
  end
end

if length(dim) > 1 && prod(dim) > 0,
  val = reshape(val,dim);
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCITON to make a cell matrix from a '()' separeted string
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function val = subStr2CellNum(str)
if isempty(str),
  val = str;
  return;
end

idx1 = strfind(str,'(');
idx2 = strfind(str,')');

val = {};
for N = 1:length(idx1),
  val{N} = str2num(str(idx1(N)+1:idx2(N)-1));
end

return;

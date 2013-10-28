function varargout = pvread_method(varargin)
%PVREAD_METHOD - Read ParaVision "method".
%  METHOD = PVREAD_METHOD(METHODFILE,...)
%  METHOD = PVREAD_METHOD(2DSEQFILE,...)
%  METHOD = PVREAD_METHOD(SESSION,EXPNO,...)  reads ParaVision's "method" and 
%  returns its contents as a structre, METHOD. 
%  Unknown parameter will be returned as a string.
%
%  Supported options are
%    'verbose' : 0|1, verbose or not.
%
%  VERSION :
%    0.90 26.03.08 YM  pre-release, checked epi/mdeft/rare/flash of 7T.
%    0.91 18.09.08 YM  supports both new csession and old getses.
%    0.92 15.01.09 YM  supports some new parameters
%
%  See also pv_imgpar pvread_2dseq pvread_acqp pvread_imnd pvread_reco pvread_visu_pars

if nargin == 0,  help pvread_method; return;  end


if ischar(varargin{1}) & ~isempty(strfind(varargin{1},'method')),
  % Called like pvread_method(METHODFILE)
  METHODFILE = varargin{1};
  ivar = 2;
elseif ischar(varargin{1}) & ~isempty(strfind(varargin{1},'2dseq')),
  % Called like pvread_method(2DSEQFILE)
  METHODFILE = fullfile(fileparts(fileparts(fileparts(varargin{1}))),'method');
  ivar = 2;
else
  % Called like pvread_method(SESSION,ExpNo)
  if nargin < 2,
    error(' ERROR %s: missing 2nd arg. as ExpNo.\n',mfilename);
    return;
  end
  if exist('csession','class'),
    ses = csession(varargin{1});
    METHODFILE = ses.filename(varargin{2},'method');
  else
    ses = goto(varargin{1});
    METHODFILE = catfilename(ses,varargin{2},'method');
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


if ~exist(METHODFILE,'file'),
  if VERBOSE,
    fprintf(' ERROR %s: ''%s'' not found.\n',mfilename,METHODFILE);
  end
  % SET OUTPUTS, IF REQUIRED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if nargout,
    varargout{1} = [];
    if nargout > 1,  varargout{2} = {};  end
  end
  return;
end


% READ TEXT LINES OF "METHOD" %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
texts = {};
fid = fopen(METHODFILE,'rt');
while ~feof(fid),
  texts{end+1} = fgetl(fid);
  %texts{end+1} = fgets(fid);
end
fclose(fid);



% MAKE "method" structure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
method.filename  = METHODFILE;

method.Method             = '';
method.EchoTime           = [];
method.PVM_MinEchoTime    = [];
method.NSegments          = [];
method.PVM_RepetitionTime = [];
method.PackDel            = [];
method.PVM_NAverages      = [];
method.PVM_NRepetitions   = [];
method.PVM_ScanTimeStr    = '';
method.SignalType         = '';
method.PVM_UserType       = '';
method.PVM_DeriveGains    = '';
method.PVM_EncUseMultiRec = '';
method.PVM_EncActReceivers= '';
method.PVM_EncZfRead      = [];
method.PVM_EncPpiAccel1   = [];
method.PVM_EncPftAccel1   = [];
method.PVM_EncPpiRefLines1= [];
method.PVM_EncZfAccel1    = [];
method.PVM_EncOrder1      = '';
method.PVM_EncStart1      = [];
method.PVM_EncMatrix      = [];
method.PVM_EncSteps1      = [];
method.PVM_EncCentralStep1= [];
method.PVM_EncTotalAccel  = [];
method.PVM_EncNReceivers  = [];
method.PVM_EncAvailReceivers = [];
method.PVM_EncChanScaling = [];
method.PVM_OperationMode  = '';
method.ExcPulseEnum       = '';
method.ExcPulse           = '';
method.RefPulseEnum       = '';
method.RefPulse           = '';
method.PVM_GradCalConst   = [];
method.PVM_Nucleus1Enum   = '';
method.PVM_Nucleus1       = '';
method.PVM_RefAttMod1     = '';
method.PVM_RefAttCh1      = [];
method.PVM_RefAttStat1    = '';
method.PVM_Nucleus2Enum   = '';
method.PVM_Nucleus3Enum   = '';
method.PVM_Nucleus4Enum   = '';
method.PVM_Nucleus5Enum   = '';
method.PVM_Nucleus6Enum   = '';
method.PVM_Nucleus7Enum   = '';
method.PVM_Nucleus8Enum   = '';
method.RephaseTime        = [];
method.PVM_EffSWh         = [];
method.PVM_EpiNavigatorMode='';
method.PVM_EpiPrefixNavYes= '';
method.PVM_EpiGradSync    = '';
method.PVM_EpiRampMode    = '';
method.PVM_EpiRampForm    = '';
method.PVM_EpiRampComp    = '';
method.PVM_EpiNShots      = [];
method.PVM_EpiEchoPosition= [];
method.PVM_EpiRampTime    = [];
method.PVM_EpiSlope       = [];
method.PVM_EpiEffSlope    = [];
method.PVM_EpiBlipTime    = [];
method.PVM_EpiSwitchTime  = [];
method.PVM_EpiEchoDelay   = [];
method.PVM_EpiModuleTime  = [];
method.PVM_EpiGradDwellTime=[];
method.PVM_EpiAutoGhost   = '';
method.PVM_EpiAcqDelayTrim= [];
method.PVM_EpiBlipAsym    = [];
method.PVM_EpiReadAsym    = [];
method.PVM_EpiReadDephTrim= [];
method.PVM_EpiEchoTimeShifting='';
method.PVM_EpiEchoShiftA  = [];
method.PVM_EpiEchoShiftB  = [];
method.PVM_EpiDriftCorr   = '';
method.PVM_EpiGrappaThresh= [];
method.PVM_EpiEchoSpacing = [];
method.PVM_EpiEffBandwidth= [];
method.PVM_EpiDephaseTime = [];
method.PVM_EpiDephaseRampTime= [];
method.PVM_EpiPlateau     = [];
method.PVM_EpiAcqDelay    = [];
method.PVM_EpiInterTime   = [];
method.PVM_EpiReadDephGrad = [];
method.PVM_EpiReadOddGrad = [];
method.PVM_EpiReadEvenGrad= [];
method.PVM_EpiPhaseDephGrad= [];
method.PVM_EpiPhaseRephGrad= [];
method.PVM_EpiBlipOddGrad = [];
method.PVM_EpiBlipEvenGrad= [];
method.PVM_EpiPhaseEncGrad= [];
method.PVM_EpiPhaseRewGrad= [];
method.PVM_EpiNEchoes     = [];
method.PVM_EpiEchoCounter = [];
method.PVM_EpiRampUpIntegral= [];
method.PVM_EpiRampDownIntegral= [];
method.PVM_EpiBlipIntegral= [];
method.PVM_EpiSlopeFactor = [];
method.PVM_EpiSlewRate    = [];
method.PVM_EpiNSamplesPerScan = [];
method.PVM_EpiPrefixNavSize = [];
method.PVM_EpiPrefixNavDur= [];
method.PVM_EpiNScans      = [];
method.PVM_EpiNInitNav    = [];
method.PVM_EpiAdjustMode  = [];
method.PVM_EpiReadCenter  = [];
method.PVM_EpiPhaseCorrection = [];
method.PVM_EpiGrappaCoefficients = [];
method.BwScale            = [];
method.PVM_TrajectoryMeasurement = '';
method.PVM_UseTrajectory  = '';
method.PVM_ExSliceRephaseTime = [];
method.SliceSpoilerDuration = [];
method.SliceSpoilerStrength = [];
method.PVM_DigAutSet      = '';
method.PVM_DigQuad        = '';
method.PVM_DigFilter      = '';
method.PVM_DigRes         = [];
method.PVM_DigDw          = [];
method.PVM_DigSw          = [];
method.PVM_DigNp          = [];
method.PVM_DigShift       = [];
method.PVM_DigGroupDel    = [];
method.PVM_DigDur         = [];
method.PVM_DigEndDelMin   = [];
method.PVM_DigEndDelOpt   = [];
method.PVM_GeoMode        = '';
method.PVM_SpatDimEnum    = '';
method.PVM_Isotropic      = '';
method.PVM_Fov            = [];
method.PVM_FovCm          = [];
method.PVM_SpatResol      = [];
method.PVM_Matrix         = [];
method.PVM_MinMatrix      = [];
method.PVM_MaxMatrix      = [];
method.PVM_AntiAlias      = [];
method.PVM_MaxAntiAlias   = [];
method.PVM_SliceThick     = [];
method.PVM_ObjOrderScheme = '';
method.PVM_ObjOrderList   = [];
method.PVM_NSPacks        = [];
method.PVM_SPackArrNSlices= [];
method.PVM_MajSliceOri    = '';
method.PVM_SPackArrSliceOrient   = '';
method.PVM_SPackArrReadOrient    = '';
method.PVM_SPackArrReadOffset    = [];
method.PVM_SPackArrPhase1Offset  = [];
method.PVM_SPackArrPhase2Offset  = [];
method.PVM_SPackArrSliceOffset   = [];
method.PVM_SPackArrSliceGapMode  = '';
method.PVM_SPackArrSliceGap      = [];
method.PVM_SPackArrSliceDistance = [];
method.PVM_SPackArrGradOrient    = [];
method.Reco_mode          = '';
method.NDummyScans        = [];
method.PVM_TriggerModule  = '';
method.PVM_TaggingOnOff   = '';
method.PVM_TaggingPulse   = '';
method.PVM_TaggingDeriveGainMode = '';
method.PVM_TaggingMode    = '';
method.PVM_TaggingDir     = '';
method.PVM_TaggingDistance = [];
method.PVM_TaggingMinDistance = [];
method.PVM_TaggingThick   = [];
method.PVM_TaggingOffset1 = [];
method.PVM_TaggingOffset2 = [];
method.PVM_TaggingAngle   = [];
method.PVM_TaggingDelay   = [];
method.PVM_TaggingModuleTime = [];
method.PVM_TaggingPulseNumber = [];
method.PVM_TaggingPulseElement = [];
method.PVM_TaggingGradientStrength = [];
method.PVM_TaggingSpoilGrad = [];
method.PVM_TaggingSpoilDuration = [];
method.PVM_TaggingGridDelay = [];
method.PVM_TaggingD0      = [];
method.PVM_TaggingD1      = [];
method.PVM_TaggingD2      = [];
method.PVM_TaggingD3      = [];
method.PVM_TaggingD4      = [];
method.PVM_TaggingD5      = [];
method.PVM_TaggingP0      = [];
method.PVM_TaggingLp0     = [];
method.PVM_TaggingGradAmp1= [];
method.PVM_TaggingGradAmp2= [];
method.PVM_TaggingGradAmp3= [];
method.PVM_TaggingGradAmp4= [];
method.PVM_TaggingSpoiler = [];
method.PVM_FatSupOnOff    = '';
method.PVM_MagTransOnOff  = '';
method.PVM_FovSatOnOff    = '';
method.PVM_FovSatNSlices  = [];
method.PVM_FovSatSliceOrient = '';
method.PVM_FovSatThick    = [];
method.PVM_FovSatOffset   = [];
method.PVM_FovSatSliceVec = [];
method.PVM_SatSlicesPulseEnum = '';
method.PVM_SatSlicesPulse = '';
method.PVM_SatSlicesDeriveGainMode = '';
method.PVM_FovSatGrad     = [];
method.PVM_FovSatSpoilTime = [];
method.PVM_FovSatSpoilGrad = [];
method.PVM_FovSatModuleTime = [];
method.PVM_FovSatFL       = [];
method.PVM_SatD0          = [];
method.PVM_SatD1          = [];
method.PVM_SatD2          = [];
method.PVM_SatP0          = [];
method.PVM_SatLp0         = [];
method.PVM_TriggerOutOnOff = '';
method.PVM_TriggerOutMode = '';
method.PVM_TriggerOutDelay = [];
method.PVM_TrigOutD0      = [];
method.PVM_PreemphasisSpecial = '';
method.PVM_PreemphasisFileEnum = '';
method.PVM_EchoTime1      = [];
method.PVM_EchoTime2      = [];
method.PVM_EchoTime       = [];
method.PVM_NEchoImages    = [];

% for MDEFT
method.EchoRepTime        = [];
method.SegmRepTime        = [];
method.SegmDuration       = [];
method.SegmNumber         = [];
method.PVM_InversionTime  = [];
method.PVM_EchoPosition   = [];
method.SequenceOptimizationMode = '';
method.EchoPad            = [];
method.RFSpoilerOnOff     = '';
method.SpoilerDuration    = [];
method.SpoilerStrength    = [];
method.NDummyEchoes       = [];
method.Mdeft_PreparationMode    = '';
method.Mdeft_ExcPulseEnum       = '';
method.Mdeft_ExcPulse           = '';
method.Mdeft_InvPulseEnum       = '';
method.Mdeft_InvPulse           = '';
method.Mdeft_PrepDeriveGainMode = '';
method.Mdeft_PrepSpoilTime      = [];
method.Mdeft_PrepMinSpoilTime   = [];
method.Mdeft_PrepSpoilGrad      = [];
method.Mdeft_PrepModuleTime     = [];
method.PVM_ppgMode1             = [];
method.PVM_ppgFreqList1Size     = [];
method.PVM_ppgFreqList1         = [];
method.PVM_ppgGradAmp1          = [];

% for RARE
method.EffectiveTE              = [];
method.PVM_RareFactor           = [];
method.PVM_SliceBandWidthScale  = [];
method.PVM_ReadDephaseTime      = [];
method.PVM_2dPhaseGradientTime  = [];
method.PVM_EvolutionOnOff       = '';
method.PVM_SelIrOnOff           = '';
method.PVM_FatSupprPulseEnum    = '';
method.PVM_FatSupprPulse        = '';
method.PVM_FatSupDeriveGainMode = '';
method.PVM_FatSupBandWidth      = [];
method.PVM_FatSupSpoilTime      = [];
method.PVM_FatSupSpoilGrad      = [];
method.PVM_FatSupModuleTime     = [];
method.PVM_FatSupFL             = [];
method.PVM_FsD0                 = [];
method.PVM_FsD1                 = [];
method.PVM_FsD2                 = [];
method.PVM_FsP0                 = [];
method.PVM_InFlowSatOnOff       = '';
method.PVM_InFlowSatNSlices     = [];
method.PVM_InFlowSatThick       = [];
method.PVM_InFlowSatGap         = [];
method.PVM_InFlowSatSide        = [];
method.PVM_FlowSatPulse         = '';
method.PVM_FlowSatDeriveGainMode= '';
method.PVM_InFlowSatSpoilTime   = [];
method.PVM_InFlowSatSpoilGrad   = [];
method.PVM_InFlowSatModuleTime  = [];
method.PVM_SfD0                 = [];
method.PVM_SfD1                 = [];
method.PVM_SfD2                 = [];
method.PVM_SfP0                 = [];
method.PVM_SfLp0                = [];
method.PVM_MotionSupOnOff       = '';
method.PVM_FlipBackOnOff        = '';

% for FLASH
method.PVM_MotionSupOnOff       = '';
method.EchoTimeMode             = '';
method.ReadSpoilerDuration      = [];
method.ReadSpoilerStrength      = [];
method.PVM_MovieOnOff           = '';
method.PVM_NMovieFrames         = [];
method.TimeForMovieFrames       = [];
method.PVM_BlBloodOnOff         = '';
method.PVM_ppgFlag1             = '';

% new parameters
method.RECO_wordtype            = '';
method.RECO_map_mode            = '';
method.RECO_map_percentile      = [];
method.RECO_map_error           = [];
method.RECO_map_range           = [];



% GET "method" VALUES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
    if isfield(method,tmpname),
      if ischar(method.(tmpname)),
        if any(tmpdim) && tmpval(1) ~= '<',
          method.(tmpname) = subStr2CellStr(tmpval,tmpdim);
        else
          method.(tmpname) = tmpval;
        end
      elseif isnumeric(method.(tmpname)),
        method.(tmpname) = str2num(tmpval);
        if length(tmpdim) > 1 & prod(tmpdim) == numel(method.(tmpname)),
          method.(tmpname) = reshape(method.(tmpname),fliplr(tmpdim));
          method.(tmpname) = permute(method.(tmpname),length(tmpdim):-1:1);
        end
      else
        method.(tmpname) = tmpval;
      end
    else
      method.(tmpname) = tmpval;
    end
  end
end

% after care of some parameters....
%method.xxxx = subStr2CellStr(method.xxxx);


% remove empty members
fields = fieldnames(method);
IDX = zeros(1,length(fields));
for N = 1:length(fields),  IDX(N) = isempty(method.(fields{N}));  end
method = rmfield(method,fields(find(IDX)));




% SET OUTPUTS, IF REQUIRED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout,
  varargout{1} = method;
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

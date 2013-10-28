function varargout = pvread_reco(varargin)
%PVREAD_RECO - Read PraVision "reco".
%  RECO = PVREAD_RECO(RECOFILE,...)
%  RECO = PVREAD_RECO(2DSEQFILE,...)
%  RECO = PVREAD_RECO(SESSION,EXPNO,...)  reads ParaVision's "reco" and returns
%  its contents as a structre, RECO.
%  Unknown parameter will be returned as a string.
%
%  Supported options are
%    'verbose' : 0|1, verbose or not.
%
%  VERSION :
%    0.90 13.06.05 YM  pre-release
%    0.91 27.02.07 YM  supports also 2dseq as the first argument
%    0.92 26.03.08 YM  returns empty data if file not found.
%    0.93 18.09.08 YM  supports both new csession and old getses.
%    0.94 15.01.09 YM  supports some new parameters.
%
%  See also pv_imgpar pvread_2dseq pvread_acqp pvread_imnd pvread_method pvread_visu_pars

if nargin == 0,  help pvread_reco; return;  end


if ischar(varargin{1}) & ~isempty(strfind(varargin{1},'reco')),
  % Called like pvread_reco(RECOFILE)
  RECOFILE = varargin{1};
  ivar = 2;
elseif ischar(varargin{1}) & ~isempty(strfind(varargin{1},'2dseq')),
  % Called like pvread_reco(2DSEQFILE)
  RECOFILE = fullfile(fileparts(varargin{1}),'reco');
  ivar = 2;
else
  % Called like pvread_reco(SESSION,ExpNo)
  if exist('csession','class'),
    ses = csession(varargin{1});
    RECOFILE = ses.filename(varargin{2},'reco');
  else
    ses = goto(varargin{1});
    RECOFILE = catfilename(ses,varargin{2},'reco');
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


if ~exist(RECOFILE,'file'),
  if VERBOSE,
    fprintf(' ERROR %s: ''%s'' not found.\n',mfilename,RECOFILE);
  end
  % SET OUTPUTS, IF REQUIRED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if nargout,
    varargout{1} = [];
    if nargout > 1,  varargout{2} = {};  end
  end
  return;
end


% READ TEXT LINES OF "RECO" %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
texts = {};
fid = fopen(RECOFILE,'rt');
while ~feof(fid),
  texts{end+1} = fgetl(fid);
  %texts{end+1} = fgets(fid);
end
fclose(fid);



% MAKE "reco" structure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
reco.filename  = RECOFILE;

reco.RECO_mode              = '';
reco.RECO_inp_order         = '';
reco.RECO_inp_size          = [];
reco.RECO_ft_size           = [];
reco.RECO_fov               = [];
reco.RECO_size              = [];
reco.RECO_offset            = [];
reco.RECO_regrid_mode       = '';
reco.RECO_regrid_offset     = [];
reco.RECO_ramp_gap          = [];
reco.RECO_ramp_time         = [];
reco.RECO_ne_mode           = '';
reco.RECO_ne_dist           = '';
reco.RECO_ne_dens           = '';
reco.RECO_ne_type           = '';
reco.RECO_ne_vals           = [];
reco.RECO_bc_mode           = '';
reco.RECO_bc_start          = [];
reco.RECO_bc_len            = [];
reco.RECO_dc_offset         = [];
reco.RECO_dc_divisor        = [];
reco.RECO_bc_coroff         = [];
reco.RECO_qopts             = '';
reco.RECO_wdw_mode          = '';
reco.RECO_lb                = [];
reco.RECO_sw                = [];
reco.RECO_gb                = [];
reco.RECO_sbs               = [];
reco.RECO_tm1               = [];
reco.RECO_tm2               = [];
reco.RECO_ft_mode           = '';
reco.RECO_pc_mode           = '';
reco.RECO_pc_lin            = {};
reco.RECO_rotate            = [];
reco.RECO_ppc_mode          = '';
reco.RECO_ref_image         = [];
reco.RECO_nr_supports       = [];
reco.RECO_sig_threshold     = [];
reco.RECO_ppc_degree        = [];
reco.RECO_ppc_coeffs        = [];
reco.RECO_dc_elim           = '';
reco.RECO_transposition     = [];
reco.RECO_image_type        = '';
reco.RECO_image_threshold   = [];
reco.RECO_ir_scale          = [];
reco.RECO_wordtype          = '';
reco.RECO_map_mode          = '';
reco.RECO_map_range         = [];
reco.RECO_map_percentile    = [];
reco.RECO_map_error         = [];
reco.RECO_globex            = [];
reco.RECO_minima            = [];
reco.RECO_maxima            = [];
reco.RECO_map_min           = [];
reco.RECO_map_max           = [];
reco.RECO_map_offset        = [];
reco.RECO_map_slope         = [];
reco.RECO_byte_order        = '';
reco.RECO_time              = '';
reco.RECO_abs_time          = [];
reco.RECO_base_image_uid    = '';
reco.GS_reco_display        = '';
reco.GS_image_type          = '';
reco.GO_reco_display        = '';
reco.GO_reco_each_nr        = '';
reco.GO_max_reco_mem        = [];

% new parameters
reco.RecoUserUpdate         = '';
reco.RecoNumInputChan       = [];
reco.RecoScaleChan          = [];
reco.RecoCombineMode        = '';
reco.RecoSortDim            = [];
reco.RecoSortSize           = [];
reco.RecoSortRange          = [];
reco.RecoSortSegment        = [];
reco.RecoSortMaps           = [];
reco.RecoGrappaAccelFactor  = [];
reco.RecoGrappaKernelRead   = [];
reco.RecoGrappaKernelPhase  = [];
reco.RecoGrappaNumRefRead   = [];
reco.RecoGrappaNumRefPhase  = [];
reco.RecoGrappaIncludeRefLines = '';
reco.RecoGrappaReadCenter   = [];
reco.RecoGrappaPhaseCenter  = [];
reco.RecoGrappaTruncThresh  = [];




% GET "reco" VALUES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
    if isfield(reco,tmpname),
      if ischar(reco.(tmpname)),
        if any(tmpdim) && tmpval(1) ~= '<',
          reco.(tmpname) = subStr2CellStr(tmpval,tmpdim);
        else
          reco.(tmpname) = tmpval;
        end
      elseif isnumeric(reco.(tmpname)),
        reco.(tmpname) = str2num(tmpval);
        if length(tmpdim) > 1 & prod(tmpdim) == numel(reco.(tmpname)),
          reco.(tmpname) = reshape(reco.(tmpname),fliplr(tmpdim));
          reco.(tmpname) = permute(reco.(tmpname),length(tmpdim):-1:1);
        end
      else
        reco.(tmpname) = tmpval;
      end
    else
      reco.(tmpname) = tmpval;
    end
  end
end

% after care of some parameters....
reco.RECO_pc_lin   = subStr2CellNum(reco.RECO_pc_lin);

% remove empty members
fields = fieldnames(reco);
IDX = zeros(1,length(fields));
for N = 1:length(fields),  IDX(N) = isempty(reco.(fields{N}));  end
reco = rmfield(reco,fields(find(IDX)));


% SET OUTPUTS, IF REQUIRED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout,
  varargout{1} = reco;
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

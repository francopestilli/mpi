function varargout = pvread_acqp(varargin)
%PVREAD_ACQP - Read ParaVision "acqp".
%  ACQP = PVREAD_ACQP(ACQPFILE,...)
%  ACQP = PVREAD_ACQP(2DSEQFILE,...)
%  ACQP = PVREAD_ACQP(SESSION,EXPNO,...)  reads ParaVision's "acqp" and 
%  returns its contents as a structre, ACQP.
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
%    0.94 15.01.09 YM  supports some new parameters
%
%  See also pv_imgpar pvread_2dseq pvread_imnd pvread_method pvread_reco pvread_visu_pars

if nargin == 0,  help pvread_acqp; return;  end


if ischar(varargin{1}) & ~isempty(strfind(varargin{1},'acqp')),
  % Called like pvread_acqp(ACQPFILE)
  ACQPFILE = varargin{1};
  ivar = 2;
elseif ischar(varargin{1}) & ~isempty(strfind(varargin{1},'2dseq')),
  % Called like pvread_acqp(2DSEQFILE)
  ACQPFILE = fullfile(fileparts(fileparts(fileparts(varargin{1}))),'acqp');
  ivar = 2;
else
  % Called like pvread_acqp(SESSION,ExpNo)
  if nargin < 2,
    error(' ERROR %s: missing 2nd arg. as ExpNo.\n',mfilename);
    return;
  end
  if exist('csession','class'),
    ses = csession(varargin{1});
    ACQPFILE = ses.filename(varargin{2},'acqp');
  else
    ses = goto(varargin{1});
    ACQPFILE = catfilename(ses,varargin{2},'acqp');
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


if ~exist(ACQPFILE,'file'),
  if VERBOSE,
    fprintf(' ERROR %s: ''%s'' not found.\n',mfilename,ACQPFILE);
  end
  % SET OUTPUTS, IF REQUIRED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if nargout,
    varargout{1} = [];
    if nargout > 1,  varargout{2} = {};  end
  end
  return;
end


% READ TEXT LINES OF "ACQP" %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
texts = {};
fid = fopen(ACQPFILE,'rt');
while ~feof(fid),
  texts{end+1} = fgetl(fid);
  %texts{end+1} = fgets(fid);
end
fclose(fid);



% MAKE "acqp" structure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
acqp.filename  = ACQPFILE;

acqp.PULPROG               = '';
acqp.GRDPROG               = '';
acqp.ACQ_experiment_mode   = '';
acqp.ACQ_user_filter       = '';
acqp.ACQ_DS_enabled        = '';
acqp.ACQ_switch_pll_enabled= '';
acqp.ACQ_preload           = [];
acqp.ACQ_dim               = [];
acqp.ACQ_dim_desc          = '';
acqp.ACQ_size              = [];
acqp.ACQ_ns_list_size      = [];
acqp.ACQ_ns                = [];
acqp.ACQ_phase_factor      = [];
acqp.ACQ_scan_size         = '';
acqp.NI                    = [];
acqp.NA                    = [];
acqp.NAE                   = [];
acqp.NR                    = [];
acqp.DS                    = [];
acqp.D                     = [];
acqp.P                     = [];
acqp.PL                    = [];
acqp.TPQQ                  = '';
acqp.DPQQ                  = '';
acqp.SW_h                  = [];
acqp.SW                    = [];
acqp.FW                    = [];
acqp.RG                    = [];
acqp.AQ_mod                = '';
acqp.DR                    = [];
acqp.PAPS                  = '';
acqp.PH_ref                = [];
acqp.ACQ_BF_enable         = '';
acqp.BF1                   = [];
acqp.SFO1                  = [];
acqp.O1                    = [];
acqp.ACQ_O1_list_size      = [];
acqp.ACQ_O1_list           = [];
acqp.ACQ_O1B_list_size     = [];
acqp.ACQ_O1B_list          = [];
acqp.BF2                   = [];
acqp.SFO2                  = [];
acqp.O2                    = [];
acqp.ACQ_O2_list_size      = [];
acqp.ACQ_O2_list           = [];
acqp.BF3                   = [];
acqp.SFO3                  = [];
acqp.O3                    = [];
acqp.ACQ_O3_list_size      = [];
acqp.ACQ_O3_list           = [];
acqp.BF4                   = [];
acqp.SFO4                  = [];
acqp.O4                    = [];
acqp.BF5                   = [];
acqp.SFO5                  = [];
acqp.O5                    = [];
acqp.BF6                   = [];
acqp.SFO6                  = [];
acqp.O6                    = [];
acqp.BF7                   = [];
acqp.SFO7                  = [];
acqp.O7                    = [];
acqp.BF8                   = [];
acqp.SFO8                  = [];
acqp.O8                    = [];
acqp.NUC1                  = '';
acqp.NUC2                  = '';
acqp.NUC3                  = '';
acqp.NUC4                  = '';
acqp.NUC5                  = '';
acqp.NUC6                  = '';
acqp.NUC7                  = '';
acqp.NUC8                  = '';
acqp.NUCLEUS               = '';
acqp.ACQ_coil_config_file  = '';
acqp.ACQ_coils             = '';
acqp.ACQ_coil_elements     = '';
acqp.ACQ_operation_mode    = '';
acqp.ACQ_Routing           = '';
acqp.ACQ_routing_mode      = '';
acqp.L                     = [];
acqp.ACQ_vd_list_size      = [];
acqp.ACQ_vd_list           = [];
acqp.ACQ_vp_list_size      = [];
acqp.ACQ_vp_list           = [];
acqp.ACQ_status            = '';
acqp.ACQ_Routing_base      = '';
acqp.ACQ_protocol_location = '';
acqp.ACQ_protocol_name     = '';
acqp.ACQ_scan_name         = '';
acqp.ACQ_method            = '';
acqp.ACQ_completed         = '';
acqp.ACQ_pipe_status       = '';
acqp.ACQ_scans_completed   = [];
acqp.ACQ_nr_completed      = [];
acqp.ACQ_total_completed   = [];
acqp.ACQ_word_size         = '';
acqp.NECHOES               = [];
acqp.ACQ_n_echo_images     = [];
acqp.ACQ_n_movie_frames    = [];
acqp.ACQ_echo_descr        = '';
acqp.ACQ_movie_descr       = '';
acqp.ACQ_fov               = [];
acqp.ACQ_read_ext          = [];
acqp.ACQ_slice_angle       = [];
acqp.ACQ_slice_orient      = '';
acqp.ACQ_patient_pos       = '';
acqp.ACQ_read_offset       = [];
acqp.ACQ_phase1_offset     = [];
acqp.ACQ_phase2_offset     = [];
acqp.ACQ_slice_sepn        = [];
acqp.ACQ_slice_sepn_mode   = '';
acqp.ACQ_slice_thick       = [];
acqp.ACQ_slice_offset      = [];
acqp.ACQ_obj_order         = [];
acqp.ACQ_flip_angle        = [];
acqp.ACQ_flipback          = '';
acqp.ACQ_echo_time         = [];
acqp.ACQ_inter_echo_time   = [];
acqp.ACQ_recov_time        = [];
acqp.ACQ_repetition_time   = [];
acqp.ACQ_scan_time         = [];
acqp.ACQ_inversion_time    = [];
acqp.ACQ_temporal_delay    = [];
acqp.ACQ_time              = '';
acqp.ACQ_time_points       = [];
acqp.ACQ_abs_time          = [];
acqp.ACQ_operator          = '';
acqp.ACQ_RF_power          = [];
acqp.ACQ_transmitter_coil  = '';
acqp.ACQ_receiver_coil     = '';
acqp.ACQ_contrast_agent    = '';
acqp.ACQ_trigger_enable    = '';
acqp.ACQ_trigger_reference = '';
acqp.ACQ_trigger_delay     = [];
acqp.ACQ_institution       = '';
acqp.ACQ_station           = '';
acqp.ACQ_sw_version        = '';
acqp.ACQ_calib_date        = '';
acqp.ACQ_grad_str_X        = [];
acqp.ACQ_grad_str_Y        = [];
acqp.ACQ_grad_str_Z        = [];
acqp.ACQ_position_X        = [];
acqp.ACQ_position_Y        = [];
acqp.ACQ_position_Z        = [];
acqp.Coil_operation        = '';
acqp.BYTORDA               = '';
acqp.INSTRUM               = '';
acqp.ACQ_adc_overflow      = '';
acqp.GRPDLY                = [];
acqp.FRQLO3                = [];
acqp.FQ1LIST               = '';
acqp.FQ2LIST               = '';
acqp.FQ3LIST               = '';
acqp.FQ8LIST               = '';
acqp.SP                    = [];
acqp.SPOFFS                = [];
acqp.SPNAM0                = '';
acqp.SPNAM1                = '';
acqp.SPNAM2                = '';
acqp.SPNAM3                = '';
acqp.SPNAM4                = '';
acqp.SPNAM5                = '';
acqp.SPNAM6                = '';
acqp.SPNAM7                = '';
acqp.SPNAM8                = '';
acqp.SPNAM9                = '';
acqp.SPNAM10               = '';
acqp.SPNAM11               = '';
acqp.SPNAM12               = '';
acqp.SPNAM13               = '';
acqp.SPNAM14               = '';
acqp.SPNAM15               = '';
acqp.HPPRGN                = '';
acqp.LOCNUC                = '';
acqp.QNP                   = [];
acqp.SOLVENT               = '';
acqp.DIGMOD                = '';
acqp.DIGTYP                = '';
acqp.DQDMODE               = '';
acqp.DSPFIRM               = '';
acqp.DECIM                 = [];
acqp.DSPFVS                = [];
acqp.ACQ_scan_shift        = [];
acqp.DEOSC                 = [];
acqp.DE                    = [];
acqp.FCUCHAN               = [];
acqp.RSEL                  = [];
acqp.SWIBOX                = [];
acqp.HPMOD                 = [];
acqp.RECCHAN               = [];
acqp.RECSEL                = [];
acqp.RECPRE                = [];
acqp.NLOGCH                = [];
acqp.POWMOD                = '';
acqp.PRECHAN               = [];
acqp.PRECHRX               = [];
acqp.OBSCHAN               = [];
acqp.ACQ_2nd_preamp        = '';
acqp.ACQ_n_trim            = [];
acqp.ACQ_trim              = [];
acqp.ACQ_scaling_read      = [];
acqp.ACQ_scaling_phase     = [];
acqp.ACQ_scaling_slice     = [];
acqp.ACQ_grad_matrix       = [];
acqp.NSLICES               = [];
acqp.ACQ_rare_factor       = [];
acqp.ACQ_phase_encoding_mode = '';
acqp.ACQ_phase_enc_start   = [];
acqp.ACQ_spatial_size_1    = [];
acqp.ACQ_spatial_phase_1   = [];
acqp.GS_dim                = [];
acqp.GS_disp_update        = '';
acqp.GS_online_reco        = '';
acqp.GS_reco_display       = '';
acqp.GS_image_type         = '';
acqp.GS_typ                = '';
acqp.GS_auto_name          = '';
acqp.GS_info_dig_filling   = '';
acqp.GS_info_normalized_area = '';
acqp.GS_info_max_point     = '';
acqp.GS_get_info_points    = '';
acqp.GS_continue           = '';
acqp.GS_ReceiverSelect     = '';
acqp.GO_init_files         = '';
acqp.GO_data_save          = '';
acqp.GO_block_size         = '';
acqp.GO_raw_data_format    = '';
acqp.GO_disp_update        = '';
acqp.GO_online_reco        = '';
acqp.GO_reco_display       = '';
acqp.GO_reco_each_nr       = '';
acqp.GO_max_reco_mem       = [];
acqp.GO_time_est           = '';
acqp.GO_use_macro          = '';
acqp.GO_macro              = '';

% for MDEFT
acqp.ACQ_spatial_size_2    = [];

% new parameters






% GET "acqp" VALUES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
    if isfield(acqp,tmpname),
      if ischar(acqp.(tmpname)),
        if any(tmpdim) && tmpval(1) ~= '<',
          acqp.(tmpname) = subStr2CellStr(tmpval,tmpdim);
        else
          acqp.(tmpname) = tmpval;
        end
      elseif isnumeric(acqp.(tmpname)),
        acqp.(tmpname) = str2num(tmpval);
        if length(tmpdim) > 1 & prod(tmpdim) == numel(acqp.(tmpname)),
          acqp.(tmpname) = reshape(acqp.(tmpname),fliplr(tmpdim));
          acqp.(tmpname) = permute(acqp.(tmpname),length(tmpdim):-1:1);
        end
      else
        acqp.(tmpname) = tmpval;
      end
    else
      acqp.(tmpname) = tmpval;
    end
  end
end

% after care of some parameters....
%acqp.xxxx = subStr2CellNum(acqp.xxxx);


% remove empty members
fields = fieldnames(acqp);
IDX = zeros(1,length(fields));
for N = 1:length(fields),  IDX(N) = isempty(acqp.(fields{N}));  end
acqp = rmfield(acqp,fields(find(IDX)));


% SET OUTPUTS, IF REQUIRED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout,
  varargout{1} = acqp;
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

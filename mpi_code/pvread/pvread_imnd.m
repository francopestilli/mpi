function varargout = pvread_imnd(varargin)
%PVREAD_IMND - Read ParaVision "imnd".
%  IMND = PVREAD_IMND(IMNDFILE,...)
%  IMND = PVREAD_IMND(2DSEQFILE,...)
%  IMND = PVREAD_IMND(SESSION,EXPNO,...)  reads ParaVision's "imnd" and 
%  returns its contents as a structre, IMND. 
%  Unknown parameter will be returned as a string.
%
%  Supported options are
%    'verbose' : 0|1, verbose or not.
%
%  VERSION :
%    0.90 13.06.05 YM  pre-release
%    0.91 14.06.05 YM  checked both 'mdeft' and 'epi'.
%    0.92 27.02.07 YM  supports also 2dseq as the first argument
%    0.93 26.03.08 YM  returns empty data if file not found.
%    0.94 18.09.08 YM  supports both new csession and old getses.
%
%  See also pv_imgpar pvread_2dseq pvread_acqp pvread_method pvread_reco pvread_visu_pars

if nargin == 0,  help pvread_imnd; return;  end


if ischar(varargin{1}) & ~isempty(strfind(varargin{1},'imnd')),
  % Called like pvread_imnd(IMNDFILE)
  IMNDFILE = varargin{1};
  ivar = 2;
elseif ischar(varargin{1}) & ~isempty(strfind(varargin{1},'2dseq')),
  % Called like pvread_imnd(2DSEQFILE)
  IMNDFILE = fullfile(fileparts(fileparts(fileparts(varargin{1}))),'imnd');
  ivar = 2;
else
  % Called like pvread_imnd(SESSION,ExpNo)
  if nargin < 2,
    error(' ERROR %s: missing 2nd arg. as ExpNo.\n',mfilename);
    return;
  end
  if exist('csession','class'),
    ses = csession(varargin{1});
    IMNDFILE = ses.filename(varargin{2},'imnd');
  else
    ses = goto(varargin{1});
    IMNDFILE = catfilename(ses,varargin{2},'imnd');
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


if ~exist(IMNDFILE,'file'),
  if VERBOSE,
    fprintf(' ERROR %s: ''%s'' not found.\n',mfilename,IMNDFILE);
  end
  % SET OUTPUTS, IF REQUIRED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if nargout,
    varargout{1} = [];
    if nargout > 1,  varargout{2} = {};  end
  end
  return;
end


% READ TEXT LINES OF "IMND" %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
texts = {};
fid = fopen(IMNDFILE,'rt');
while ~feof(fid),
  texts{end+1} = fgetl(fid);
  %texts{end+1} = fgets(fid);
end
fclose(fid);



% MAKE "imnd" structure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
imnd.filename  = IMNDFILE;

imnd.IMND_method                 = '';
imnd.IMND_method_display_name    = '';
imnd.IMND_dummy_method           = '';
imnd.IMND_nucleus                = '';
imnd.IMND_matrix_eq              = [];
imnd.IMND_matrix                 = [];
imnd.IMND_sw_h                   = [];
imnd.IMND_scout_orient_matrix_curr = [];
imnd.IMND_scout_orient_matrix    = [];
imnd.IMND_rep_time               = [];
imnd.IMND_recov_time             = [];
imnd.IMND_echo_time              = [];
imnd.IMND_add_delay              = [];
imnd.IMND_homospoil_delay        = [];
imnd.IMND_pulse_angle            = [];
imnd.IMND_total_time             = [];
imnd.IMND_pulse_length           = [];
imnd.IMND_refocus_length         = [];
imnd.IMND_sat_pulse_length       = [];
imnd.IMND_n_averages             = [];
imnd.IMND_flipback               = '';
imnd.IMND_n_echo_images          = [];
imnd.IMND_echo_scan_eq           = [];
imnd.IMND_n_echoes               = [];
imnd.IMND_rare_factor            = [];
imnd.EPI_AQ_mod                  = '';
imnd.EPI_DIGMOD                  = '';
imnd.EPI_DSPFIRM                 = '';
imnd.EPI_max_read                = [];
imnd.IMND_max_read               = [];
imnd.EPI_int                     = [];
imnd.EPI_double                  = [];
imnd.EPI_diff_use_corr           = '';
imnd.EPI_supp_flag               = '';
imnd.EPI_trim                    = [];
imnd.EPI_scan_mode               = '';
imnd.EPI_TE_eff                  = [];
imnd.EPI_se_asymmetry_offset     = [];
imnd.EPI_read_spoiler            = [];
imnd.EPI_zero_phase              = [];
imnd.EPI_zero_phase_ms           = [];
imnd.EPI_seg_acq_time            = [];
imnd.EPI_image_time              = [];
imnd.EPI_even_only               = '';
imnd.EPI_read_echo_pos           = [];
imnd.EPI_phaseblip_asym          = [];
imnd.EPI_phasedur_asym           = [];
imnd.EPI_phaseblip_ms            = [];
imnd.EPI_phase_off               = '';
imnd.EPI_use_pipefilter          = '';
imnd.EPI_linear_regrid           = '';
imnd.IMND_regrid_mode            = '';
imnd.IMND_regrid_traj            = [];
imnd.EPI_correction_mode         = '';
imnd.EPI_navigation_type         = '';
imnd.EPI_ramp_time               = [];
imnd.EPI_ramp_gap                = [];
imnd.EPI_ramp_time_x             = [];
imnd.EPI_ramp_time_y             = [];
imnd.EPI_ramp_time_z             = [];
imnd.IMND_assym_acq              = [];
imnd.IMND_matched_bw             = '';
imnd.IMND_max_read               = [];
imnd.IMND_flow                   = [];
imnd.EPI_FID                     = '';
imnd.EPI_NAV_FIRST_NR            = '';
imnd.EPI_SE_DIFFUSION            = '';
imnd.EPI_SE_Inversion            = '';
imnd.EPI_SE_Tagging              = '';
imnd.EPI_SPIN_ECHO               = '';
imnd.EPI_STE_DIFFUSION           = '';
imnd.EPI_STIMULATED_ECHO         = '';
imnd.EPI_Not_TC                  = '';
imnd.EPI_Set_TC                  = '';
imnd.EPI_Set_TCnav               = '';
imnd.EPI_Set_TCnF                = '';
imnd.EPI_seg_grad                = [];
imnd.EPI_tagging_phase           = '';
imnd.EPI_tagging_read            = '';
imnd.EPI_O3_list_size            = [];
imnd.EPI_O6_list_size            = [];
imnd.EPI_O6_list                 = [];
imnd.Trigger_In_Once             = '';
imnd.Trigger_In_Every_Package    = '';
imnd.Trigger_In_Every_Excitation = '';
imnd.Trigger_Out_Once            = '';
imnd.Trigger_Out_Every_Package   = '';
imnd.Trigger_Out_Every_Excitation= '';
imnd.EPI_xfer_buffer_size        = [];
imnd.EPI_grad_cal_const          = [];
imnd.EPI_X_factor                = [];
imnd.EPI_Y_factor                = [];
imnd.EPI_Z_factor                = [];
imnd.EPI_status                  = '';
imnd.EPI_preemp_file             = '';
imnd.EPI_resid                   = '';
imnd.IMND_store_sw_h             = [];
imnd.EPI_SEG_CALC                = '';
imnd.EPI_Trigger_In              = '';
imnd.EPI_Trigger_Out             = '';
imnd.EPI_Pause_Trigger_Out       = '';
imnd.EPI_DS_enabled              = '';
imnd.EPI_recm_slice_rep_time     = [];
imnd.EPI_slice_rep_time          = [];
imnd.EPI_use_vd                  = '';
imnd.EPI_use_id                  = '';
imnd.EPI_use_Synch               = '';
imnd.EPI_TC_mode                 = '';
imnd.EPI_TimeToNav               = [];
imnd.EPI_TC_nslices              = [];
imnd.EPI_TC_DS                   = [];
imnd.EPI_nav_DS                  = [];
imnd.EPI_navAU_DS                = [];
imnd.EPI_n_navfids               = [];
imnd.EPI_n_navprep               = [];
imnd.EPI_n_navecho               = [];
imnd.EPI_TC_rep_time             = [];
imnd.EPI_TC_respFreq             = [];
imnd.EPI_dummy_echoes            = [];
imnd.EPI_ds_echopairs            = [];
imnd.EPI_recm_image_rep_time     = [];
imnd.EPI_image_rep_time          = [];
imnd.EPI_swh_eff_phase           = [];
imnd.EPI_segmentation_mode       = '';
imnd.IMND_numsegments            = [];
imnd.EPI_numsegments             = [];
imnd.EPI_nr                      = [];
imnd.EPI_act_rep_time            = [];
imnd.IMND_inv_delay_storage      = [];
imnd.IMND_num_segments           = [];
imnd.IMND_tau_time               = [];
imnd.IMND_MagPrep_mode           = '';
imnd.IMND_dim                    = [];
imnd.IMND_patient_pos            = '';
imnd.IMND_dimension              = '';
imnd.IMND_square_fov_matrix      = '';
imnd.IMND_isotropic              = '';
imnd.IMND_fov_eq                 = [];
imnd.IMND_fov                    = [];
imnd.IMND_slice_orient           = '';
imnd.IMND_n_slices               = [];
imnd.IMND_slice_offset           = [];
imnd.IMND_slice_sepn_mode        = '';
imnd.IMND_slice_sepn             = [];
imnd.IMND_slice_thick            = [];
imnd.IMND_slice_angle            = [];
imnd.IMND_slice_angle_eq         = [];
imnd.IMND_ScoutRel_SgRotAngle    = [];
imnd.IMND_ScoutRel_SgRotAngle_eq = [];
imnd.IMND_ScoutRel_SgTiltAngle   = [];
imnd.IMND_ScoutRel_SgTiltAngle_eq= [];
imnd.IMND_ScoutRel_RgRotAngle    = [];
imnd.IMND_ScoutRel_RgRotAngle_eq = [];
imnd.IMND_read_ext               = [];
imnd.IMND_read_offset            = [];
imnd.IMND_read_offset_eq         = [];
imnd.IMND_slice_scheme           = '';
imnd.IMND_slice_list             = [];
imnd.IMND_n_slicepacks           = [];
imnd.IMND_slicepack_n_slices     = [];
imnd.IMND_slicepack_vector       = [];
imnd.IMND_slicepack_position     = [];
imnd.IMND_slicepack_gap          = [];
imnd.IMND_read_vector            = [];
imnd.IMND_slicepack_read_offset  = [];
imnd.IMND_phase1_offset          = [];
imnd.IMND_phase2_offset          = [];
imnd.IMND_anti_alias             = [];
imnd.IMND_csind_flag             = '';
imnd.IMND_acq_mode               = '';
imnd.IMND_trigger_enable         = '';
imnd.IMND_auto_adv               = '';
imnd.IMND_evolution_trigger      = '';
imnd.IMND_movie                  = '';
imnd.IMND_mtc_mode               = '';
imnd.IMND_inv_mode               = '';
imnd.IMND_fat_mode               = '';
imnd.IMND_suppression            = '';
imnd.IMND_supp_shape_enum        = '';
imnd.IMND_supp_length            = [];
imnd.IMND_sat_mode               = '';
imnd.IMND_sat_shape              = '';
imnd.IMND_sat_slice_thick_hz     = [];
imnd.IMND_FovSat_n_slices        = [];
imnd.IMND_FovSat_thick           = [];
imnd.IMND_FovSat_offset          = [];
imnd.IMND_FovSat_dir_vector      = [];
imnd.IMND_FovSat_rot_angle       = [];
imnd.IMND_FovSat_tilt_angle      = [];
imnd.IMND_InflowSat_n_slices     = [];
imnd.IMND_InflowSat_thick        = [];
imnd.IMND_InflowSat_slice_offset = [];
imnd.IMND_contrast_agent         = '';
imnd.IMND_grad_refo              = '';
imnd.IMND_rf_spoil               = '';
imnd.IMND_use_grad               = [];
imnd.IMND_use_rise_time          = [];
imnd.IMND_max_spoil_time         = [];
imnd.IMND_imag_shape_enum        = '';
imnd.IMND_imag_shape             = '';
imnd.IMND_sl_thick_hz            = [];
imnd.IMND_acq_time               = [];
imnd.IMND_DW_time                = [];
imnd.IMND_rep_delay              = [];
imnd.IMND_nuc1                   = '';
imnd.IMND_bf1                    = [];
imnd.IMND_rcvr_offset_bc         = '';
imnd.IMND_isotropic_reco         = '';
imnd.IMND_zf                     = [];
imnd.IMND_apc                    = '';
imnd.IMND_phase_encoding_mode_1  = '';
imnd.IMND_phase_encoding_mode    = '';
imnd.IMND_phase_start_1          = [];
imnd.IMND_phase_enc_start        = [];
imnd.IMND_user_phase             = [];
imnd.IMND_dscan_time             = [];
imnd.IMND_dscans                 = [];
imnd.IMND_derive_gains           = '';
imnd.IMND_reference_gain         = [];
imnd.IMND_ref_gain_state         = '';
imnd.IMND_rg_defined             = '';
imnd.IMND_motionsup              = '';
imnd.IMND_EffEchoTime1           = [];
imnd.IMND_NEchoScan1             = [];
imnd.IMND_RareMaxEchoes          = [];
imnd.IMND_flowcomp               = '';
imnd.IMND_bandwidth_1            = [];
imnd.IMND_ScanSummary            = '';
imnd.IMND_invflag                = '';
imnd.IMND_mtcflag                = '';
imnd.IMND_fatflag                = '';
imnd.IMND_FovSat_flag            = [];
imnd.IMND_InflowSat_flag         = [];
imnd.IMND_TE_long                = '';



% GET "imnd" VALUES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
    if isfield(imnd,tmpname),
      if ischar(imnd.(tmpname)),
        if any(tmpdim) && tmpval(1) ~= '<',
          imnd.(tmpname) = subStr2CellStr(tmpval,tmpdim);
        else
          imnd.(tmpname) = tmpval;
        end
        imnd.(tmpname) = tmpval;
      elseif isnumeric(imnd.(tmpname)),
        imnd.(tmpname) = str2num(tmpval);
        if length(tmpdim) > 1 & prod(tmpdim) == numel(imnd.(tmpname)),
          imnd.(tmpname) = reshape(imnd.(tmpname),fliplr(tmpdim));
          imnd.(tmpname) = permute(imnd.(tmpname),length(tmpdim):-1:1);
        end
      else
        imnd.(tmpname) = tmpval;
      end
    else
      imnd.(tmpname) = tmpval;
    end
  end
end

% after care of some parameters....
%imnd.xxxx   = subStr2CellNum(imnd.xxxx);


% remove empty members
fields = fieldnames(imnd);
IDX = zeros(1,length(fields));
for N = 1:length(fields),  IDX(N) = isempty(imnd.(fields{N}));  end
imnd = rmfield(imnd,fields(find(IDX)));




% SET OUTPUTS, IF REQUIRED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout,
  varargout{1} = imnd;
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

function IMGP = pv_imgpar(varargin)
%PV_IMGPAR - Get ParaVision imaging parameters.
%  IMGP = PV_IMGPAR(IMGFILE,...)
%  IMGP = PV_IMGPAR(SESSION,EXPNO,...) gets ParaVision's imaging parameters.
%
%  Supported options are
%    'acqp'   : set acqp parameters, see pvread_acqp
%    'imnd'   : set imnd parameters, see pvread_imnd
%    'method' : set method parameters, see pvread_method
%    'reco'   : set reco parameters, see pvread_reco
%
%  VERSION :
%    0.90 29.08.08 YM  pre-release
%    0.91 18.09.08 YM  supports both new csession and old getses.
%    0.92 23.09.08 YM  bug fix on IMND_num_segments/_numsegmetns, RECO_transposition.
%
%  See also getpvpars pvread_2dseq pvread_acqp pvread_method pvread_reco

if nargin < 1,  eval(sprintf('help %s;',mfilename));  return;  end


if ischar(varargin{1}) & ~isempty(strfind(varargin{1},'2dseq')),
  % Called like pv_imgpar(2DSEQFILE)
  imgfile = varargin{1};
  ivar = 2;
else
  % Called like pv_imgpar(SESSION,ExpNo)
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
reco      = [];
acqp      = [];
imnd      = [];
method    = [];
for N = ivar:2:length(varargin),
  switch lower(varargin{N}),
   case {'reco'}
    reco = varargin{N+1};
   case {'acqp'}
    acqp = varargin{N+1};
   case {'imnd'}
    imnd = varargin{N+1};
   case {'method'}
    method = varargin{N+1};
  end
end

if isempty(reco),   reco   = pvread_reco(imgfile);    end
if isempty(acqp),   acqp   = pvread_acqp(imgfile);    end
if isempty(method), method = pvread_method(imgfile,'verbose',0);  end


%if isfield(acqp,'ACQ_method') && ~isempty(acqp.ACQ_method),
if isfield(method,'Method') && ~isempty(method.Method),
  f_PVM = 1;
else
  f_PVM = 0;
  if isempty(imnd),
    imnd = pvread_imnd(fullfile(fileparts(acqp.filename),'imnd'));
  end
end


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

dx = reco.RECO_fov(1)*10/nx;   % [mm]
dy = reco.RECO_fov(2)*10/ny;   % [mm]

if length(reco.RECO_fov) >= 3,
  ds = reco.RECO_fov(3)*10/ns;
else
  ds = mean(acqp.ACQ_slice_sepn);
  if ~any(ds),
    ds = acqp.ACQ_slice_thick;
  end
end


if strncmp(acqp.PULPROG, '<BLIP_epi',9) || strncmp(acqp.PULPROG, '<epi',4) || strncmp(acqp.PULPROG, '<mp_epi',7)
  nechoes = acqp.NECHOES;
else
  if acqp.ACQ_rare_factor > 0
    nechoes = acqp.NECHOES/acqp.ACQ_rare_factor;   % don't count echoes used for RARE phase encode
  else
    nechoes = acqp.NECHOES;
  end
end
nechoes = max([1 nechoes]);


if f_PVM == 1
  if isfield(method,'PVM_EpiNShots'),
    nseg = method.PVM_EpiNShots;			 
  else
    nseg = 1;
  end
  slitr	= acqp.ACQ_repetition_time/1000/acqp.NSLICES;  % [s]
  segtr	= acqp.ACQ_repetition_time/1000; 
  imgtr	= acqp.ACQ_repetition_time/1000*nseg;
  if isfield(method,'PVM_EchoTime'),
    effte	= method.PVM_EchoTime/1000;            % [s]
  elseif isfield(method,'EchoTime'),
    effte	= method.EchoTime/1000;            % [s]
  else
    effte   = 0;
  end
  recovtr = acqp.ACQ_recov_time(:)'/1000; % [s] for T1 series
else
  if isfield(imnd,'IMND_numsegments') && any(imnd.IMND_numsegments),
    nseg = imnd.IMND_numsegments;
  elseif isfield(imnd,'IMND_num_segments') && any(imnd.IMND_num_segments),
    nseg = imnd.IMND_num_segments;
  else
    nseg = 0;
  end
    
  % glitch for EPI
  if isfield(imnd,'EPI_segmentation_mode') && strcmpi(imnd.EPI_segmentation_mode,'No_Segments'),
    nseg = 1;
  end

  if strncmp(acqp.PULPROG, '<BLIP_epi',9)
    slitr	= imnd.EPI_slice_rep_time/1000;  %[s]
    
    % these values are NOT necessarily correct
    segtr	= imnd.IMND_rep_time;
    imgtr	= segtr * nseg;			% for TCmode !
    switch imnd.EPI_scan_mode,
     case 'FID',
      effte = imnd.EPI_TE_eff/1000;				% [s]
     case 'SPIN_ECHO',
      effte = imnd.IMND_echo_time/1000;
     case 'SE_Fair',
      effte	= imnd.IMND_echo_time/1000;				% [s]
     otherwise
      fprintf('!! Not yet implemented: acqp.EPI_scan_mode = %s !!\n\n', imnd.EPI_scan_mode);
    end
  else
    slitr	= imnd.IMND_rep_time;            % [s]
    segtr	= imnd.IMND_acq_time/1000;       % [s] 
    imgtr	= slitr;
    effte	= imnd.IMND_echo_time/1000;      % [s]
  end
  recovtr	= imnd.IMND_recov_time(:)'/1000;     % [s] for T1 series
end

% dummy scans
dummy_time = 0;  dummy_scan = 0;
if f_PVM == 1,
  if isfield(method,'NDummyScans'),
    dummy_scan = method.NDummyScans;
  elseif isfield(acqp,'DS'),
    dummy_scan = acqp.DS;
  end
  if isfield(acqp,'MP_DummyScanTime'),
    dummy_time = acqp.MP_DummyScanTime;
  else
    dummy_time = dummy_scan * segtr;
  end
else
  dummy_time = imnd.IMND_dscan_time;
  if isfield(imnd,'EPI_TC_mode') && strncmpi(imnd.EPI_TC_mode,'Set_TCnF',8),
    dummy_scan = imnd.EPI_navAU_DS;
  else
    dummy_scan = imnd.IMND_dscans;
  end
end

% transposition on reco
transpos = 0;
if isfield(reco,'RECO_transposition'),
  transpos = reco.RECO_transposition(1);
elseif isfield(reco,'RECO_transpose_dim'),
  transpos = reco.RECO_transpose_dim(1);
end


IMGP.imgsize      = [nx ny ns nt];
IMGP.dimsize      = [dx dy ds imgtr];
IMGP.dimunit      = {'mm','mm','mm','sec'};
IMGP.dimname      = {'x','y','slice','time'};
IMGP.fov          = reco.RECO_fov * 10;  % in mm
IMGP.res          = [dx dy];
IMGP.slithk       = acqp.ACQ_slice_thick;
IMGP.slioffset    = acqp.ACQ_slice_offset;
IMGP.slisepn      = acqp.ACQ_slice_sepn;
IMGP.nseg         = nseg;
IMGP.nechoes      = nechoes;
IMGP.slitr        = slitr;
IMGP.segtr        = segtr;
IMGP.imgtr        = imgtr;
IMGP.effte        = effte;
IMGP.recovtr      = recovtr;
IMGP.flip_angle   = 0;

IMGP.dummy_time   = dummy_time;
IMGP.dummy_scan   = dummy_scan;

IMGP.PULPROG      = acqp.PULPROG;
IMGP.ACQ_time     = acqp.ACQ_time;
IMGP.ACQ_abs_time = acqp.ACQ_abs_time;
IMGP.RECO_image_type = reco.RECO_image_type;
IMGP.RECO_byte_order = reco.RECO_byte_order;
IMGP.RECO_wordtype = reco.RECO_wordtype;
IMGP.RECO_transposition = transpos;

if isfield(acqp,'ACQ_flip_angle'),
  IMGP.flip_angle = acqp.ACQ_flip_angle;
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
  IMGP.imgsize(1:3) = IMGP.imgsize(tmpvec);
  IMGP.dimsize(1:3) = IMGP.dimsize(tmpvec);
  IMGP.dimname(1:3) = IMGP.dimname(tmpvec);
  %IMGP.res  = IMGP.dimsize([1 2]);
end


if nt == 1,
  IMGP.imgsize = IMGP.imgsize(1:3);
  IMGP.dimsize = IMGP.dimsize(1:3);
  IMGP.dimunit = IMGP.dimunit(1:3);
  IMGP.dimname = IMGP.dimname(1:3);
end


return

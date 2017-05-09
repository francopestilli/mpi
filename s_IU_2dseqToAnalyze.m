% Transform Bruker scan format (2dseq) to ANALYZE-7
%
% Notes:
%    - Set the qform_code or sform_code to 1 depending on whether the xform
%    is stored in the qt_xyz/ijk or sto_xyz/ijk
%    - bvecs and bvals should be saved as (3,nDirs) amd (1,nDirs) in dimensions.
%
% Copyright Franco Pestilli Indiana University 2017

% Move to the folder with NHP data
baseDir = '/N/dc2/projects/lifebid/franpest/';

% Base folder for each subjct
nhpDir      = '161223_M';% 'M00.yO1';
analyzeDir  = 'analyze';
niftiDir    = 'nifti';
niftiFolder = fullfile(baseDir,nhpDir,'7_anlz/raw');
scantoload  = 7;
dwiFile_name = sprintf('%s_scan%i_FULLDATA.nii.gz', nhpDir,scantoload);
anatFile = fullfile(baseDir,nhpDir,'anat','t1_from_fs_RAS.nii.gz');
b_fileName = fullfile(niftiFolder, sprintf('%s_scan%i',nhpDir,scantoload));
bvecs_file = [b_fileName '.bvecs'];
bvals_file = [b_fileName '.bvals'];

% Build an analyze file froma Bruker file
nhpMpiBrukerBuildAnalyze(scantoload,fullfile(baseDir,nhpDir),analyzeDir)

%% function nhpMpiBuildNiftiFromAnalyze(analyzeFiles,saveName)
% Build a 3D nifti file from the individual analyze files
cd(fullfile(baseDir,nhpDir,'analyze',sprintf('scan00%i', scantoload)))
ni = niftiRead(sprintf('%s_scan%i_00001.img', nhpDir, scantoload));

% We open on file at the time
sz3d = size(ni.data);
ni.data = nan(sz3d(1),sz3d(2),sz3d(3),61*length(scantoload));
c = 1;
for fi = 1:61
    if fi < 10
        thisfile = sprintf('%s_scan%i_0000%i.hdr', nhpDir,scantoload,fi);
    else
        thisfile = sprintf('%s_scan%i_000%i.hdr', nhpDir,scantoload,fi);
    end
    fprintf('Loading file: %s\n',thisfile)
    ni_temp = niftiRead(thisfile);
    % We append the data into the first opened file
    ni.data(:,:,:,c) = ni_temp.data;
    c = c + 1;
end

% We update the header information
% Notice, the headers in the analyze files do not have the corect center.
% Build that here.
ni.fname = dwiFile_name;
ni.dim   = size(ni.data);
ni.qform_code = 1; % the qto_* fields contain the xForm information
ni.slice_dim  = 3;
ni.phase_dim  = 2;
ni.freq_dim   = 1;
ni.slice_start=0;
ni.slice_end  =size(ni.data,3)-1;

% Save the nifti file just created, one folder up
if ~(exist(niftiFolder,'dir') == 7)
  mkdir(niftiFolder);
end
p = pwd; 
cd(niftiFolder)
niftiWrite(ni)
cd(p)

% === >>> END nhpMpiBuildNiftiFromAnalyze <<< === %

%% Build the bvecs
c=1;
% Build the gradients information fromt he Bruker 'method' file
method_fname = fullfile(baseDir,nhpDir,sprintf('%i/method',scantoload));
[bvecs,bvals,dw] = nhpMpiBrukerBuildDiffusionGradients(method_fname);

all_bvecs = horzcat(bvecs);
all_bvals = horzcat(bvals);

% Write out the bvals and bvecs

dlmwrite(bvecs_file,all_bvecs,' ');
dlmwrite(bvals_file,all_bvals,' ');

%% Reconstruct the T1 anatomical file
niAnat = niftiRead( anatFile );

%% Preprocess the file
%res = floor(100*ni.pixdim(1:3))./100;
res = [.5,.5,.5]; 
dwParams = dtiInitParams(...
    'clobber',1, ...
    'phaseEncodeDir',2, ...
    'bvecsFile',bvecs_file, ...
    'bvalsFile',bvals_file, ...
    'dt6BaseName','dti_trilin', ...
    'outDir', pwd, ...
    'dwOutMm', res ...
);

dtiInit(dwiFile_name,anatFile, dwParams)

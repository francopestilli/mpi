% This script tests how to flip the dimensions of the analyze files before
% building the nifti file that we use with mr diffusion.
%
% Really the only way to test that the nifti file was build the way we want
% it is to run the process all the way down to dtiInit and tractography.
%
% Only by looking at the tracts generated using the tensor fit we can
% understand whether the nifti were build correctly.
%
% Franco (c) Stanford Vista Team 2012

% Move to the folder with NHP data
baseDir = '/azure/scr1/frk/nhp';

% Base folder for each subjct
nhpDir      =  'M00.yO1';
analyzeDir  = fullfile('analyze','scan0020');
niftiDir    = 'nifti';
niftiFolder = fullfile(baseDir,nhpDir,'scan20/raw');
nFiles      = 68; % this is the number fo analuze files inside a folder, 
                  % each analyze file is one volume acuired of diffusion
                  % weighted or b0-signal
analyzeName = 'M00yO1_scan20_00001.img';

% We assume that the analyzefiles were created already.
% To build an analyze file from a Bruker file use: 
% nhpMpiBrukerBuildAnalyze(20,fullfile(baseDir,nhpDir),analyzeDir)

% Now we build the nifti file by loadin a bunch of analyze files.
analyzeFile = fullfile(baseDir,nhpDir,analyzeDir,analyzeName);
[dw_name,~,ni] = nhpMpiBuildNiftiFromAnalyze(analyzeFile,nFiles);
 
% This is the critical step. After we build the nifti file we need to check
% whether the x,y or z dimension needs to be flipped.
%
% If one of the dimensions needs to be flipped the same flipping needs to
% be applied to the bvecs. See below.
%
% First lets try without swapping dimensions.


% Save the nifti file just created, one folder up
if ~(exist(niftiFolder,'dir') == 7)
  mkdir(niftiFolder);
end
p = pwd; 
cd(niftiFolder)
niftiWrite(ni)
cd(p)

% Build the bvecs
% Build the gradients information fromt he Bruker 'method' file
method_fname = fullfile(baseDir,nhpDir,sprintf('%s/method','20'));
[bvecs,bvals,dw] = nhpMpiBrukerBuildDiffusionGradients(method_fname);

% Write out the bvals and bvecs
b_fileName = fullfile(p, dw_name(1:end-7));
dlmwrite([b_fileName '.bvecs'],bvecs,' ');
dlmwrite([b_fileName '.bvals'],bvals,' ');

% Reconstruct the T1 anatomical file
cd(fullfile(baseDir, 'M00.yO1','analyze','scan0024'))
ni             = niftiRead('M00yO1_scan24.hdr');
ni.fname       = [ni.fname(1:end-4),'_t1.nii.gz'];
ni.qform_code  = 1; % the qto_* fields contain the xForm information
ni.slice_dim   = 3;
ni.phase_dim   = 2;
ni.freq_dim    = 1;
ni.slice_start = 0;
ni.slice_end   = size(ni.data,3)-1;

p = pwd; 
cd(niftiFolder)
niftiWrite(ni)
cd(p)

% Align first then save it and do dtiInit/
% http://white.stanford.edu/newlm/index.php/Anatomical-Processing

% Align the T1 to ACPC and resample to a predetermined Resolution.
% t1_name = 't1.nii.gz';
% mrAnatAverageAcpcNifti({'M00yO1_scan24_t1.nii.gz'},t1_name,[],ni.pixdim(1:3))
 
%% Preprocess the file
cd(niftiFolder)
dwParams = dtiInitParams('clobber',1,...
  'phaseEncodeDir',2, ...
  'dwOutMm',[1 1 1], ...
  'numBootStrapSamples',2);
dtiInit(dw_name,t1_name,dwParams)

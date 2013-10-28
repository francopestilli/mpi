%% Transform Bruker scan format (2dseq) to ANALYZE-7
%
% First attempt to debunk the bruker data from the MPI.
%
% Notes:
%    - Set the qform_code or sform_code to 1 depending on whether the xform
%    is stored in the qt_xyz/ijk or sto_xyz/ijk
%    - bvecs and bvals should be saved as (3,nDirs) amd (1,nDirs) in dimensions.
%
% Franco (c) Stanford Vista Team 2012

% Move to the folder with NHP data
baseDir = '/azure/scr1/frk/nhp';

% Base folder for each subjct
nhpDir    =  'M00.EM1';% 'M00.yO1';
analyzeDir = 'analyze';
niftiDir  = 'nifti';
niftiFolder = fullfile(baseDir,nhpDir,'scan40/raw');
scanstoload = {'40'};

% Build an analyze file froma Bruker file
nhpMpiBrukerBuildAnalyze(20,fullfile(baseDir,nhpDir),analyzeDir)

%% function nhpMpiBuildNiftiFromAnalyze(analyzeFiles,saveName)
% Build a 3D nifti file from the individual analyze files
cd(fullfile(baseDir,nhpDir,'analyze','scan0040'))
ni = niftiRead('M00EM1_scan40_00001.img');

% We open on file at the time
sz3d = size(ni.data);
ni.data = nan(sz3d(1),sz3d(2),sz3d(3),68*length(scanstoload));
c=1;
for is = 1:length(scanstoload)
  cd(fullfile(baseDir,nhpDir,'analyze',sprintf('scan00%s',scanstoload{is})));
  for fi = 1:68
    if fi < 10
      thisfile = sprintf('M00EM1_scan%s_0000%i.hdr',scanstoload{is},fi);
    else
      thisfile = sprintf('M00EM1_scan%s_000%i.hdr',scanstoload{is},fi);
    end
    fprintf('Loading file: %s\n',thisfile)
    ni_temp = niftiRead(thisfile);
    % We append the data into the first opened file
    ni.data(:,:,:,c) = ni_temp.data;
    c = c +1;
  end
end
% We update the header information
% Notice, the headers in the analyze files do not have the corect center.
% Build that here.
ni.fname = 'M00EM1_scan40.nii.gz';
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
%% END nhpMpiBuildNiftiFromAnalyze


% Build the bvecs
c=1;
for is = 1:length(scanstoload)
% Build the gradients information fromt he Bruker 'method' file
method_fname = fullfile(baseDir,nhpDir,sprintf('%s/method',scanstoload{is}));
[bvecs,bvals,dw] = nhpMpiBrukerBuildDiffusionGradients(method_fname);

all_bvecs = horzcat(bvecs);
all_bvals = horzcat(bvals);
end

% Write out the bvals and bvecs
b_fileName = fullfile(niftiFolder, 'M00EM1_scan40');
dlmwrite([b_fileName '.bvecs'],all_bvecs,' ');
dlmwrite([b_fileName '.bvals'],all_bvals,' ');

% Reconstruct the T1 anatomical file
cd(fullfile(baseDir, 'M00.yO1','analyze','scan0024'))
ni = niftiRead('M00yO1_scan24.hdr');
ni.fname = [ni.fname(1:end-4),'_t1.nii.gz'];
ni.qform_code = 1; % the qto_* fields contain the xForm information
ni.slice_dim  = 3;
ni.phase_dim  = 2;
ni.freq_dim   = 1;
ni.slice_start=0;
ni.slice_end  =size(ni.data,3)-1;

p = pwd; 
cd(niftiFolder)
niftiWrite(ni)
cd(p)

%% Preprocess the file
cd(niftiFolder)
dtiInit('M00EM1_scan40.nii.gz','M00yO1_scan24_t1.nii.gz')

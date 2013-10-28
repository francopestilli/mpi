function [fname,p, ni] = nhpMpiBuildNiftiFromAnalyze(analyzeFile,nFiles)
%
% Build a 3D nifti file from the individual analyze files
%
% analyzeFile = fullfile(baseDir,nhpDir,'analyze','scan0040','M00EM1_scan40_00001.img')
%

% Extract the path informatin from the analyzeFile.
[p,fname] = fileparts(analyzeFile);

% We rebuild the file name as a string
fname = fname(1:14);

% Load the first of many files
% We will use this as a template for the ehader information.
if exist(analyzeFile,'file')
    ni = niftiRead(analyzeFile);
else
  keyboard
end


% We open on file at the time
sz3d = size(ni.data);
ni.data = nan(sz3d(1),sz3d(2),sz3d(3),nFiles);
c=1;
for fi = 1:nFiles
  if fi < 10
    thisfile = fullfile(p,sprintf('%s0000%i.hdr',fname,fi));
  else
    thisfile = fullfile(p,sprintf('%s000%i.hdr',fname,fi));
  end
  fprintf('Loading file: %s\n',thisfile)
  ni_temp = niftiRead(thisfile);
  % We append the data into the first opened file
  ni.data(:,:,:,c) = ni_temp.data;
  c = c +1;
end

% We update the header information
% Notice, the headers in the analyze files do not have the corect center.
% Build that here.
fname    = sprintf('%snA%i.nii.gz',fname,nFiles);
ni.fname = fname;
ni.dim   = size(ni.data);
ni.qform_code = 1; % the qto_* fields contain the xForm information
ni.slice_dim  = 3;
ni.phase_dim  = 2;
ni.freq_dim   = 1;
ni.slice_start=0;
ni.slice_end  =size(ni.data,3)-1;
end

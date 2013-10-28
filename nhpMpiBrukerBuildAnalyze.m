function savedir = nhpMpiBrukerBuildAnalyze(scans,baseDir,saveDir)
%
%  Reconstruct one Bruker/MPI scan at the time. Saves an analyze file.
%  This is a wrapper around the MPI bru2analyze.m
%
% INPUTS:
%    scans     - A vector of scan indexes (1:n). These indexes refer to the
%                folders under baseDir/nhpDir.
%    baseDir   - This is the base directory where all the MPI data set reside, 
%                currently /azure/scr1/frk/nhp/<SUBJS> 
%    saveDir   - This is the folder where the analyze files will be saved.
%
% OUTPUTS
%   savedir    - Full-path to analyze file.
%
% Franco (c) Stanford Vista Team 2012


% Loop over the scans for the current subject and save out an analyze file.
for fi = length(scans) % Scan types
  twodseqFile = fullfile(baseDir,sprintf('%i',scans(fi)),'/pdata/1/2dseq'); 
  
  % Preprocess the Bruker scan only if it exists.
  if exist(twodseqFile,'file')
    % make a directory to save the ANALYZE file
    savedir     = fullfile(baseDir,saveDir,sprintf('scan00%i',scans(fi)));
    if ~isdir(savedir), mkdir(savedir); end
    
    fprintf('\n[%s] Saving analyze files: /*.hdr & *.img\n%s\n',mfilename, savedir);
    bru2analyze(twodseqFile, 'SaveDir',savedir);
  end
end

if nargout < 1, clear savedir;end
end
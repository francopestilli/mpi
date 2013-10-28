function rootPath = nhpMpiDwiRootPath(dataDir)
% Determine path to root of the NHP MPI code set.
%
%        rootPath = nhpMpiDwiRootPath;
%
% INPUTS:
%     dataDir - Logical. 
%             - 1, returns the path to the data dir which is:
%                  '/biac2/wandell2/data/diffusion/nhp'
%             - 0, returns the path to the code base which lives in
%                  vistaproj/mpi_nhp. Default is 0.
%
% This function MUST reside in the directory at the base of the nhpMpiDwi
% directory structure 
%
% Franco & Hiromasa (c) Stanford Vista Team 2012
if notDefined('dataDir'), dataDir = 0;end

if ~dataDir % Return path to code set
rootPath = which('nhpMpiDwiRootPath');
rootPath = fileparts(rootPath);
else
  rootPath = '/biac2/wandell2/data/diffusion/nhp/';
end

return

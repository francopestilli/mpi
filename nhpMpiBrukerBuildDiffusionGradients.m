function [bvecs,bvals,dw] = nhpMpiBrukerBuildDiffusionGradients(method_fname)
%
% Read the 'method' file from a the MPI Bruker scanner and build diffusion
% gradients informatation (bvecs and bvals).
%
% [bvecs,bvals,dw] = nhpMpiBrukerBuildDiffusionGradients(method_fname)
%
% INPUTS:
%   method_fname - the full path to a bruker 'method' file.
%
% OUTPUTS:
%   bvecs - 3xnBvecs vecotr containing the bvecs as expected by mrDiffusion.
%
%   bvals - 1xNbvecs vector of bvals, as epxceted by mrDiffusion
%
%   dw - a structure containing all the information rearding gradient
%        direction and bvals.
%
% See: http://filer.case.edu/vxs33/pvman/A/Docs/A06_MethDescr.pdf
%      http://filer.case.edu/vxs33/pvman/D/Docs/A13_MethProg.pdf
%
% Notes:
%    In an email Georgios A. Keliris he gave us the following
%    information regaridng the MPI-Bruker scan sequences:
%    - z (3rd dimension) in the image refers to the main filed (b0)
%    - The NHP head is positioned as follows:
%      z=H-F | x=A-P | y=R-L
%    - Gradeitns are most certainly stored as consecutie triplets:
%      [[x1,y,1z1],[x2,y2,z2],...,[xn,yn,zn]]
%    - Grdients are always normalized (PVM_DwDirectScale='yes')
%    - B0 and diffusion data are stored in the files as follows:
%      GAK: Based on the image (2dseg file). First volume respectively frame
%      1 to Slices is B0 and Slices+1 to 2xSlices is the diffusion image.
%      Example: Study: M00.yO1, Scan 20, frame 1 to 48 is B0 and frame 49
%      to 96 is diffusion image.
%
% Franco (c) Stanford Vista Team 2012

dw.bvals = [];dw.bvecs = [];

% Read the method file
mth = pvread_method(method_fname);

% Check that this was a Diffusion scan:
if ~strcmpi(mth.Method,'DtiEpi')
    error('[%s] This scan does not seem to be a DW scan.\n[PVM_DwMeasMode: %s].',mafilename,mth.PVM_DwMeasMode);
end

% Check whether the diffusion directions vectors are normalized to norm = 1.0
if ~strcmpi(mth.PVM_DwDirectScale,'no')
  warning('[%s] The diffusion directions were not set to be normalized to 1.\nThe resulting bvecs might be wrong.',mafilename);
end

% Number of average DW measurements
dw.nAverages = mth.PVM_DwNDiffExpEach;

% Get the number of diffusion directions acquired.
dw.nBvecs = str2double( mth.PVM_DwNDiffDir );

% Get the number of bvals acquired:
dw.nBvals = str2double( mth.PVM_DwAoImages );

% Get the bvalue sued for this scan
dw.bval = str2double( mth.PVM_DwBvalEach );

% No bulld the bvals
dw.bvals =repmat(dw.bval,dw.nBvals,3);

% The indices of the b0 measuements in the DWI data file can be figured out
% from the list of phases of the gradients. THe b0 measurements have
% 0-phase (I think).
dw.indicesb0 = find(str2num(mth.PVM_DwGradPhase) == 0);
dw.indices   = find(str2num(mth.PVM_DwGradPhase));

% The diffusion directions on a DW sequence on a bruker scanner are stroed
% in the struct variable: 'PVM_DwDir'
dw.bvecs = str2num(mth.PVM_DwDir);
dw.bvecs = reshape(dw.bvecs,3,dw.nBvecs)';

% Check that the vectors are unit length.
% If we organized the vectors corretly the dot product of the vector in the
% rows of bvecs with itself should be 1.
% This is valid onlyin the case in which 'PVM_DwDirectScale='no'. See
% above.
if ~all(round(dot(dw.bvecs,dw.bvecs,2)) == 1), keyboard; end

% Concatenate the bvecs and set the gradients for the bvals to zero
bvecs = zeros(3,size(dw.bvecs,1) + size(dw.bvals,1));
bvecs(:,dw.indices) = dw.bvecs';
% gradients (bvecs) are aligned in scanner space. Here we use the xform of
% the nifti to reorient them in image space:
%
% xfrom from scanner to image space
%xform = ni.qto_xyz;
%
% X-form the bvecs
%bvecs2       = xform*bvecs';
bvecNorm    = sqrt(sum(bvecs.^2));
nz          = bvecNorm~=0;
bvecs(:,nz) = bvecs(:,nz)./repmat(bvecNorm(nz),[3 1]);

bvals = zeros(size(dw.bvecs,1) + size(dw.bvals,1),1);
if (dw.bval > 10), divideby = 1000;
else               divideby = 1;end
bvals(dw.indices) = dw.bval/divideby;
bvals = bvals';

% Save out mrDiffusion bevecs/bvals files
%
% Scale the bvalues according to gradient magnitude. This assumes that the
% specified b-value is the max bvalue. Note that we only do this when all
% the bvec norms are 1 or less. If any of the bvec norms are >1, then we
% assume that the bvecs are just encoded sloppily and their norms do not
% really reflect the gradient amplitudes.
if( all(bvecNorm<=1) ), bvals = bvals.*bvecNorm.^2; end

return

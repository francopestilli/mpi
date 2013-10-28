function ni = nhpMpiSwapDimensions(ni,swapType)
%
% Sawp the dimensions of the nifti file created by loading a series of
% analzuse fiels from the rbuker scanner.
%
%  ni = nhpMpiSwapDimensions(ni,swapType)
%
% This might not be used. Still work in progress.
%
% Franco (c) Stanford Vista Team 2012

switch swapType
  case 'x'
  case 'y'
    [ni.data] = applyCannonicalXform(ni.data, img2std, ni.pixdim, insertMarkerFlag);
  case 'z'
    ni.data = applyCannonicalXform(ni.data, img2std, ni.pixdim, insertMarkerFlag);
  case 'xy'
    ni.data = applyCannonicalXform(ni.data, img2std, ni.pixdim, insertMarkerFlag);
  case 'xz'
    ni.data = applyCannonicalXform(ni.data, img2std, ni.pixdim, insertMarkerFlag);
  case 'yz'
    ni.data = applyCannonicalXform(ni.data, img2std, ni.pixdim, insertMarkerFlag);
  case 'xyz'
    ni.data = applyCannonicalXform(ni.data, img2std, ni.pixdim, insertMarkerFlag);
  otherwise
    keyboard
end
end

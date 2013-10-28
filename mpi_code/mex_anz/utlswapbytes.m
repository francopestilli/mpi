%UTLSWAPBYTES - swaps bytes of given data.
% SV = UTLSWAPBYTES(V) swaps bytes of V and returns the result.
% UTLSWAPBYTES(V) does the same thing but it will modify directly the original
% data V without allocating additional memory for the result.
% Input data V can be multi-dimesional, but its data class
% must be 2bytes or 4bytes type, ie. int16/uint16/int32/uint32/single.
%
% Usage: sv = utlswapbytes(v,[verbose=0|1])
% Notes: class of 'v' must be int16,uint16,int32,uint32,single.
%      : if nargout==0, then swaps 'v' directly.
% 
% To compile,
%   mex utlswapbytes.c
%
% VERSION :
%   0.90 2005.05.31 Yusuke MURAYAMA @MPI  first release.
%   0.91 2005.06.01 Yusuke MURAYAMA @MPI  if nargout==0, swap the original.
%
% See also CLASS, INT16, UINT16, INT32, UINT32, SINGLE

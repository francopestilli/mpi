%
% mexanz.m : batch file to make all mex DLLs.
%
% VERSION : 1.00  31-May-2005  YM
%         : 1.01  10-Jan-2006  YM  Matlab7.1 supports swapbytes()

% make_hdr
clear make_hdr;
mex make_hdr.c  -D_USE_IN_MATLAB

% swap_endian
clear utlswapbytes;
mex utlswapbytes.c


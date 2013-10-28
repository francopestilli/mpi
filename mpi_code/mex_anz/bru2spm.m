function varargout = bru2spm(varargin)
%BRU2SPM - dumps Brucker 2dseq as ANALIZE-7 format for SPM.
%  BRU2SPM() just calls BRU2ANALYZE function and remains to keep compatibility.
%  See BRU2ANALYZE for detail.
%
%  VERSION :
%    0.90 24.10.07 YM  renamed to bru2analyze.m
%
%  See also BRU2ANALYZE

if nargin == 0,  help bru2spm; return;  end

if nargout,
  varargout = bru2analyze(varargin{:});
else
  bru2analyze(varargin{:});
end

return

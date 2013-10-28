function varargout = anzview(varargin)
if nargout,
  varargout = anz_view(varargin{:});
else
  anz_view(varargin{:});
end

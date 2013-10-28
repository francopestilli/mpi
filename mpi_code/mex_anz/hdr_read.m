function HDR = hdr_read(filename)
%HDR_READ - reads ANALYZE header
%  HDR = HDR_READ(FILENAME) reads a header file of ANALYZE(TM).
%
%  For detail, see http://www.mayo.edu/bir/PDF/ANALYZE75.pdf
%
%  REQUIREMENT :
%    utlswapbytes.dll
%
%  VERSION :
%    0.90 31.05.05 YM  pre-release.
%    0.91 01.06.05 YM  modified for BRU2ANZ.
%    0.92 06.08.07 YM  bug fix, when big-endian.
%    0.93 29.04.08 YM  filename can be as .img
%
%  See also ANZ_READ, MAKE_HDR, UTLSWAPBYTES, DBH.H

if nargin == 0,  help hdr_read; return;  end

HDR = [];
if isempty(filename),  return;  end


[fp fn fe] = fileparts(filename);
if ~strcmpi(fe,'.hdr'),
  filename = fullfile(fp,sprintf('%s.hdr',fn));
end


if ~exist(filename,'file'),
  error('%s: ''%s'' not found.',mfilename,filename);
end

% check filesize
tmp = dir(filename);
if tmp.bytes < 4,
  fclose(fid);
  fprintf('\n %s ERROR: invalid file size[%d].',...
          mfilename,tmp.bytes);
  return;
end


BRU2ANZ = 1;

% open the file
fid = fopen(filename,'r');

% read "header_key"
HK.sizeof_hdr = fread(fid, 1, 'int32=>int32');
hsize = HK.sizeof_hdr;
if hsize > hex2dec('01000000'),  hsize = utlswapbytes(hsize);  end
if tmp.bytes < hsize,
  fclose(fid);
  fprintf('\n %s ERROR: file size[%d] is smaller than %dbytes.',...
          mfilename,tmp.bytes,hsize);
  return;
end
HK.data_type     = subConvStr(fread(fid,10, 'char'));
HK.db_name       = subConvStr(fread(fid,18, 'char'));
HK.extents       = fread(fid, 1, 'int32=>int32');
HK.session_error = fread(fid, 1, 'int16=>int16');
HK.regular       = subConvStr(fread(fid, 1, 'char'));
HK.hkey_un0      = fread(fid, 1, 'char');

% read "image_dimension"
DIME.dim         = fread(fid, 8, 'int16=>int16')';
if BRU2ANZ,
DIME.vox_units   = subConvStr(fread(fid, 4, 'char'));
DIME.cal_units   = subConvStr(fread(fid, 8, 'char'));
else
DIME.unused8     = fread(fid, 1, 'int16=>int16');
DIME.unused9     = fread(fid, 1, 'int16=>int16');
DIME.unused10    = fread(fid, 1, 'int16=>int16');
DIME.unused11    = fread(fid, 1, 'int16=>int16');
DIME.unused12    = fread(fid, 1, 'int16=>int16');
DIME.unused13    = fread(fid, 1, 'int16=>int16');
end
DIME.unused14    = fread(fid, 1, 'int16=>int16');
DIME.datatype    = fread(fid, 1, 'int16=>int16');
DIME.bitpix      = fread(fid, 1, 'int16=>int16');
DIME.dim_un0     = fread(fid, 1, 'int16=>int16');
DIME.pixdim      = fread(fid, 8, 'single=>single')';
DIME.vox_offset  = fread(fid, 1, 'single=>single');
if BRU2ANZ,
DIME.roi_scale   = fread(fid, 1, 'single=>single');
else
DIME.funused1    = fread(fid, 1, 'single=>single');
end
DIME.funused2    = fread(fid, 1, 'single=>single');
DIME.funused3    = fread(fid, 1, 'single=>single');
DIME.cal_max     = fread(fid, 1, 'single=>single');
DIME.cal_min     = fread(fid, 1, 'single=>single');
DIME.compressed  = fread(fid, 1, 'single=>single');
DIME.verified    = fread(fid, 1, 'single=>single');
DIME.glmax       = fread(fid, 1, 'int32=>int32');
DIME.glmin       = fread(fid, 1, 'int32=>int32');

% read "data_history"
HIST.descrip     = subConvStr(fread(fid,80, 'char'));
HIST.aux_file    = subConvStr(fread(fid,24, 'char'));
HIST.orient      = fread(fid, 1, 'char');
HIST.originator  = subConvStr(fread(fid,10, 'char'));
HIST.generated   = subConvStr(fread(fid,10, 'char'));
HIST.scannum     = subConvStr(fread(fid,10, 'char'));
HIST.patient_id  = subConvStr(fread(fid,10, 'char'));
HIST.exp_date    = subConvStr(fread(fid,10, 'char'));
HIST.exp_time    = subConvStr(fread(fid,10, 'char'));
HIST.hist_un0    = subConvStr(fread(fid, 3, 'char'));
HIST.views       = fread(fid, 1, 'int32=>int32');
HIST.vols_added  = fread(fid, 1, 'int32=>int32');
HIST.start_field = fread(fid, 1, 'int32=>int32');
HIST.field_skip  = fread(fid, 1, 'int32=>int32');
HIST.omax        = fread(fid, 1, 'int32=>int32');
HIST.omin        = fread(fid, 1, 'int32=>int32');
HIST.smax        = fread(fid, 1, 'int32=>int32');
HIST.smin        = fread(fid, 1, 'int32=>int32');


% for debug, ftell(fid) should return 348
%ftell(fid)

% close the file
fclose(fid);

% return the structure
HDR.hk   = HK;		% header_key
HDR.dime = DIME;    % image_dimension
HDR.hist = HIST;	% data_history

% swap header's bytes, if needed.
if HDR.dime.dim(1) < 0 | HDR.dime.dim(1) > 15,
  HDR = subSwapHdr(HDR,BRU2ANZ);
end


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str = subConvStr(dat)
dat = dat(:)';
if any(dat)
  str = deblank(char(dat));
else
  str = '';
end

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function HDR = subSwapHdr(HDR,BRU2ANZ)
HDR.hk.sizeof_hdr    = utlswapbytes(HDR.hk.sizeof_hdr);
HDR.hk.extents       = utlswapbytes(HDR.hk.extents);
HDR.hk.session_error = utlswapbytes(HDR.hk.session_error);
HDR.dime.dim(1)      = utlswapbytes(HDR.dime.dim(1));
HDR.dime.dim(2)      = utlswapbytes(HDR.dime.dim(2));
HDR.dime.dim(3)      = utlswapbytes(HDR.dime.dim(3));
HDR.dime.dim(4)      = utlswapbytes(HDR.dime.dim(4));
HDR.dime.dim(5)      = utlswapbytes(HDR.dime.dim(5));
HDR.dime.dim(6)      = utlswapbytes(HDR.dime.dim(6));
HDR.dime.dim(7)      = utlswapbytes(HDR.dime.dim(7));
HDR.dime.dim(8)      = utlswapbytes(HDR.dime.dim(8));
HDR.dime.unused14    = utlswapbytes(HDR.dime.unused14);
HDR.dime.datatype    = utlswapbytes(HDR.dime.datatype);
HDR.dime.bitpix      = utlswapbytes(HDR.dime.bitpix);
HDR.dime.pixdim(1)   = utlswapbytes(HDR.dime.pixdim(1));
HDR.dime.pixdim(2)   = utlswapbytes(HDR.dime.pixdim(2));
HDR.dime.pixdim(3)   = utlswapbytes(HDR.dime.pixdim(3));
HDR.dime.pixdim(4)   = utlswapbytes(HDR.dime.pixdim(4));
HDR.dime.pixdim(5)   = utlswapbytes(HDR.dime.pixdim(5));
HDR.dime.pixdim(6)   = utlswapbytes(HDR.dime.pixdim(6));
HDR.dime.pixdim(7)   = utlswapbytes(HDR.dime.pixdim(7));
HDR.dime.pixdim(8)   = utlswapbytes(HDR.dime.pixdim(8));
HDR.dime.vox_offset  = utlswapbytes(HDR.dime.vox_offset);
if BRU2ANZ,
  HDR.dime.roi_scale       = utlswapbytes(HDR.dime.roi_scale);
else
  HDR.dime.funused1    = utlswapbytes(HDR.dime.funused1);
end
HDR.dime.funused2    = utlswapbytes(HDR.dime.funused2);
HDR.dime.cal_max     = utlswapbytes(HDR.dime.cal_max);
HDR.dime.cal_min     = utlswapbytes(HDR.dime.cal_min);
HDR.dime.compressed  = utlswapbytes(HDR.dime.compressed);
HDR.dime.verified    = utlswapbytes(HDR.dime.verified);
HDR.dime.dim_un0     = utlswapbytes(HDR.dime.dim_un0);
HDR.dime.glmax       = utlswapbytes(HDR.dime.glmax);
HDR.dime.glmin       = utlswapbytes(HDR.dime.glmin);

return;


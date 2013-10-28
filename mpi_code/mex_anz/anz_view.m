function varargout = anz_view(varargin)
%ANZ_VIEW - displays ANALYZE format images
%  ANZ_VIEW(IMGFILE,...) displays ANALYZE format images.
%
%  EXAMPLE :
%    >> anz_view('');
%    >> anz_view('D99_T1weighted.img');
%
%  VERSION :
%    0.90 02.05.08 YM   pre-release
%    0.91 05.05.08 YM   improved memory usage
%
%  See also anz_read anz_write

if nargin == 0,  help anz_view; return;  end

% execute callback function then return;
if ischar(varargin{1}) & ~isempty(findstr(varargin{1},'Callback')),
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
  return;
end


% DEFAULT CONTROL SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ANAP.anz_view.xxxx
ANAP.anz_view.anascale = [];
ANAP.anz_view.colormap = 'gray';
ANAP.anz_view.xreverse = 0;
ANAP.anz_view.yreverse = 0;
ANAP.anz_view.zreverse = 1;

IMGFILE = varargin{1};
for N = 2:2:length(varargin),
  switch lower(varargin{N}),
   case {'anascale','scale'}
    ANAP.anz_view.anascale = varargin{N+1};
   case {'cmap','colormap','color'}
    ANAP.anz_view.colormap = varargin{N+1};
   case {'xreverse'}
    ANAP.anz_view.xreverse = varargin{N+1};
   case {'yreverse'}
    ANAP.anz_view.yreverse = varargin{N+1};
   case {'zreverse'}
    ANAP.anz_view.zreverse = varargin{N+1};
  end
end


% GET SCREEN SIZE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
oldunits = get(0,'units');
set(0,'units','char');
SZscreen = get(0,'ScreenSize');
set(0,'units',oldunits);
scrW = SZscreen(3);  scrH = SZscreen(4);

figW = 175; figH = 55;
figX = 31;  figY = scrH-figH-5;

%[figX figY figW figH]


% CREATE A MAIN FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hMain = figure(...
    'Name',sprintf('%s: %s',mfilename,datestr(now)),...
    'NumberTitle','off', 'toolbar','figure',...
    'Tag','main', 'units','char', 'pos',[figX figY figW figH],...
    'HandleVisibility','on', 'Resize','on',...
    'DoubleBuffer','on', 'BackingStore','on', 'Visible','on',...
    'DefaultAxesFontSize',10,...
    'DefaultAxesFontName', 'Comic Sans MS',...
    'DefaultAxesfontweight','bold',...
    'PaperPositionMode','auto', 'PaperType','A4', 'PaperOrientation', 'landscape');



% WIDGETS TO ANALYZE FILE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XDSP = 10; H = figH - 2.5;
AnzFileTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H-0.3 30 1.5],...
    'String','FILE:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','AnzFileTxt',...
    'BackgroundColor',get(hMain,'Color'));
AnzFileEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+8 H 96 1.5],...
    'Callback','anz_view(''Main_Callback'',gcbo,''init'',guidata(gcbo))',...
    'String',IMGFILE,'Tag','AnzFileEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','ANALYZE file',...
    'FontWeight','Bold');
AnzReadBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[XDSP+105 H 15 1.5],...
    'Callback','anz_view(''Main_Callback'',gcbo,''browse-file'',guidata(gcbo))',...
    'Tag','AnzReadBtn','String','Browse...',...
    'TooltipString','browse a ANALYZE file','FontWeight','Bold');
% AnzSaveBtn = uicontrol(...
%     'Parent',hMain,'Style','PushButton',...
%     'Units','char','Position',[XDSP+106 H 15 1.5],...
%     'Callback','anz_view(''Main_Callback'',gcbo,''save-file'',guidata(gcbo))',...
%     'Tag','AnzSaveBtn','String','Save...',...
%     'TooltipString','save a ANALYZE file','FontWeight','Bold');

cmaps = {'gray','jet','autumn','hot','cool','bone','copper','pink','red','green','blue','yellow'};
idx = find(strcmpi(cmaps,ANAP.anz_view.colormap));
if isempty(idx),
  fprintf('WARNING %s: unknown colormap name ''%s''.\n',mfilename,ANAP.mview.colormap);
  idx = 1;
end
ColormapCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+123 H 15 1.5],...
    'Callback','anz_view(''Main_Callback'',gcbo,''update-cmap'',guidata(gcbo))',...
    'String',cmaps,'Value',idx,'Tag','ColormapCmb',...
    'TooltipString','Select colormap',...
    'FontWeight','bold');
clear cmaps idx;
AnaScaleEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+139 H 20 1.5],...
    'Callback','anz_view(''Main_Callback'',gcbo,''update-anascale'',guidata(gcbo))',...
    'String',deblank(sprintf('%g ',ANAP.anz_view.anascale)),'Tag','AnaScaleEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set anatomy scaling, [min max gamma]',...
    'FontWeight','bold');




% AXES for plots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% AXES FOR LIGHT BOX %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = 3; XSZ = 55; YSZ = 20;
XDSP=10;
LightiboxAxs = axes(...
    'Parent',hMain,'Tag','LightboxAxs',...
    'Units','char','Position',[XDSP H XSZ*2+12 YSZ*2+6.5],...
    'Box','off','color','black','Visible','off');




% AXES FOR ORTHOGONL VIEW %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = 28; XSZ = 55; YSZ = 20;
XDSP=10;
CoronalTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H+YSZ 20 1.5],...
    'String','Coronal (X-Z)','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','CoronalTxt',...
    'BackgroundColor',get(hMain,'Color'));
CoronalEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+22 H+YSZ+0.2 8 1.5],...
    'Callback','anz_view(''OrthoView_Callback'',gcbo,''edit-coronal'',guidata(gcbo))',...
    'String','','Tag','CoronalEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set coronal slice',...
    'FontWeight','Bold');
CoronalSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[XDSP+XSZ*0.6 H+YSZ+0.2 XSZ*0.4 1.2],...
    'Callback','anz_view(''OrthoView_Callback'',gcbo,''slider-coronal'',guidata(gcbo))',...
    'Tag','CoronalSldr','SliderStep',[1 4],...
    'TooltipString','coronal slice');
CoronalAxs = axes(...
    'Parent',hMain,'Tag','CoronalAxs',...
    'Units','char','Position',[XDSP H XSZ YSZ],...
    'Box','off','Color','black');
SagitalTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+10+XSZ H+YSZ 20 1.5],...
    'String','Sagital (Y-Z)','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','SagitalTxt',...
    'BackgroundColor',get(hMain,'Color'));
SagitalEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+10+XSZ+22 H+YSZ+0.2 8 1.5],...
    'Callback','anz_view(''OrthoView_Callback'',gcbo,''edit-sagital'',guidata(gcbo))',...
    'String','','Tag','SagitalEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set sagital slice',...
    'FontWeight','Bold');
SagitalSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[XDSP+10+XSZ*1.6 H+YSZ+0.2 XSZ*0.4 1.2],...
    'Callback','anz_view(''OrthoView_Callback'',gcbo,''slider-sagital'',guidata(gcbo))',...
    'Tag','SagitalSldr','SliderStep',[1 4],...
    'TooltipString','sagital slice');
SagitalAxs = axes(...
    'Parent',hMain,'Tag','SagitalAxs',...
    'Units','char','Position',[XDSP+10+XSZ H XSZ YSZ],...
    'Box','off','Color','black');


H = 3;
TransverseTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H+YSZ 20 1.5],...
    'String','Transverse (X-Y)','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','TransverseTxt',...
    'BackgroundColor',get(hMain,'Color'));
TransverseEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+22 H+YSZ+0.2 8 1.5],...
    'Callback','anz_view(''OrthoView_Callback'',gcbo,''edit-transverse'',guidata(gcbo))',...
    'String','','Tag','TransverseEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set transverse slice',...
    'FontWeight','Bold');
TransverseSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[XDSP+XSZ*0.6 H+YSZ+0.2 XSZ*0.4 1.2],...
    'Callback','anz_view(''OrthoView_Callback'',gcbo,''slider-transverse'',guidata(gcbo))',...
    'Tag','TransverseSldr','SliderStep',[1 4],...
    'TooltipString','transverse slice');
TransverseAxs = axes(...
    'Parent',hMain,'Tag','TransverseAxs',...
    'Units','char','Position',[XDSP H XSZ YSZ],...
    'Box','off','Color','black');

TriplotAxs = axes(...
    'Parent',hMain,'Tag','TriplotAxs',...
    'Units','char','Position',[XDSP+10+XSZ H XSZ YSZ],...
    'Box','off','color','white');





% VIEW MODE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = 28;
XDSP=XDSP+XSZ+7;
ViewModeCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+10+XSZ H+YSZ 32 1.5],...
    'Callback','anz_view(''Main_Callback'',gcbo,''view-mode'',guidata(gcbo))',...
    'String',{'orthogonal','lightbox-cor','lightbox-sag','lightbox-trans'},...
    'Tag','ViewModeCmb','Value',1,...
    'TooltipString','Select the view mode',...
    'FontWeight','bold');
ViewPageList = uicontrol(...
    'Parent',hMain,'Style','Listbox',...
    'Units','char','Position',[XDSP+10+XSZ H+10 32 9],...
    'String',{'page1','page2','page3','page4'},...
    'Callback','anz_view(''Main_Callback'',gcbo,''view-page'',guidata(gcbo))',...
    'HorizontalAlignment','left',...
    'FontName','Comic Sans MS','FontSize',9,...
    'Tag','ViewPageList','Background','white');


% INFORMATION TEXT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
InfoTxt = uicontrol(...
    'Parent',hMain,'Style','Listbox',...
    'Units','char','Position',[XDSP+10+XSZ H+2.5 32 7],...
    'String',{'session','group','datsize','resolution'},...
    'HorizontalAlignment','left',...
    'FontName','Comic Sans MS','FontSize',9,...
    'Tag','InfoTxt','Background','white');




% AXES FOR COLORBAR %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = 3;
ColorbarAxs = axes(...
    'Parent',hMain,'Tag','ColorbarAxs',...
    'units','char','Position',[XDSP+10+XSZ H XSZ*0.1 YSZ],...
    'FontSize',8,...
    'Box','off','YAxisLocation','right','XTickLabel',{},'XTick',[]);


% CHECK BOX FOR X,Y,Z direction %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XReverseCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+10+XSZ+15 H+YSZ/2 20 1.5],...
    'Tag','XReverseCheck','Value',ANAP.anz_view.xreverse,...
    'Callback','anz_view(''OrthoView_Callback'',gcbo,''dir-reverse'',guidata(gcbo))',...
    'String','X-Reverse','FontWeight','bold',...
    'TooltipString','Xdir reverse','BackgroundColor',get(hMain,'Color'));
YReverseCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+10+XSZ+15 H+YSZ/2-2.5 20 1.5],...
    'Tag','YReverseCheck','Value',ANAP.anz_view.yreverse,...
    'Callback','anz_view(''OrthoView_Callback'',gcbo,''dir-reverse'',guidata(gcbo))',...
    'String','Y-Reverse','FontWeight','bold',...
    'TooltipString','Ydir reverse','BackgroundColor',get(hMain,'Color'));
ZReverseCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+10+XSZ+15 H+YSZ/2-2.5*2 20 1.5],...
    'Callback','anz_view(''OrthoView_Callback'',gcbo,''dir-reverse'',guidata(gcbo))',...
    'Tag','ZReverseCheck','Value',ANAP.anz_view.zreverse,...
    'String','Z-Reverse','FontWeight','bold',...
    'TooltipString','Zdir reverse','BackgroundColor',get(hMain,'Color'));


% CHECK BOX FOR "cross-hair" %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CrosshairCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+10+XSZ+15 H+YSZ/2-7.5 20 1.5],...
    'Callback','anz_view(''OrthoView_Callback'',gcbo,''crosshair'',guidata(gcbo))',...
    'Tag','CrosshairCheck','Value',1,...
    'String','Crosshair','FontWeight','bold',...
    'TooltipString','show a crosshair','BackgroundColor',get(hMain,'Color'));





% get widgets handles at this moment
HANDLES = findobj(hMain);


% INITIALIZE THE APPLICATION
setappdata(hMain,'ANA',[]);
setappdata(hMain,'ANAP',ANAP);
Main_Callback(SagitalAxs,'init');
set(hMain,'visible','on');



% NOW SET "UNITS" OF ALL WIDGETS AS "NORMALIZED".
HANDLES = HANDLES(find(HANDLES ~= hMain));
set(HANDLES,'units','normalized');


% RETURNS THE WINDOW HANDLE IF REQUIRED.
if nargout,
  varargout{1} = hMain;
end





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Main_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(hObject);

switch lower(eventdata),
 case {'init'}

  IMGFILE = get(wgts.AnzFileEdt,'String');
  if isempty(IMGFILE),  return;  end
  
  if ~exist(IMGFILE,'file'),
    fprintf('\nERROR %s:  ''%s'' not found.\n',mfilename,IMGFILE);
  end

  [img hdr] = anz_read(IMGFILE);
  if ~ischar(hdr.dime.datatype),
    switch hdr.dime.datatype,
     case 1
      hdr.dime.datatype = 'binary';
     case 2
      hdr.dime.datatype = 'uint8';
     case 4
      hdr.dime.datatype = 'int16';
     case 8
      hdr.dime.datatype = 'int32';
     case 16
      hdr.dime.datatype = 'single';
     case 32
      hdr.dime.datatype = 'complex';
     case 64
      hdr.dime.datatype = 'double';
     case 128
      hdr.dime.datatype = 'rgb';
     otherwise
      hdr.dime.datatype = 'unknown';
    end
  end
  
  
  ANA.imgfile = IMGFILE;
  ANA.hdr     = hdr;
  ANA.dat     = img;
  ANA.ds      = hdr.dime.pixdim(2:4);
  clear hdr img;

  ANAP = getappdata(wgts.main,'ANAP');

  % converts ANA.dat into RGB
  anaminv = 0;
  anamaxv = 0;
  anagamma = 1.8;
  if isfield(ANAP,'anz_view') & isfield(ANAP.anz_view,'anascale') & ~ ...
        isempty(ANAP.anz_view.anascale),
    if length(ANAP.anz_view.anascale) == 1,
      anamaxv = ANAP.anz_view.anascale;
    else
      anaminv = ANAP.anz_view.anascale(1);
      anamaxv = ANAP.anz_view.anascale(2);
      if length(ANAP.anz_view.anascale) > 2,
        anagamma = ANAP.anz_view.anascale(3);
      end
    end
  end
  if anamaxv == 0,
    tmpana = double(ANA.dat);
    %anamaxv = round(mean(tmpana(:))*3.5);
    anamaxv = round(double(max(ANA.dat(:)))*0.7);
  end
  ANA.ana256 = subScaleAnatomy(ANA.dat,anaminv,anamaxv,anagamma);
  ANA.scale = [anaminv anamaxv anagamma];
  clear tmpana anaminv anamaxv anagamma;
  
  setappdata(wgts.main,'ANA',ANA);

  INFTXT = {};
  INFTXT{end+1} = sprintf('dim: [%s]',deblank(sprintf('%d ',size(ANA.dat))));
  INFTXT{end+1} = sprintf('res: [%s]',deblank(sprintf('%g ',ANA.ds)));
  INFTXT{end+1} = sprintf('data: %s',ANA.hdr.dime.datatype);
  set(wgts.InfoTxt,'String',INFTXT);
  
  
  set(wgts.AnaScaleEdt,'String',sprintf('%g %g  %g',ANA.scale));
  
  % initialize view
  OrthoView_Callback(hObject(1),'init',[]);
  LightboxView_Callback(hObject(1),'init',[]);

  Main_Callback(hObject,'redraw',[]);

  
 case {'browse-file'}
  [f,d] = uigetfile( ...
	  {'*.img', 'All ANALYZE Files (*.img)'; ...
	   '*.*',   'All Files (*.*)'}, ...
	  'Pick ANALYZE file');
  if isequal(f,0) | isequal(d,0),  return;  end
  IMGFILE = fullfile(d,f);
  
  setappdata(wgts.main,'ANA',[]);
  set(wgts.AnzFileEdt,'String',IMGFILE);
  Main_Callback(hObject,'init',[]);

 case {'update-cmap'}
  % update tick for colorbar
  GRAHANDLE = getappdata(wgts.main,'GRAHANDLE');
  if ~isempty(GRAHANDLE),
    ANA = getappdata(wgts.main,'ANA');
    MINV = ANA.scale(1);  MAXV = ANA.scale(2);
    ydat = [0:255]/255 * (MAXV - MINV) + MINV;
    set(GRAHANDLE.colorbar,'ydata',ydat);
    set(wgts.ColorbarAxs,'ylim',[MINV MAXV]);
  end
  
  CMAP = subGetColormap(wgts);
  axes(wgts.ColorbarAxs);  colormap(CMAP);
  setappdata(wgts.main,'CMAP',CMAP);

  Main_Callback(hObject,'redraw',[]);

  
  
 case {'update-anascale'}
  anascale = str2num(get(wgts.AnaScaleEdt,'String'));
  if length(anascale) ~= 3,  return;  end
  ANA = getappdata(wgts.main,'ANA');
  if isempty(ANA),  return;  end
  ANA.ana256 = subScaleAnatomy(ANA.dat,anascale(1),anascale(2),anascale(3));
  setappdata(wgts.main,'ANA',ANA);  clear ANA anascale;
  Main_Callback(hObject,'update-cmap',[]);
  %Main_Callback(hObject,'redraw',[]);
  
 case {'redraw'}
  ViewMode = get(wgts.ViewModeCmb,'String');
  ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
  if strcmpi(ViewMode,'orthogonal'),
    OrthoView_Callback(hObject,'redraw',[]);
  else
    LightboxView_Callback(hObject,'redraw',[]);
  end
  %fprintf('redraw\n');
  
 case {'view-mode'}
  ViewMode = get(wgts.ViewModeCmb,'String');
  ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
  hL = [wgts.LightboxAxs];
  hO = [wgts.CoronalTxt, wgts.CoronalEdt, wgts.CoronalSldr, wgts.CoronalAxs,...
        wgts.SagitalTxt, wgts.SagitalEdt, wgts.SagitalSldr, wgts.SagitalAxs,...
        wgts.TransverseTxt, wgts.TransverseEdt, wgts.TransverseSldr, wgts.TransverseAxs,...
        wgts.CrosshairCheck];
  
  if strcmpi(ViewMode,'orthogonal'),
    set(hL,'visible','off');
    set(findobj(hL),'visible','off');
    set(hO,'visible','on');
    h = findobj([wgts.CoronalAxs, wgts.SagitalAxs, wgts.TransverseAxs, wgts.TriplotAxs]);
    set(h,'visible','on');
  else
    set(hL,'visible','on');
    set(findobj(hL),'visible','on');
    set(hO,'visible','off');
    h = findobj([wgts.CoronalAxs, wgts.SagitalAxs, wgts.TransverseAxs, wgts.TriplotAxs]);
    set(h,'visible','off');
    LightboxView_Callback(hObject,'init',[]);
    LightboxView_Callback(hObject,'redraw',[]);
  end

 case {'view-page'}
  ViewMode = get(wgts.ViewModeCmb,'String');
  ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
  if ~isempty(strfind(ViewMode,'lightbox')),
    LightboxView_Callback(hObject,'redraw',[]);
  end
  
 otherwise
end
  
return;


       
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to handle orthogonal view
function OrthoView_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(get(hObject,'Parent'));
ANA  = getappdata(wgts.main,'ANA');

switch lower(eventdata),
 case {'init'}
  
  iX = 1;  iY = 1;  iZ = 1;
  nX = size(ANA.dat,1);  nY = size(ANA.dat,2);  nZ = size(ANA.dat,3);
  % set slider edit value
  set(wgts.SagitalEdt,   'String', sprintf('%d',iX));
  set(wgts.CoronalEdt,   'String', sprintf('%d',iY));
  set(wgts.TransverseEdt,'String', sprintf('%d',iZ));
  % set slider, add +0.01 to prevent error.
  set(wgts.SagitalSldr,   'Min',1,'Max',nX+0.01,'Value',iX);
  set(wgts.CoronalSldr,   'Min',1,'Max',nY+0.01,'Value',iY);
  set(wgts.TransverseSldr,'Min',1,'Max',nZ+0.01,'Value',iZ);
  % set slider step, it is normalized from 0 to 1, not min/max
  set(wgts.SagitalSldr,   'SliderStep',[1, 2]/max(1,nX));
  set(wgts.CoronalSldr,   'SliderStep',[1, 2]/max(1,nY));
  set(wgts.TransverseSldr,'SliderStep',[1, 2]/max(1,nZ));
  
  CMAP = subGetColormap(wgts);
  setappdata(wgts.main,'CMAP',CMAP);
  
  AXISCOLOR = [0.8 0.2 0.8];
  % now draw images
  axes(wgts.SagitalAxs); cla;
  tmpimg = squeeze(ANA.ana256(iX,:,:));
  hSag = image(1:nY,1:nZ,ind2rgb(tmpimg',CMAP));
  set(hSag,...
      'ButtonDownFcn','anz_view(''OrthoView_Callback'',gcbo,''button-sagital'',guidata(gcbo))');
  set(wgts.SagitalAxs,'tag','SagitalAxs');	% set this again, some will reset.
  axes(wgts.CoronalAxs); cla;
  tmimg = squeeze(ANA.ana256(:,iY,:));
  hCor = image(1:nX,1:nZ,ind2rgb(tmpimg',CMAP));
  set(hCor,...
      'ButtonDownFcn','anz_view(''OrthoView_Callback'',gcbo,''button-coronal'',guidata(gcbo))');
  set(wgts.CoronalAxs,'tag','CoronalAxs');  % set this again, some will reset.
  axes(wgts.TransverseAxs); cla;
  tmpimg = squeeze(ANA.ana256(:,:,iZ));
  hTra = image(1:nX,1:nY,ind2rgb(tmpimg',CMAP));
  set(hTra,...
      'ButtonDownFcn','anz_view(''OrthoView_Callback'',gcbo,''button-transverse'',guidata(gcbo))');
  set(wgts.TransverseAxs,'tag','TransverseAxs');	% set this again, some will reset.
  
  % now draw a color bar
  MINV = ANA.scale(1);  MAXV = ANA.scale(2);
  axes(wgts.ColorbarAxs); cla;
  ydat = [0:255]/255 * (MAXV - MINV) + MINV;
  hColorbar = imagesc(1,ydat,[0:255]'); colormap(CMAP);
  set(wgts.ColorbarAxs,'Tag','ColorbarAxs');  % set this again, some will reset.
  set(wgts.ColorbarAxs,'ylim',[MINV MAXV],...
                    'YAxisLocation','right','XTickLabel',{},'XTick',[],'Ydir','normal');
  
  haxs = [wgts.SagitalAxs, wgts.CoronalAxs, wgts.TransverseAxs];
  set(haxs,'fontsize',8,'xcolor',AXISCOLOR,'ycolor',AXISCOLOR);
  GRAHANDLE.sagital    = hSag;
  GRAHANDLE.coronal    = hCor;
  GRAHANDLE.transverse = hTra;
  GRAHANDLE.colorbar   = hColorbar;
  
  % draw crosshair(s)
  axes(wgts.SagitalAxs);
  hSagV = line([iY iY],[ 1 nZ],'color','y');
  hSagH = line([ 1 nY],[iZ iZ],'color','y');
  set([hSagV hSagH],...
      'ButtonDownFcn','anz_view(''OrthoView_Callback'',gcbo,''button-sagital'',guidata(gcbo))');
  axes(wgts.CoronalAxs);
  hCorV = line([iX iX],[ 1 nZ],'color','y');
  hCorH = line([ 1 nX],[iZ iZ],'color','y');
  set([hCorV hCorH],...
      'ButtonDownFcn','anz_view(''OrthoView_Callback'',gcbo,''button-coronal'',guidata(gcbo))');
  axes(wgts.TransverseAxs);
  hTraV = line([iX iX],[ 1 nY],'color','y');
  hTraH = line([ 1 nX],[iY iY],'color','y');
  set([hTraV hTraH],...
      'ButtonDownFcn','anz_view(''OrthoView_Callback'',gcbo,''button-transverse'',guidata(gcbo))');
  if get(wgts.CrosshairCheck,'Value') == 0,
    set([hSagV hSagH hCorV hCorH hTraV hTraH],'visible','off');
  end
  
  GRAHANDLE.sagitalV    = hSagV;
  GRAHANDLE.sagitalH    = hSagH;
  GRAHANDLE.coronalV    = hCorV;
  GRAHANDLE.coronalH    = hCorH;
  GRAHANDLE.transverseV = hTraV;
  GRAHANDLE.transverseH = hTraH;
  
  % tri-plot
  axes(wgts.TriplotAxs); cla;
  [xi,yi,zi] = meshgrid(iX,1:nY,1:nZ);
  hSag = surface(...
      'xdata',reshape(xi,[nY,nZ]),'ydata',reshape(yi,[nY,nZ]),'zdata',reshape(zi,[nY,nZ]),...
      'cdata',squeeze(ANA.ana256(:,iX,:)),...
      'facecolor','texturemap','edgecolor','none',...
      'CDataMapping','direct','linestyle','none');
  [xi,yi,zi] = meshgrid(1:nX,iY,1:nZ);
  hCor = surface(...
      'xdata',reshape(xi,[nX,nZ]),'ydata',reshape(yi,[nX,nZ]),'zdata',reshape(zi,[nX,nZ]),...
      'cdata',squeeze(ANA.ana256(iY,:,:)),...
      'facecolor','texturemap','edgecolor','none',...
      'CDataMapping','direct','linestyle','none');
  [xi,yi,zi] = meshgrid(1:nX,1:nY,iZ);
  hTra = surface(...
      'xdata',1:nX,'ydata',1:nY,'zdata',reshape(zi,[nY,nX]),...
      'cdata',permute(squeeze(ANA.ana256(:,:,iZ)),[2 1 3]),...
      'facecolor','texturemap','edgecolor','none',...
      'CDataMapping','direct','linestyle','none');

  set(gca,'Tag','TriplotAxs');
  set(gca,'fontsize',8,...
          'xlim',[1 nX],'ylim',[1 nY],'zlim',[1 nZ],'zdir','reverse');
  view(50,36);  grid on;
  xlabel('X'); ylabel('Y');  zlabel('Z');
  
  GRAHANDLE.triSagital = hSag;
  GRAHANDLE.triCoronal = hCor;
  GRAHANDLE.triTransverse = hTra;

  setappdata(wgts.main,'GRAHANDLE',GRAHANDLE);

  OrthoView_Callback(hObject,'dir-reverse',[]);

 case {'redraw'}
  OrthoView_Callback(hObject,'slider-sagital',[]);
  OrthoView_Callback(hObject,'slider-coronal',[]);
  OrthoView_Callback(hObject,'slider-transverse',[]);
  
 case {'slider-sagital'}
  GRAHANDLE = getappdata(wgts.main,'GRAHANDLE');
  if ~isempty(GRAHANDLE),
    CMAP = getappdata(wgts.main,'CMAP');
    iX = round(get(wgts.SagitalSldr,'Value'));
    tmpimg = squeeze(ANA.ana256(iX,:,:));
    set(GRAHANDLE.sagital,'cdata',ind2rgb(tmpimg',CMAP));
    set(GRAHANDLE.coronalV,   'xdata',[iX iX]);
    set(GRAHANDLE.transverseV,'xdata',[iX iX]);
    set(wgts.SagitalEdt,'String',sprintf('%d',iX));
    xdata = get(GRAHANDLE.triSagital,'xdata');
    xdata(:) = iX;
    set(GRAHANDLE.triSagital,'xdata',xdata,'cdata',tmpimg);
  end
  
  
 case {'slider-coronal'}
  GRAHANDLE = getappdata(wgts.main,'GRAHANDLE');
  if ~isempty(GRAHANDLE)
    CMAP = getappdata(wgts.main,'CMAP');
    iY = round(get(wgts.CoronalSldr,'Value'));
    tmpimg = squeeze(ANA.ana256(:,iY,:));
    set(GRAHANDLE.coronal,'cdata',ind2rgb(tmpimg',CMAP));
    set(GRAHANDLE.sagitalV,   'xdata',[iY iY]);
    set(GRAHANDLE.transverseH,'ydata',[iY iY]);
    set(wgts.CoronalEdt,'String',sprintf('%d',iY));
    ydata = get(GRAHANDLE.triCoronal,'ydata');
    ydata(:) = iY;
    set(GRAHANDLE.triCoronal,'ydata',ydata,'cdata',tmpimg);
  end
  
 case {'slider-transverse'}
  GRAHANDLE = getappdata(wgts.main,'GRAHANDLE');
  if ~isempty(GRAHANDLE)
    CMAP = getappdata(wgts.main,'CMAP');
    iZ = round(get(wgts.TransverseSldr,'Value'));
    tmpimg = squeeze(ANA.ana256(:,:,iZ));
    set(GRAHANDLE.transverse,'cdata',ind2rgb(tmpimg',CMAP));
    set(GRAHANDLE.sagitalH,   'ydata',[iZ iZ]);
    set(GRAHANDLE.coronalH,   'ydata',[iZ iZ]);
    set(wgts.TransverseEdt,'String',sprintf('%d',iZ));
    zdata = get(GRAHANDLE.triTransverse,'zdata');
    zdata(:) = iZ;
    set(GRAHANDLE.triTransverse,'zdata',zdata,'cdata',tmpimg);
  end
  
 case {'edit-sagital'}
  iX = str2num(get(wgts.SagitalEdt,'String'));
  if isempty(iX),
    iX = round(get(wgts.SagitalSldr,'Value'));
    set(wgts.SagitalEdt,'String',sprintf('%d',iX));
  else
    if iX < 0,
      iX = 1; 
      set(wgts.SagitalEdt,'String',sprintf('%d',iX));
    elseif iX > size(ANA.dat,1),
      iX = size(ANA.dat,1);
      set(wgts.SagitalEdt,'String',sprintf('%d',iX));
    end
    set(wgts.SagitalSldr,'Value',iX);
    OrthoView_Callback(hObject,'slider-sagital',[]);
  end
  
 case {'edit-coronal'}
  iY = str2num(get(wgts.CoronalEdt,'String'));
  if isempty(iY),
    iY = round(get(wgts.CoronalSldr,'Value'));
    set(wgts.CoronalEdt,'String',sprintf('%d',iY));
  else
    if iY < 0,
      iY = 1; 
      set(wgts.CoronalEdt,'String',sprintf('%d',iY));
    elseif iY > size(ANA.dat,2),
      iY = size(ANA.dat,1);
      set(wgts.CoronalEdt,'String',sprintf('%d',iY));
    end
    set(wgts.CoronalSldr,'Value',iY);
    OrthoView_Callback(hObject,'slider-coronal',[]);
  end
 
 case {'edit-transverse'}
  iZ = str2num(get(wgts.TransverseEdt,'String'));
  if isempty(iZ),
    iZ = round(get(wgts.TransverseSldr,'Value'));
    set(wgts.TransverseEdt,'String',sprintf('%d',iZ));
  else
    if iZ < 0,
      iZ = 1; 
      set(wgts.TransverseEdt,'String',sprintf('%d',iZ));
    elseif iZ > size(ANA.dat,3),
      iZ = size(ANA.dat,1);
      set(wgts.TransverseEdt,'String',sprintf('%d',iZ));
    end
    set(wgts.TransverseSldr,'Value',iZ);
    OrthoView_Callback(hObject,'slider-transverse',[]);
  end

 case {'dir-reverse'}
  % note that image(),imagesc() reverse Y axies
  Xrev = get(wgts.XReverseCheck,'Value');
  Yrev = get(wgts.YReverseCheck,'Value');
  Zrev = get(wgts.ZReverseCheck,'Value');
  if Xrev == 0,
    corX = 'normal';   traX = 'normal';
  else
    corX = 'reverse';  traX = 'reverse';
  end
  if Yrev == 0,
    sagX = 'normal';   traY = 'reverse';
  else
    sagX = 'reverse';  traY = 'normal';
  end
  if Zrev == 0,
    sagY = 'reverse';  corY = 'reverse';
  else
    sagY = 'normal';   corY = 'normal';
  end
  set(wgts.SagitalAxs,   'xdir',sagX,'ydir',sagY);
  set(wgts.CoronalAxs,   'xdir',corX,'ydir',corY);
  set(wgts.TransverseAxs,'xdir',traX,'ydir',traY);

 case {'crosshair'}
  GRAHANDLE = getappdata(wgts.main,'GRAHANDLE');
  if ~isempty(GRAHANDLE),
    if get(wgts.CrosshairCheck,'value') == 0,
      set(GRAHANDLE.sagitalV,   'visible','off');
      set(GRAHANDLE.sagitalH,   'visible','off');
      set(GRAHANDLE.coronalV,   'visible','off');
      set(GRAHANDLE.coronalH,   'visible','off');
      set(GRAHANDLE.transverseV,'visible','off');
      set(GRAHANDLE.transverseH,'visible','off');
    else
      set(GRAHANDLE.sagitalV,   'visible','on');
      set(GRAHANDLE.sagitalH,   'visible','on');
      set(GRAHANDLE.coronalV,   'visible','on');
      set(GRAHANDLE.coronalH,   'visible','on');
      set(GRAHANDLE.transverseV,'visible','on');
      set(GRAHANDLE.transverseH,'visible','on');
    end
  end
  
 case {'button-sagital'}
  click = get(wgts.main,'SelectionType');
  if strcmpi(click,'alt') & get(wgts.CrosshairCheck,'Value') == 1,
    pt = round(get(wgts.SagitalAxs,'CurrentPoint'));
    iY = pt(1,1);  iZ = pt(1,2);
    if iY > 0 & iY <= size(ANA.dat,2),
      set(wgts.CoronalEdt,'String',sprintf('%d',iY));
      set(wgts.CoronalSldr,'Value',iY);
      OrthoView_Callback(hObject,'slider-coronal',[]);
    end
    if iZ > 0 & iZ <= size(ANA.dat,3),
      set(wgts.TransverseEdt,'String',sprintf('%d',iZ));
      set(wgts.TransverseSldr,'Value',iZ);
      OrthoView_Callback(hObject,'slider-transverse',[]);
    end
  elseif strcmpi(click,'open'),
    % double click
    subZoomIn('sagital',wgts,ANA);
  end
  
 case {'button-coronal'}
  click = get(wgts.main,'SelectionType');
  if strcmpi(click,'alt') & get(wgts.CrosshairCheck,'Value') == 1,
    pt = round(get(wgts.CoronalAxs,'CurrentPoint'));
    iX = pt(1,1);  iZ = pt(1,2);
    if iX > 0 & iX <= size(ANA.dat,1),
      set(wgts.SagitalEdt,'String',sprintf('%d',iX));
      set(wgts.SagitalSldr,'Value',iX);
      OrthoView_Callback(hObject,'slider-sagital',[]);
    end
    if iZ > 0 & iZ <= size(ANA.dat,3),
      set(wgts.TransverseEdt,'String',sprintf('%d',iZ));
      set(wgts.TransverseSldr,'Value',iZ);
      OrthoView_Callback(hObject,'slider-transverse',[]);
    end
  elseif strcmpi(click,'open'),
    % double click
    subZoomIn('coronal',wgts,ANA);
  end

 case {'button-transverse'}
  click = get(wgts.main,'SelectionType');
  if strcmpi(click,'alt') & get(wgts.CrosshairCheck,'Value') == 1,
    pt = round(get(wgts.TransverseAxs,'CurrentPoint'));
    iX = pt(1,1);  iY = pt(1,2);
    if iX > 0 & iX <= size(ANA.dat,1),
      set(wgts.SagitalEdt,'String',sprintf('%d',iX));
      set(wgts.SagitalSldr,'Value',iX);
      OrthoView_Callback(hObject,'slider-sagital',[]);
    end
    if iY > 0 & iY <= size(ANA.dat,2),
      set(wgts.CoronalEdt,'String',sprintf('%d',iY));
      set(wgts.CoronalSldr,'Value',iY);
      OrthoView_Callback(hObject,'slider-coronal',[]);
    end
  elseif strcmpi(click,'open'),
    % double click
    subZoomIn('transverse',wgts,ANA);
  end
  
 otherwise
end


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to handle lightbox view
function LightboxView_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(get(hObject,'Parent'));
ANA  = getappdata(wgts.main,'ANA');
ViewMode = get(wgts.ViewModeCmb,'String');
ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
switch lower(ViewMode),
 case {'lightbox-cor'}
  iDimension = 2;
 case {'lightbox-sag'}
  iDimension = 1;
 case {'lightbox-trans'}
  iDimension = 3;
 otherwise
  iDimension = 3;
end
nmaximages = size(ANA.dat,iDimension);

NCol = 5;
NRow = 4;

switch lower(eventdata),
 case {'init'}
  NPages = floor((nmaximages-1)/NCol/NRow)+1;
  tmptxt = {};
  for iPage = 1:NPages,
    tmptxt{iPage} = sprintf('Page%d: %d-%d',iPage,...
                            (iPage-1)*NCol*NRow+1,min([nmaximages,iPage*NCol*NRow]));
  end
  set(wgts.ViewPageList,'String',tmptxt,'Value',1);
  ViewMode = get(wgts.ViewModeCmb,'String');
  ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
  if strcmpi(ViewMode,'lightbox'),
    LightboxView_Callback(hObject,'redraw',handles);
  end
  
 case {'redraw'}
  axes(wgts.LightboxAxs);  cla;
  pagestr = get(wgts.ViewPageList,'String');
  pagestr = pagestr{get(wgts.ViewPageList,'Value')};
  ipage = sscanf(pagestr,'Page%d:');
  SLICES = (ipage-1)*NCol*NRow+1:min([nmaximages,ipage*NCol*NRow]);
  if iDimension == 1,
    nX = size(ANA.dat,2);  nY = size(ANA.dat,3);
    INFSTR = 'Sag';
  elseif iDimension == 2,
    nX = size(ANA.dat,1);  nY = size(ANA.dat,3);
    INFSTR = 'Cor';
  else
    nX = size(ANA.dat,1);  nY = size(ANA.dat,2);
    INFSTR = 'Trans';
  end
  X = [0:nX-1];  Y = [nY-1:-1:0];
  CMAP = getappdata(wgts.main,'CMAP');
  
  for N = 1:length(SLICES),
    iSlice = SLICES(N);
    if iDimension == 1,
      tmpimg = squeeze(ANA.ana256(iSlice,:,:));
    elseif iDimension == 2,
      tmpimg = squeeze(ANA.ana256(:,iSlice,:));
    else
      tmpimg = squeeze(ANA.ana256(:,:,iSlice));
    end
    iCol = floor((N-1)/NRow)+1;
    iRow = mod((N-1),NRow)+1;
    offsX = nX*(iRow-1);
    offsY = nY*NCol - iCol*nY;
    tmpx = X + offsX;  tmpy = Y + offsY;
    image(tmpx,tmpy,ind2rgb(tmpimg',CMAP));  hold on;
    text(min(tmpx)+1,min(tmpy)+1,sprintf('%s=%d',INFSTR,iSlice),...
         'color',[0.9 0.9 0.5],'VerticalAlignment','bottom',...
         'FontName','Comic Sans MS','FontSize',8,'Fontweight','bold');
  end
  axes(wgts.LightboxAxs);
  set(gca,'Tag','LightboxAxs','color','black');
  set(gca,'XTickLabel',{},'YTickLabel',{},'XTick',[],'YTick',[]);
  set(gca,'xlim',[0 nX*NRow],'ylim',[0 nY*NCol]);
  set(gca,'YDir','normal');

 otherwise
end

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to scale anatomy image
function ANASCALED = subScaleAnatomy(ANA,MINV,MAXV,GAMMA)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isstruct(ANA),
  tmpana = single(ANA.dat);
else
  tmpana = single(ANA);
end
clear ANA;
tmpana = (tmpana - MINV) / (MAXV - MINV);
tmpana = round(tmpana*255) + 1; % +1 for matlab indexing
tmpana(find(tmpana(:) <   0)) =   1;
tmpana(find(tmpana(:) > 256)) = 256;

ANASCALED = uint8(round(tmpana));

  
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to scale anatomy image
function ANARGB = subScaleAnatomy_OLD(ANA,MINV,MAXV,GAMMA)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isstruct(ANA),
  tmpana = single(ANA.dat);
else
  tmpana = single(ANA);
end
clear ANA;
tmpana = (tmpana - MINV) / (MAXV - MINV);
tmpana = round(tmpana*255) + 1; % +1 for matlab indexing
tmpana(find(tmpana(:) <   0)) =   1;
tmpana(find(tmpana(:) > 256)) = 256;
anacmap = gray(256).^(1/GAMMA);
for N = size(tmpana,3):-1:1,
  ANARGB(:,:,:,N) = ind2rgb(tmpana(:,:,N),anacmap);
end
clear tmpana;

ANARGB = permute(ANARGB,[1 2 4 3]);  % [x,y,rgb,z] --> [x,y,z,rgb]

  
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to get a color map
function cmap = subGetColormap(wgts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cmapstr = get(wgts.ColormapCmb,'String');
cmapstr = cmapstr{get(wgts.ColormapCmb,'value')};
switch lower(cmapstr),
 case {'jet','hsv','hot','cool','spring','summer','autumn','winter','gray','bone','copper','pink'}
  eval(sprintf('cmap = %s(256);',cmapstr));
 case {'red'}
  %cmap = zeros(256,3);  cmap(:,1) = 1;
  cmap = gray(256);  cmap(:,[2 3]) = 0;
 case {'green'}
  %cmap = zeros(256,3);  cmap(:,2) = 1;
  cmap = gray(256);  cmap(:,[1 3]) = 0;
 case {'blue'}
  %cmap = zeros(256,3);  cmap(:,3) = 1;
  cmap = gray(256);  cmap(:,[1 2]) = 0;
 case {'yellow'}
  %cmap = zeros(256,3);  cmap(:,1) = 1;  cmap(:,2) = 1;
  cmap = gray(256);  cmap(:,3) = 0;
 otherwise
  cmap = gray(256);
end

ANA = getappdata(wgts.main,'ANA');

gammav = ANA.scale(3);
if ~isempty(gammav),
  cmap = cmap.^(1/gammav);
end

return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to fuse anatomy and functional images
function IMG = subFuseImage(ANARGB,STATV,MINV,MAXV,PVAL,ALPHA,CMAP)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
IMG = ANARGB;
if isempty(STATV) | isempty(PVAL) | isempty(ALPHA),  return;  end

PVAL(find(isnan(PVAL(:)))) = 1;  % to avoid error;

tmpdat = repmat(PVAL,[1 1 3]);   % for rgb
idx = find(tmpdat(:) < ALPHA);
if ~isempty(idx),
  % scale STATV from MINV to MAXV as 0 to 1
  STATV = (STATV - MINV)/(MAXV - MINV);
  STATV = round(STATV*255) + 1;  % +1 for matlab indexing
  STATV(find(STATV(:) <   0)) =   1;
  STATV(find(STATV(:) > 256)) = 256;
  % map 0-256 as RGB
  STATV = ind2rgb(STATV,CMAP);
  % replace pixels
  IMG(idx) = STATV(idx);
end

 
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to zoom-in plot
function subZoomIn(planestr,wgts,ANA)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch lower(planestr)
 case {'coronal'}
  hfig = wgts.main + 1001;
  hsrc = wgts.CoronalAxs;
  DX = ANA.ds(1);  DY = ANA.ds(3);
  N = str2num(get(wgts.CoronalEdt,'String'));
  tmpstr = sprintf('CORONAL %03d: %s',N, ANA.imgfile);
  tmpxlabel = 'X (mm)';  tmpylabel = 'Z (mm)';
 case {'sagital'}
  hfig = wgts.main + 1002;
  hsrc = wgts.SagitalAxs;
  DX = ANA.ds(2);  DY = ANA.ds(3);
  N = str2num(get(wgts.SagitalEdt,'String'));
  tmpstr = sprintf('SAGITAL %03d: %s',N,ANA.imgfile);
  tmpxlabel = 'Y (mm)';  tmpylabel = 'Z (mm)';
 case {'transverse'}
  hfig = wgts.main + 1003;
  hsrc = wgts.TransverseAxs;
  DX = ANA.ds(1);  DY = ANA.ds(2);
  N = str2num(get(wgts.TransverseEdt,'String'));
  tmpstr = sprintf('TRANSVERSE %03d: %s',N,ANA.imgfile);
  tmpxlabel = 'X (mm)';  tmpylabel = 'Y (mm)';
end

tmpstr = strrep(tmpstr,'\','/');

figure(hfig);  clf;
pos = get(hfig,'pos');
set(hfig,'Name',tmpstr,'pos',[pos(1)-680+pos(3) pos(2)-500+pos(4) 680 500]);
haxs = copyobj(hsrc,hfig);
set(haxs,'ButtonDownFcn','');  % clear callback function
set(hfig,'Colormap',get(wgts.main,'Colormap'));
h = findobj(haxs,'type','image');
set(h,'ButtonDownFcn','');  % clear callback function
set(h,'xdata',get(h,'xdata')*DX,'ydata',get(h,'ydata')*DY);
nx = length(get(h,'xdata'));  ny = length(get(h,'ydata'));

% to keep actual size correct, do like this...
anasz = size(ANA.dat).*ANA.ds;
maxsz = max(anasz);
%set(haxs,'Position',[0.01 0.1 nx*DX/100 ny*DY/100],'units','normalized');
set(haxs,'Position',[0.01 0.1 nx*DX/maxsz*0.85 ny*DY/maxsz*0.85],'units','normalized');
h = findobj(haxs,'type','line');
for N =1:length(h),
  set(h(N),'xdata',get(h(N),'xdata')*DX,'ydata',get(h(N),'ydata')*DY);
end
set(haxs,'xlim',get(haxs,'xlim')*DX,'ylim',get(haxs,'ylim')*DY);
set(haxs,'xtick',[0 10 20 30 40 50 60 70 80 90 100 110 120]);
set(haxs,'ytick',[0 10 20 30 40 50 60 70 80 90 100 110 120]);
xlabel(tmpxlabel);  ylabel(tmpylabel);
title(haxs,strrep(tmpstr,'_','\_'));
%title(haxs,tmpstr);
daspect(haxs,[1 1 1]);
pos = get(haxs,'pos');
hbar = copyobj(wgts.ColorbarAxs,hfig);
set(hbar,'pos',[0.85 pos(2) 0.045 pos(4)]);    

return;

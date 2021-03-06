function varargout = tom_HT_particlepicker(varargin)


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @tom_HT_particlepicker_OpeningFcn, ...
                   'gui_OutputFcn',  @tom_HT_particlepicker_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% -------------------------------------------------------------------------
% Opening function
% -------------------------------------------------------------------------
function tom_HT_particlepicker_OpeningFcn(hObject, eventdata, handles, varargin)

if nargin == 4
    handles.projectstruct = varargin{1};
else
    error('This GUI must be called from tom_HT_main.');
end

result = tom_HT_getmicrographgroups(handles.projectstruct);
if ~isempty(result)
    string = {'---please select---',result.name{:}};
    set(handles.popupmenu_imageseries,'String',string);
    set(handles.popupmenu_imageseries,'UserData',[-1;result.micrographgroup_id]);
else 
    
end
set(gcf,'CurrentAxes',handles.powerspectrum);
axis off;
set(handles.figure_particlepicker,'Renderer','Painters','DoubleBuffer','on');
handles.particlestack = tom_HT_particlestack(handles.projectstruct);
handles.imrect = [];

handles.output = hObject;
guidata(hObject, handles);



% -------------------------------------------------------------------------
% Output function
% -------------------------------------------------------------------------
function varargout = tom_HT_particlepicker_OutputFcn(hObject, eventdata, handles) 

varargout{1} = handles.output;


% -------------------------------------------------------------------------
% Image series select box
% -------------------------------------------------------------------------
function popupmenu_imageseries_Callback(hObject, eventdata, handles)

[seriesname,seriesid] = tom_HT_getselecteddropdownfieldindex(hObject);

if strcmp(seriesname,'---please select---') == 0
    handles.imageseries = tom_HT_imageseries(handles.projectstruct,seriesid);
    numfiles = get_numberoffiles(handles.imageseries);
    set(handles.slider_imageseries,'Min',1,'Max',numfiles,'Value',1,'SliderStep',[1./(numfiles-1) 1./(numfiles-1)]);
    handles.imageseries = set_position(handles.imageseries,1);
    result = get_stacks_fromdb(handles.particlestack);
    if ~isempty(result)
        string = {'---please select---',result.name{:}};
        set(handles.popupmenu_loadstack,'String',string);
        set(handles.popupmenu_loadstack,'UserData',[-1;result.partgroup_id]);
    end
    result = tom_HT_getimageseriesresults(handles.projectstruct,seriesid);
    if ~isempty(result)
        string = {'---please select---',result.name{:}};
        set(handles.popupmenu_goodbad,'String',string);
        set(handles.popupmenu_goodbad,'UserData',[-1;result.experiment_id]);
    end
end

guidata(hObject, handles);

% -------------------------------------------------------------------------
% file filter dropdown box
% -------------------------------------------------------------------------
function popupmenu_goodbad_Callback(hObject, eventdata, handles)

[resultname,resultid] = tom_HT_getselecteddropdownfieldindex(hObject);

if strcmp(resultname,'---please select---') == 0
    handles.imageseries = getgoodbadresultfromdb(handles.imageseries,resultid);
    handles.imageseries = removebadimages(handles.imageseries);
    numfiles = get_numberoffiles(handles.imageseries);
    set(handles.slider_imageseries,'Min',1,'Max',numfiles,'Value',1,'SliderStep',[1./(numfiles-1) 1./(numfiles-1)]);
end

guidata(hObject, handles);


% -------------------------------------------------------------------------
% imageseries slider
% -------------------------------------------------------------------------
function slider_imageseries_Callback(hObject, eventdata, handles)

handles.imageseries = set_position(handles.imageseries,round(get(hObject,'Value')));

handles = create_imageview(hObject,handles);

guidata(hObject, handles);


% -------------------------------------------------------------------------
% binning
% -------------------------------------------------------------------------
function popupmenu_binning_Callback(hObject, eventdata, handles)

handles = create_imageview(hObject,handles);

guidata(hObject, handles);


% -------------------------------------------------------------------------
% button exit
% -------------------------------------------------------------------------
function button_exit_Callback(hObject, eventdata, handles)

handles.particlestack = update_radius(handles.particlestack,str2double(get(handles.radius,'String')));

try
    delete(handles.imagefigure);
end

try
    delete(handles.gallery);
end

try
    delete(handles.figure_particlepicker);
end


% -------------------------------------------------------------------------
% load stack
% -------------------------------------------------------------------------
function popupmenu_loadstack_Callback(hObject, eventdata, handles)

[stackname,stackid] = tom_HT_getselecteddropdownfieldindex(hObject);

if strcmp(stackname,'---please select---') == 0
    [handles.particlestack,radius] = loadfromdb(handles.particlestack,stackid);
    set(handles.radius,'String',num2str(radius));
    handles = create_imageview(hObject,handles);
end

guidata(hObject, handles);


% -------------------------------------------------------------------------
% button new stack
% -------------------------------------------------------------------------
function button_newstack_Callback(hObject, eventdata, handles)

prompt = {'stack name:','description'};
dlg_title = 'Create new stack';
num_lines = 1;
def = {'',''};
answer = inputdlg(prompt,dlg_title,num_lines,def);

handles.particlestack = tom_HT_particlestack(handles.projectstruct);
handles.particlestack = createdbstack(handles.particlestack,answer{1},answer{2});
result = get_stacks_fromdb(handles.particlestack);
if ~isempty(result)
    string = {'---please select---',result.name{:}};
    set(handles.popupmenu_loadstack,'String',string);
    set(handles.popupmenu_goodbad,'UserData',[-1;result.partgroup_id]);
end

guidata(hObject, handles);


% -------------------------------------------------------------------------
% autosave particles to database
% -------------------------------------------------------------------------
function checkbox_autosave_Callback(hObject, eventdata, handles)

guidata(hObject, handles);


% -------------------------------------------------------------------------
% button particle gallery
% -------------------------------------------------------------------------
function button_gallery_Callback(hObject, eventdata, handles)

if get(hObject,'Value') == 1
    cols = str2double(get(handles.edit_cols,'String'));
    handles.gallery = tom_HT_stackwidget();
    handles.gallery = layout(handles.gallery,500,500,cols,cols);
    cbs{1} = ['tom_HT_particle_info_cb(' sprintf('%5.20f',hObject)  ');'];
    cbs{2} = ['tom_HT_deleteparticle_cb(' sprintf('%5.20f',hObject)  ');'];
    handles.gallery = add_callbacks(handles.gallery,cbs);
    handles.gallery = normalize(handles.gallery);
    handles = update_gallery(handles,'updateall');
else
    delete(handles.gallery);
    handles = rmfield(handles,'gallery');
end

guidata(hObject, handles);


% -------------------------------------------------------------------------
% checkbox autoupdate particle gallery
% -------------------------------------------------------------------------
function checkbox_autoupdate_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of checkbox_autoupdate

guidata(hObject, handles);


% -------------------------------------------------------------------------
% button alignment experiment
% -------------------------------------------------------------------------
function button_alignment_Callback(hObject, eventdata, handles)

guidata(hObject, handles);


% -------------------------------------------------------------------------
% checkbox powerspectrum center region
% -------------------------------------------------------------------------
function checkbox_centerregion_Callback(hObject, eventdata, handles)

handles = display_powerspectrum(handles);

guidata(hObject, handles);


% -------------------------------------------------------------------------
% checkbox show powerspectrum
% -------------------------------------------------------------------------
function checkbox_showps_Callback(hObject, eventdata, handles)

handles = display_powerspectrum(handles);

guidata(hObject, handles);


% -------------------------------------------------------------------------
% average power spectrum
% -------------------------------------------------------------------------
function popupmenu_averageps_Callback(hObject, eventdata, handles)

handles = display_powerspectrum(handles);

guidata(hObject, handles);


% -------------------------------------------------------------------------
% button ctf tool
% -------------------------------------------------------------------------
function button_ctftool_Callback(hObject, eventdata, handles)

guidata(hObject, handles);


% -------------------------------------------------------------------------
% button filter change
% -------------------------------------------------------------------------
function button_filterchange_Callback(hObject, eventdata, handles)

guidata(hObject, handles);


% -------------------------------------------------------------------------
% button fitmagnification
% -------------------------------------------------------------------------
function button_fitmag_Callback(hObject, eventdata, handles)

mag = handles.scrollpanelapi.findFitMag();
handles.scrollpanelapi.setMagnification(floor(mag.*100)./100);

guidata(hObject, handles);


% -------------------------------------------------------------------------
% checkbox adjust contrast
% -------------------------------------------------------------------------
function checkbox_imcontrast_Callback(hObject, eventdata, handles)

if get(hObject,'Value') == 1
    handles.contrasttool = imcontrast(handles.imagefigure);
else
    try 
        delete(handles.contrasttool); 
    end
end

handles = create_pointermanager(hObject,handles);

guidata(hObject, handles);


% -------------------------------------------------------------------------
% create imageview
% -------------------------------------------------------------------------
function handles = create_imageview(hObject,handles)

handles = delete_imrects(handles);

if ~isfield(handles,'imagefigure')
    handles.imagefigure = figure('Toolbar','none','Menubar','none','Name','Micrograph');
    iptPointerManager(handles.imagefigure);
    set(gcf,'Renderer','Painters','DoubleBuffer','on');
    handles.I = imshow(zeros(1024,1024));
    handles.scrollpanel = imscrollpanel(handles.imagefigure,handles.I);
    handles.scrollpanelapi = iptgetapi(handles.scrollpanel);
    set(handles.scrollpanel,'Units','normalized');
    handles.imageaxis = gca;
    handles.magnification = immagbox(handles.uipanel_zoom,handles.I);
    set(handles.magnification,'Position',[30 10 60 20]);
else
    delete(handles.overview);
    try 
        delete(handles.contrasttool); 
    end
end

mag = handles.scrollpanelapi.getMagnification();
contents = get(handles.popupmenu_binning,'String');
binning = str2double(contents{get(handles.popupmenu_binning,'Value')});
handles.micrograph = getmicrograph(handles.imageseries,[],1,[],binning);
image = get(handles.micrograph,'image');
handles.scrollpanelapi.replaceImage(image.Value');
stat = get(handles.micrograph,'stat');
set(handles.imageaxis,'Clim',[stat.min stat.max]);

handles.xlim = [0 size(image.Value,1)];
handles.ylim = [0 size(image.Value,2)];

handles.scrollpanelapi.setMagnification(mag);
axes(handles.imageaxis);
handles = show_imrects(handles);

if get(handles.checkbox_imcontrast,'Value') == 1
    handles.contrasttool = imcontrast(handles.imagefigure);
end

set(handles.imageaxis,'Clim',[stat.mean-3.*stat.std stat.mean+3.*stat.std]);

handles.overview = imoverviewpanel(handles.uipanel_overview,handles.I);

set(handles.text_image,'String',get_positiontext(handles.imageseries));
set(handles.text_imageinfo,'String',get_infotext(handles.micrograph));

handles = create_pointermanager(hObject,handles);
handles = display_powerspectrum(handles);

if get(handles.checkbox_autoupdate,'Value') == 1 && get(handles.button_gallery,'Value') == 1
    handles.gallery = clearall(handles.gallery);
    handles = update_gallery(handles,'updateall');
end



% -------------------------------------------------------------------------
% pick particle callback
% -------------------------------------------------------------------------
function pick_particle(src,eventdata,hObject)

handles = guidata(hObject);

point1 = get(gca,'currentpoint');
button = get(gcf,'selectiontype');

%button values:
%normal: left mouse button
%alt: right mouse button
%extend: middle mouse buttons

pt = point1(1,1:2);
x = round(pt(1));
y = round(pt(2));

%Handle pick particle event (left mouse button)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(button,'normal') == true
    contents = get(handles.popupmenu_binning,'String');
    binning = str2double(contents{get(handles.popupmenu_binning,'Value')});
    x = x.*2^binning;
    y = y.*2^binning;
    radius = str2double(get(handles.radius,'String'));
    micrographid = get(handles.micrograph,'micrographid');
    handles = draw_rect(handles,x,y);
    [handles.particlestack,dbid] = add_particle(handles.particlestack,x,y,radius,micrographid);
    set(handles.imrect,'UserData',dbid);
    if get(handles.checkbox_autoupdate,'Value') == 1
        image = get(handles.micrograph,'image');
        [handles.particlestack,particle] = get_lastparticle(handles.particlestack,image.Value,binning);
        handles.gallery = addparticle(handles.gallery,particle);
    end
end

guidata(hObject, handles);


% -------------------------------------------------------------------------
% create pointer manager
% -------------------------------------------------------------------------
function handles = create_pointermanager(hObject,handles)

iptSetPointerBehavior(handles.I, @(hFigure, currentPoint)set(hFigure, 'Pointer', 'cross'));
set(handles.I, 'ButtonDownFcn', {@pick_particle,hObject});


% -------------------------------------------------------------------------
% show power spectrum
% -------------------------------------------------------------------------
function handles = display_powerspectrum(handles)

if get(handles.checkbox_showps,'Value') == 1

    contents = get(handles.popupmenu_averageps,'String'); 
    avg = str2double(contents{get(handles.popupmenu_averageps,'Value')});

    axes(handles.powerspectrum);
    [handles.micrograph,ps_size] = show_powerspectrum(handles.micrograph,avg);
 
    if get(handles.checkbox_centerregion,'Value') == 1
        set(handles.powerspectrum,'XLim',[ps_size(1)./4+0.5 ps_size(1).*(3./4)+0.5],'YLim',[ps_size(1)./4+0.5 ps_size(1).*(3./4)+0.5]);
    else
        set(handles.powerspectrum,'XLim',[0.5 ps_size(1)+.5],'YLim',[0.5 ps_size(1)+0.5]);
    end
    
else

    axes(handles.powerspectrum);
    cla;
    axis off;
    
end


% -------------------------------------------------------------------------
% delete all imrects in current micrograph
% -------------------------------------------------------------------------
function handles = delete_imrects(handles)

for imrectnum=1:size(handles.imrect,2)
    api = iptgetapi(handles.imrect(imrectnum));
    api.delete();
end

handles.imrect = [];


% -------------------------------------------------------------------------
% show all imrects in current micrograph
% -------------------------------------------------------------------------
function handles = show_imrects(handles)

micrographid = get(handles.micrograph,'micrographid');
particles = get_particles(handles.particlestack,micrographid);

if ~isempty(particles.micrographid)
    handles = draw_rect(handles,particles.position.x,particles.position.y,particles.radius);
end


% -------------------------------------------------------------------------
% draw particle rectangle
% -------------------------------------------------------------------------
function handles = draw_rect(handles,x,y,radius)

contents = get(handles.popupmenu_binning,'String');
binning = str2double(contents{get(handles.popupmenu_binning,'Value')});

if nargin<4
    radius = str2double(get(handles.radius,'String'))./2^binning;
    radius = repmat(radius,1,size(x,2));
else 
    radius = radius./2^binning;
end

x = x./2^binning;
y = y./2^binning;

for i=1:size(x,2)
    fcn = makeConstrainToRectFcn('imrect',[handles.xlim(1)-radius(i), handles.xlim(2)+radius(i)],[handles.ylim(1)-radius(i), handles.ylim(2)+radius(i)]);
    imrectnum = size(handles.imrect,2)+1;
    handles.imrect(imrectnum) = imrect(gca,[x(i)-radius(i) y(i)-radius(i) radius(i).*2 radius(i).*2]);
    api = iptgetapi(handles.imrect(imrectnum));
    api.setResizable(false);
    api.setColor([0 1 0]);
    api.setDragConstraintFcn(fcn);
end


% -------------------------------------------------------------------------
% update the gallery
% -------------------------------------------------------------------------
function handles = update_gallery(handles,flag)

switch flag
    case 'updateall'
        contents = get(handles.popupmenu_binning,'String');
        binning = str2double(contents{get(handles.popupmenu_binning,'Value')});
        image = get(handles.micrograph,'image');
        [handles.particlestack,stack,ids] = getparticles_frommicrograph(handles.particlestack,get(handles.micrograph,'micrographid'),image.Value,binning);
        handles.gallery = loadimages(handles.gallery,stack,ids);
end


% -------------------------------------------------------------------------
% Create functions
% -------------------------------------------------------------------------
function popupmenu_imageseries_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function slider_imageseries_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function radius_Callback(hObject, eventdata, handles)
function radius_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function popupmenu_binning_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_averageps_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function popupmenu_averageps_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function popupmenu_loadstack_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit_cols_Callback(hObject, eventdata, handles)
function edit_cols_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function popupmenu_goodbad_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end







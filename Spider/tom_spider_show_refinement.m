function varargout = tom_spider_show_refinement(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @tom_spider_show_refinement_OpeningFcn, ...
                   'gui_OutputFcn',  @tom_spider_show_refinement_OutputFcn, ...
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
function tom_spider_show_refinement_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;

guidata(hObject, handles);


% -------------------------------------------------------------------------
% Output function
% -------------------------------------------------------------------------
function varargout = tom_spider_show_refinement_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


function listbox_iter_Callback(hObject, eventdata, handles)

guidata(hObject, handles);


% -------------------------------------------------------------------------
% button browse
% -------------------------------------------------------------------------

function button_browse_Callback(hObject, eventdata, handles)

PathName = uigetdir();

if PathName == 0
    return;
end

set(handles.edit_directory,'String',PathName);

handles = load_refinement(handles);

guidata(hObject, handles);


% -------------------------------------------------------------------------
% edit directory name
% -------------------------------------------------------------------------
function edit_directory_Callback(hObject, eventdata, handles)

handles = load_refinement(handles);

guidata(hObject, handles);



% -------------------------------------------------------------------------
% Helper: Load refinement iterations
% -------------------------------------------------------------------------
function handles = load_refinement(handles)

files = dir([get(handles.edit_directory,'String') '/3D/model*.spi']);

handles.numiter = 1;



% -------------------------------------------------------------------------
% Create functions
% -------------------------------------------------------------------------
function edit_directory_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function listbox_iter_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



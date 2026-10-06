function varargout = GUI_Recordings_SingePlot(varargin)
% GUI_RECORDINGS_SINGEPLOT MATLAB code for GUI_Recordings_SingePlot.fig
%      GUI_RECORDINGS_SINGEPLOT, by itself, creates a new GUI_RECORDINGS_SINGEPLOT or raises the existing
%      singleton*.
%
%      H = GUI_RECORDINGS_SINGEPLOT returns the handle to a new GUI_RECORDINGS_SINGEPLOT or the handle to
%      the existing singleton*.
%
%      GUI_RECORDINGS_SINGEPLOT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI_RECORDINGS_SINGEPLOT.M with the given input arguments.
%
%      GUI_RECORDINGS_SINGEPLOT('Property','Value',...) creates a new GUI_RECORDINGS_SINGEPLOT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI_Recordings_SingePlot_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI_Recordings_SingePlot_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUI_Recordings_SingePlot

% Last Modified by GUIDE v2.5 25-Nov-2012 15:41:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_Recordings_SingePlot_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_Recordings_SingePlot_OutputFcn, ...
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


% --- Executes just before GUI_Recordings_SingePlot is made visible.
function GUI_Recordings_SingePlot_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI_Recordings_SingePlot (see VARARGIN)

% Choose default command line output for GUI_Recordings_SingePlot
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GUI_Recordings_SingePlot wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GUI_Recordings_SingePlot_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function et_sF_Callback(hObject, eventdata, handles)
% hObject    handle to et_sF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_sF as text
%        str2double(get(hObject,'String')) returns contents of et_sF as a double


% --- Executes during object creation, after setting all properties.
function et_sF_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_sF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lb_ch.
function lb_ch_Callback(hObject, eventdata, handles)
% hObject    handle to lb_ch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lb_ch contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lb_ch


% --- Executes during object creation, after setting all properties.
function lb_ch_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lb_ch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_sT_Callback(hObject, eventdata, handles)
% hObject    handle to et_sT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_sT as text
%        str2double(get(hObject,'String')) returns contents of et_sT as a double


% --- Executes during object creation, after setting all properties.
function et_sT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_sT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_ampPP_Callback(hObject, eventdata, handles)
% hObject    handle to et_ampPP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_ampPP as text
%        str2double(get(hObject,'String')) returns contents of et_ampPP as a double

    % ampPP = str2double(get(hObject,'String'));
    % sData = cell2mat(get(get(handles.a_t0,'Children'),'YData'))';

    load('cData.mat');
    DataShow_SinglePlot(handles,cData,sF,sT);    
    




% --- Executes during object creation, after setting all properties.
function et_ampPP_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_ampPP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function t_load_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to t_load (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    [file, path] = uigetfile('*.mat');
    if ~isequal(file, 0)
        load([path,file]);
        if(exist('sF','var'))               % Load current data
            if (exist('cdata','var'))
                cData = cdata;
            end
            DataShow_SinglePlot(handles,cData,sF,sT);            
            save('cData.mat','cData','sF','sT');
        elseif exist('recSession','var')    % Load session
            
            
        end
    end


% --------------------------------------------------------------------
function t_save_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to t_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    [filename, pathname] = uiputfile({'*.mat','MAT-files (*.mat)'},'Save as', 'Untitled.mat');
    copyfile('cData.mat',[pathname,filename],'f');


% --- Executes on slider movement.
function s_t0_Callback(hObject, eventdata, handles)
% hObject    handle to s_t0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

    xMin = get(hObject,'Value');
    xMax = get(hObject,'Max');
    tw = str2double(get(handles.et_tw,'String'));
    
    if xMax >= xMin+tw 
        set(handles.a_t0,'XLim',[xMin xMin+tw]);
    end

% --- Executes during object creation, after setting all properties.
function s_t0_CreateFcn(hObject, eventdata, handles)
% hObject    handle to s_t0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function et_tw_Callback(hObject, eventdata, handles)
% hObject    handle to et_tw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tw as text
%        str2double(get(hObject,'String')) returns contents of et_tw as a double

    xLim    = get(handles.a_t0,'XLim');
    tw      = str2double(get(hObject,'String'));
    xMax    = xLim(1)+tw;
    
    if (isempty(tw))
         set(hObject,'String','0')
    end
    set(handles.a_t0,'XLim',[xLim(1) xMax]);

    sT = str2double(get(handles.et_sT,'String'));
    set(handles.s_t0, 'Max', sT);


% --- Executes during object creation, after setting all properties.
function et_tw_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_record.
function pb_record_Callback(hObject, eventdata, handles)
% hObject    handle to pb_record (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    sF = str2double(get(handles.et_sF,'String'));
    sT = str2double(get(handles.et_sT,'String'));

    cData = DAQShow_SBI_SinglePlot(handles);
    save('cData.mat','cData','sF','sT');



% --- Executes during object creation, after setting all properties.
function pb_record_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pb_record (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

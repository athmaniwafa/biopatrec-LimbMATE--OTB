% ---------------------------- Copyright Notice ---------------------------
% This file is part of BioPatRec © which is open and free software under
% the GNU Lesser General Public License (LGPL). See the file "LICENSE" for
% the full license governing this code and copyrights.
%
% BioPatRec was initially developed by Max J. Ortiz C. at Integrum AB and
% Chalmers University of Technology. All authors’ contributions must be kept
% acknowledged below in the section "Updates % Contributors".
%
% Would you like to contribute to science and sum efforts to improve
% amputees’ quality of life? Join this project! or, send your comments to:
% maxo@chalmers.se.
%
% The entire copyright notice must be kept in this or any source file
% linked to BioPatRec. This will ensure communication with all authors and
% acknowledge contributions here and in the project web page (optional).
%
% -------------------------- Function Description -------------------------
% GUI for visualisation and analysis of HD-sEMG data
%
% ------------------------- Updates & Contributors ------------------------
% 20??-??-?? / Max Ortiz  / Created initial version
% 2017-09-24 / Simon Nilsson / Updated version as part of master's thesis
function varargout = GUI_Recordings_Image(varargin)
% GUI_RECORDINGS_IMAGE MATLAB code for GUI_Recordings_Image.fig
%      GUI_RECORDINGS_IMAGE, by itself, creates a new GUI_RECORDINGS_IMAGE or raises the existing
%      singleton*.
%
%      H = GUI_RECORDINGS_IMAGE returns the handle to a new GUI_RECORDINGS_IMAGE or the handle to
%      the existing singleton*.
%
%      GUI_RECORDINGS_IMAGE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI_RECORDINGS_IMAGE.M with the given input arguments.
%
%      GUI_RECORDINGS_IMAGE('Property','Value',...) creates a new GUI_RECORDINGS_IMAGE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI_Recordings_Image_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI_Recordings_Image_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
% Edit the above text to modify the response to help GUI_Recordings_Image
% Last Modified by GUIDE v2.5 06-Jul-2017 20:08:11
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_Recordings_Image_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_Recordings_Image_OutputFcn, ...
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
% --- Executes just before GUI_Recordings_Image is made visible.
function GUI_Recordings_Image_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI_Recordings_Image (see VARARGIN)
% Choose default command line output for GUI_Recordings_Image
handles.output = hObject;
% Initialise structure for storing movie data
frames = struct('msg', {},...
                'img', {},...
                'lim', {});
playTimer = timer('TimerFcn', @pbTimer_callback,...
                  'ExecutionMode', 'fixedRate',...
                  'BusyMode', 'queue');
playTimer.UserData = struct('frames', frames,...
                            'nF', 0,...
                            'cF', 0,...
                            'fT', 0,...
                            'needsUpdate', true,...
                            'axes', handles.a_t0);
handles.playTimer = playTimer;
% Update handles structure
guidata(hObject, handles);
% UIWAIT makes GUI_Recordings_Image wait for user response (see UIRESUME)
% uiwait(handles.figure1);
fID = LoadFeaturesIDs;
set(handles.pm_features,'String',fID);
% --- Outputs from this function are returned to the command line.
function varargout = GUI_Recordings_Image_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get default command line output from handles structure
varargout{1} = handles.output;
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
% --------------------------------------------------------------------
function t_load_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to t_load (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [file, path] = uigetfile('*.mat', 'MultiSelect', 'on');
    if ~isequal(file, 0)
        set(handles.t_msg,'String','Loading...')
        drawnow;
        load([path,file]);
        if(exist('sF','var'))               % Load current data
            if (exist('cdata','var'))
                cData = cdata;
            end
            DataShow_SinglePlot(handles,cData,sF,sT);
            save('cData.mat','cData','sF','sT');
            set(handles.t_msg,'String','cData loaded')      % Show message about acquisition
        elseif exist('recSession','var')    % Load session
            handles.recSession = recSession;
            if isfield(recSession,'OTB400Electrodes') && ...
                    isfield(recSession,'nCh') && ismember(recSession.nCh,[64 128])
                OTB400_ChannelMap('install',handles.figure1,handles.a_t0, ...
                    recSession.nCh,recSession.OTB400Electrodes);
                set(handles.et_rows,'String','8');
                set(handles.et_columns,'String',num2str(recSession.nCh/8));
                if isfield(recSession,'OTB400VisibleChannels')
                    OTB400_ChannelMap('setmask',handles.figure1, ...
                        logical(recSession.OTB400VisibleChannels));
                end
            else
                OTB400_ChannelMap('remove',handles.figure1);
            end
            guidata(hObject, handles);
            set(handles.t_msg,'String','recSession loaded')      % Show message about acquisition
        end
    end
    setNeedsUpdate(hObject);
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
    % xMin = get(hObject,'Value');
    % xMax = get(hObject,'Max');
    % tw = str2double(get(handles.et_tw,'String'));
    % if xMax >= xMin+tw
    %     set(handles.a_t0,'XLim',[xMin xMin+tw]);
    % end
    movieSession = handles.playTimer.UserData;
    movieSession.cF = round(get(hObject, 'Value'));
    %pauseMovie(hObject);
    handles.playTimer.UserData = movieSession;
    showFrame(handles.playTimer);
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
    %xLim    = get(handles.a_t0,'XLim');
    tw      = str2double(get(hObject,'String'));
    %xMax    = xLim(1)+tw;
    if (isempty(tw))
         set(hObject,'String','0')
    end
    %set(handles.a_t0,'XLim',[xLim(1) xMax]);
    setNeedsUpdate(hObject);
    %sT = str2double(get(handles.et_sT,'String'));
    %set(handles.s_t0, 'Max', sT);
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
function et_ti_Callback(hObject, eventdata, handles)
% hObject    handle to et_ti (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of et_ti as text
%        str2double(get(hObject,'String')) returns contents of et_ti as a double
    %xLim    = get(handles.a_t0,'XLim');
    ti      = str2double(get(hObject,'String'));
    %xMax    = xLim(1)+tw;
    if (isempty(ti))
         set(hObject,'String','0')
    end
    %set(handles.a_t0,'XLim',[xLim(1) xMax]);
    setNeedsUpdate(hObject);
% --- Executes during object creation, after setting all properties.
function et_ti_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_ti (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function et_lp_Callback(hObject, eventdata, handles)
% hObject    handle to et_lp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of et_lp as text
%        str2double(get(hObject,'String')) returns contents of et_lp as a double
    setNeedsUpdate(hObject);
% --- Executes during object creation, after setting all properties.
function et_lp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_lp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function et_hp_Callback(hObject, eventdata, handles)
% hObject    handle to et_hp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of et_hp as text
%        str2double(get(hObject,'String')) returns contents of et_hp as a double
    setNeedsUpdate(hObject);
% --- Executes during object creation, after setting all properties.
function et_hp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_hp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function et_order_Callback(hObject, eventdata, handles)
% hObject    handle to et_order (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of et_order as text
%        str2double(get(hObject,'String')) returns contents of et_order as a double
    setNeedsUpdate(hObject);
% --- Executes during object creation, after setting all properties.
function et_order_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_order (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- Executes on button press in pb_start.
function pb_start_Callback(hObject, eventdata, handles)
% hObject    handle to pb_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    mode = 2;
    % Call AFE selection GUI
    GUI_AFEselection(0,0,0,0,0,handles,0,0,mode);
% --- Executes on button press in pb_preprocess.
function pb_preprocess_Callback(hObject, eventdata, handles)
% hObject    handle to pb_preprocess (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    preprocessMovie(hObject);
% --- Executes on selection change in pm_features.
function pm_features_Callback(hObject, eventdata, handles)
% hObject    handle to pm_features (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns pm_features contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pm_features
    setNeedsUpdate(hObject);
% --- Executes during object creation, after setting all properties.
function pm_features_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pm_features (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function et_rows_Callback(hObject, eventdata, handles)
% hObject    handle to et_rows (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of et_rows as text
%        str2double(get(hObject,'String')) returns contents of et_rows as a double
    % Clear figure and show channel numbers
    axes(handles.a_t0);
    cla;
    showChannelNumbers(hObject);
    setNeedsUpdate(hObject);
% --- Executes during object creation, after setting all properties.
function et_rows_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_rows (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function et_columns_Callback(hObject, eventdata, handles)
% hObject    handle to et_columns (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of et_columns as text
%        str2double(get(hObject,'String')) returns contents of et_columns as a double
    % Clear figure and show channel numbers
    axes(handles.a_t0);
    cla;
    showChannelNumbers(hObject);
    setNeedsUpdate(hObject);
% --- Executes during object creation, after setting all properties.
function et_columns_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_columns (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- Executes on button press in cb_vr.
function cb_vr_Callback(hObject, eventdata, handles)
% hObject    handle to cb_vr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of cb_vr
    setNeedsUpdate(hObject);
% --- Executes on button press in cb_bp.
function cb_bp_Callback(hObject, eventdata, handles)
% hObject    handle to cb_bp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of cb_bp
    setNeedsUpdate(hObject);
% --- Executes on button press in pb_playImage.
function pb_playImage_Callback(hObject, eventdata, handles)
% hObject    handle to pb_playImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    % Start or stop the timer, set message on button
    if strcmp(get(handles.playTimer,'Running'),'on')
        pauseMovie(hObject);
    else
        playMovie(hObject);
    end
% --- Executes on button press in pb_stopImage.
function pb_stopImage_Callback(hObject, eventdata, handles)
% hObject    handle to pb_stopImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    stopMovie(hObject);
% --- Executes on button press in pb_disconnect.
function pb_disconnect_Callback(hObject, eventdata, handles)
% hObject    handle to pb_disconnect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(hObject, 'UserData', 1); % Set disconnect button pressed
% --- Executes on selection change in pm_pType.
function pm_pType_Callback(hObject, eventdata, handles)
% hObject    handle to pm_pType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns pm_pType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pm_pType
% --- Executes during object creation, after setting all properties.
function pm_pType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pm_pType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function et_pNum_Callback(hObject, eventdata, handles)
% hObject    handle to et_pNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of et_pNum as text
%        str2double(get(hObject,'String')) returns contents of et_pNum as a double
% --- Executes during object creation, after setting all properties.
function et_pNum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_pNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function et_nCh_Callback(hObject, eventdata, handles)
% hObject    handle to et_nCh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of et_nCh as text
%        str2double(get(hObject,'String')) returns contents of et_nCh as a double
% --- Executes during object creation, after setting all properties.
function et_nCh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_nCh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- Executes on button press in cb_cont.
function cb_cont_Callback(hObject, eventdata, handles)
% hObject    handle to cb_cont (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of cb_cont
    % Disable/enable sample time textfield
    if get(hObject,'Value')
        set(handles.et_sT,'Enable', 'off');
    else
        set(handles.et_sT,'Enable','on');
    end
% --- Executes on button press in cb_live.
function cb_live_Callback(hObject, eventdata, handles)
% hObject    handle to cb_live (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of cb_live
function et_rTw_Callback(hObject, eventdata, handles)
% hObject    handle to et_rTw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of et_rTw as text
%        str2double(get(hObject,'String')) returns contents of et_rTw as a double
% --- Executes during object creation, after setting all properties.
function et_rTw_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_rTw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- Executes on button press in pushbutton9.
function pushbutton9_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%% Helper functions
function labels = watershedSegment(iData)
    labels = zeros(size(iData));
    K = 3; % Upscaling factor
    iData_us = imresize(iData,K);
    labels_us = watershed(-iData_us);
    for i = 1:size(iData,1)
        for j = 1:size(iData,2)
            pixels = labels_us((i*K-1):i*K,(j*K-1):j*K);
            label = mode(pixels(:));
            labels(i,j) = label;
        end
    end
function showChannelNumbers(hObject)
    % Get handles structure
    handles = guidata(hObject);
    % The HD helper already writes local electrode numbers on the map.
    if isappdata(handles.figure1,'OTB400_ChannelMapState')
        return
    end
    % Select figure,
    axes(handles.a_t0);
    % Get number of rows and columns
    r = str2double(get(handles.et_rows,'String'));
    c = str2double(get(handles.et_columns,'String'));
    xlim([0.5 c+0.5]);
    ylim([0.5 r+0.5]);
    % Draw numbers
    ch = 1;
    for i=1:c
        for j=1:r
            text(i,j,num2str(ch));
            ch = ch+1;
        end
    end
%% Recording functions
function startRecording(handles, afeSettings)
    % Capture focus
    figure(handles.figure1);
    % Get required informations from afeSettings structure
    nCh          = afeSettings.channels;
    sF           = afeSettings.sampleRate;
    deviceName   = afeSettings.name;
    ComPortType  = afeSettings.ComPortType;
    if isfield(afeSettings,'compressData')
        compressData = afeSettings.compressData;
    else
        compressData = 0;
    end
    if strcmp(ComPortType, 'COM')
        ComPortName = afeSettings.ComPortName;
    end
    % Save back acquisition parameters to the handles
    handles.nCh         = nCh;
    handles.sF          = sF;
    handles.ComPortType = ComPortType;
    if strcmp(ComPortType, 'COM')
        handles.ComPortName = ComPortName;
    end
    handles.deviceName  = deviceName;
    % Get recording options
    live = get(handles.cb_live,'Value');
    if live
        rows = str2double(get(handles.et_rows,'String'));
        cols = str2double(get(handles.et_columns,'String'));
    end
    cont = get(handles.cb_cont,'Value');
    % Get sampling time (if not continuous) and time window
    tW = str2double(get(handles.et_rTw,'String'));
    if contains(deviceName,'OTB400')
        if ~isfinite(tW) || tW <= 0
            error('OTB400: invalid recording window (seconds).');
        end
        tWs = round(tW*sF);           % Samples requested from the device
        if tWs < 1
            error('OTB400: time window contains no samples.');
        end
        tW = tWs/sF;                 % Exact duration of those samples
    else
        tWs = tW*sF;                % Original behaviour for other devices
    end
    handles.tW = tW;
    handles.tWs = tWs;
    if cont
        sT = tW;
        % Reset disconnect button status
        set(handles.pb_disconnect, 'UserData',0);
    else
        sT = str2double(get(handles.et_sT,'String'));
    end
    handles.sT = sT;
    handles.sTall = sT;
    % OTB400 HD: create interactive panel and configure the .NET device.
    % All parameters come from GUI_AFEselection; no channel count is fixed here.
    if contains(deviceName,'OTB400')
        if contains(deviceName,'HD')
            if ~isfield(afeSettings,'OTB400Electrodes')
                error('OTB400 HD: select electrodes in GUI_AFEselection first.');
            end
            electrodes = afeSettings.OTB400Electrodes;
            OTB400_ChannelMap('install',handles.figure1,handles.a_t0,nCh,electrodes);
            % Show the geometry actually used for the HD map.
            set(handles.et_rows,'String',num2str(8));
            set(handles.et_columns,'String',num2str(nCh/8));
            ot = OT_Acquire('hd',nCh,max(60,sT+10),electrodes);
        else
            OTB400_ChannelMap('remove',handles.figure1);
            ot = OT_Acquire('bipolar',nCh,max(60,sT+10));
        end
        handles.objOT = ot;
        % Protect .NET device also if the function returns early on error.
        otGuard = onCleanup(@() ot.disconnectBTdevice());
    else
        OTB400_ChannelMap('remove',handles.figure1);
    end
    % Connect the chosen device, it returns the connection object
    obj = ConnectDevice(handles);
    % Set the selected device and Start the acquisition
    SetDeviceStartAcquisition(handles, obj);
    % Collect data
    if ~cont % Non-continuous mode
        if contains(deviceName,'OTB400')
            nTotal = round(sT*sF);
            nWindows = ceil(nTotal/tWs);
        else
            nTotal = sT*sF;              % Original behaviour for other devices
            nWindows = sT/tW;
        end
        cDataAll = zeros(nTotal, nCh);
        for timeWindowNr = 1:nWindows
            firstSample = (timeWindowNr-1)*tWs+1;
            if contains(deviceName,'OTB400')
                nThisWindow = min(tWs,nTotal-firstSample+1);
            else
                nThisWindow = tWs;
            end
            [cData, error] = Acquire_tWs(deviceName, obj, nCh, nThisWindow, compressData);
            if error == 1
                errordlg('Error occurred during the acquisition!','Error');
                return
            end
            cDataAll(firstSample:firstSample+nThisWindow-1,:)=cData;
            if live
                previewTw(handles.a_t0,cData, rows, cols);
            end
            % Show current recording time
            if contains(deviceName,'OTB400')
                cT = (firstSample+nThisWindow-1)/sF;
            else
                cT = timeWindowNr*tW;
            end
            tT = sT;
            cT = [num2str(floor(cT/60)) ':' num2str(floor(mod(cT,60)),'%02d')];
            tT = [num2str(floor(tT/60)) ':' num2str(floor(mod(tT,60)),'%02d')];
            set(handles.t_msg, 'String', ['Recording... ' cT ' / ' tT]);
            drawnow;
        end
    else % Continuous mode
        % Show recording message
        set(handles.t_msg, 'String', 'Continuous recording...');
        drawnow;
        cDataAll = [];
        while ~get(handles.pb_disconnect, 'UserData') % Check if disconnect button pressed
            [cData, error] = Acquire_tWs(deviceName, obj, nCh, tWs, compressData);    % acquire a new time window of samples
            if error == 1
                errordlg('Error occurred during the acquisition!','Error');
                return
            end
            cDataAll = [cDataAll; cData];
            if live
                previewTw(handles.a_t0,cData, rows, cols);
            end
        end
        % Compute length of recorded session
        sT = size(cDataAll,1)/sF;
    end
    % Save data for recording session
    if isfield(handles,'recSession')
        handles = rmfield(handles,'recSession');
    end
    handles.recSession.sF = sF;
    handles.recSession.sT = sT;
    handles.recSession.nCh = nCh;
    handles.recSession.tdata = cDataAll;
    if contains(deviceName,'OTB400_HD')
        handles.recSession.OTB400Electrodes = afeSettings.OTB400Electrodes;
        handles.recSession.deviceName = char(deviceName);
        handles.recSession.OTB400VisibleChannels = ...
            OTB400_ChannelMap('mask',handles.figure1);
    end
    guidata(handles.figure1, handles);
    % Stop acquisition
    StopAcquisition(deviceName, obj);
    % Show message
    set(handles.t_msg, 'String', 'Recording finished!');
    setNeedsUpdate(handles.figure1);
%% Movie playback functions
function preprocessMovie(hObject)
    % Get handles structure
    handles = guidata(hObject);
    % Is there a loaded recSession?
    if isfield(handles,'recSession')
        recSession = handles.recSession;
    else
        set(handles.t_msg,'String','No recSession loaded...')      % Show message about acquisition
        return;
    end
    % Get frame data from timer
    movieSession = handles.playTimer.UserData;
    % Preprocessing variables
    tI      = str2double(get(handles.et_ti,'String'));
    tW      = str2double(get(handles.et_tw,'String'));
    sTi     = round(tI * recSession.sF);
    sTw     = round(tW * recSession.sF);
    allF    = get(handles.pm_features,'String');
    fID     = char(allF(get(handles.pm_features,'Value')));
    r       = str2double(get(handles.et_rows,'String'));
    c       = str2double(get(handles.et_columns,'String'));
    % Filter variables
    fLp     = str2double(get(handles.et_lp,'String'));
    fHp     = str2double(get(handles.et_hp,'String'));
    fOrder  = str2double(get(handles.et_order,'String'));
    % Options
    useBp   = get(handles.cb_bp, 'Value');
    useVr   = get(handles.cb_vr, 'Value');
    useWs   = get(handles.cb_ws, 'Value');
    % Initialise frame data structure
    if isfield(recSession,'nM') % Recorded session
        nF = (floor((size(recSession.tdata,1) - sTw)/sTi)+1)*recSession.nM;
        nM = recSession.nM;
    else % Live session
        nF = (floor((size(recSession.tdata,1) - sTw)/sTi)+1);
        nM = 1;
    end
    frames = struct('msg', cell(1,nF),...
                    'img', cell(1,nF),...
                    'lim', cell(1,nF));
    % Disable preprocessing button
    set(handles.pb_preprocess, 'Enable', 'off');
    % Go through moves of recording session
    cF = 1;
    for cM = 1 : nM
        % Variables to store limits
        minLim = +inf;
        maxLim = -inf;
        movData = recSession.tdata(:,:,cM);
        % Use Virtual Reference if selected
        if useVr
            movData = movData - mean(movData,2)*ones(1,size(movData,2));
        end
        % Starting frame of move
        sF = cF;
        % Go through all time windows
        for k = 1 : sTi : (size(movData,1)-sTw+1)
            if isfield(recSession,'nM')
                % Store name of movement if inside time
                if mod(k/recSession.sF, (recSession.cT + recSession.rT))...
                        <= recSession.cT
                    frames(cF).msg = recSession.mov(cM);
                else
                    frames(cF).msg = 'Rest...';
                end
            else
                frames(cF).msg = 'Live session';
            end
            % Get the data for the time window
            tempData = movData(k:k+sTw-1,:);
            % Filter raw data
            % TODO: Add more filtering/processing possibilities
            % Move filter to not be per frame?
            if useBp
                tempData = ApplyButterFilter(recSession.sF, fOrder, fLp, fHp, tempData);
            end
            % Compute Image (physical numbering for OTB400 HD)
            if isappdata(handles.figure1,'OTB400_ChannelMapState')
                iData = OTB400_ChannelMap('features',handles.figure1, ...
                    tempData,recSession.sF,fID);
            else
                iData = zeros(r,c);
                cIdx = 1;
                for i = 1 : c
                    for j = 1 : r
                        if cIdx <= recSession.nCh
                            feature = GetSigFeatures(tempData(:,cIdx), recSession.sF, {fID});
                            iData(j,i) = feature.(fID);
                            cIdx = cIdx+1;
                        else
                            break;
                        end
                    end
                end
            end
            if useWs
               labels = watershedSegment(iData); % Segment image
               for label = unique(labels)' % Average over each label
                   idxs = find(labels == label);
                   iData(idxs) = mean(iData(idxs));
               end
            end
            % Store frame
            frames(cF).img = iData;
            % Update limits - separate limits for each move
            minLim = min(minLim, min(iData(:)));
            maxLim = max(maxLim, max(iData(:)));
            % Advance current frame
            cF = cF + 1;
            % Display progress
            set(handles.t_msg,'String',...
                ['Preprocessing (' num2str(floor(100*cF/nF)) '%)'])
            drawnow
        end
        % Set limits for move
        for i = sF:(cF-1)
            frames(i).lim = [minLim maxLim];
        end
    end
    % Store data
    movieSession.frames = frames;
    movieSession.nF = nF;
    movieSession.cF = 1;
    movieSession.fT = tI;
    movieSession.needsUpdate = false;
    handles.playTimer.UserData = movieSession;
    % Update timer
    set(handles.playTimer, 'Period', tI);
    % Update UI
    updateSlider(hObject);
    set(handles.s_t0, 'Enable', 'on');
    set(handles.pb_playImage, 'Enable', 'on');
    set(handles.pb_stopImage, 'Enable', 'on');
    set(handles.t_msg,'String', 'Done!');
    % Store handles structure
    guidata(hObject, handles);
function updateSlider(hObject)
    % Get handles structure
    handles = guidata(hObject);
    % Get frame data from playback timer
    movieSession = handles.playTimer.UserData;
    % Update slider values
    set(handles.s_t0, 'Max', movieSession.nF);
    set(handles.s_t0, 'Value', movieSession.cF);
    set(handles.s_t0, 'SliderStep',...
        [1/movieSession.nF 10/movieSession.nF]);
    % Show current time
    cT = movieSession.cF*movieSession.fT;
    tT = movieSession.nF*movieSession.fT;
    cT = [num2str(floor(cT/60)) ':' num2str(floor(mod(cT,60)),'%02d')];
    tT = [num2str(floor(tT/60)) ':' num2str(floor(mod(tT,60)),'%02d')];
    set(handles.t_time, 'String', [cT ' / ' tT]);
    % Store handles structure
    guidata(hObject, handles);
function setNeedsUpdate(hObject)
    % Get handles structure
    handles = guidata(hObject);
    % Get frame data from playback timer
    movieSession = handles.playTimer.UserData;
    % Set update needed
    movieSession.needsUpdate = true;
    handles.playTimer.UserData = movieSession;
    % Enable preprocessing button
    set(handles.pb_preprocess, 'Enable', 'on');
    % Store handles structure
    guidata(hObject, handles);
function playMovie(hObject)
    % Get handles structure
    handles = guidata(hObject);
    % Start playback timer
    start(handles.playTimer);
    % Set button text
    set(handles.pb_playImage,'String','Pause');
function pauseMovie(hObject)
    % Get handles structure
    handles = guidata(hObject);
    % Stop playback timer
    stop(handles.playTimer);
    % Set button text
    set(handles.pb_playImage,'String','Play');
function stopMovie(hObject)
    % Get handles structure
    handles = guidata(hObject);
    % Stop playback timer
    stop(handles.playTimer);
    % Set play button text
    set(handles.pb_playImage,'String','Play');
    % Reset current frame
    movieSession = handles.playTimer.UserData;
    movieSession.cF = 1;
    handles.playTimer.UserData = movieSession;
    % Update view
    showFrame(handles.playTimer);
    % Store handles structure
    guidata(hObject, handles);
function pbTimer_callback(src, event)
    % Get frame data from timer
    movieSession = src.UserData;
    % Stop playback if current frames exceeds number of frames
    if movieSession.cF > movieSession.nF
        stopMovie(movieSession.axes);
        return
    end
    % Show current frame
    showFrame(src);
    % Increment current frame
    movieSession.cF = movieSession.cF + 1;
    % Store frame data in timer
    src.UserData = movieSession;
function showFrame(pbTimer)
    % Get frame data from timer
    movieSession = pbTimer.UserData;
    % Display image data for current frame
    axes(movieSession.axes);
    if isappdata(ancestor(movieSession.axes,'figure'),'OTB400_ChannelMapState')
        OTB400_ChannelMap('render',movieSession.axes, ...
            movieSession.frames(movieSession.cF).img, ...
            movieSession.frames(movieSession.cF).lim);
    else
        imagesc(movieSession.frames(movieSession.cF).img,...
                movieSession.frames(movieSession.cF).lim);
    end
    % Display name of movement
    handles = guidata(movieSession.axes);
    set(handles.t_msg,'String',movieSession.frames(movieSession.cF).msg)
    % Overlay channel numbers if chosen
    if get(handles.cb_showCh, 'Value')
        showChannelNumbers(handles.cb_showCh);
    end
    % Overlay centre of gravity if chosen
    if get(handles.cb_COG, 'Value')
        [cgx, cgy] = computeCOG(movieSession.frames(movieSession.cF).img);
        text(cgx, cgy, 'x');
    end
    % Update slider
    updateSlider(movieSession.axes);
function previewTw(ax,twData, rows, cols)
    % Interactive HD preview uses the physical electrode order.
    if isappdata(ancestor(ax,'figure'),'OTB400_ChannelMapState')
        OTB400_ChannelMap('preview',ax,twData);
        return
    end
    % Compute Image
    iData = zeros(rows,cols);
    cIdx = 1;
    for i = 1 : cols
        for j = 1 : rows
            if cIdx <= size(twData, 2)
                iData(j,i) = mean(abs(twData(:,cIdx)));
                cIdx = cIdx+1;
            else
                break;
            end
        end
    end
    % Show preview
    axes(ax);
    imagesc(iData);
    drawnow;
% --- Executes on button press in cb_showCh.
function cb_showCh_Callback(hObject, eventdata, handles)
% hObject    handle to cb_showCh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of cb_showCh
% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: delete(hObject) closes the figure
stop(handles.playTimer);
delete(handles.playTimer);
delete(hObject);
% --- Executes on button press in cb_ws.
function cb_ws_Callback(hObject, eventdata, handles)
% hObject    handle to cb_ws (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of cb_ws
setNeedsUpdate(hObject);
% --- Executes on button press in pb_lhsh.
function pb_lhsh_Callback(hObject, eventdata, handles)
% hObject    handle to pb_lhsh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Is there a loaded recSession?
if isfield(handles,'recSession')
    recSession = handles.recSession;
else
    set(handles.t_msg,'String','No recSession loaded...')      % Show message about acquisition
    return;
end
% Get reference channels
refChs = inputdlg('Enter channels for reference compartment (separated by commas)');
if isempty(refChs)
    return;
end
refChs = sscanf(refChs{1}, '%d %*[,]')
if isempty(refChs)
    warndlg('Please enter at least one channel for the reference compartment');
    return;
end
% Initialize compartment channel array
compChs = {};
% Get compartment channels
i = 1;
not_done = true;
while not_done
    chs = inputdlg(['Enter channels for compartment ' num2str(i) ' (separated by commas)']);
    if isempty(chs)
        return;
    else
        chs = sscanf(chs{1}, '%d %*[,]')
        if isempty(chs)
            not_done = false;
        else
            % Save channel numbers
            compChs = [compChs chs];
            i = i+1;
        end
    end
end
if isempty(compChs)
    warndlg('Please enter channels for at least one compartment');
    return;
end
% Get all used channels for filtering
allChs = unique(cat(1,refChs,compChs{:}));
% Unpack variables
nM = recSession.nM;
cT = recSession.cT;
rT = recSession.rT;
nR = recSession.nR;
sF = recSession.sF;
% Filter variables
useBp   = get(handles.cb_bp, 'Value');
fLp     = str2double(get(handles.et_lp,'String'));
fHp     = str2double(get(handles.et_hp,'String'));
fOrder  = str2double(get(handles.et_order,'String'));
% TODO: Do this on filtered/treated data?
nC = length(compChs);
cRTable = cell(nM + 1, nC + 2);
cRTable{1,1} = ' ';
cRTable{1,2} = 'R';
for i = 1:nC
    cRTable{1, i+2} = ['C' num2str(i) '/R'];
end
% Go through each movement
for cM = 1:nM
    % Get move data
    movData = recSession.tdata(:,:,cM);
    % Filter data
    if useBp
        for i = allChs
            movData(:,i) = ApplyButterFilter(sF, fOrder, fLp, fHp, movData(:,i));
        end
    end
    % Compute time indexes for contractions (inner 70%)
    contStarts = 0:(cT + rT):(nR - 1)*(cT + rT);
    contEnds = cT:(cT + rT):nR*(cT + rT);
    % Remove outer 30%
    contStarts = contStarts + 0.15*cT;
    contEnds = contEnds - 0.15*cT;
    % Compute indexes
    contStartIdxs = floor(contStarts*sF);
    contEndIdxs = floor(contEnds*sF);
    numIdxs = diff([contStartIdxs; contEndIdxs]);
    contIdxs = zeros(1, sum(numIdxs));
    n = 1; % Index variable for contIdxs
    for i=1:length(contStartIdxs)
        contIdxs(n:(n + numIdxs(i))) = contStartIdxs(i):contEndIdxs(i);
        n = n + numIdxs(i) + 1;
    end
    % Average for reference channels
    refAvg = mean(mean(abs(movData(contIdxs,refChs))));
    % Average for compartment channels
    compAvg = zeros(length(compChs),1);
    for i = 1:length(compAvg)
        cCompChs = compChs{i};
        compAvg(i) = mean(mean(abs(movData(contIdxs,cCompChs))));
    end
    disp(recSession.mov(cM));
    disp(refAvg)
    disp(compAvg)
    % Name of movement
    cRTable{cM + 1, 1} = recSession.mov{cM};
    % Reference strength
    cRTable{cM + 1, 2} = refAvg;
    % Ratios
    cRTable{cM + 1,3:end} = (compAvg./refAvg).';
end
GUI_CRTable('Data',cRTable);
% --- Executes on button press in pb_taskmaps.
function pb_taskmaps_Callback(hObject, eventdata, handles)
% hObject    handle to pb_taskmaps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    % Get handles structure
    handles = guidata(hObject);
    % Is there a loaded recSession?
    if isfield(handles,'recSession')
        recSession = handles.recSession;
    else
        set(handles.t_msg,'String','No recSession loaded...')      % Show message about acquisition
        return;
    end
    % Unpack variables
    cT = recSession.cT;
    rT = recSession.rT;
    nR = recSession.nR;
    sF = recSession.sF;
    % Preprocessing variables
    r       = str2double(get(handles.et_rows,'String'));
    c       = str2double(get(handles.et_columns,'String'));
    % Filter variables
    fLp     = str2double(get(handles.et_lp,'String'));
    fHp     = str2double(get(handles.et_hp,'String'));
    fOrder  = str2double(get(handles.et_order,'String'));
    % Options
    useBp   = get(handles.cb_bp, 'Value');
    usePLH  = get(handles.cb_plh, 'Value');
    useVr   = get(handles.cb_vr, 'Value');
    useWs   = get(handles.cb_ws, 'Value');
    useCOG  = get(handles.cb_COG, 'Value');
    % Initialise frame data structure
    if isfield(recSession,'nM') % Recorded session
        nM = recSession.nM;
    else % Live session
        warndlg('Can only be performed on recording sessions');
        return;
    end
    % Compute time indexes for contractions (inner 70%)
    contStarts = 0:(cT + rT):(nR - 1)*(cT + rT);
    contEnds = cT:(cT + rT):nR*(cT + rT);
    % Remove outer 30%
    contStarts = contStarts + 0.15*cT;
    contEnds = contEnds - 0.15*cT;
    % Compute indexes
    contStartIdxs = floor(contStarts*sF);
    contEndIdxs = floor(contEnds*sF);
    numIdxs = diff([contStartIdxs; contEndIdxs]);
    contIdxs = zeros(1, sum(numIdxs));
    n = 1; % Index variable for contIdxs
    for i=1:length(contStartIdxs)
        contIdxs(n:(n + numIdxs(i))) = contStartIdxs(i):contEndIdxs(i);
        n = n + numIdxs(i) + 1;
    end
    % Go through moves of recording session
    for cM = 1 : nM
        % Variables to store limits
        minLim = +inf;
        maxLim = -inf;
        movData = recSession.tdata(:,:,cM);
        % Use Virtual Reference if selected
        if useVr
            movData = movData - mean(movData,2)*ones(1,size(movData,2));
        end
        % Use BP filter if seleted
        if useBp
            movData = ApplyButterFilter(recSession.sF, fOrder, fLp, fHp, movData);
        end
        % Use PLH filter
        if usePLH
            movData = BSbutterPLHarmonics(recSession.sf, movData);
        end
        % Compute Image
        iData = zeros(r,c);
        cIdx = 1;
        for i = 1 : c
            for j = 1 : r
                if cIdx <= recSession.nCh
                    iData(j,i) = mean(abs(movData(contIdxs,cIdx)));
                    cIdx = cIdx + 1;
                else
                    break;
                end
            end
        end
        % Compute COG
        if useCOG
            [cgx, cgy] = computeCOG(iData, 0);
        end
        if useWs
           labels = watershedSegment(iData); % Segment image
           for label = unique(labels)' % Average over each label
               idxs = find(labels == label);
               iData(idxs) = mean(iData(idxs));
           end
        end
        % Update limits - separate limits for each move
        % minLim = min(minLim, min(iData(:)));
        % maxLim = max(maxLim, max(iData(:)));
        % Show map
        figure;
        imagesc(iData);
        colorbar;
        if useCOG
            text(cgx, cgy, 'x');
            disp([recSession.mov{cM}...
                  ', Center of gravity: ('...
                  num2str(cgx) ', ' num2str(cgy) ')']);
        end
        title(recSession.mov(cM));
    end
    % Store handles structure
    guidata(hObject, handles);
% --- Executes on button press in cb_COG.
function cb_COG_Callback(hObject, eventdata, handles)
% hObject    handle to cb_COG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of cb_COG
function [cgx, cgy] = computeCOG(iData, minVal)
% Compute center of gravity of image in iData
% minVal is an optional argument that is subtracted from the image,
% otherwise the minimum value of the image is used
if nargin == 2
    iData = iData - minVal;
else
    iData = iData - min(iData(:));
end
[index_x, index_y] = meshgrid(1:size(iData,2), 1:size(iData,1));
cgx = sum(sum(index_x.*iData))/sum(sum(iData));
cgy = sum(sum(index_y.*iData))/sum(sum(iData));
% --- Executes on button press in cb_plh.
function cb_plh_Callback(hObject, eventdata, handles)
% hObject    handle to cb_plh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of cb_plh

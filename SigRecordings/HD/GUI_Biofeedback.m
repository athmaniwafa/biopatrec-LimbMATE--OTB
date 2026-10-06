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
% GUI for performing biofeedback training
%
% ------------------------- Updates & Contributors ------------------------
% 2017-09-24 / Simon Nilsson  / Created initial version 

function varargout = GUI_Biofeedback(varargin)
% GUI_BIOFEEDBACK MATLAB code for GUI_Biofeedback.fig
%      GUI_BIOFEEDBACK, by itself, creates a new GUI_BIOFEEDBACK or raises the existing
%      singleton*.
%
%      H = GUI_BIOFEEDBACK returns the handle to a new GUI_BIOFEEDBACK or the handle to
%      the existing singleton*.
%
%      GUI_BIOFEEDBACK('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI_BIOFEEDBACK.M with the given input arguments.
%
%      GUI_BIOFEEDBACK('Property','Value',...) creates a new GUI_BIOFEEDBACK or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI_Biofeedback_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI_Biofeedback_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUI_Biofeedback

% Last Modified by GUIDE v2.5 24-Sep-2017 21:35:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_Biofeedback_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_Biofeedback_OutputFcn, ...
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


% --- Executes just before GUI_Biofeedback is made visible.
function GUI_Biofeedback_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI_Biofeedback (see VARARGIN)

% Initialise animation timer
fps = 30;
spf = round(1/fps, 3);
animTimer = timer('ExecutionMode','fixedRate',...
                       'Period',spf,...
                       'TimerFcn',@animCallback);
animStruct = struct('axis', handles.a_main,...
                    'textBar', handles.t_msg,...
                    'options', [],...
                    'animVars', [],...
                   'animObjs', [],...
                   'logDir', [],...
                   'updateFun', @updateCS,...
                   'activityFun', @actDoNothing,...
                   'initFun', @initCS,...
                   'actVar', []);
% Initialise figure
[animVars, animObjs] = animStruct.initFun(animStruct.axis);
animStruct.animVars = animVars;
animStruct.animObjs = animObjs;   
               
animTimer.UserData = animStruct;
handles.animTimer = animTimer;

% Initialise recording timer
recTimer = timer('ExecutionMode','fixedRate',...
                 'Period',1,... % Set in startBiofeedback
                 'TimerFcn',@recCallback,...
                 'StopFcn',@recStopCallback);
recStruct = struct('animTimer',animTimer,...
                   'updateAnimVarsFun', @computeStrengths,...
                   'calibFun', @calibrateStrengths,...
                   'textBar', handles.t_msg,...
                   'AFEObj',[],...
                   'AFEName','',...
                   'nCh',0,...
                   'tWs',0,...
                   'sF',0,...
                   'cVals',[],...
                   'options',[]);
recTimer.UserData = recStruct;
handles.recTimer = recTimer;

% Preselect channels if applicable
if ~isempty(varargin)
    set(handles.lb_left, 'Value', varargin{1});
    set(handles.lb_right, 'Value', varargin{2});
end

% Initialise variables for keyboard control
handles.figure1.UserData = struct('left', 0,...
                                  'right', 0,...
                                  'up', 0,...
                                  'down', 0);

% Choose default command line output for GUI_Biofeedback
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GUI_Biofeedback wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GUI_Biofeedback_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in lb_left.
function lb_left_Callback(hObject, eventdata, handles)
% hObject    handle to lb_left (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lb_left contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lb_left


% --- Executes during object creation, after setting all properties.
function lb_left_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lb_left (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lb_right.
function lb_right_Callback(hObject, eventdata, handles)
% hObject    handle to lb_right (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lb_right contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lb_right


% --- Executes during object creation, after setting all properties.
function lb_right_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lb_right (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_stop.
function pb_stop_Callback(hObject, eventdata, handles)
% hObject    handle to pb_stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(hObject, 'UserData', 1);
stop(handles.recTimer);
stop(handles.animTimer);
enableControls(handles);

% --- Executes on button press in pb_start.
function pb_start_Callback(hObject, eventdata, handles)
% hObject    handle to pb_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(handles.cb_debug, 'value') % Debug (offline) mode
    startDebugging(handles);
else % Normal mode
    mode = 3;
    % Call AFE selection GUI
    GUI_AFEselection(0,0,0,0,0,handles,0,0,mode);
end

function et_tW_Callback(hObject, eventdata, handles)
% hObject    handle to et_tW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tW as text
%        str2double(get(hObject,'String')) returns contents of et_tW as a double


% --- Executes during object creation, after setting all properties.
function et_tW_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function s_speed_Callback(hObject, eventdata, handles)
% hObject    handle to s_speed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function s_speed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to s_speed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function et_lPf_Callback(hObject, eventdata, handles)
% hObject    handle to et_lPf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_lPf as text
%        str2double(get(hObject,'String')) returns contents of et_lPf as a double


% --- Executes during object creation, after setting all properties.
function et_lPf_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_lPf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_hPf_Callback(hObject, eventdata, handles)
% hObject    handle to et_hPf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_hPf as text
%        str2double(get(hObject,'String')) returns contents of et_hPf as a double


% --- Executes during object creation, after setting all properties.
function et_hPf_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_hPf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_fO_Callback(hObject, eventdata, handles)
% hObject    handle to et_fO (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_fO as text
%        str2double(get(hObject,'String')) returns contents of et_fO as a double


% --- Executes during object creation, after setting all properties.
function et_fO_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_fO (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_min_l_Callback(hObject, eventdata, handles)
% hObject    handle to et_min_l (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_min_l as text
%        str2double(get(hObject,'String')) returns contents of et_min_l as a double


% --- Executes during object creation, after setting all properties.
function et_min_l_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_min_l (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_max_l_Callback(hObject, eventdata, handles)
% hObject    handle to et_max_l (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_max_l as text
%        str2double(get(hObject,'String')) returns contents of et_max_l as a double


% --- Executes during object creation, after setting all properties.
function et_max_l_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_max_l (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
stop(handles.recTimer);
stop(handles.animTimer);
delete(handles.recTimer);
delete(handles.animTimer);
delete(hObject);


% --- Executes on button press in pb_arkanoid.
function pb_arkanoid_Callback(hObject, eventdata, handles)
% hObject    handle to pb_arkanoid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% PLEASE NOTE: The Arkanoid files is not included by default due to
% copyright considerations. Please put the contents of
% https://github.com/Awilum/html5-arkanoid in a folder named 'arkanoid'
% in the same folder as this file to use it.

% Check that recording is running
if strcmp(handles.animTimer.running, 'off')
    warndlg('Please start recording first');
    return;
end
% Find Chrome browser
if ~isfield(handles, 'chromePath')
    [fn, p, ~] = uigetfile('chrome.exe', 'Please locate Chrome');
    handles.chromePath = [p fn];
end

animStruct = handles.animTimer.UserData;

% Create robot
import java.awt.*;
import java.awt.event.*;
animStruct.actVar=Robot;
animStruct.activityFun = @actMouseControl;

handles.animTimer.UserData = animStruct;

% Launch browser
% TODO: Add support for other systems?
currPath = mfilename('fullpath');
currPath = regexprep(currPath, '\\[^\\]*$', '');
system(['"' handles.chromePath '" --chrome-frame --start-maximized --disable-gpu-shader-disk-cache --app="' currPath '\arkanoid\arkanoid.html"']);

% Log start if appropriate
if animStruct.options.loggingEnabled
    logActMessage('Arkanoid started', animStruct.logFile);
end

guidata(hObject, handles);

% --- Executes on button press in pb_score.
function pb_score_Callback(hObject, eventdata, handles)
% hObject    handle to pb_score (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Check that recording is running
if strcmp(handles.animTimer.running, 'off')
    warndlg('Please start recording first');
    return;
end

% Set update function, initialise scoring variables
animStruct = handles.animTimer.UserData;

% Initialize variables
axes(animStruct.axis);
goalRect = rectangle('Visible','off');
animStruct.actVar = struct('state', 'nextLevel',...
                           'level',0,...
                           'goalLimits', []);
animStruct.actGraphics = struct('goalRect', goalRect);
animStruct.activityFun = @actScoreSession;

handles.animTimer.UserData = animStruct;

function et_min_r_Callback(hObject, eventdata, handles)
% hObject    handle to et_min_r (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_min_r as text
%        str2double(get(hObject,'String')) returns contents of et_min_r as a double


% --- Executes during object creation, after setting all properties.
function et_min_r_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_min_r (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function et_max_r_Callback(hObject, eventdata, handles)
% hObject    handle to et_max_r (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_max_r as text
%        str2double(get(hObject,'String')) returns contents of et_max_r as a double


% --- Executes during object creation, after setting all properties.
function et_max_r_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_max_r (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_mult_Callback(hObject, eventdata, handles)
% hObject    handle to et_mult (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_mult as text
%        str2double(get(hObject,'String')) returns contents of et_mult as a double


% --- Executes during object creation, after setting all properties.
function et_mult_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_mult (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key release with focus on figure1 or any of its controls.
function figure1_WindowKeyReleaseFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was released, in lower case
%	Character: character interpretation of the key(s) that was released
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) released
% handles    structure with handles and user data (see GUIDATA)
switch eventdata.Key
    case 'escape' % Stop current animation activity
        stopActivity(handles);
    % Directions for keyboard control
    case 'rightarrow'
        hObject.UserData.right = 0;
    case 'leftarrow'
        hObject.UserData.left = 0;
    case 'uparrow'
        hObject.UserData.up = 0;
    case 'downarrow'
        hObject.UserData.down = 0;
end


% --- Executes on key press with focus on figure1 or any of its controls.
function figure1_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
switch eventdata.Key
    % Directions for keyboard control
    case 'rightarrow'
        hObject.UserData.right = 1;
    case 'leftarrow'
        hObject.UserData.left = 1;
    case 'uparrow'
        hObject.UserData.up = 1;
    case 'downarrow'
        hObject.UserData.down = 1;
end


% --- Executes on button press in cb_debug.
function cb_debug_Callback(hObject, eventdata, handles)
% hObject    handle to cb_debug (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_debug


% --- Executes on button press in togglebutton1.
function togglebutton1_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebutton1


% --- Executes on button press in cb_log.
function cb_log_Callback(hObject, eventdata, handles)
% hObject    handle to cb_log (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_log


% --- Executes on button press in cb_calib.
function cb_calib_Callback(hObject, eventdata, handles)
% hObject    handle to cb_calib (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_calib


% --- Executes on selection change in pm_mode.
function pm_mode_Callback(hObject, eventdata, handles)
% hObject    handle to pm_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pm_mode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pm_mode

animStruct = handles.animTimer.UserData;
recStruct = handles.recTimer.UserData;

% Set init and update functions according to menu choice
val = get(hObject, 'Value');
switch val;
    case 1 % CS
        animStruct.initFun = @initCS;
        animStruct.updateFun = @updateCS;
        recStruct.updateAnimVarsFun = @computeStrengths;
        recStruct.calibFun = @calibrateStrengths;
        set(handles.p_CS, 'Visible', 'on');
        set(handles.p_COG, 'Visible', 'off');
    case 2 % COG
        animStruct.initFun = @initCOG;
        animStruct.updateFun = @updateCOG;
        recStruct.updateAnimVarsFun = @computeCOG;
        recStruct.calibFun = @calibrateCOG;
        set(handles.p_COG, 'Visible', 'on');
        set(handles.p_CS, 'Visible', 'off');
end

% Reinitialize
delete(animStruct.animObjs);
[animVars, animObjs] = animStruct.initFun(animStruct.axis);
animStruct.animVars = animVars;
animStruct.animObjs = animObjs;

handles.animTimer.UserData = animStruct;
handles.recTimer.UserData = recStruct;


% --- Executes during object creation, after setting all properties.
function pm_mode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pm_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_COGRows_Callback(hObject, eventdata, handles)
% hObject    handle to et_COGRows (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_COGRows as text
%        str2double(get(hObject,'String')) returns contents of et_COGRows as a double


% --- Executes during object creation, after setting all properties.
function et_COGRows_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_COGRows (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_COGColumns_Callback(hObject, eventdata, handles)
% hObject    handle to et_COGColumns (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_COGColumns as text
%        str2double(get(hObject,'String')) returns contents of et_COGColumns as a double


% --- Executes during object creation, after setting all properties.
function et_COGColumns_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_COGColumns (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cb_COGFlip.
function cb_COGFlip_Callback(hObject, eventdata, handles)
% hObject    handle to cb_COGFlip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_COGFlip



function et_COGSpeed_Callback(hObject, eventdata, handles)
% hObject    handle to et_COGSpeed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_COGSpeed as text
%        str2double(get(hObject,'String')) returns contents of et_COGSpeed as a double


% --- Executes during object creation, after setting all properties.
function et_COGSpeed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_COGSpeed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_COGRef_Callback(hObject, eventdata, handles)
% hObject    handle to et_COGRef (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_COGRef as text
%        str2double(get(hObject,'String')) returns contents of et_COGRef as a double


% --- Executes during object creation, after setting all properties.
function et_COGRef_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_COGRef (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_COGMin_Callback(hObject, eventdata, handles)
% hObject    handle to et_COGMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_COGMin as text
%        str2double(get(hObject,'String')) returns contents of et_COGMin as a double


% --- Executes during object creation, after setting all properties.
function et_COGMin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_COGMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_COGMax_Callback(hObject, eventdata, handles)
% hObject    handle to et_COGMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_COGMax as text
%        str2double(get(hObject,'String')) returns contents of et_COGMax as a double


% --- Executes during object creation, after setting all properties.
function et_COGMax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_COGMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_fitts.
function pb_fitts_Callback(hObject, eventdata, handles)
% hObject    handle to pb_fitts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Check that recording is running
if strcmp(handles.animTimer.running, 'off')
    warndlg('Please start recording first');
    return;
end

% Set update function, initialise scoring variables
animStruct = handles.animTimer.UserData;

% Initialize variables
axes(animStruct.axis);
goalRect = rectangle('Visible','off');
reps = FL_generateReps([30, 30, 60, 60], [13, 13, 18, 18], 2);
animStruct.actVar = struct('state', 'nextLevel',...
                           'reps', reps,...
                           'dT', 1,...
                           'tO', 15,...
                           'wasInGoal', false);
animStruct.actGraphics = struct('goalRect', goalRect);
animStruct.activityFun = @actFittsLawTest;

handles.animTimer.UserData = animStruct;

%% USER FUNCTIONS

% GUI flow functions

function [handlesOut, obj] = prepareAfe(handlesIn, afeSettings, tW)
%PREPAREAFE Prepare and connect to AFE
%   Prepares AFE options and starts the acquisition    
    % Copy input handles structure
    handlesOut = handlesIn;

    % Get required informations from afeSettings structure
    nCh          = afeSettings.channels;
    sF           = afeSettings.sampleRate;
    deviceName   = afeSettings.name;
    ComPortType  = afeSettings.ComPortType;

    % ConnectDevice needs these fields
    handlesOut.tW = tW;
    handlesOut.sTall = ceil(tW);
    handlesOut.sT = tW;
    handlesOut.nCh = nCh;
    handlesOut.sF = sF;
    handlesOut.tWs = tW*sF;
    handlesOut.ComPortType = ComPortType;
    if strcmp(ComPortType, 'COM')
        handlesOut.ComPortName = afeSettings.ComPortName;     
    end
    handlesOut.deviceName  = deviceName;

    % Connect the chosen device, it returns the connection object
    obj = ConnectDevice(handlesOut);

    % Set timeout to a more reasonable value
    obj.Timeout = handlesOut.sTall*2;

    % Set the selected device and Start the acquisition
    SetDeviceStartAcquisition(handlesOut, obj);
    RequestSamplesRHA32(obj, handlesOut.tWs)
    % Collect starting samples
    pause(tW);

function startDebugging(handles)
%STARTDEBUGGING Start debugging sessions
%   Starts a biofeedback session with keyboard control
%   for debugging and development
%   Arrow left/right to control bar
%   Arrow up/down to increase/decrease speed    
    % Read recording options
    options = readOptionsToStruct(handles);

    disableControls(handles);

    % Capture focus
    figure(handles.figure1);

    % Start animation
    startAnimation(handles, options);

    % Show recording message
    set(handles.t_msg, 'String', 'Debug mode...');
    drawnow;

    animStruct = handles.animTimer.UserData;
    movingBar = animStruct.animObjs(end);

    set(handles.pb_stop, 'UserData', 0);
    while ~get(handles.pb_stop, 'UserData') % Check if stop button pressed
        newPos = movingBar.Position(1);
        
        % Parse keyboard directional inpute
        directions = handles.figure1.UserData;
        if directions.left
            newPos = newPos - 0.01;
        end
        if directions.right
            newPos = newPos + 0.01;
        end
        % Limit position between 0 and 1
        newPos = max(newPos, 0);
        newPos = min(newPos, 1 - movingBar.Position(3));
        
        % Save modified fields
        movingBar.Position(1) = newPos;
        
        % Pause to process callbacks
        pause(0.001);
    end

    % Show message, enable controls, save handles structure
    set(handles.t_msg, 'String', 'Finished!');
    enableControls(handles);
    guidata(handles.figure1, handles);

function startBiofeedback(handles, afeSettings)
%STARTBIOFEEDBACK Start biofeedback session
%   Reads options, connects to AFE,
%   starts animation and recording timers    
    % Read recording options
    options = readOptionsToStruct(handles);

    recStruct = handles.recTimer.UserData;

    disableControls(handles);

    % Capture focus
    figure(handles.figure1);

    % Calibration of signal levels
    if options.calibrationEnabled
        recStruct.calibFun(options, handles, afeSettings);
        return;
    end

    % Prepare AFE parameters, connect to AFE
    [handles, obj] = prepareAfe(handles, afeSettings, options.tW);

    % Start animation
    startAnimation(handles, options);

    % Set recording parameters
    recStruct.AFEObj = obj;
    recStruct.AFEName = afeSettings.name;
    recStruct.nCh = afeSettings.channels;
    recStruct.tWs = handles.tWs; % Computed in prepareAfe
    recStruct.sF = afeSettings.sampleRate;
    recStruct.CData = [];
    recStruct.options = options;
    if options.loggingEnabled
        % Log options
        save([options.logDir '\options.mat'],'-struct','options');
        recStruct.lastLog = clock; % For periodical logging
        recStruct.logInterval = 600; % Seconds
        animStruct = recStruct.animTimer.UserData;
        logActMessage('Recording started', animStruct.logFile);
    end
    handles.recTimer.UserData = recStruct;

    % Show recording message
    set(handles.t_msg, 'String', 'Continuous recording...');
    drawnow;

    % Start recording timer
    set(handles.recTimer,'Period',options.tW + 0.05);
    start(handles.recTimer);

    % Save handles structure
    guidata(handles.figure1, handles);

function startAnimation(handles, options)
%STARTANIMATION Start animation
%   Saves options to animation timer and starts it
%   Creates activity logfile if logging enabled      

    % Save options
    animStruct = handles.animTimer.UserData;
    animStruct.options = options;
    if options.loggingEnabled
        % Create activity log file
        animStruct.logFile = fopen([options.logDir '\actLog.txt'], 'wt');
    end
    handles.animTimer.UserData = animStruct;
    
    % Start animation
    start(handles.animTimer);

%% CS functions

function [animVars, animObjs] = initCS(ax)
%INITCS Initialize graphics and variables for COG mode
%   Returns initialized animation vars and graphics objects    
    axis(ax);
    cla;
    axis([0 1 0 1]);
    axis off;
    leftBar = rectangle('Position', [0.1875 0.25 0.125 0.375],...
                        'FaceColor', [0 0 1]);
    rightBar = rectangle('Position', [0.6875 0.25 0.125 0.375],...
                        'FaceColor', [0 0 1]);
    movingBar = rectangle('Position', [0.4750 0.01 0.05 0.23],...
                        'FaceColor', [0 0 0]);

    animVars = [0, 0];
    animObjs = [leftBar, rightBar, movingBar];

function computeStrengths(options, cVals, animTimer)
%COMPUTESTRENGTHS Compute compartment strength
%   Called by recording timer to compute compartment strengths
%   Stores computed values in animation timer    
    % Unpack parameters
    leftChannels = options.leftChannels;
    rightChannels = options.rightChannels;
    maxL = options.signalMaxLeft;
    minL = options.signalMinLeft;
    maxR = options.signalMaxRight;
    minR = options.signalMinRight;

    % Compute strengths
    leftStrength = max(mean(cVals(leftChannels)) - minL, 0);
    leftStrength = min(leftStrength/(maxL - minL),1);
    rightStrength = max(mean(cVals(rightChannels)) - minR, 0);
    rightStrength = min(rightStrength/(maxR - minR),1);

    % Update animation timer with strength values
    animStruct = animTimer.UserData;
    animStruct.animVars = [leftStrength, rightStrength];
    animTimer.UserData = animStruct;

function calibrateStrengths(options, handles, afeSettings)
%CALIBRATESTRENGTHS Calibration function for COG mode
%   Records data to set signal min and signal max
%   for both compartments.
%   Updates the corresponding values in the GUI    
    cT = 10; % Calibration time

    % Unpack parameters          
    leftChannels = options.leftChannels;
    rightChannels = options.rightChannels;

    sF = afeSettings.sampleRate;
    nCh = afeSettings.channels;
    tWs = options.tW*afeSettings.sampleRate;

    minL = Inf;
    minR = Inf;
    maxL = -Inf;
    maxR = -Inf;

    % Prepare AFE parameters, connect to AFE
    [handles, obj] = prepareAfe(handles, afeSettings, options.tW);

    while cT >= 0
        tic;
        
        % Acquire current time window of samples
        cData = AcquireSamplesRHA32(obj, nCh, tWs);
        % Request new set of samples
        RequestSamplesRHA32(obj, tWs);
        
        cVals = processTw(options, sF, cData);
        
        lVal = mean(cVals(leftChannels));
        rVal = mean(cVals(rightChannels));
        
        minL = min(minL, lVal);
        minR = min(minR, rVal);
        maxL = max(maxL, lVal);
        maxR = max(maxR, rVal);
        
        set(handles.t_msg, 'String',...
            ['Calibrating, ' num2str(round(cT,3)) 's remaining.']);
        drawnow;
        cT = cT - toc;
    end

    disp([minL minR maxL maxR]);
    set(handles.et_min_l, 'String', num2str(minL));
    set(handles.et_min_r, 'String', num2str(minR));
    set(handles.et_max_l, 'String', num2str(maxL));
    set(handles.et_max_r, 'String', num2str(maxR));

    % Stop acquisition, enable controls
    StopAcquisition(afeSettings.name, obj);
    enableControls(handles);

function updateCS( animVars, animObjs, options )
%UPDATECS Animation callback for the CS mode
%   Called by animation timer to calculate and set
%   new position of moving bar each frame

    % Unpack arguments
    leftStrength = animVars(1);
    rightStrength = animVars(2);

    leftBar  = animObjs(1);
    rightBar = animObjs(2);
    movingBar = animObjs(3);

    speedMult = options.speedMult;

    % Update strength bars
    leftBar.Position(4) = leftStrength*0.75;
    rightBar.Position(4) = rightStrength*0.75;

    % Compute speed of moving bar
    barSpeed = speedMult*(rightStrength - leftStrength);

    % Update moving bar position
    currPos = movingBar.Position(1);
    newPos = currPos + barSpeed;
    newPos = max(newPos, 0);
    newPos = min(newPos, 0.95);
    movingBar.Position(1) = newPos;

%% COG functions

function [animVars, animObjs] = initCOG(ax)
%INITCOG Initialize graphics and variables for COG mode
%   Returns initialized animation vars and graphics objects
    axis(ax);
    cla;
    axis([0 1 0 1]);
    axis off;

    movingBar = rectangle('Position', [0.4750 0.01 0.05 0.23],...
                        'FaceColor', [0 0 0]);
                    
    HDax = axes('Position', [0.295 0.35 0.4 0.6]);
    axis([0 1 0 1]);
    axis off;

        
    animVars = [0, 0];
    animObjs = [HDax, movingBar];

function computeCOG(options, cVals, animTimer)
%COMPUTECOG Compute lateral COG and strength multiplier
%   Called by recording timer to compute lateral COG
%   and strength multiplier for current time window.
%   Stores computed values in animation timer
    % Unpack parameters
    rows = options.COGRows;
    columns = options.COGColumns;
    refPos = options.COGRef;
    flipColumns = options.COGFlip;
    sMin = options.COGMin;
    sMax = options.COGMax;
    % Compute HD-EMG map
    cIdx = 1;
    nCh = numel(cVals);
    iData = zeros(rows, columns);
    for i = 1 : columns
        for j = 1 : rows
            if cIdx <= nCh
                iData(j,i) = cVals(cIdx);
                cIdx = cIdx + 1;
            else
                break;
            end
        end
    end
    if flipColumns
        iData = fliplr(iData);
    end

    % Average strength and strength multiplier
    avgStrength = mean(iData(:));
    strengthMult = abs((avgStrength - options.COGMin)/(options.COGMax - options.COGMin));
    strengthMult = max(min(strengthMult,1),0);

    % Compute COG after removing minimum signal level
    [index_x, ~] = meshgrid(1:size(iData,2), 1:size(iData,1));
    cgx = sum(sum(index_x.*(iData - options.COGMin)))/...
                sum(sum((iData - options.COGMin)));
    cgxNorm = (cgx - 1)/(columns - 1);

    xmin = 0.5;
    xmax = columns + 0.5;
    % ymin = 0.5;
    ymax = rows + 0.5;

    COGBarSize = 0.008 * (xmax - xmin);
    refBarSize = 0.016 * (xmax - xmin);

    % Update animation timer with strength values
    animStruct = animTimer.UserData;
    animObjs = animStruct.animObjs;

    % Draw HD-EMG map
    HDAx   = animObjs(1);
    imagesc([1 columns], [1 rows], iData, 'Parent', HDAx);
    HDAx.CLim = [sMin sMax];
    HDAx.XTick = 1:columns;
    HDAx.YTick = 1:rows;

    % Draw reference and COG bars
    COGBarPos = cgx - COGBarSize/2;
    refBarPos = 1 + refPos * (columns - 1) - refBarSize/2;

    refBar = rectangle('Position', [refBarPos 0 refBarSize ymax],...
                        'FaceColor', [0 0 0], 'Parent', HDAx);
    COGBar = rectangle('Position', [COGBarPos 0 COGBarSize ymax],...
                        'FaceColor', [0 1 1]*strengthMult, 'Parent', HDAx);
    % Update animation variables                
    animStruct.animObjs = animObjs;
    animStruct.animVars = [cgxNorm - refPos, strengthMult];
    animTimer.UserData = animStruct;

function calibrateCOG(options, handles, afeSettings)
%CALIBRATECOG Calibration function for COG mode
%   Records data to set reference COG, signal min and signal max
%   Updates the corresponding values in the GUI   
    pT = 5; % Pause time
    cT = 5; % Calibration time, COG
    sT = 3; % Calibration time, signal levels

    % Unpack parameters
    rows = options.COGRows;
    columns = options.COGColumns;
    flipColumns = options.COGFlip;

    sF = afeSettings.sampleRate;
    nCh = afeSettings.channels;
    tWs = options.tW*afeSettings.sampleRate;

    CalibMessageCOG(handles, pT, 'Prepare for COG calibration.');

    % Prepare AFE parameters, connect to AFE
    [handles, obj] = prepareAfe(handles, afeSettings, options.tW);

    % Calibration of COG
    iDataAll = [];
    while cT >= 0
        tic;
        
        % Acquire current time window of samples
        cData = AcquireSamplesRHA32(obj, nCh, tWs);
        % Request new set of samples
        RequestSamplesRHA32(obj, tWs);
        
        cVals = processTw(options, sF, cData);
        
        % Compute HD-EMG map
        cIdx = 1;
        nCh = numel(cVals);
        iData = zeros(rows, columns);
        for i = 1 : columns
            for j = 1 : rows
                if cIdx <= nCh
                    iData(j,i) = cVals(cIdx);
                    cIdx = cIdx + 1;
                else
                    break;
                end
            end
        end
        if flipColumns
            iData = fliplr(iData);
        end
        
        iDataAll = cat(3, iDataAll, iData);
        
        set(handles.t_msg, 'String',...
            ['Calibrating COG, ' num2str(round(cT,3)) 's remaining.']);
        drawnow;
        cT = cT - toc;
    end

    CalibMessageCOG(handles, pT, 'Prepare for minimum level calibration.');

    %sMin = Inf;
    %sMax = -Inf;
    sMin = 0;
    sMax = 0;
    % Calibration of minimum signal level
    t = sT;
    num = 0;
    while t >= 0
        tic;
        
        % Acquire current time window of samples
        cData = AcquireSamplesRHA32(obj, nCh, tWs);
        % Request new set of samples
        RequestSamplesRHA32(obj, tWs);
        
        cVals = processTw(options, sF, cData);
        
        %sMin = min(sMin, mean(cVals(:)));
        sMin = sMin + mean(cVals(:));
        num = num + 1;
        
        set(handles.t_msg, 'String',...
            ['Calibrating levels, ' num2str(round(t,3)) 's remaining.']);
        drawnow;
        t = t - toc;
    end
    sMin = sMin/num;

    CalibMessageCOG(handles, pT, 'Prepare for maximum level calibration.');

    % Calibration of maximum signal level
    t = sT;
    num = 0;
    while t >= 0
        tic;
        
        % Acquire current time window of samples
        cData = AcquireSamplesRHA32(obj, nCh, tWs);
        % Request new set of samples
        RequestSamplesRHA32(obj, tWs);
        
        cVals = processTw(options, sF, cData);
        
        %sMax = max(sMax, mean(cVals(:)));
        sMax = sMax + mean(cVals(:));
        num = num + 1;
        
        set(handles.t_msg, 'String',...
            ['Calibrating levels, ' num2str(round(t,3)) 's remaining.']);
        drawnow;
        t = t - toc;
    end
    sMax = sMax/num;

    % Compute average COG of calibration data
    [index_x, ~] = meshgrid(1:size(iData,2), 1:size(iData,1));
    cgx = sum(sum(index_x.*mean(iDataAll - sMin,3)))/sum(sum(mean(iDataAll - sMin,3)));
    cgxNorm = (cgx - 1)/(columns - 1);

    % Set signal levels
    disp(cgxNorm);
    set(handles.et_COGRef, 'String', num2str(cgxNorm));
    disp([sMin sMax]);
    set(handles.et_COGMin, 'String', num2str(sMin));
    set(handles.et_COGMax, 'String', num2str(sMax));

    % Stop acquisition, enable controls
    StopAcquisition(afeSettings.name, obj);
    enableControls(handles);

function CalibMessageCOG(handles, pT, msg)
%CALIBMESSAGECOG Show calibration message
%   Displays calibration message and waiting time   
    % Pause, show preparation message
    while pT >= 0
        tic;

        pause(0.1);

        set(handles.t_msg, 'String',...
            [ msg ' Calibrating in ' num2str(round(pT,3)) 's...']);
        drawnow;
        pT = pT - toc;
    end    

function updateCOG( animVars, animObjs, options )
%UPDATECOG Animation callback for the COG mode
%   Called by animation timer to calculate and set
%   new position of moving bar each frame
    COGDiff = animVars(1);
    strengthMult = animVars(2);

    movingBar = animObjs(2);

    speedMult = options.COGSpeed;

    barSpeed = strengthMult.^2*speedMult*COGDiff;

    % Update moving bar position
    currPos = movingBar.Position(1);
    newPos = currPos + barSpeed;
    newPos = max(newPos, 0);
    newPos = min(newPos, 0.95);
    movingBar.Position(1) = newPos;

%% Option functions

function options = readOptionsToStruct(handles)
%READOPTIONSTOSTRUCT Reads GUI options to struct
%   Return struct with options from GUI
%   Also sets log directory if logging enabled      
    options = struct('tW',str2double(get(handles.et_tW,'String')),...
       'fOrder',str2double(get(handles.et_fO, 'String')),...
       'fLp',str2double(get(handles.et_lPf, 'String')),...
       'fHp',str2double(get(handles.et_hPf, 'String')),...
       'signalMaxLeft',str2double(get(handles.et_max_l, 'String')),...
       'signalMinLeft',str2double(get(handles.et_min_l, 'String')),...
       'signalMaxRight',str2double(get(handles.et_max_r, 'String')),...
       'signalMinRight',str2double(get(handles.et_min_r, 'String')),...
       'speedMult',str2double(get(handles.et_mult, 'String')),...
       'COGRows',str2double(get(handles.et_COGRows, 'String')),...
       'COGColumns',str2double(get(handles.et_COGColumns, 'String')),...
       'COGRef',str2double(get(handles.et_COGRef, 'String')),...
       'COGSpeed',str2double(get(handles.et_COGSpeed, 'String')),...
       'COGMin',str2double(get(handles.et_COGMin, 'String')),...
       'COGMax',str2double(get(handles.et_COGMax, 'String')),...
       'leftChannels',get(handles.lb_left, 'Value'),...
       'rightChannels',get(handles.lb_right, 'Value'),...
       'COGFlip',get(handles.cb_COGFlip, 'Value'),...
       'loggingEnabled',get(handles.cb_log, 'Value'),...
       'calibrationEnabled',get(handles.cb_calib, 'Value'));

    % Set log directory if logging enabled
    if options.loggingEnabled
        options.logDir = uigetdir;
    end    

%% Activity functions  

function reply = actScoreSession(animTimer)
%ACTSCORESESSION Goal game activity
%   Activity function for the goal game      
    % Get activity struct
    animStruct = animTimer.UserData;

    movingBar = animStruct.animObjs(end);

    scoreStruct = animStruct.actVar;
    scoreGraphics = animStruct.actGraphics;

    msg = '';
    switch scoreStruct.state
        case 'nextLevel'
            scoreStruct.level = scoreStruct.level + 1;
            set(animStruct.textBar, 'String',...
                ['Get ready for level ' num2str(scoreStruct.level) '!']);
            scoreStruct.stateTime = 3;
            scoreStruct.state = 'pause';
            msg = ['Scoring session start level ' num2str(scoreStruct.level)];
        case 'pause'
            scoreStruct.stateTime = scoreStruct.stateTime - toc(scoreStruct.actTime);
            if scoreStruct.stateTime <= 0 % Begin level
                scoreStruct.goalLimits = SS_updateScoreGoal(scoreStruct.level,...
                                             scoreGraphics.goalRect);
                % Initialize timers for level TODO: make reasonable
                scoreStruct.goalTime = 2;
                scoreStruct.stateTime = scoreStruct.goalTime +...
                                        max(10 - 0.5*scoreStruct.level,1);
                scoreStruct.state = 'level';
            end
        case 'level'
            scoreStruct.stateTime = scoreStruct.stateTime - toc(scoreStruct.actTime);
            if SS_isInGoal(movingBar, scoreStruct.goalLimits)
                scoreStruct.goalTime = scoreStruct.goalTime - toc(scoreStruct.actTime);
                set(scoreGraphics.goalRect,'FaceColor', [0 0.8 0]);
            else
                set(scoreGraphics.goalRect,'FaceColor', [0 0.5 0]);
            end
            %decreaseStateTimer;
            set(animStruct.textBar, 'String',...
                ['Level: ' num2str(scoreStruct.stateTime) 's. Goal: '...
                           num2str(scoreStruct.goalTime) 's.']);
            if scoreStruct.goalTime <= 0
                scoreStruct.state = 'nextLevel';
            elseif scoreStruct.stateTime <= 0
                scoreStruct.state = 'finish';
                score = scoreStruct.level - 1;
                % TODO: Logging
                set(animStruct.textBar, 'String',...
                    ['Game over! Score: ' num2str(score)]);
                msg = ['Scoring session finished. Score: ' num2str(score)];
            end
    end

    reply{1} = scoreStruct.state;
    if ~isempty(msg) % Append log message if existant
        reply{2} = msg;
    end

    scoreStruct.actTime = tic;

    animStruct.actVar = scoreStruct;
    animTimer.UserData = animStruct;  

function reply = actFittsLawTest(animTimer)
%ACTFITTSLAWTEST Fitt's law test activity
%   Activity function for the Fitts's law test  

    % Get activity struct
    animStruct = animTimer.UserData;

    movingBar = animStruct.animObjs(end);

    fittStruct = animStruct.actVar;
    fittGraphics = animStruct.actGraphics;
    goalRect = fittGraphics.goalRect;

    msg = '';
    switch fittStruct.state
        case 'nextLevel'
            set(animStruct.textBar, 'String',...
                [num2str(size(fittStruct.reps,2)) ' repetition(s) remaining.']);
            fittStruct.stateTime = 3;
            fittStruct.state = 'pause';
        case 'pause'
            % Keep moving bar in centre
            movingBar.Position(1) = 0.5 - movingBar.Position(3)/2;
            
            fittStruct.stateTime = fittStruct.stateTime - toc(fittStruct.actTime);
            if fittStruct.stateTime <= 0 % Begin level
                rep = fittStruct.reps(:,1);
                fittStruct.reps(:,1) = [];
                fittStruct.goalLimits = FL_updateFittsGoal(rep,...
                                             goalRect);
                % Initialize timers for level
                fittStruct.goalTime = fittStruct.dT;
                fittStruct.stateTime = fittStruct.tO;
                fittStruct.state = 'level';
                % Initialize level metrics
                fittStruct.lastPos = movingBar.Position(1);
                fittStruct.stopDist = 0;
                fittStruct.travelDist = 0;
                fittStruct.overshoot = 0;
                msg = ['FL, D: ' num2str(rep(1)) ', W: ' num2str(rep(2))];
            end
        case 'level'
            fittStruct.stateTime = fittStruct.stateTime - toc(fittStruct.actTime);
            
            if SS_isInGoal(movingBar, fittStruct.goalLimits)
                fittStruct.goalTime = fittStruct.goalTime - toc(fittStruct.actTime);
                set(goalRect,'FaceColor', [0 0.8 0]);
                fittStruct.stopDist = fittStruct.stopDist +...
                    abs(movingBar.Position(1) - fittStruct.lastPos);
                fittStruct.wasInGoal = true;
            else
                fittStruct.stopDist = 0;
                fittStruct.goalTime = fittStruct.dT;
                set(goalRect,'FaceColor', [0 0.5 0]);
                if fittStruct.wasInGoal
                    fittStruct.overshoot = fittStruct.overshoot + 1;
                    fittStruct.wasInGoal = false;
                end
            end
            
            fittStruct.travelDist = fittStruct.travelDist +...
                    abs(movingBar.Position(1) - fittStruct.lastPos);
            fittStruct.lastPos = movingBar.Position(1);
            
            set(animStruct.textBar, 'String',...
                ['Timeout: ' num2str(fittStruct.stateTime) 's. Goal: '...
                           num2str(fittStruct.goalTime) 's.']);
                       
            % Is repetition finished?
            if fittStruct.goalTime <= 0 || fittStruct.stateTime <= 0
                % Completed
                set(goalRect,'Visible','off');
                if size(fittStruct.reps, 2) ~= 0;
                    fittStruct.state = 'nextLevel';
                else
                    fittStruct.state = 'finish';
                end
                completed = fittStruct.goalTime <= 0;
                MT = fittStruct.tO - fittStruct.stateTime;
                msg = ['C: ' num2str(completed) ', '...
                       'MT: ' num2str(MT) ', '...
                       'TD: ' num2str(fittStruct.travelDist) ', '...
                       'SD: ' num2str(fittStruct.stopDist) ', '...
                       'OS: ' num2str(fittStruct.overshoot)];
            end
    end

    reply{1} = fittStruct.state;
    if ~isempty(msg) % Append log message if existant
        reply{2} = msg;
    end

    fittStruct.actTime = tic;

    animStruct.actVar = fittStruct;
    animTimer.UserData = animStruct;

function reply = actMouseControl(animTimer)
%ACTMOUSECONTROL Mouse control pseudo-activity
%   Activity using the moving bar position to control the mouse cursor
%   to use as input for external activities    
    % TODO: Change for different screen sizes?
    animStruct = animTimer.UserData;
    movingBar = animStruct.animObjs(end);
    offsFromCenter = (movingBar.Position(1) - 0.475)/0.475;
    animStruct.actVar.mouseMove(960 + 220*offsFromCenter, 540);

    reply = {'arkanoid'};

function reply = actDoNothing(~)
%ACTDONOTHING Standard activity (i.e. no activity)
%   Dummy function for when no activity is performed   
    reply = {''};

function goalLimits = FL_updateFittsGoal( rep, goalRect )
%FL_UPDATEFITTSGOAL Update Fitts's law test goal
%   Updates position value of Fitts's law test goal according to repetition data 
%   rep is a 2-length vector consisting of Position and Width of the repetition goal

    % Convert degrees to normalized distance (from [-100, +100] to [0, 1])
    rep(1) = (rep(1) + 100)/200; % Position
    rep(2) = rep(2)/200; % Width
    goalCenter = rep(1);
    goalLimits = [goalCenter - rep(2)/2, goalCenter + rep(2)/2];
    set(goalRect, 'Position',...
       [goalLimits(1) 0.01 goalLimits(2) - goalLimits(1) 0.23]);
    set(goalRect, 'Visible', 'on');
    uistack(goalRect, 'bottom');

function reps = FL_generateReps(distances, widths, trials)
%FL_GENERATEREPS Generate Fitts's law test repetitions
%   Returns a randomized permutation of trials times all possible number
%   of combinations of distances (positive and negative) and widths
    reps = [distances, -distances; widths, widths];
    reps = repmat(reps, 1, trials);

    randIdxs = randperm(size(reps,2));
    reps = reps(:,randIdxs);

function goalLimits = SS_updateScoreGoal(level, goalRect)
%SS_UPDATESCOREGOAL Update scoring session goal
%   Updates position value of score goal to new random values
    goalCenter = rand*0.8 + 0.1;
    goalLimits = [goalCenter - 0.1, goalCenter + 0.1];
    set(goalRect, 'Position',...
       [goalLimits(1) 0.01 goalLimits(2) - goalLimits(1) 0.23]);
    set(goalRect, 'Visible', 'on');
    uistack(goalRect, 'bottom');

function inGoal = SS_isInGoal(movingBar, goalLimits)
%SS_ISINGOAL Moving bar in scoring session goal
%   Returns true if moving bar is in scoring session goal      
    barPos = movingBar.Position;
    inGoal = (barPos(1) >= goalLimits(1)) && ...
        ((barPos(1) + barPos(3)) <= goalLimits(2));    

function stopActivity(handles)
%STOPACTIVITY Stop current animation activity
%   Clears activity vars, deletes activity graphics and logs stopping 
    animStruct = handles.animTimer.UserData;
    % Delete activity variables
    if isfield(animStruct,'actVar')
        animStruct = rmfield(animStruct,'actVar');
    end
    % Delete activity graphic object
    if isfield(animStruct,'actGraphics')
        objNames = fieldnames(animStruct.actGraphics);
        for i = 1:numel(objNames)
            delete(animStruct.actGraphics.(objNames{i}));
        end
        animStruct = rmfield(animStruct,'actGraphics');
    end
    % Log stopping if appropriate
    if animStruct.options.loggingEnabled
        logActMessage('Activity stopped', animStruct.logFile);
    end
    animStruct.activityFun = @actDoNothing;
    handles.animTimer.UserData = animStruct;

%% Logging functions

function logRecStruct(recStruct)
%LOGRECSTRUCT Log recstruct
%   Logs contents in recstruct to a new CVals-file    
    nameBase = 'CVals';
    logDir = recStruct.options.logDir;
    logFiles = dir([logDir '\' nameBase '*.mat']);
    if numel(logFiles) == 0
        name = [nameBase '1.mat'];
    else
        % Find number that isn't taken
        num = 1;
        while any(strcmp({logFiles.name}, [nameBase num2str(num) '.mat']))
            num = num + 1;
        end
        name = [nameBase num2str(num) '.mat'];
    end
    save([logDir '\' name],...
        '-struct','recStruct','cVals','nCh','sF');

function logActMessage(msg, logFile)
%LOGACTMESSAGE Log activity message
%   Logs activity message to logfile preceded by current time
    fprintf(logFile, [datestr(datetime('now')) ' - ' msg '\n']);

%% Processing functions    

function [cVals] = processTw(options, sF, cData)
%PROCESSTW Processes a time windows into cVals
%   Filters and computes the RMS of each channel    
    % Get parameters
    fOrder = options.fOrder;
    fLp = options.fLp;
    fHp = options.fHp;

    % Process time window
    tempData = ApplyButterFilter(sF, fOrder, fLp, fHp, cData);
    cVals = mean(abs(tempData));

%% GUI functions

function enableControls(handles)
%ENABLECONTROLS Enable controls
%   Call to enable controls after recording    
    set(handles.et_fO, 'Enable', 'on');
    set(handles.et_lPf, 'Enable', 'on');    
    set(handles.et_hPf, 'Enable', 'on');    
    set(handles.et_max_l, 'Enable', 'on');    
    set(handles.et_min_l, 'Enable', 'on');   
    set(handles.et_max_r, 'Enable', 'on');    
    set(handles.et_min_r, 'Enable', 'on'); 
    set(handles.lb_left, 'Enable', 'on');    
    set(handles.lb_right, 'Enable', 'on');
    set(handles.et_mult, 'Enable', 'on');
    set(handles.cb_log, 'Enable', 'on');
    set(handles.cb_debug, 'Enable', 'on');

function disableControls(handles)
%DISABLECONTROLS Disable controls
%   Called to disable controls during recording    
    set(handles.et_fO, 'Enable', 'off');
    set(handles.et_lPf, 'Enable', 'off');    
    set(handles.et_hPf, 'Enable', 'off');    
    set(handles.et_max_l, 'Enable', 'off');    
    set(handles.et_min_l, 'Enable', 'off');   
    set(handles.et_max_r, 'Enable', 'off');    
    set(handles.et_min_r, 'Enable', 'off');   
    set(handles.lb_left, 'Enable', 'off');    
    set(handles.lb_right, 'Enable', 'off');
    set(handles.et_mult, 'Enable', 'off');
    set(handles.cb_log, 'Enable', 'off');
    set(handles.cb_debug, 'Enable', 'off');

%% Timer callback functions

function animCallback(src, event)
%ANIMCALLBACK Animation timer callback
%   Animates GUI and processes activity functions
    % Unpack anim struct
    animStruct = src.UserData;
    loggingEnabled = animStruct.options.loggingEnabled;

    % Process animation update function
    animStruct.updateFun(animStruct.animVars,...
                         animStruct.animObjs,...
                         animStruct.options);


    % Process activity update function
    reply = animStruct.activityFun(src);

    % Log eventual message
    if loggingEnabled && numel(reply) == 2
        logActMessage(reply{2}, animStruct.logFile);
    end

    % Cancel activity when finished
    if strcmp(reply{1}, 'finish')
        handles = guidata(animStruct.axis);
        stopActivity(handles);
    end

    drawnow;

function recStopCallback(src, event)
%RECSTOPCALLBACK Stop callback of recording timer
%   Stops acquisition and logs recStruct
    % Unpack rec struct
    recStruct = src.UserData;
    textBar = recStruct.textBar;
    obj = recStruct.AFEObj;
    name = recStruct.AFEName;
    loggingEnabled = recStruct.options.loggingEnabled;

    % Stop acquisition and animation
    StopAcquisition(name, obj);

    % Write to log files if logging enabled
    if loggingEnabled
        logRecStruct(recStruct);
        recStruct.cVals = [];
        recStruct.lastLog = clock;
        animStruct = recStruct.animTimer.UserData;
        logActMessage('Recording stopped', animStruct.logFile);
        fclose(animStruct.logFile);
    end
    src.UserData = recStruct;

    % Show message, enable controls, save handles structure
    set(textBar, 'String', 'Finished!');

function recCallback(src, event)
%RECCALLBACK Callback of recording timer
%   Acquires samples in buffer and requests a new set of samples
%   Updates animation timer with collected values 
    % Unpack rec struct
    recStruct = src.UserData;
    animTimer = recStruct.animTimer;
    loggingEnabled = recStruct.options.loggingEnabled;
    tWs = recStruct.tWs;
    nCh = recStruct.nCh;
    obj = recStruct.AFEObj;
    sF = recStruct.sF;
    %name = recStruct.AFEName;
    options = recStruct.options;

    try
        % Acquire current time window of samples
        cData = AcquireSamplesRHA32(obj, nCh, tWs);
    catch
        warning('Failed to retrieve time window');
        % Request new set of samples
        RequestSamplesRHA32(obj, tWs);
        return;
    end
    % Request new set of samples
    RequestSamplesRHA32(obj, tWs);

    cVals = processTw(options, sF, cData); % Filter, compute features?
    if loggingEnabled
        lastLog = recStruct.lastLog;
        logInterval = recStruct.logInterval;
        recStruct.cVals = [recStruct.cVals; cVals];
        if etime(clock, lastLog) > logInterval % Periodical logging
            logRecStruct(recStruct);
            recStruct.cVals = [];
            recStruct.lastLog = clock;
        end
        src.UserData = recStruct;
    end

    % Update animation
    recStruct.updateAnimVarsFun(options, cVals, animTimer);

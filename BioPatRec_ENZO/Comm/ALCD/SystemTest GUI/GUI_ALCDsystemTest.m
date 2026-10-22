function varargout = GUI_ALCDsystemTest(varargin)
% GUI_ALCDSYSTEMTEST MATLAB code for GUI_ALCDsystemTest.fig
%      GUI_ALCDSYSTEMTEST, by itself, creates a new GUI_ALCDSYSTEMTEST or raises the existing
%      singleton*.
%
%      H = GUI_ALCDSYSTEMTEST returns the handle to a new GUI_ALCDSYSTEMTEST or the handle to
%      the existing singleton*.
%
%      GUI_ALCDSYSTEMTEST('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI_ALCDSYSTEMTEST.M with the given input arguments.
%
%      GUI_ALCDSYSTEMTEST('Property','Value',...) creates a new GUI_ALCDSYSTEMTEST or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI_ALCDsystemTest_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI_ALCDsystemTest_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUI_ALCDsystemTest

% Last Modified by GUIDE v2.5 16-Nov-2017 14:53:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_ALCDsystemTest_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_ALCDsystemTest_OutputFcn, ...
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


% --- Executes just before GUI_ALCDsystemTest is made visible.
function GUI_ALCDsystemTest_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI_ALCDsystemTest (see VARARGIN)

% Choose default command line output for GUI_ALCDsystemTest
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GUI_ALCDsystemTest wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GUI_ALCDsystemTest_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in pm_ComPort.
function pm_ComPort_Callback(hObject, eventdata, handles)
% hObject    handle to pm_ComPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pm_ComPort contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pm_ComPort


% --- Executes during object creation, after setting all properties.
function pm_ComPort_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pm_ComPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
serialportlist = instrhwinfo('serial');
if ~isempty(serialportlist.AvailableSerialPorts)
    serialportlist = serialportlist.SerialPorts;
    set(hObject,'String',serialportlist);
else
    set(hObject,'String','None Available');
end


% --- Executes on button press in pb_connect.
function pb_connect_Callback(hObject, eventdata, handles)
% hObject    handle to pb_connect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    compath_idx = get(handles.pm_ComPort,'Value');
    ComPortName     = get(handles.pm_ComPort,'string');
    ComPortName     = ComPortName(compath_idx);
%     BaudRate    = 921600;
    BaudRate    = 460800;
    set(handles.t_msg,'String','Testing connection...');   
    delete(instrfindall);
    obj = serial (ComPortName, 'baudrate', BaudRate, 'databits', 8, 'byteorder', 'bigEndian');
    % Open connection
    fclose(obj);
    fopen(obj);
    fwrite(obj,'A','char');
    fwrite(obj,'C','char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'C')
        set(handles.t_msg,'String','Connection stablished');
    else
        set(handles.t_msg,'String','Error, device is not responding or COM port is changed!');        
    end
    fclose(obj);
    handles.obj = obj;
    guidata(hObject,handles);


% --- Executes on selection change in pm_movement.
function pm_movement_Callback(hObject, eventdata, handles)
% hObject    handle to pm_movement (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pm_movement contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pm_movement


% --- Executes during object creation, after setting all properties.
function pm_movement_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pm_movement (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function et_predictionTime_Callback(hObject, eventdata, handles)
% hObject    handle to et_predictionTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_predictionTime as text
%        str2double(get(hObject,'String')) returns contents of et_predictionTime as a double


% --- Executes during object creation, after setting all properties.
function et_predictionTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_predictionTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function et_strength_Callback(hObject, eventdata, handles)
% hObject    handle to et_strength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_strength as text
%        str2double(get(hObject,'String')) returns contents of et_strength as a double


% --- Executes during object creation, after setting all properties.
function et_strength_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_strength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_singleTest.
function pb_singleTest_Callback(hObject, eventdata, handles)
% hObject    handle to pb_singleTest (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

clc
set(handles.t_msg,'String','ALC-D system test: single run'); 
%disp('*****************************************************');
if isfield(handles,'obj')==0
    set(handles.t_msg,'String','No connection object found! Connect with the device'); 
    disp('No connection object found! Connect with the device');
    return;
end
mov = get(handles.pm_movement,'Value')-1;
if mov == 0
    % if manually select the file
    [file, path] = uigetfile({'*.mat'});
    if ~isequal(file, 0)
        [pathstr,name,ext] = fileparts(file);
        if(strcmp(ext,'.mat'))
            load([path,file]);
            movement2execute = data;
        else
            disp('Not a valid file!');
            errordlg('Not a valid file!','Error');
            return; 
        end
    end
else
    % use a predefined file
    str = get(handles.pm_movement,'String');
    load(str{mov+1});
    movement2execute = data;
end
plots = get(handles.cb_plots,'Value');
newPredictionTime = str2double(get(handles.et_predictionTime,'String'));
strength = str2double(get(handles.et_strength,'String'));
neurostimulator = get(handles.cb_neurostimulator,'Value');
testData = singleSystemTestALCD( handles.obj, newPredictionTime, movement2execute, strength, neurostimulator, plots );
testTypeStr = 'ALCD-SingleTest-';
timeTest = clock;
year = timeTest(1);
month = timeTest(2);
day = timeTest(3);
hour = timeTest(4);
min = timeTest(5);
strSaveName = [testTypeStr num2str(day) '_' num2str(month) '_' num2str(year) '-' num2str(hour) '_' num2str(min) '.mat'];
save(strSaveName,'testData');
set(handles.t_msg,'String','ALC-D system test: single run completed!');


% --- Executes on button press in pb_multipleRun.
function pb_multipleRun_Callback(hObject, eventdata, handles)
% hObject    handle to pb_multipleRun (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

clc
set(handles.t_msg,'String','ALC-D system test: multiple run'); 
%disp('*****************************************************');
if isfield(handles,'obj')==0
    set(handles.t_msg,'String','No connection object found! Connect with the device'); 
    disp('No connection object found! Connect with the device');
    return;
end
strength = str2double(get(handles.et_strength,'String'));
newPredictionTime = str2double(get(handles.et_predictionTime,'String'));
neurostimulator = get(handles.cb_neurostimulator,'Value');
runs = str2double(get(handles.et_longRunTime,'String'))*(60/18);
for i = 1:runs
    if mod(i,2)
        mov = 1; %ch1emg_ch2off
    else
        mov = 2; %ch1off_ch2emg
    end
    % load the predefined file
    str = get(handles.pm_movement,'String');
    load(str{mov+1});
    movement2execute = data;
    % strength is randomly generated
    strength = int8(rand(1,1)*100);
    % run single system test for multiple times 
    testData = singleSystemTestALCD( handles.obj, newPredictionTime, movement2execute, strength, neurostimulator, plots  );
    testTypeStr = ['ALCD-MultipleTest-run' num2str(i)];
    timeTest = clock;
    year = timeTest(1);
    month = timeTest(2);
    day = timeTest(3);
    hour = timeTest(4);
    min = timeTest(5);
    strSaveName = [testTypeStr num2str(day) '_' num2str(month) '_' num2str(year) '-' num2str(hour) '_' num2str(min) '.mat'];
    save(strSaveName,'testData');
    set(handles.t_msg,'String','ALC-D long system test: single run completed!');  
end
set(handles.t_msg,'String','ALC-D system test: multiple-run completed!');


% --- Executes on button press in cb_neurostimulator.
function cb_neurostimulator_Callback(hObject, eventdata, handles)
% hObject    handle to cb_neurostimulator (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_neurostimulator


function et_longRunTime_Callback(hObject, eventdata, handles)
% hObject    handle to et_longRunTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_longRunTime as text
%        str2double(get(hObject,'String')) returns contents of et_longRunTime as a double


% --- Executes during object creation, after setting all properties.
function et_longRunTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_longRunTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_recsession.
function pb_recsession_Callback(hObject, eventdata, handles)
% hObject    handle to pb_recsession (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

clc
set(handles.t_msg,'String','ALC-D system test: recording-session run'); 
%disp('*****************************************************');
if isfield(handles,'obj')==0
    set(handles.t_msg,'String','No connection object found! Connect with the device'); 
    disp('No connection object found! Connect with the device');
    return;
end
% manually select the recSession file
[file, path] = uigetfile({'*.mat'});
if ~isequal(file, 0)
    [pathstr,name,ext] = fileparts(file);
    if(strcmp(ext,'.mat'))
        load([path,file]);
        if exist('recSession','var')
            nM = recSession.nM;
        else
            disp('Not a valid file!');
            errordlg('Not a valid file!','Error');
            return;  
        end
    else
        disp('Not a valid file!');
        errordlg('Not a valid file!','Error');
        return; 
    end
end
newPredictionTime = str2double(get(handles.et_predictionTime,'String'));
strength = str2double(get(handles.et_strength,'String'));
neurostimulator = get(handles.cb_neurostimulator,'Value');
% loop over all movements
for i = 1:nM
    testData(i) = singleSystemTestALCD( handles.obj, newPredictionTime, recSession.tdata(:,1:2,i), strength, neurostimulator );
end
testTypeStr = 'ALCD-RecSessionTest-';
timeTest = clock;
year = timeTest(1);
month = timeTest(2);
day = timeTest(3);
hour = timeTest(4);
min = timeTest(5);
strSaveName = [testTypeStr num2str(day) '_' num2str(month) '_' num2str(year) '-' num2str(hour) '_' num2str(min) '.mat'];
save(strSaveName,'testData');
set(handles.t_msg,'String','ALC-D system test: recording-session run completed!');


% --- Executes on button press in cb_plots.
function cb_plots_Callback(hObject, eventdata, handles)
% hObject    handle to cb_plots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_plots


% --- Executes on button press in pb_quickPlay.
function pb_quickPlay_Callback(hObject, eventdata, handles)
% hObject    handle to pb_quickPlay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  
mov = get(handles.pm_movement,'Value')-1;
if mov == 0
    % if manually select the file
    [file, path] = uigetfile({'*.mat'});
    if ~isequal(file, 0)
        [pathstr,name,ext] = fileparts(file);
        if(strcmp(ext,'.mat'))
            load([path,file]);
            movement2execute = data;
        else
            disp('Not a valid file!');
            errordlg('Not a valid file!','Error');
            return; 
        end
    end
else
    % use a predefined file
    str = get(handles.pm_movement,'String');
    load(str{mov+1});
    movement2execute = data;
end
strength = str2double(get(handles.et_strength,'String'));
disp('Quick playback of selected recording');
disp('Preparing the analog output...');
devices = daq.getDevices;
if isempty(devices)
   disp('(ERRORCODE 1) No NI card identified! Please, check connections.'); 
   return;
end
s = daq.createSession('ni');
s.addAnalogOutputChannel('dev5','ao0','Voltage');
s.addAnalogOutputChannel('dev5','ao1','Voltage');
s.Rate = 1000;         
disp('Generate pseudoEMG signals...');
queueOutputData(s,movement2execute*(strength/100));
s.startForeground;


% --- Executes on button press in pb_replot.
function pb_replot_Callback(hObject, eventdata, handles)
% hObject    handle to pb_replot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% manually select the file
[file, path] = uigetfile({'*.mat'});
if ~isequal(file, 0)
    [pathstr,name,ext] = fileparts(file);
    if(strcmp(ext,'.mat'))
        load([path,file]);
        if(exist('testData','var'))
            logFile = testData.logFile;
            newPredictionTime = logFile.time/logFile.numLogUnits;
            movement2execute = testData.movement2execute;
            if(isfield(testData,'oscilloscopeData'))
                neurostimulator = 1;
                oscilloscopeData = testData.oscilloscopeData;
            else
                neurostimulator = 0;
            end
        else
            disp('Not a valid file!');
            errordlg('Not a valid file!','Error');
            return;  
        end
    else
        disp('Not a valid file!');
        errordlg('Not a valid file!','Error');
        return; 
    end
end
% plot data
% signals vs movements
sF = 1000;
time = length(movement2execute)/sF;
tv = 0:1/sF:time-1/sF;
figure
set(gcf,'color','white')
ax1 = subplot(4,1,1);
plot(tv, movement2execute)
title('input signals vs time')
ylabel('[V]')
xlabel('time [s]')
legend('OPEN', 'CLOSE')
sF = 1/newPredictionTime;
time = logFile.numLogUnits*newPredictionTime;
tv = 0:1/sF:time-1/sF;
ax2 = subplot(4,1,2);
plot(tv, [logFile.LogUnits.tmabs1 logFile.LogUnits.tmabs2])
title('processed signals vs time')
ylabel('[V]')
xlabel('time [s]')
legend('OPEN', 'CLOSE')
ax3 = subplot(4,1,3);
plot(tv, logFile.LogUnits.outIdx, 'x-b')
title('predicted movement vs time')
ylabel('[Class]')
xlabel('time [s]')
ax4 = subplot(4,1,4);
plot(tv, logFile.LogUnits.activLevel, 'x-b')
title('predicted strength vs time')
ylabel('[Value]')
xlabel('time [s]')
% sensors vs stimulation
sF = 1/newPredictionTime;
time = logFile.numLogUnits*newPredictionTime;
tv = 0:1/sF:time-1/sF;
figure
set(gcf,'color','white')
ax1 = subplot(3,1,1);
plot(tv, logFile.LogUnits.sensors.pad1, 'r')
hold
plot(tv, logFile.LogUnits.sensors.pad2, 'm')
plot(tv, logFile.LogUnits.sensors.pad3, 'c')
title('pad sensor values vs time')
ylabel('value')
xlabel('time [s]')
legend('PAD1', 'PAD2', 'PAD3')
if neurostimulator
    ax3 = subplot(3,1,3);
    plot(tv, logFile.LogUnits.stimFreq, 'x-r')
    title('stimulation frequency vs time')
    ylabel('[Hz]')
    xlabel('time [s]')
    sF = 1000;
    time = length(movement2execute)/sF;
    sF = 1e6/time;
    tv = 0:1/sF:time-1/sF;
    ax2 = subplot(3,1,2);
    plot(tv, oscilloscopeData, 'x-r')
    title('stimulation vs time')
    ylabel('[V]')
    xlabel('time [s]')
    linkaxes([ax1,ax2,ax3],'x');
end
% battery and temperature
sF = 1/newPredictionTime;
time = logFile.numLogUnits*newPredictionTime;
tv = 0:1/sF:time-1/sF;
figure
set(gcf,'color','white')
ax1 = subplot(2,1,1);
plot(tv, logFile.LogUnits.vBattery, 'x-g')
title('battery voltage vs time')
ylabel('[V]')
xlabel('time [s]')
ax1 = subplot(2,1,2);
plot(tv, logFile.LogUnits.sensors.temperature, 'x-')
title('temperature vs time')
ylabel('[Celsius degrees]')
xlabel('time [s]')

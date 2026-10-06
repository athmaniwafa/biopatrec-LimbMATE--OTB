function varargout = GUI_TestNS1(varargin)
% GUI_TESTNS1 MATLAB code for GUI_TestNS1.fig
%      GUI_TESTNS1, by itself, creates a new GUI_TESTNS1 or raises the existing
%      singleton*.
%
%      H = GUI_TESTNS1 returns the handle to a new GUI_TESTNS1 or the handle to
%      the existing singleton*.
%
%      GUI_TESTNS1('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI_TESTNS1.M with the given input arguments.
%
%      GUI_TESTNS1('Property','Value',...) creates a new GUI_TESTNS1 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI_TestNS1_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI_TestNS1_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUI_TestNS1

% Last Modified by GUIDE v2.5 24-Nov-2016 14:23:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_TestNS1_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_TestNS1_OutputFcn, ...
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


% --- Executes just before GUI_TestNS1 is made visible.
function GUI_TestNS1_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI_TestNS1 (see VARARGIN)

% Choose default command line output for GUI_TestNS1
handles.output = hObject;

% Take useful information from GUI father (if it exists)
if size(varargin,2) > 0
    oldHandles = varargin{1};
    if isfield(oldHandles,'obj')
        handles.obj = oldHandles.obj;
    end
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GUI_TestNS1 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GUI_TestNS1_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in cb_ch1.
function cb_ch1_Callback(hObject, eventdata, handles)
% hObject    handle to cb_ch1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_ch1


% --- Executes on button press in cb_ch2.
function cb_ch2_Callback(hObject, eventdata, handles)
% hObject    handle to cb_ch2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_ch2


% --- Executes on button press in cb_ch3.
function cb_ch3_Callback(hObject, eventdata, handles)
% hObject    handle to cb_ch3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_ch3



function et_amp_Callback(hObject, eventdata, handles)
% hObject    handle to et_amp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_amp as text
%        str2double(get(hObject,'String')) returns contents of et_amp as a double


% --- Executes during object creation, after setting all properties.
function et_amp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_amp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_pw_Callback(hObject, eventdata, handles)
% hObject    handle to et_pw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_pw as text
%        str2double(get(hObject,'String')) returns contents of et_pw as a double


% --- Executes during object creation, after setting all properties.
function et_pw_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_pw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_freq_Callback(hObject, eventdata, handles)
% hObject    handle to et_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_freq as text
%        str2double(get(hObject,'String')) returns contents of et_freq as a double


% --- Executes during object creation, after setting all properties.
function et_freq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function menu_connect_Callback(hObject, eventdata, handles)
% hObject    handle to menu_connect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % Ask for connection settings
    prompt = {'Enter COM Port:','Enter baudrate:'};
    dlg_title = 'Connect to NS1';
    num_lines = 1;
    def = {'5','460800'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    ComPortName = num2str(char(answer(1)));
    baud = str2num(char(answer(2)));

    %WiFi = get(handles.cb_WiFi,'Value');
    WiFi = 0;
    if ispc
        ComPortName = strcat('COM',ComPortName);
    end
    set(handles.t_msg,'String','Testing connection...');   
    if isfield(handles,'obj')
        obj = handles.obj;
        fclose(obj);
    else
         if WiFi
            obj = tcpip('192.168.100.10',65100,'NetworkRole','client');        % WIICOM
         else
            obj = serial (ComPortName, 'baudrate', baud, 'databits', 8, 'byteorder', 'bigEndian');
         end
    end
    % Open connection
    fclose(obj);
    fopen(obj);
    fwrite(obj,'A','char');
    fwrite(obj,'C','char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'C')
        set(handles.t_msg,'String','Connection Established');
    else
        set(handles.t_msg,'String','Error, device is not responding or COM port is changed!');        
    end
    fclose(obj);
    handles.obj = obj;
    guidata(hObject,handles);
    
    
% --- Executes on button press in pb_send.
function pb_send_Callback(hObject, eventdata, handles)
% hObject    handle to pb_send (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    amplitude = str2double(get(handles.et_amp,'String'))/10;
    pulseWidth = str2double(get(handles.et_pw,'String'))/10;
    frequency = str2double(get(handles.et_freq,'String'));
    pulses = str2double(get(handles.et_pulses,'String'));
    ch1 = get(handles.cb_ch1,'Value');
    ch2 = get(handles.cb_ch2,'Value');
    ch3 = get(handles.cb_ch3,'Value');
    if(ch1+ch2+ch3 == 0)
        set(handles.t_msg,'String','Select at least one channel!!!');
        return
    end
    
    % Get connection object
    if isfield(handles,'obj')
        obj = handles.obj;
    else
        set(handles.t_msg,'String','No connection obj found');   
        return;
    end
    % Open the connection
    fopen(obj);
    
    fwrite(obj,hex2dec('B0'),'char');
    
    if(ch1)
        channel = hex2dec('00');
    end
    if(ch2)
        channel =hex2dec('01');
    end
    if(ch3)
        channel = hex2dec('02');
    end
    fwrite(obj,channel,'char');
    fwrite(obj,amplitude,'char');
    fwrite(obj,pulseWidth,'char');
    fwrite(obj,frequency,'char');
    fwrite(obj,pulses,'char');
    
    answer = fread(obj,1,'char');
    replay = fread(obj,1,'char');
    if replay == 176 %0xB0
        switch answer
            case hex2dec('AA')
                set(handles.t_msg,'String','ACK_OK'); 
            case hex2dec('80')
                set(handles.t_msg,'String','ERR_WRONG_STRUCTURE');
            case hex2dec('81')
                set(handles.t_msg,'String','ERR_WRONG_COMMAND');
            case hex2dec('82')
                set(handles.t_msg,'String','ERR_WRONG_CHANNEL');
            case hex2dec('83')
                set(handles.t_msg,'String','ERR_WRONG_CHECKSUM');
            case hex2dec('84')
                set(handles.t_msg,'String','ERR_AMPLITUDE');
            case hex2dec('85')
                set(handles.t_msg,'String','ERR_PULSE_WIDTH');
            case hex2dec('86')
                set(handles.t_msg,'String','ERR_FREQUENCY'); 
            case hex2dec('87')
                set(handles.t_msg,'String','ERR_PULSE_NUMBER');
            case hex2dec('88')
                set(handles.t_msg,'String','ERR_INCORRECT_STIM');
            case hex2dec('89')
                set(handles.t_msg,'String','ERR_CHARGE');   
            otherwise
               set(handles.t_msg,'String','Not known answer! probably error');
        end
    else
        set(handles.t_msg,'String','Communication Error'); 
        fclose(obj);
        return
    end

    fclose(obj);



function et_pulses_Callback(hObject, eventdata, handles)
% hObject    handle to et_pulses (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_pulses as text
%        str2double(get(hObject,'String')) returns contents of et_pulses as a double


% --- Executes during object creation, after setting all properties.
function et_pulses_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_pulses (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function menuALCD_Callback(hObject, eventdata, handles)
% hObject    handle to menuALCD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_readSettings_Callback(hObject, eventdata, handles)
% hObject    handle to menu_readSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
    % Get connection object
    if isfield(handles,'obj')
        obj = handles.obj;
    else
        set(handles.t_msg,'String','No connection obj found');   
        return;
    end
    % Open the connection
    fopen(obj);
    
    fwrite(obj,hex2dec('B1'),'char');
    replay = fread(obj,1,'char');
    
    stimParams.mode = fread(obj,1,'char');
    stimParams.channel = fread(obj,1,'char');
    stimParams.amplitude = fread(obj,1,'char');
    stimParams.pulseWidth = fread(obj,1,'char');
    stimParams.frequency = fread(obj,1,'char');
    stimParams.pulses = fread(obj,1,'char');
   
    replay = fread(obj,1,'char');
    if replay == 177 %0xB1
        save('STIM_SETTINGS.mat','stimParams');  
        set(handles.t_msg,'String','Standard Stimulation Parameters saved into STIM_SETTINGS.mat file');
    else
        set(handles.t_msg,'String','Communication Error'); 
        fclose(obj);
        return
    end
    
    fclose(obj);


% --------------------------------------------------------------------
function menu_writeSettings_Callback(hObject, eventdata, handles)
% hObject    handle to menu_writeSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % Ask for type of stimulation
    prompt = {'Insert Type of Stimulation'};
    dlg_title = 'Type of Stimulation';
    num_lines = 1;
    def = {'1'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    mode = str2num(cell2mat(answer));     
    amplitude = str2double(get(handles.et_amp,'String'))/10;
    pulseWidth = str2double(get(handles.et_pw,'String'))/10;
    frequency = str2double(get(handles.et_freq,'String'));
    pulses = str2double(get(handles.et_pulses,'String'));
    ch1 = get(handles.cb_ch1,'Value');
    ch2 = get(handles.cb_ch2,'Value');
    ch3 = get(handles.cb_ch3,'Value');
    if(ch1+ch2+ch3 == 0)
        set(handles.t_msg,'String','Select at least one channel!!!');
        return
    end
    
    % Get connection object
    if isfield(handles,'obj')
        obj = handles.obj;
    else
        set(handles.t_msg,'String','No connection obj found');   
        return;
    end
    % Open the connection
    fopen(obj);
    
    fwrite(obj,hex2dec('B2'),'char');
    replay = fread(obj,1,'char');
    
    if(ch1)
        channel = hex2dec('00');
    end
    if(ch2)
        channel =hex2dec('01');
    end
    if(ch3)
        channel = hex2dec('02');
    end
    fwrite(obj,mode,'char');
    fwrite(obj,channel,'char');
    fwrite(obj,amplitude,'char');
    fwrite(obj,pulseWidth,'char');
    fwrite(obj,frequency,'char');
    fwrite(obj,pulses,'char');
    
    replay = fread(obj,1,'char');
    if replay == 178 %0xB2
        set(handles.t_msg,'String','Standard Stimulation Parameters written correctly!');
    else
        set(handles.t_msg,'String','Communication Error'); 
        fclose(obj);
        return
    end
    
    fclose(obj);


% --- Executes on button press in cb_enableNS1.
function cb_enableNS1_Callback(hObject, eventdata, handles)
% hObject    handle to cb_enableNS1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_enableNS1

    enableNS = get(handles.cb_enableNS1,'Value');
    
    % Get connection object
    if isfield(handles,'obj')
        obj = handles.obj;
    else
        set(handles.t_msg,'String','No connection obj found');   
        return;
    end
    % Open the connection
    fopen(obj);

    % Set up the filters enable
    fwrite(obj,hex2dec('B3'),'char');
    replay = fread(obj,1,'char');
    if replay == hex2dec('B3')
        fwrite(obj,enableNS,'char');
        replay = fread(obj,1,'char');
        if replay == hex2dec('B3')
            if(enableNS)
                set(handles.t_msg,'String','Neurostimulator enabled');
            else
                set(handles.t_msg,'String','Neurostimulator disabled');
            end
        else
            set(handles.t_msg,'String','Error Setting Neurostimulator enable'); 
            fclose(obj);
            return
        end
    else
        set(handles.t_msg,'String','Error Setting Neurostimulator enable'); 
        fclose(obj);
        return
    end
    
    fclose(obj);

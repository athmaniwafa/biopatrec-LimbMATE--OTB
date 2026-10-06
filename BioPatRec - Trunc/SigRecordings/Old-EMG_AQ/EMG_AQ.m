function varargout = EMG_AQ(varargin)
% EMG_AQ M-file for EMG_AQ.fig
%      EMG_AQ, by itself, creates a new EMG_AQ or raises the existing
%      singleton*.
%
%      H = EMG_AQ returns the handle to a new EMG_AQ or the handle to
%      the existing singleton*.
%
%      EMG_AQ('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EMG_AQ.M with the given input arguments.
%
%      EMG_AQ('Property','Value',...) creates a new EMG_AQ or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before EMG_AQ_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to EMG_AQ_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help EMG_AQ

% Last Modified by GUIDE v2.5 22-Jun-2011 16:58:17
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @EMG_AQ_OpeningFcn, ...
                   'gui_OutputFcn',  @EMG_AQ_OutputFcn, ...
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


% --- Executes just before EMG_AQ is made visible.
function EMG_AQ_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to EMG_AQ (see VARARGIN)
% Choose default command line output for EMG_AQ
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes EMG_AQ wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = EMG_AQ_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pb_startrecording.
function pb_startrecording_Callback(hObject, eventdata, handles)
Fs = str2double(get(handles.et_Fs,'String'));
Ts = str2double(get(handles.et_Ts,'String'));
Tp = str2double(get(handles.et_Tp,'String'));

[ai,chp] = init_ai(handles,Fs,Ts);
cdata = daq_show(handles,ai,chp,Fs,Ts,Tp);
save('cdata.mat','cdata','Fs','Ts');

stop(ai);
delete(ai);



function et_Fs_Callback(hObject, eventdata, handles)
% hObject    handle to et_Fs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of et_Fs as text
%        str2double(get(hObject,'String')) returns contents of et_Fs as a double

input = str2double(get(hObject,'String'));
if (isempty(input))
     set(hObject,'String','0')
end
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function et_Fs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_Fs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_Ts_Callback(hObject, eventdata, handles)
% hObject    handle to et_Ts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_Ts as text
%        str2double(get(hObject,'String')) returns contents of et_Ts as a double
input = str2double(get(hObject,'String'));
if (isempty(input))
     set(hObject,'String','0')
end
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function et_Ts_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_Ts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_Tp_Callback(hObject, eventdata, handles)
% hObject    handle to et_Tp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_Tp as text
%        str2double(get(hObject,'String')) returns contents of et_Tp as a double
input = str2double(get(hObject,'String'));
if (isempty(input))
     set(hObject,'String','0')
end
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function et_Tp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_Tp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_initai.
function pb_initai_Callback(hObject, eventdata, handles)
% hObject    handle to pb_initai (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get user input from GUI


% --- Executes on button press in cb_filter50hz.
function cb_filter50hz_Callback(hObject, eventdata, handles)
% hObject    handle to cb_filter50hz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_filter50hz


% --- Executes on button press in cb_filterBP.
function cb_filterBP_Callback(hObject, eventdata, handles)
% hObject    handle to cb_filterBP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_filterBP


% --- Executes on button press in cb_filter80Hz.
function cb_filter80Hz_Callback(hObject, eventdata, handles)
% hObject    handle to cb_filter80Hz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_filter80Hz


% --- Executes on button press in cb_ch0.
function cb_ch0_Callback(hObject, eventdata, handles)
% hObject    handle to cb_ch0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_ch0


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



function et_if0_Callback(hObject, eventdata, handles)
    input = str2double(get(hObject,'String'));
    if (isempty(input))
         set(hObject,'String','0')
    end

    xmax = str2double(get(handles.et_ff0,'String'));
    set(handles.a_f0,'XLim',[input xmax]);
    set(handles.a_f1,'XLim',[input xmax]);
    set(handles.a_f2,'XLim',[input xmax]);
    set(handles.a_f3,'XLim',[input xmax]);

    guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function et_if0_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_if0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_ff0_Callback(hObject, eventdata, handles)
    input = str2double(get(hObject,'String'));
    if (isempty(input))
         set(hObject,'String','0')
    end

    xmin = str2double(get(handles.et_if0,'String'));
    set(handles.a_f0,'XLim',[xmin input]);
    set(handles.a_f1,'XLim',[xmin input]);
    set(handles.a_f2,'XLim',[xmin input]);
    set(handles.a_f3,'XLim',[xmin input]);

    guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function et_ff0_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_ff0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_n_Callback(hObject, eventdata, handles)
    input = str2double(get(hObject,'String'));
    if (isempty(input))
         set(hObject,'String','0')
    end
    guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function et_n_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_n (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_fc1_Callback(hObject, eventdata, handles)
    input = str2double(get(hObject,'String'));
    if (isempty(input))
         set(hObject,'String','0')
    end
    guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function et_fc1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_fc1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end



function et_fc2_Callback(hObject, eventdata, handles)
    input = str2double(get(hObject,'String'));
    if (isempty(input))
         set(hObject,'String','0')
    end
    guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function et_fc2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_fc2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end


% --- Executes on button press in pb_applybutter.
function pb_applybutter_Callback(hObject, eventdata, handles)
    % Get parameters
    N = str2double(get(handles.et_n,'String'));
    Fc1 = str2double(get(handles.et_fc1,'String'));
    Fc2 = str2double(get(handles.et_fc2,'String'));
    % Load matrix
    load('cdata.mat');
    cdata = apply_butter(Fs, N, Fc1, Fc2, cdata);
    data_show(handles,cdata,Fs,Ts);
    save('cdata.mat','cdata','Fs','Ts');


function et_it0_Callback(hObject, eventdata, handles)
    input = str2double(get(hObject,'String'));
    if (isempty(input))
         set(hObject,'String','0')
    end

    xmax = str2double(get(handles.et_ft0,'String'));
    set(handles.a_t0,'XLim',[input xmax]);
    set(handles.a_t1,'XLim',[input xmax]);
    set(handles.a_t2,'XLim',[input xmax]);
    set(handles.a_t3,'XLim',[input xmax]);

    guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function et_it0_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_it0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_ft0_Callback(hObject, eventdata, handles)
input = str2double(get(hObject,'String'));
if (isempty(input))
     set(hObject,'String','0')
end

xmin = str2double(get(handles.et_it0,'String'));
set(handles.a_t0,'XLim',[xmin input]);
set(handles.a_t1,'XLim',[xmin input]);
set(handles.a_t2,'XLim',[xmin input]);
set(handles.a_t3,'XLim',[xmin input]);

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function et_ft0_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_ft0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function m_file_Callback(hObject, eventdata, handles)
% hObject    handle to m_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function m_load_Callback(hObject, eventdata, handles)
    t_load_ClickedCallback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function t_load_ClickedCallback(hObject, eventdata, handles)
% Callback function run when the Open menu item is selected
ss=[];
[file, path] = uigetfile('*.mat');
    if ~isequal(file, 0)
        load([path,file]);
        if(exist('Fs','var')) == 1                  % load one shot
            data_show(handles,cdata,Fs,Ts);
            save('cdata.mat','cdata','Fs','Ts');
        else                                        % load session
            df = recording_session_show_fig();
            dfdata = guidata(df);
            set(dfdata.et_Fs,'String',num2str(ss.Fs));
            set(dfdata.et_Ne,'String',num2str(ss.Ne));
            set(dfdata.et_Nr,'String',num2str(ss.Nr));
            set(dfdata.et_Tc,'String',num2str(ss.Tc));
            set(dfdata.et_Tr,'String',num2str(ss.Tr));
            set(dfdata.et_Psr,'String',num2str(ss.Psr));
            set(dfdata.et_msg,'String',ss.msg);
            sNe = 1:ss.Ne;
            set(dfdata.pm_Ne,'String',num2str(sNe'));
            set(dfdata.pm_data,'UserData',ss);         % Save Struct in user data
            set(dfdata.t_mhandles,'UserData',handles); % Save this GUI handles

        end
    end


% --------------------------------------------------------------------
function t_save_ClickedCallback(hObject, eventdata, handles)    
% Callback function run when the Save menu item is selected
    [filename, pathname] = uiputfile({'*.mat','MAT-files (*.mat)'},'Save as', 'Untitled.mat');
    copyfile('cdata.mat',[pathname,filename],'f');


% --------------------------------------------------------------------
function m_record_Callback(hObject, eventdata, handles)
% hObject    handle to m_record (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function m_Rstandardsession_Callback(hObject, eventdata, handles)
%Function that calls the standard recording session
    Fs = 10000; % Sampling Frequency
    Ne = 4;     % number of excersices or movements
    Nr = 10;    % number of excersice repetition
    Tc = 2;     % time that the contractions should last
    Tr = 3;     % relaxing time
    Psr = .5;   % Percentage of the escersice time to be consider for training
    msg = {'Open   Hand';
           'Close  Hand';
           'Flex   Hand';
           'Extend Hand'};
           %'Pronation  ';
           %'Supination '};

    cdata = recording_session(Fs,Ne,Nr,Tc,Tr,Psr,msg,handles);
    Ts = (Tc+Tr)*Nr;
    save('cdata.mat','cdata','Fs','Ts');


% --------------------------------------------------------------------
function m_Recordoneshot_Callback(hObject, eventdata, handles)
    pb_startrecording_Callback(hObject, eventdata, handles)


% --------------------------------------------------------------------
function m_Rcustomizedsession_Callback(hObject, eventdata, handles)
    %Call the figure recording_Session_fig and pass this figure handles
    recording_session_fig();


% --------------------------------------------------------------------
function m_filters_Callback(hObject, eventdata, handles)
% hObject    handle to m_filters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function m_Fcustomized_Callback(hObject, eventdata, handles)
% hObject    handle to m_Fcustomized (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function m_Fbandstop_Callback(hObject, eventdata, handles)
% hObject    handle to m_Fbandstop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function m_Fplh_Callback(hObject, eventdata, handles)
    load('cdata.mat');
    cdata = BSbutterPLHarmonics(Fs,cdata);
    data_show(handles,cdata,Fs,Ts);
    save('cdata.mat','cdata','Fs','Ts');


% --------------------------------------------------------------------
function m_FBSbutter_Callback(hObject, eventdata, handles)
% hObject    handle to m_FBSbutter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function m_Pattern_Recognition_Callback(hObject, eventdata, handles)
    pattern_recognition_fig();

% --------------------------------------------------------------------
function m_PR_train_ANN_Callback(hObject, eventdata, handles)
% hObject    handle to m_PR_train_ANN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function m_Control_Callback(hObject, eventdata, handles)


% --------------------------------------------------------------------
function m_signalanalysis_Callback(hObject, eventdata, handles)
    signalchrs_fig();


% --------------------------------------------------------------------
function m_onemotorTP_Callback(hObject, eventdata, handles)
    one_motro_test_panel_fig();


% --- Executes on button press in cb_ch4.
function cb_ch4_Callback(hObject, eventdata, handles)
% hObject    handle to cb_ch4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_ch4


% --- Executes on button press in cb_ch5.
function cb_ch5_Callback(hObject, eventdata, handles)
% hObject    handle to cb_ch5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_ch5


% --- Executes on button press in cb_ch6.
function cb_ch6_Callback(hObject, eventdata, handles)
% hObject    handle to cb_ch6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_ch6


% --- Executes on button press in cb_ch7.
function cb_ch7_Callback(hObject, eventdata, handles)
% hObject    handle to cb_ch7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_ch7

function varargout = GUI_TestALCD(varargin)
% GUI_TESTALCD MATLAB code for GUI_TestALCD.fig
%      GUI_TESTALCD, by itself, creates a new GUI_TESTALCD or raises the existing
%      singleton*.
%
%      H = GUI_TESTALCD returns the handle to a new GUI_TESTALCD or the handle to
%      the existing singleton*.
%
%      GUI_TESTALCD('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI_TESTALCD.M with the given input arguments.
%
%      GUI_TESTALCD('Property','Value',...) creates a new GUI_TESTALCD or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI_TestALCD_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI_TestALCD_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUI_TestALCD

% Last Modified by GUIDE v2.5 26-Oct-2017 12:01:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_TestALCD_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_TestALCD_OutputFcn, ...
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


% --- Executes just before GUI_TestALCD is made visible.
function GUI_TestALCD_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI_TestALCD (see VARARGIN)

% Choose default command line output for GUI_TestALCD
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GUI_TestALCD wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GUI_TestALCD_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pb_start.
function pb_start_Callback(hObject, eventdata, handles)
% hObject    handle to pb_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

     sT = str2double(get(handles.et_sT,'String'));
%      RTfilterEnable = get(handles.FiltCheckBox,'Value');
     tW = str2double(get(handles.et_tWplot,'String'));
     sF = get(handles.pm_sF,'string');
     sF = str2num(sF{get(handles.pm_sF,'Value')});
     
     %Selected channels
     allCh = str2double(get(handles.lb_ch,'String'));
     vCh = allCh(get(handles.lb_ch,'Value')); % Vector of channels
     nCh = size(vCh,1);    
    
    % Setting for data peeking
    tv = 0:1/sF:tW-1/sF;                                                   % Create vector of time
    tWs = tW*sF;                                                           % Time window samples
    sData = zeros(tWs,nCh);                                                % tWs sized matrix useful for real time plot
    allData = zeros(sT*sF, nCh);                                           % sT*sF sized matrix used for keep all datas
    
    plotGain = 10000000;
    
    % Offset the plot of the different channels to fit into the main figure
    ampPP     = 5;
    offVector = 0:nCh-1;
    offVector = offVector .* ampPP;
    for i = 1 : nCh
        sData(:,i) = sData(:,i) + offVector(i);
    end    
    
    % Draw figure
    p_t0 = plot(handles.a_t0, tv, sData);
    xlim([0,tW]);
    set(handles.a_t0,'YTick',offVector);
    set(handles.a_t0,'YTickLabel',1:nCh);   

    % Get connection object
    if isfield(handles,'obj')
        obj = handles.obj;
    else
        set(handles.t_msg,'String','No connection obj found');   
        return;
    end
    
    % Set up receiving buffer
    obj.InputBufferSize = sT*sF*4*nCh;
    
    % Open the connection
    fopen(obj);
    % Read available data and discard it
    if obj.BytesAvailable > 1
        fread(obj,obj.BytesAvailable,'uint8');    % Read the samples        
    end    

    sData = zeros(tWs, nCh);                                               % tWs sized vector used for offset and plot datas
    printFlag = 1; 

    % Start the acquisition
    fwrite(obj,'G','char');
    fwrite(obj,nCh,'char');
    replay = char(fread(obj,1,'char'));
    switch replay
        case 'G'
            set(handles.t_msg,'String','EMG Start');
        case 'L'
            set(handles.t_msg,'String','Error: Neuromotus locked');
            fclose(obj);
            return
        case 'B'
            set(handles.t_msg,'String','Error: Battery Low!');
            fclose(obj);
            return
    end
    
    tic;
    for i = 1:sT*sF  
        % Set warnings to temporarily issue error (exceptions)
        s = warning('error', 'instrument:fread:unsuccessfulRead');
        try
            % float data mode (4bytes X nCh channels)
            byteData = fread(obj,nCh,'float32');                             
            allData(i,:) = byteData(1:nCh,:)';
            sData(printFlag,:) = byteData(1:nCh,:)';
        catch exception
           set(handles.t_msg,'String','Error in communication'); 
           delete(obj);
           return
        end
        %Set warning back to normal state
        warning(s);

%         % float data mode (4bytes X nCh channels)
%         byteData = fread(obj,nCh,'float32');                             
%         allData(i,:) = byteData(1:nCh,:)';
%         sData(printFlag,:) = byteData(1:nCh,:)'; 

        printFlag = printFlag + 1; 
        if printFlag >= tWs+1 
            
            % calculate single channel's plot gain for time window
            % the idea is that the gain is automatically scaled depending on the absolute maximum
            % value found in this new recording. In this way the gain will be changed
            % dynamically to be able to discern a "rest" from a "contraction" plot
            K = ampPP/(2*(max(max(abs(sData)))));
            if K < plotGain
                % if the signals in the different windows is getting bigger the gain
                % must be reduced consequently, the channels plots must always fit
                % the main plot
                plotGain = K;
            end
            % plot a new tWs sized window
            for j = 1 : nCh
                set(p_t0(j),'YData',sData(:,j)*plotGain + offVector(j));       % add offsets to plot channels in same graph
            end 
            printFlag = 1;
            drawnow 
        end 
    end
    
    toc;
    
    % Stop the aquisition
    fwrite(obj,'T','char');
    
    % Close connection
    fclose(obj);
    disp(obj);
    
    % Print the data    
    tv = 0:1/sF:sT-1/sF;                                                   % Create vector of time
    for i = 1:sT*sF 
        for k = 1:nCh        
            sData(i,k) = allData(i,k)*plotGain + offVector(k);
        end 
    end
    plot(tv, sData);
    
    if get(handles.cb_FFT,'Value');
        % Plot FFT of acquired signals
        nS = length(sData(:,1));     
        nS = 2^nextpow2(nS);               % Find next power of 2
        X = fft(sData,nS);
        spectra2side = abs(X/nS);          % 2-side Magnitude Spectrum
        %phi = angle(X);                   % Phase (radians)
        %S = (X .^ 2);                     % Power Density Spectrum
        % 1-side Magnitude Spectrum
        spectra1side = spectra2side(1:nS/2+1,:);
        spectra1side(2:end-1) = 2*spectra1side(2:end-1);                                     
        % Offset and scale the data
        offVector = 0:nCh-1;
        for j = 1 : nCh
            fData(:,j) = spectra1side(:,j) + offVector(j);
        end
        % plot
        figure(1)
        f = sF*(0:(nS/2))/nS;
        a_f0 = plot(f,fData);
        title('Single-Sided Amplitude Spectrum')
        xlabel('f (Hz)')
        ylabel('|A(f)|')
        %set(a_f0,'YTick',offVector);
        %set(a_f0,'YTickLabel',0:nCh-1);
        %xlim(a_f0, [0,sF/2]);
    end
    
    set(handles.t_msg,'String','');
   
    save('EMG.mat','allData');                                         % save all original datas
    %save('byteData.mat','byteData');                                       % to check the sync: the first 3 bytes must be 0x(C0 00 00)
    
    
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



function et_Mode_Callback(hObject, eventdata, handles)
% hObject    handle to et_Mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_Mode as text
%        str2double(get(hObject,'String')) returns contents of et_Mode as a double


% --- Executes during object creation, after setting all properties.
function et_Mode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_Mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function et_tWplot_Callback(hObject, eventdata, handles)
% hObject    handle to et_tWplot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tWplot as text
%        str2double(get(hObject,'String')) returns contents of et_tWplot as a double


% --- Executes during object creation, after setting all properties.
function et_tWplot_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tWplot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_connect.
function pb_connect_Callback(hObject, eventdata, handles)
% hObject    handle to pb_connect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    WiFi = get(handles.cb_WiFi,'Value');
    compath_idx = get(handles.pm_ComPort,'Value');
    ComPortName     = get(handles.pm_ComPort,'string');
    ComPortName     = ComPortName(compath_idx);
%     BaudRate    = 921600;
    BaudRate    = 460800;
    set(handles.t_msg,'String','Testing connection...');   
    delete(instrfindall);
    if WiFi
        obj = tcpip('192.168.100.10',65100,'NetworkRole','client');        % WIICOM
    else
        obj = serial (ComPortName, 'baudrate', BaudRate, 'databits', 8, 'byteorder', 'bigEndian');
    end
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


% --- Executes on selection change in et_Ampp.
function et_Ampp_Callback(hObject, eventdata, handles)
% hObject    handle to et_Ampp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns et_Ampp contents as cell array
%        contents{get(hObject,'Value')} returns selected item from et_Ampp


% --- Executes during object creation, after setting all properties.
function et_Ampp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_Ampp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in FiltCheckBox.
function FiltCheckBox_Callback(hObject, eventdata, handles)
% hObject    handle to FiltCheckBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of FiltCheckBox


function txt_COM_Callback(hObject, eventdata, handles)
% hObject    handle to txt_COM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_COM as text
%        str2double(get(hObject,'String')) returns contents of txt_COM as a double


% --- Executes during object creation, after setting all properties.
function txt_COM_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_COM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in mode_pb.
function mode_pb_Callback(hObject, eventdata, handles)
% hObject    handle to mode_pb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

     % Read the selected Mode to create the proper buffer size and time vector
     mode = str2double(get(handles.et_Mode,'String'));
     switch mode
        case 2
            sF = 4000;
        case 3
            sF = 2000;
        case 4
            sF = 1000;
        case 5
            sF = 500;
        case 6
            sF = 250;
        otherwise
           sF = 2000;
           set(handles.t_msg,'String','Mode value not correct -> sF = 2000SPS');
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

    % Set up the ADS1299 datarate output (and bandwidth)
    fwrite(obj,'F','char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'F')
        fwrite(obj,mode,'char');
        replay = char(fread(obj,1,'char'));
        if strcmp(replay,'F');
            set(handles.t_msg,'String','DataRate set');
        else
            set(handles.t_msg,'String','Error Setting Mode'); 
            fclose(obj);
            return
        end
    else
        set(handles.t_msg,'String','Error Setting Mode'); 
        fclose(obj);
        return
    end
    
    fclose(obj);


% --- Executes on button press in gain_pb.
function gain_pb_Callback(hObject, eventdata, handles)
% hObject    handle to gain_pb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % Read selected gain
    switch get(handles.et_Ampp,'Value');
        case 1
            A = 7;
            ADSgain = 24;
        case 2
            A = 6;
            ADSgain = 12;
        case 3
            A = 5;
            ADSgain = 8;
        case 4
            A = 4;
            ADSgain = 6;
        case 5
            A = 3;
            ADSgain = 4;
        case 6
            A = 2;
            ADSgain = 2;
        case 7
            A = 1;
            ADSgain = 1;
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
 
    % Set up the ADS1299 gain
    fwrite(obj,'K','char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'K')
        fwrite(obj,A,'char');
        replay = char(fread(obj,1,'char'));
        if strcmp(replay,'K');
            set(handles.t_msg,'String','Gain set');
        else
            set(handles.t_msg,'String','Error Setting Gain'); 
            fclose(obj);
            return
        end
    else
        set(handles.t_msg,'String','Error Setting Gain'); 
        fclose(obj);
        return
    end
    
    fclose(obj);


% --- Executes on button press in pb_PatRecStart.
function pb_PatRecStart_Callback(hObject, eventdata, handles)
% hObject    handle to pb_PatRecStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    %Selected channels
    allCh = str2double(get(handles.lb_ch,'String'));
    vCh = allCh(get(handles.lb_ch,'Value')); % Vector of channels
    nCh = size(vCh,1);   
    tPrediction = str2double(get(handles.et_tPredict,'String'));
    samples = str2double(get(handles.eT_samples,'String'));
     
    % Get connection object
    if isfield(handles,'obj')
        obj = handles.obj;
    else
        set(handles.t_msg,'String','No connection obj found');   
        return;
    end
    
    % Set up receiving buffer
    obj.InputBufferSize = samples;
    
    % Open the connection
    fopen(obj);
    % Read available data and discard it
    if obj.BytesAvailable > 1
        fread(obj,obj.BytesAvailable,'uint8');    % Read the samples        
    end    
    
    % Start the Control Test
    fwrite(obj,'L','char');
    fwrite(obj,nCh,'char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'L')
        set(handles.t_msg,'String','Control-Test Start');
    else
        set(handles.t_msg,'String','Error Start'); 
        fclose(obj);
        return
    end

    tic;
    for i = 1:samples
        % Read the predicted movement from ALC-D
        % Movements are hardcoded accordingly to this definition:
        % #define REST 			  		0
        % #define OPENHAND 			  	1
        % #define CLOSEHAND			  	2
        % #define PRONATION            	3
        % #define SUPINATION            4
        % #define SWITCH1               5
        % Conversion of the ALC-D output is needed because:
        %  - zero index
        %  - REST is usually the last one in BioPatRec
        movIdx = fread(obj,1,'char');   
        activLevel = fread(obj,1,'char');
        set(handles.txt_predict,'String',num2str(movIdx));
        set(handles.txt_activLevel,'String',num2str(activLevel));
        switch movIdx
            case 199
                set(handles.t_msg,'String','majority vote step');
            case 0
                set(handles.t_msg,'String','rest');
            case 1
                set(handles.t_msg,'String','open');
            case 2
                set(handles.t_msg,'String','close');
            case 3
                set(handles.t_msg,'String','switch1');
            case 4
                set(handles.t_msg,'String','pronation');
            case 5
                set(handles.t_msg,'String','supination');
            case 6
                set(handles.t_msg,'String','co-contraction');
%             case 4
%                 set(handles.t_msg,'String','flex');
%             case 5
%                 set(handles.t_msg,'String','extend');
            otherwise
                set(handles.t_msg,'String','possible error!');
        end
        drawnow;
        outMov(i,:) = [movIdx activLevel];
    end
    disp('Estimated time:');
    samples*tPrediction
    toc
    
    % Stop the aquisition
    fwrite(obj,'T','char');
    % Close connection
    fclose(obj);
    set(handles.t_msg,'String','Control-Test session completed');
    set(handles.txt_predict,'String','');
    set(handles.txt_activLevel,'String','');
    save('Control-Output.mat','outMov');                                                                               
    

% --- Executes on button press in pb_PatRecStop.
function pb_PatRecStop_Callback(hObject, eventdata, handles)
% hObject    handle to pb_PatRecStop (see GCBO)
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
    % Stop ADS1299 continous acquisition
    fwrite(obj,'T','char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'T')
        set(handles.t_msg,'String','');
    else
        set(handles.t_msg,'String','Error with Stop command'); 
        fclose(obj);
        return
    end
    fclose(obj);


% --- Executes on button press in pb_features.
function pb_features_Callback(hObject, eventdata, handles)
% hObject    handle to pb_features (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % Selected channels
    allCh = str2double(get(handles.lb_ch,'String'));
    vCh = allCh(get(handles.lb_ch,'Value')); % Vector of channels
    nCh = size(vCh,1);  
    sF = get(handles.pm_sF,'string');
    sF = str2num(sF{get(handles.pm_sF,'Value')});
    tW = str2double(get(handles.et_tW,'String'));
    oW = str2double(get(handles.et_oW,'String'));

    tWplot = str2double(get(handles.et_tWplot,'String'));
    sF = get(handles.pm_sF,'string');
    sF = str2num(sF{get(handles.pm_sF,'Value')});
    tPrediction = str2double(get(handles.et_tPredict,'String'));
     
    samples = str2double(get(handles.eT_samples,'String'));
    plotGain = 10000000;
    sData = zeros((tWplot/tPrediction)+1,nCh); 
    tv = 0:tPrediction:tWplot;  
    
    % Offset the plot of the different channels to fit into the main figure
    ampPP     = 20000;
    offVector = 0:nCh-1;
    offVector = offVector .* ampPP;
    for i = 1 : nCh
        sData(:,i) = sData(:,i) + offVector(i);
    end    
    % Draw figure
    p_t0 = plot(handles.a_t0, tv, sData);
    xlim([0,tWplot]);
    set(handles.a_t0,'YTick',offVector);
    set(handles.a_t0,'YTickLabel',1:nCh); 
     
    % Get connection object
    if isfield(handles,'obj')
        obj = handles.obj;
    else
        set(handles.t_msg,'String','No connection obj found');   
        return;
    end
    % Set up receiving buffer
    obj.InputBufferSize = 4*8*samples*5;

    % Open the connection
    fopen(obj);
    % Read available data and discard it
    if obj.BytesAvailable > 1
        fread(obj,obj.BytesAvailable,'uint8');    % Read the samples        
    end    
    
    % Set the parameters for features extraction
    tWs = sF*tW;
    oWs = sF*oW;
    FeaturesEnables(1) = get(handles.cb_mabs,'Value');
    FeaturesEnables(2) = get(handles.cb_wl,'Value');
    FeaturesEnables(3) = get(handles.cb_zc,'Value');
    FeaturesEnables(4) = get(handles.cb_slpch,'Value');
    FeaturesEnables(5) = get(handles.cb_std,'Value');
    nFeatures = sum(FeaturesEnables(:));
    SetFeaturesExtractionParametersALCD(handles, tWs, oWs, FeaturesEnables);
    
    feat2Plot = 0; % TMABS
%     feat2Plot = 1; % TWL
%     feat2Plot = 2; % TZC
%     feat2Plot = 3; % TSLPCH
%     feat2Plot = 4; % TSTD
    featureOffset = feat2Plot*nCh; 
    
    % Start the features extraction
    fwrite(obj,'X','char');
    fwrite(obj,nCh,'char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'X')
        set(handles.t_msg,'String','Features reception Start');
    else
        set(handles.t_msg,'String','Error Start'); 
        fclose(obj);
        return
    end
    drawnow;
    
    printFlag = 1;
    
    tic;
    for i = 1:samples
        % (4bytes X features X nCh channels)
        byteData = fread(obj,(nFeatures*nCh),'float32');                             
        features(i,:) = byteData;   
        sData(printFlag,:) = byteData(1+featureOffset:nCh+featureOffset,:)';
        
        printFlag = printFlag + 1; 
        if printFlag > tWplot/tPrediction+1
            
            % calculate single channel's plot gain for time window
            % the idea is that the gain is automatically scaled depending on the absolute maximum
            % value found in this new recording. In this way the gain will be changed
            % dynamically to be able to discern a "rest" from a "contraction" plot
            K = ampPP/(2*(max(max(abs(sData)))));
            if K < plotGain
                % if the signals in the different windows is getting bigger the gain
                % must be reduced consequently, the channels plots must always fit
                % the main plot
                plotGain = K;
            end
            % plot a new tWs sized window
            for j = 1 : nCh
                set(p_t0(j),'YData',sData(:,j)*plotGain + offVector(j));       % add offsets to plot channels in same graph
            end 
            printFlag = 1;
            drawnow 
        end 
        
    end
    toc;
    
    % Stop the aquisition
    fwrite(obj,'T','char');
    % Close connection
    fclose(obj);
    disp(obj);
    set(handles.t_msg,'String','Features Received');
    % Print the data    
    tv = 0:tPrediction:samples*tPrediction-tPrediction;                                                   
    for i = 1:samples 
        for k = 1:nCh        
            sData(i,k) = features(i,k)*plotGain + offVector(k);
        end 
    end
    plot(tv, sData);
    drawnow;
    save('features.mat','features');                                                                                      


function eT_samples_Callback(hObject, eventdata, handles)
% hObject    handle to eT_samples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eT_samples as text
%        str2double(get(hObject,'String')) returns contents of eT_samples as a double


% --- Executes during object creation, after setting all properties.
function eT_samples_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eT_samples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cb_WiFi.
function cb_WiFi_Callback(hObject, eventdata, handles)
% hObject    handle to cb_WiFi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_WiFi


% --- Executes on button press in cb_filters.
function cb_filters_Callback(hObject, eventdata, handles)
% hObject    handle to cb_filters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_filters

    FiltersEnable = get(handles.cb_filters,'Value');
    
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
    fwrite(obj,'H','char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'H')
        fwrite(obj,FiltersEnable,'char');
        replay = char(fread(obj,1,'char'));
        if strcmp(replay,'H');
            if(FiltersEnable)
                set(handles.t_msg,'String','Filters enabled');
            else
                set(handles.t_msg,'String','Filters disabled');
            end
        else
            set(handles.t_msg,'String','Error Setting Filters enable'); 
            fclose(obj);
            return
        end
    else
        set(handles.t_msg,'String','Error Setting Filters enable'); 
        fclose(obj);
        return
    end
    
    fclose(obj);


% --- Executes on button press in cb_testsignal.
function cb_testsignal_Callback(hObject, eventdata, handles)
% hObject    handle to cb_testsignal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_testsignal

    TestSignalEnable = uint8(get(handles.cb_testsignal,'Value'));
    
    % Get connection object
    if isfield(handles,'obj')
        obj = handles.obj;
    else
        set(handles.t_msg,'String','No connection obj found');   
        return;
    end
    % Open the connection
    fopen(obj);

    % Set up the test signal enable
    fwrite(obj,'P','char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'P')
        fwrite(obj,TestSignalEnable,'char');
        replay = char(fread(obj,1,'char'));
        if strcmp(replay,'P');
            if(TestSignalEnable)
                set(handles.t_msg,'String','Test Signal enabled');
            else
                set(handles.t_msg,'String','Test Signal disabled');
            end
        else
            set(handles.t_msg,'String','Error Setting Test Signal enable'); 
            fclose(obj);
            return
        end
    else
        set(handles.t_msg,'String','Error Setting Test Signal enable'); 
        fclose(obj);
        return
    end
    
    fclose(obj);


% --- Executes on button press in pb_readRegisters.
function pb_readRegisters_Callback(hObject, eventdata, handles)
% hObject    handle to pb_readRegisters (see GCBO)
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

    % Ask for 24 bytes containing the config registers of ADS1299
    fwrite(obj,'q','char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'q')
        for i = 1:24
            reg(i,:) = dec2hex(fread(obj,1,'char'));
        end
        %msgbox({'CONFIG REGISTERs:'},{'00 = %x'});
        replay = char(fread(obj,1,'char'));
        if strcmp(replay,'q')
            disp(obj)
            save('CONFIG.mat','reg');  
            set(handles.t_msg,'String','Config registers value saved into CONFIG.mat file');
        else
            set(handles.t_msg,'String','Error Reading Registers'); 
            fclose(obj);
            return
        end
    else
        set(handles.t_msg,'String','Error Reading Registers'); 
        fclose(obj);
        return
    end

    fclose(obj);


% --- Executes on button press in cb_wl.
function cb_wl_Callback(hObject, eventdata, handles)
% hObject    handle to cb_wl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_wl


% --- Executes on button press in cb_zc.
function cb_zc_Callback(hObject, eventdata, handles)
% hObject    handle to cb_zc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_zc


% --- Executes on button press in cb_slpch.
function cb_slpch_Callback(hObject, eventdata, handles)
% hObject    handle to cb_slpch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_slpch


% --- Executes on button press in cb_mabs.
function cb_mabs_Callback(hObject, eventdata, handles)
% hObject    handle to cb_mabs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_mabs


% --------------------------------------------------------------------
function menu_test_Callback(hObject, eventdata, handles)
% hObject    handle to menu_test (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_testFilters_Callback(hObject, eventdata, handles)
% hObject    handle to menu_testFilters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    [file, path] = uigetfile({'*.mat';'*.csv'});
    if ~isequal(file, 0)
        [pathstr,name,ext] = fileparts(file);
        if(strcmp(ext,'.mat'))
            load([path,file]);
            if(exist('recSession','var')) == 1              % Load current data 
                Data = recSession.tdata(:,:,1);
                nCh = recSession.nCh;
            elseif(exist('allData','var')) == 1
                Data = allData;
                nCh = size(Data,2);
            else
                set(handles.t_msg,'String','File not valid');
            end
        end
    end

    % Send samples to ALC-D and receiving back the filtered samples
    set(handles.t_msg,'String','Filtering data on ALC-D...');
    
    % Get connection object
    if isfield(handles,'obj')
        obj = handles.obj;
    else
        set(handles.t_msg,'String','No connection obj found');   
        return;
    end
    % Open the connection
    fopen(obj);
   
    tic
    fwrite(obj,'h','char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'h')
        fwrite(obj,nCh,'char');
        fwrite(obj,length(Data),'float');
        set(handles.t_msg,'String','Filtering can take some minutes...');
        drawnow;
        for sample = 1:length(Data)
            for ch = 1:nCh
                fwrite(obj,Data(sample,ch),'float');
                FiltData(sample,ch) = fread(obj,1,'float32');
                message = sprintf('Filtering can take some minutes... %d on %d', sample, length(Data));
                set(handles.t_msg,'String', message);
                drawnow;
            end   
        end
        replay = char(fread(obj,1,'char'));
        if strcmp(replay,'h')
            set(handles.t_msg,'String','Filtering completed');
        else
            set(handles.t_msg,'String','Error in Synchronization');
            fclose(obj);
            return
        end
    else
        set(handles.t_msg,'String','Error in Synchronization');
        fclose(obj);
        return
    end
    toc
    
    fclose(obj);
    disp(obj)
    save('FilterTest.mat','FiltData');   
    set(handles.t_msg,'String','Results saved in FilterTest.mat');
    

% --- Executes on button press in cb_std.
function cb_std_Callback(hObject, eventdata, handles)
% hObject    handle to cb_std (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_std
    
   
% --- Executes on button press in cb_impedance.
function cb_impedance_Callback(hObject, eventdata, handles)
% hObject    handle to cb_impedance (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_impedance

    impedanceMeasureEnable = get(handles.cb_impedance,'Value');
    
    % Get connection object
    if isfield(handles,'obj')
        obj = handles.obj;
    else
        set(handles.t_msg,'String','No connection obj found');   
        return;
    end
    % Open the connection
    fopen(obj);

%     %% OBSOLETE
%     % Set up the downsampling enable
%     fwrite(obj,'D','char');
%     replay = char(fread(obj,1,'char'));
%     if strcmp(replay,'D')
%         fwrite(obj,DownSamplingEnable,'char');
%         replay = char(fread(obj,1,'char'));
%         if strcmp(replay,'D');
%             if(DownSamplingEnable)
%                 set(handles.t_msg,'String','DownSampling enabled');
%             else
%                 set(handles.t_msg,'String','DownSampling disabled');
%             end
%         else
%             set(handles.t_msg,'String','Error Setting DownSampling enable'); 
%             fclose(obj);
%             return
%         end
%     else
%         set(handles.t_msg,'String','Error Setting DownSampling enable'); 
%         fclose(obj);
%         return
%     end

    % Set up the downsampling enable
    fwrite(obj,'I','char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'I')
        fwrite(obj,impedanceMeasureEnable,'char');
        answer = char(fread(obj,1,'char'));
        if(answer)
            set(handles.t_msg,'String','Impedance Measure settings enabled');
        else
            set(handles.t_msg,'String','Impedance Measure settings disabled');
        end
    else
        set(handles.t_msg,'String','Error Setting Impedance Measure settings'); 
        fclose(obj);
        return
    end
    
    fclose(obj);


% --------------------------------------------------------------------
function menu_Hardware_Callback(hObject, eventdata, handles)
% hObject    handle to menu_Hardware (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_fwVersion_Callback(hObject, eventdata, handles)
% hObject    handle to menu_fwVersion (see GCBO)
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

    % Ask for serial number and firmware version of the device
    fwrite(obj,hex2dec('a0'),'uint8');
    replay = fread(obj,1,'uint8');
    if replay == hex2dec('a0')
        serialN = [];
        stop = 0;
        while stop == 0
            serialN = [serialN char(fread(obj,1,'char'))];
            stop = strcmp(serialN(end),'~');
        end
        serialN = serialN(1:end-1);
        firmwareV = [];
        stop = 0;
        while stop == 0
            firmwareV = [firmwareV char(fread(obj,1,'char'))];
            stop = strcmp(firmwareV(end),'~');
        end
        firmwareV = firmwareV(1:end-1);
        replay = fread(obj,1,'uint8');
        if replay == hex2dec('a0')
            msgbox(sprintf('Device: %s\nFirmware version: %s',serialN,firmwareV));
        else
            set(handles.t_msg,'String','Error Reading Firmware version'); 
            fclose(obj);
            return
        end
    else
        set(handles.t_msg,'String','Error Reading Firmware version'); 
        fclose(obj);
        return
    end

    fclose(obj);


% --------------------------------------------------------------------
function menu_SD_Callback(hObject, eventdata, handles)
% hObject    handle to menu_SD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_Read_Callback(hObject, eventdata, handles)
% hObject    handle to menu_Read (see GCBO)
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
    
    % Ask for SD memory blocks
    prompt = {'Enter number of Blocks to Read:','Enter starting Address:'};
    dlg_title = 'SDcard download';
    num_lines = 1;
    def = {'10','0'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    numBlocks = str2num(char(answer(1)));
    address = str2num(char(answer(2)));
    
    tic
    % Set warnings to temporarily issue error (exceptions)
    s = warning('error', 'instrument:fread:unsuccessfulRead');
    fwrite(obj,'m','char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'m')
        fwrite(obj,numBlocks,'uint32');
        fwrite(obj,address,'uint32');
        for i = 1:numBlocks 
            try
                SDcardValues(i,:) = fread(obj,512,'char');
                message = sprintf('Downloading can take some minutes... %d on %d', i, numBlocks);
                set(handles.t_msg,'String', message);
                drawnow;
            catch exception
               save('SDcard.mat','SDcardValues'); 
               set(handles.t_msg,'String','Error in communication: not all blocks were donwloaded'); 
               delete(obj);
               return
               
%             SDcardValues(i,:) = fread(obj,512,'char');
%             message = sprintf('Downloading can take some minutes... %d on %d', i, numBlocks);
%             set(handles.t_msg,'String', message);
%             drawnow;
            end
            %Set warning back to normal state
            warning(s)
        end
        replay = char(fread(obj,1,'char'));
        if strcmp(replay,'m')
            disp(obj)
            save('SDcard.mat','SDcardValues');  
            set(handles.t_msg,'String','SDcard read successful: value saved into SDcard.mat file');
        else
            set(handles.t_msg,'String','Error Reading SDcard'); 
            fclose(obj);
            return
        end
    else
        set(handles.t_msg,'String','Error Reading SDcard'); 
        fclose(obj);
        return
    end
    toc

    fclose(obj);
    
   
% --------------------------------------------------------------------
function menu_memorySpace_Callback(hObject, eventdata, handles)
% hObject    handle to menu_memorySpace (see GCBO)
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
    
    tic
     
    fwrite(obj,'n','char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'n')
        LastLocationUsed = fread(obj,1,'uint32');
        replay = char(fread(obj,1,'char'));
        if strcmp(replay,'n')
            disp(obj) 
            message = sprintf('Memory state: %dB on %dGB, %d, block Idx = %d', LastLocationUsed*512, 16, (LastLocationUsed*512*100/16000000000), LastLocationUsed);
            set(handles.t_msg,'String', message);
            drawnow;
        else
            set(handles.t_msg,'String','Error with SDcard'); 
            fclose(obj);
            return
        end
    else
        set(handles.t_msg,'String','Error with SDcard'); 
        fclose(obj);
        return
    end
    
    toc

    fclose(obj);


% --------------------------------------------------------------------
function menu_Control_Callback(hObject, eventdata, handles)
% hObject    handle to menu_Control (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_SetChsMovs_Callback(hObject, eventdata, handles)
% hObject    handle to menu_SetChsMovs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % Open Fig and load information   
    guidata(hObject,handles);
    GUI_ControlSettings(handles);


% --------------------------------------------------------------------
function menu_PR_Callback(hObject, eventdata, handles)
% hObject    handle to menu_PR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_UploadCoefficients_Callback(hObject, eventdata, handles)
% hObject    handle to menu_UploadCoefficients (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


    % Dialog box to open a patRec file
    [file, path] = uigetfile({'*.mat'});
    if ~isequal(file, 0)
        [pathstr,name,ext] = fileparts(file);
        if(strcmp(ext,'.mat'))
            load([path,file]);
            if ~exist('patRec','var')  
                disp('Not a valid pattern recognition training file');
                errordlg('Not a valid patRec file','Error');
                return;   
            end
        else
            disp('Not a valid pattern recognition training file');
            errordlg('Not a valid patRec file','Error');
            return; 
        end
    end
    
    handles.patRec = patRec;
    
    if strcmp(handles.patRec.patRecTrained.algorithm, 'DA')
        UpdateCoefficientsALCD(handles);
    elseif strcmp(handles.patRec.patRecTrained.algorithm, 'SVM')
        UpdateCoefficientsALCD(handles);
    else
        set(handles.t_msg,'String','No DA or SVM found. No data uploaded');
    end


% --------------------------------------------------------------------
function menu_SetPRControl_Callback(hObject, eventdata, handles)
% hObject    handle to menu_SetPRControl (see GCBO)
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
    
    % Ask which algorithm
    prompt = {'Which algorithm? (1 = LDA, 2 = SVM)'};
    dlg_title = 'PR algorithm selection';
    num_lines = 1;
    def = {'1'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    controlMode = str2num(answer{:});

    % Set up PatRec-Control enable
    fwrite(obj,'l','char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'l')
        fwrite(obj,controlMode,'char');
        replay = char(fread(obj,1,'char'));
        if strcmp(replay,'l');
            switch controlMode
                case 1
                    set(handles.t_msg,'String','PatRec-Control enabled: LDA');
                case 2
                    set(handles.t_msg,'String','PatRec-Control enabled: SVM');
            end
        else
            set(handles.t_msg,'String','Error Setting PatRec-Control'); 
            fclose(obj);
            return
        end
    else
        set(handles.t_msg,'String','Error Setting PatRec-Control'); 
        fclose(obj);
        return
    end
    
    fclose(obj);
    

% --------------------------------------------------------------------
function menu_SetDirectControl_Callback(hObject, eventdata, handles)
% hObject    handle to menu_SetDirectControl (see GCBO)
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
    
    controlMode = 0;

    % Set up Direct-Control enable
    fwrite(obj,'l','char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'l')
        fwrite(obj,controlMode,'char');
        replay = char(fread(obj,1,'char'));
        if strcmp(replay,'l');
            set(handles.t_msg,'String','Direct-Control enabled');
        else
            set(handles.t_msg,'String','Error Setting Direct-Control'); 
            fclose(obj);
            return
        end
    else
        set(handles.t_msg,'String','Error Setting Direct-Control'); 
        fclose(obj);
        return
    end
    
    fclose(obj);


% --------------------------------------------------------------------
function menu_CheckBattery_Callback(hObject, eventdata, handles)
% hObject    handle to menu_CheckBattery (see GCBO)
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

    % ask for battery state
    fwrite(obj,'B','char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'B')
        battery = fread(obj,1,'float32');
        replay = char(fread(obj,1,'char'));
        if strcmp(replay,'B');
            msgbox(sprintf('Battery Voltage = %2.3g V',battery),'battery')
        else
            set(handles.t_msg,'String','Error, device is not responding or COM port is changed!'); 
            fclose(obj);
            return
        end
    else
        set(handles.t_msg,'String','Error, device is not responding or COM port is changed!');        
    end
    
    fclose(obj);


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


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% % Get connection object
% if isfield(handles,'obj')
%     obj = handles.obj;
%     % Close and delete connection
%     if strcmp(obj.status,'open')
%         fclose(obj);
%     end
%     delete(obj);
% end

% Hint: delete(hObject) closes the figure
delete(hObject);


% --------------------------------------------------------------------
function menu_CONTROL_Callback(hObject, eventdata, handles)
% hObject    handle to menu_CONTROL (see GCBO)
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

    % Set up the CONTROL MODE enable
    fwrite(obj,hex2dec('EE'),'char');
    replay = char(fread(obj,4,'char')');
    if strcmp(replay,'CTRL')
        set(handles.t_msg,'String','CONTROL MODE enabled'); 
    else
        set(handles.t_msg,'String','Error Setting CONTROL MODE'); 
        fclose(obj);
        return
    end
    
    fclose(obj);


% --------------------------------------------------------------------
function menu_COMMAND_Callback(hObject, eventdata, handles)
% hObject    handle to menu_COMMAND (see GCBO)
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

    % Set up the COMMAND MODE enable
    fwrite(obj,hex2dec('AA'),'char');
    replay = char(fread(obj,4,'char')');
    if strcmp(replay,'COMM')
        set(handles.t_msg,'String','COMMAND MODE enabled'); 
    else
        set(handles.t_msg,'String','Error Setting COMMAND MODE'); 
        fclose(obj);
        return
    end
    
    fclose(obj);


% --------------------------------------------------------------------
function menu_resetBlockIdx_Callback(hObject, eventdata, handles)
% hObject    handle to menu_resetBlockIdx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % Ask for SD memory blocks
    prompt = {'Are you sure? (y/n)'};
    dlg_title = 'Reset blockIdx';
    num_lines = 1;
    def = {'n'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    if strcmp(answer,'y')

        % Get connection object
        if isfield(handles,'obj')
            obj = handles.obj;
        else
            set(handles.t_msg,'String','No connection obj found');   
            return;
        end
        % Open the connection
        fopen(obj);

        % reset blockIdx (LogFile block pointer on hardware)
        fwrite(obj,'o','char');
        replay = char(fread(obj,1,'char')');
        if strcmp(replay,'o')
            set(handles.t_msg,'String','reset blockIdx'); 
        else
            set(handles.t_msg,'String','Error resetting blockIdx'); 
            fclose(obj);
            return
        end

        fclose(obj);
    else
        
    end


% --------------------------------------------------------------------
function menu_readLog_Callback(hObject, eventdata, handles)
% hObject    handle to menu_readLog (see GCBO)
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
    
    tic
    % Read blockIdx
    fwrite(obj,'n','char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'n')
        LastLocationUsed = fread(obj,1,'uint32');
        replay = char(fread(obj,1,'char'));
        if strcmp(replay,'n')
            disp(obj) 
            message = sprintf('Memory state: %dB on %dGB, %d, block Idx = %d ', LastLocationUsed*512, 2, (LastLocationUsed*512*100/2000000000), LastLocationUsed);
            set(handles.t_msg,'String', message);
            drawnow;
        else
            set(handles.t_msg,'String','Error with SDcard'); 
            fclose(obj);
            return
        end
    else
        set(handles.t_msg,'String','Error with SDcard'); 
        fclose(obj);
        return
    end
    numBlocks = LastLocationUsed;
    address = 19;
    
    fclose(obj);
    % Set up receiving buffer
    obj.InputBufferSize = 512*numBlocks;
    % Open the connection again
    fopen(obj);
    
    % Set warnings to temporarily issue error (exceptions)
    s = warning('error', 'instrument:fread:unsuccessfulRead');
    SDcardValues = zeros(numBlocks,512);   
    for i = 1:numBlocks
        go = 0;
        attempt = 0;
        while go == 0
            fwrite(obj,'m','char');
            replay = char(fread(obj,1,'char'));
            if strcmp(replay,'m')
                fwrite(obj,1,'uint32');
                fwrite(obj,address+i,'uint32');
                try
                    SDcardValues(i,:) = fread(obj,512,'char');
                catch exception
                   save('LogFile_ALC-D.mat','SDcardValues'); 
                   set(handles.t_msg,'String','Error1 in communication: not all blocks were donwloaded'); 
                   delete(obj);
                   return
                end 
                warning(s);
                if SDcardValues(i,1) ~= 255 && SDcardValues(i,1) ~= 127 && SDcardValues(i,1) ~= 0 && attempt < 3
                    go = 0;
                    attempt = attempt + 1;
                else
                    go = 1;     
                end
                char(fread(obj,1,'char'));
            else
                save('LogFile_ALC-D.mat','SDcardValues'); 
                set(handles.t_msg,'String','Error2 in communication: not all blocks were donwloaded'); 
                fclose(obj);
                return 
            end
        end
        message = sprintf('Downloading can take some minutes... %d on %d', i, numBlocks);
        set(handles.t_msg,'String', message);
        drawnow;
    end
    save('LogFile_ALC-D.mat','SDcardValues');
    set(handles.t_msg,'String','SDcard read successful: value saved into LogFile_ALC-D.mat file');
    toc
   
%     % Set warnings to temporarily issue error (exceptions)
%     s = warning('error', 'instrument:fread:unsuccessfulRead');
%     SDcardValues = zeros(numBlocks,512);
%     fwrite(obj,'m','char');
%     replay = char(fread(obj,1,'char'));
%     if strcmp(replay,'m')
%         fwrite(obj,numBlocks,'uint32');
%         fwrite(obj,address,'uint32');
%         for i = 1:numBlocks
%             try
%                 SDcardValues(i,:) = fread(obj,512,'char');
%                 message = sprintf('Downloading can take some minutes... %d on %d', i, numBlocks);
%                 set(handles.t_msg,'String', message);
%                 drawnow;
%             catch exception
%                save('LogFile_ALC-D.mat','SDcardValues'); 
%                set(handles.t_msg,'String','Error in communication: not all blocks were donwloaded'); 
%                delete(obj);
%                return
%             end
%             %Set warning back to normal state
%             warning(s); 
%         end
%         replay = char(fread(obj,1,'char'));
%         if strcmp(replay,'m')
%             disp(obj)
%             save('LogFile_ALC-D.mat','SDcardValues');  % BUG!!!!
%             set(handles.t_msg,'String','SDcard read successful: value saved into LogFile_ALC-D.mat file');
%         else
%             set(handles.t_msg,'String','Error Reading SDcard'); 
%             fclose(obj);
%             return
%         end 
%     else
%         set(handles.t_msg,'String','Error Reading SDcard'); 
%         fclose(obj);
%         return
%     end
%     toc

    fclose(obj);


% --- Executes on selection change in pm_sF.
function pm_sF_Callback(hObject, eventdata, handles)
% hObject    handle to pm_sF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pm_sF contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pm_sF

    sF = get(handles.pm_sF,'string');
    sF = str2num(sF{get(handles.pm_sF,'Value')});

    % Get connection object
    if isfield(handles,'obj')
        obj = handles.obj;
    else
        set(handles.t_msg,'String','No connection obj found');   
        return;
    end
    % Open the connection
    fopen(obj);

    % Set up the ADS1299 datarate output (and bandwidth)
    fwrite(obj,'r','char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'r')
        fwrite(obj,sF,'uint32');
        replay = char(fread(obj,1,'char'));
        if strcmp(replay,'r');
            set(handles.t_msg,'String','sampling frequency set');
        else
            set(handles.t_msg,'String','Error Setting sampling frequency'); 
            fclose(obj);
            return
        end
    else
        set(handles.t_msg,'String','Error Setting sampling frequency'); 
        fclose(obj);
        return
    end
    
    fclose(obj);


% --- Executes during object creation, after setting all properties.
function pm_sF_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pm_sF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cb_FFT.
function cb_FFT_Callback(hObject, eventdata, handles)
% hObject    handle to cb_FFT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_FFT


% --- Executes on button press in cb_motorEnable.
function cb_motorEnable_Callback(hObject, eventdata, handles)
% hObject    handle to cb_motorEnable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_motorEnable

    motorsEnable = get(handles.cb_motorEnable,'Value');
    
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
    fwrite(obj,'e','char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'e')
        fwrite(obj,motorsEnable,'char');
        replay = char(fread(obj,1,'char'));
        if strcmp(replay,'e');
            if(motorsEnable)
                set(handles.t_msg,'String','Motors enabled');
            else
                set(handles.t_msg,'String','Motors disabled');
            end
        else
            set(handles.t_msg,'String','Error Setting Motors enable'); 
            fclose(obj);
            return
        end
    else
        set(handles.t_msg,'String','Error Setting Motors enable'); 
        fclose(obj);
        return
    end
    
    fclose(obj);


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


% --- Executes on button press in pb_executeMov.
function pb_executeMov_Callback(hObject, eventdata, handles)
% hObject    handle to pb_executeMov (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    set(handles.pb_executeMov,'Enable','off');
    speed = str2double(get(handles.et_speedMov,'String'));
    time = str2double(get(handles.et_timeMov,'String'));
    mov = get(handles.pm_movement,'Value') - 1;
    
    if mov == 0
        errordlg('Select a movement!');
        return
    end

    % Get connection object
    if isfield(handles,'obj')
        obj = handles.obj;
    else
        set(handles.t_msg,'String','No connection obj found');   
%         return;
    end
    
    % Open connection
    if ~strcmp(obj.status,'open')
        fopen(obj);
    end   
    switch mov
        case 1
            SendMotorCommand(obj, 0, 'A', 1, speed);
            pause(time);
            SendMotorCommand(obj, 0, 'R', 1, 0);
        case 2   
            SendMotorCommand(obj, 0, 'A', 0, speed);
            pause(time);  
            SendMotorCommand(obj, 0, 'R', 1, 0);
        case 3 % SWITCH
            SendMotorCommand(obj, 0, 'S', 0, 0);  
            pause(time);  
    end
    % Close connection
    fclose(obj);
    
    %ActivateSP_FixedTime(obj,'B',speed,time);
    set(handles.pb_executeMov,'Enable','on');

function et_speedMov_Callback(hObject, eventdata, handles)
% hObject    handle to et_speedMov (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_speedMov as text
%        str2double(get(hObject,'String')) returns contents of et_speedMov as a double


% --- Executes during object creation, after setting all properties.
function et_speedMov_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_speedMov (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_timeMov_Callback(hObject, eventdata, handles)
% hObject    handle to et_timeMov (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_timeMov as text
%        str2double(get(hObject,'String')) returns contents of et_timeMov as a double


% --- Executes during object creation, after setting all properties.
function et_timeMov_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_timeMov (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_sensors.
function pb_sensors_Callback(hObject, eventdata, handles)
% hObject    handle to pb_sensors (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    if isfield(handles,'sensors')
        sensors = handles.sensors;
    else
        sensor_dir = uigetdir;
        sensors = InitSensors(sensor_dir);
        handles.sensors = sensors;
    end
    nrSensors = size(sensors,2);
    %GUI_Sensors(hObject, eventdata, handles);

    sT = str2double(get(handles.et_sT,'String'));
    tW = 0.5;
    sF = 10;
    tS = 1/sF;
     
    %Selected channels
    nrSensors = 3;
    nCh = nrSensors;    
    
    % Setting for data peeking
    tv = 0:1/sF:tW-1/sF;                                                   % Create vector of time
    tWs = tW*sF;                                                           % Time window samples
    sData = zeros(tWs,nCh);                                                % tWs sized matrix useful for real time plot
    allData = zeros(sT*sF, nCh);                                           % sT*sF sized matrix used for keep all datas
    
    plotGain = 10000000;
    
    % Offset the plot of the different channels to fit into the main figure
    ampPP     = 20000;
    offVector = 0:nCh-1;
    offVector = offVector .* ampPP;
    for i = 1 : nCh
        sData(:,i) = sData(:,i) + offVector(i);
    end    
    
    % Draw figure
    p_t0 = plot(handles.a_t0, tv, sData);
    xlim([0,tW]);
    set(handles.a_t0,'YTick',offVector);
    set(handles.a_t0,'YTickLabel',1:nCh);   

    % Get connection object
    if isfield(handles,'obj')
        obj = handles.obj;
    else
        set(handles.t_msg,'String','No connection obj found');   
        return;
    end
    
    % Open the connection
    fopen(obj);
    % Read available data and discard it
    if obj.BytesAvailable > 1
        fread(obj,obj.BytesAvailable,'uint8');    % Read the samples        
    end    

    sData = zeros(tWs, nCh);                                               % tWs sized vector used for offset and plot datas
    printFlag = 1; 
    
    tic;
    for i = 1:sT*sF  
        startTic = tic;
        fwrite(obj,'Y');
        data.Strain(i) = fread(obj, 1, 'char');
        data.Pad1(i) = fread(obj, 1, 'char');
        data.Pad2(i) = fread(obj, 1, 'char');
        data.Pad3(i) = fread(obj, 1, 'char');
        data.AccX(i) = fread(obj, 1, 'int32');    
        data.AccY(i) = fread(obj, 1, 'int32');    
        data.AccZ(i) = fread(obj, 1, 'int32');
        data.GyrX(i) = fread(obj, 1, 'int32');    
        data.GyrY(i) = fread(obj, 1, 'int32');    
        data.GyrZ(i) = fread(obj, 1, 'int32');
        data.Vbattery(i) = fread(obj,1,'float32'); 
        data.Temperature(i) = fread(obj,1,'float32');
%         allData(i) = data;
%         sData(printFlag,:) = data;
%         printFlag = printFlag + 1; 
%         if printFlag >= tWs+1 
%             % plot a new tWs sized window
%             for j = 1 : nCh
%                 set(p_t0(j),'YData',sData(:,j) + offVector(j));       % add offsets to plot channels in same graph
%             end 
%             printFlag = 1;
%             drawnow 
%         end 
        elapsedTime = toc(startTic);
        pause(tS-(toc(startTic)-elapsedTime))
        disp(toc(startTic)-elapsedTime)
    end
    toc;
    
%     tic;
%     for i = 1:sT*sF  
%         % Set warnings to temporarily issue error (exceptions)
%         s = warning('error', 'instrument:fread:unsuccessfulRead');
%         try
%             startTic = tic;
%             for n = 1:nrSensors
%                 id = cell2mat(sensors(n).id);
%                 fwrite(obj,'Y');
%                 fwrite(obj,id);
%                 reply = char(fread(obj,1,'char'));
%                 if strcmp(reply,id)
%                     switch char(sensors(n).name)
%                         case 'Strain'
%                             data.Strain = fread(obj, 1, 'char');
%                         case 'Pad1'
%                             data.Pad1 = fread(obj, 1, 'char');
%                         case 'Pad2'
%                             data.Pad2 = fread(obj, 1, 'char');
%                         case 'Pad3'
%                             data.Pad3 = fread(obj, 1, 'char');
%                         case 'AccX'
%                             data.AccX = fread(obj, 1, 'int16');    
%                         case 'AccY'
%                             data.AccY = fread(obj, 1, 'int16');    
%                         case 'AccZ'
%                             data.AccZ = fread(obj, 1, 'int16');
%                         case 'GyrX'
%                             data.GyrX = fread(obj, 1, 'int16');    
%                         case 'GyrY'
%                             data.GyrY = fread(obj, 1, 'int16');    
%                         case 'GyrZ'
%                             data.GyrZ = fread(obj, 1, 'int16');
%                         case 'Vbattery'
%                             data.Vbattery = fread(obj,1,'float32'); 
%                         case 'Temperature'
%                             data.Temperature = fread(obj,1,'float32');
%                     end
%                 else
%                 % set(handles.t_msg,'String','Error on A'); 
%                 end
%             end                       
%             elapsedTime = toc(startTic);
%             allData(i,:) = data;
%             sData(printFlag,:) = data;
%         catch exception
%            set(handles.t_msg,'String','Error in communication'); 
%            delete(obj);
%            return
%         end
%         %Set warning back to normal state
%         warning(s);
%         printFlag = printFlag + 1; 
%         if printFlag >= tWs+1 
%             % plot a new tWs sized window
%             for j = 1 : nCh
%                 set(p_t0(j),'YData',sData(:,j) + offVector(j));       % add offsets to plot channels in same graph
%             end 
%             printFlag = 1;
%             drawnow 
%         end 
%         pause(0.5-(toc(startTic)-elapsedTime))
%         disp(toc(startTic)-elapsedTime)
%     end
%     toc;
    
    % Close connection
    fclose(obj);
    disp(obj);
    
    % Print the data    
%     tv = 0:1/sF:sT-1/sF;                                                   % Create vector of time
%     for i = 1:sT*sF 
%         for k = 1:nCh        
%             sData(i,k) = allData(i,k)*plotGain + offVector(k);
%         end 
%     end
%     plot(tv, sData);
 
    set(handles.t_msg,'String','');
    save('sensorsData.mat','data');                                         % save all original datas
    guidata(hObject,handles);



function et_tPredict_Callback(hObject, eventdata, handles)
% hObject    handle to et_tPredict (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tPredict as text
%        str2double(get(hObject,'String')) returns contents of et_tPredict as a double


% --- Executes during object creation, after setting all properties.
function et_tPredict_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tPredict (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pm_control.
function pm_control_Callback(hObject, eventdata, handles)
% hObject    handle to pm_control (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pm_control contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pm_control

    menu = get(handles.pm_control,'string');
    menu = menu{get(handles.pm_control,'Value')};
    
    switch menu
        case 'select control algorithm'
            algorithm.mode = 0; % None
            set(handles.et_tPredict,'String',0.05);
        case 'Majority Vote'
            algorithm.mode = 1; % MV
            prompt = {'Majority-Vote Steps:'};
            def = {'3'};
            % Ask for parameters
            dlg_title = 'Post-Algorithm Parameters';
            num_lines = 1;
            answer = inputdlg(prompt,dlg_title,num_lines,def);
            if size(answer,1) == 0
                return
            end
            algorithm.param(1) = str2num(char(answer(1)));
            set(handles.et_tPredict,'String',0.05*algorithm.param(1));
        case 'Ramp'
            algorithm.mode = 2; % RAMP
            prompt = {'Ramp Length','Proportional?'};
            def = {'5','1'};
            % Ask for parameters
            dlg_title = 'Post-Algorithm Parameters';
            num_lines = 1;
            answer = inputdlg(prompt,dlg_title,num_lines,def);
            if size(answer,1) == 0
                return
            end
            algorithm.param(1) = str2num(char(answer(1)));  
            algorithm.param(2) = str2num(char(answer(2)));
            set(handles.et_tPredict,'String',0.05);
        case 'Delicate Grasp'
            algorithm.mode = 3; % DELICATE GRASP
            prompt = {'Enable','Threshold'};
            def = {'1','35'};
            % Ask for parameters
            dlg_title = 'Post-Algorithm Parameters';
            num_lines = 1;
            answer = inputdlg(prompt,dlg_title,num_lines,def);
            if size(answer,1) == 0
                return
            end
            algorithm.param(1) = str2num(char(answer(1)));  
            algorithm.param(2) = str2num(char(answer(2))); 
            set(handles.et_tPredict,'String',0.05);
        otherwise
            set(handles.t_msg,'String','Error, it is not a proper algorithm');
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

    % Set up the ADS1299 datarate output (and bandwidth)
    fwrite(obj,'a','char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'a')
        fwrite(obj,algorithm.mode,'char');
        if algorithm.mode ~= 0
            for i = 1:size(algorithm.param,2)
                fwrite(obj,algorithm.param(i),'char');
            end
        end
        replay = char(fread(obj,1,'char'));
        if strcmp(replay,'a');
            set(handles.t_msg,'String','control algorithm set');
        else
            set(handles.t_msg,'String','Error Setting Control Algorithm'); 
            fclose(obj);
            return
        end
    else
        set(handles.t_msg,'String','Error Setting Control Algorithm'); 
        fclose(obj);
        return
    end
    
    fclose(obj);


% --- Executes during object creation, after setting all properties.
function pm_control_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pm_control (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
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


function et_oW_Callback(hObject, eventdata, handles)
% hObject    handle to et_oW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_oW as text
%        str2double(get(hObject,'String')) returns contents of et_oW as a double


% --- Executes during object creation, after setting all properties.
function et_oW_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_oW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function menu_featuresParameters_Callback(hObject, eventdata, handles)
% hObject    handle to menu_featuresParameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 
    sF = get(handles.pm_sF,'string');
    sF = str2num(sF{get(handles.pm_sF,'Value')});
    tW = str2double(get(handles.et_tW,'String'));
    oW = str2double(get(handles.et_oW,'String'));
     
    % Get connection object
    if isfield(handles,'obj')
        obj = handles.obj;
    else
        set(handles.t_msg,'String','No connection obj found');   
        return;
    end

    % Open the connection
    fopen(obj);
    % Read available data and discard it
    if obj.BytesAvailable > 1
        fread(obj,obj.BytesAvailable,'uint8');    % Read the samples        
    end    
    
    % Set the parameters for features extraction
    tWs = sF*tW;
    oWs = sF*oW;
    FeaturesEnables(1) = get(handles.cb_mabs,'Value');
    FeaturesEnables(2) = get(handles.cb_wl,'Value');
    FeaturesEnables(3) = get(handles.cb_zc,'Value');
    FeaturesEnables(4) = get(handles.cb_slpch,'Value');
    FeaturesEnables(5) = get(handles.cb_std,'Value');
    SetFeaturesExtractionParametersALCD(handles, tWs, oWs, FeaturesEnables);
    
    % Close connection
    fclose(obj);


% --------------------------------------------------------------------
function menu_checkStatus_Callback(hObject, eventdata, handles)
% hObject    handle to menu_checkStatus (see GCBO)
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

    % ask for status
    fwrite(obj,hex2dec('21'),'char');
    replay = fread(obj,1,'char');
    if replay == hex2dec('21')
        battery = fread(obj,1,'float32');
        temperature = fread(obj,1,'float32');
        sensorHand = fread(obj,1,'char');
        if(sensorHand)
            SH = 'present';
        else
            SH = 'not present';
        end
        enableNS1 = fread(obj,1,'char');
        if(enableNS1)
            enableSH = 'enabled';
        else
            enableSH = 'not enabled';
        end
        sdCard = fread(obj,1,'char');
        if(sdCard)
            SD = 'present';
        else
            SD = 'not present';
        end
        iNEMO = fread(obj,1,'char');
        if(iNEMO)
            IMU = 'present';
        else
            IMU = 'not present';
        end
        enableMotor = fread(obj,1,'char');
        if(enableMotor)
            enableM = 'enabled';
        else
            enableM = 'not enabled';
        end
        enableFilter = fread(obj,1,'char');
        if(enableFilter)
            enableF = 'enabled';
        else
            enableF = 'not enabled';
        end
        controlAlgorithm = fread(obj,1,'char');
        switch(controlAlgorithm)
            case 0
                PC = 'none';
            case 1
                PC = 'Majority Vote';
            case 2
                PC = 'Ramp';
            otherwise
                PC = 'not recognized';
        end
        controlMode = fread(obj,1,'char');
        switch(controlMode)
            case 0
                CM = 'Direct Control';
            case 1
                CM = 'Linear Discriminant Analysis';
            case 2
                CM = 'Support Vector Machine';
            otherwise
                CM = 'not recognized';
        end
        tWs = fread(obj,1,'uint32');
        oWs = fread(obj,1,'uint32');
        sF = fread(obj,1,'uint32');
        nChannels = fread(obj,1,'char');
        nFeatures = fread(obj,1,'char');
        rampLength = fread(obj,1,'char');
        rampMode = fread(obj,1,'char');
        mvSteps = fread(obj,1,'char');
        delicateGrasp = fread(obj,1,'char');
        delicateGraspThreshold = fread(obj,1,'char');
        
        replay = char(fread(obj,1,'char'));
        if replay == hex2dec('21')
            status = sprintf('Battery Voltage = %2.3g V\nCPU Temperature = %2.3g °C\nSensor-Hand = %s\nNeurostimulator = %s\nSD-card = %s\niNEMO = %s\nMotors = %s\nFilters = %s\nPost-Control-Algorithm = %s\nControl Algorithm = %s\ntime window samples = %d\noverlapp window samples = %d\nsampling frequency = %d Hz\nnumber of channels = %d\nnumber of features = %d\nramp length = %d\nramp mode = %d\nmajority vote steps = %d\ndelicate grasp = %d\ndelicate grasp threshold = %d', battery, temperature, SH, enableSH, SD, IMU, enableM, enableF, PC, CM, tWs, oWs, sF, nChannels, nFeatures, rampLength, rampMode, mvSteps, delicateGrasp, delicateGraspThreshold);
            msgbox(status,'System Status')
        else
            set(handles.t_msg,'String','Error, device is not responding or COM port is changed!'); 
            fclose(obj);
            return
        end
    else
        set(handles.t_msg,'String','Error, device is not responding or COM port is changed!');        
    end
    
    fclose(obj);


% --------------------------------------------------------------------
function menu_NS_Callback(hObject, eventdata, handles)
% hObject    handle to menu_NS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_NSsetup_Callback(hObject, eventdata, handles)
% hObject    handle to menu_NSsetup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % Open Fig and load information   
    guidata(hObject,handles);
    GUI_TestNS1(handles);


% --------------------------------------------------------------------
function menu_setDC_Callback(hObject, eventdata, handles)
% hObject    handle to menu_setDC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % Open Fig and load information   
    guidata(hObject,handles);
    GUI_ControlSettings_List(handles);


% --------------------------------------------------------------------
function menu_EF_Callback(hObject, eventdata, handles)
% hObject    handle to menu_EF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_accFunction_Callback(hObject, eventdata, handles)
% hObject    handle to menu_accFunction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % Ask for parameters
    dlg_title = 'Accelerometer Function';
    prompt = {'Enable?','Threshold'};
    def = {'1','6'};
    num_lines = 1;
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    if size(answer,1) == 0
        return
    end
    enable = str2num(char(answer(1)));  
    threshold = str2num(char(answer(2)));

    % Get connection object
    if isfield(handles,'obj')
        obj = handles.obj;
    else
        set(handles.t_msg,'String','No connection obj found');   
        return;
    end
    % Open the connection
    fopen(obj);
    
    % Set the accelerometer function
    fwrite(obj,'b','char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'b')
        fwrite(obj,enable,'char');
        if enable 
            fwrite(obj,threshold,'char');
        end
        replay = char(fread(obj,1,'char'));
        if strcmp(replay,'b');
            if(enable)
                set(handles.t_msg,'String','Accelerometer function enable');
            else
                set(handles.t_msg,'String','Accelerometer function disabled');
            end
        else
            set(handles.t_msg,'String','Error Setting accelerometer function'); 
            fclose(obj);
            return
        end
    else
        set(handles.t_msg,'String','Error Setting accelerometer function'); 
        fclose(obj);
        return
    end
    fclose(obj);


% --------------------------------------------------------------------
function menu_updatePRtable_Callback(hObject, eventdata, handles)
% hObject    handle to menu_updatePRtable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % Ask for windowing parameters
    dlg_title = 'Windows size';
    prompt = {'window size [s]','increment [s]'};
    def = {'0.2','0.05'};
    num_lines = 1;
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    if size(answer,1) == 0
        return
    end
    tW = str2num(char(answer(1)));  
    iW = str2num(char(answer(2)));

    % Load recSession and calculate table
    [file, path] = uigetfile({'*.mat';'*.csv'});
    % Check that the loaded file is a "ss" struct
    if ~isequal(file, 0)
        [pathstr,name,ext] = fileparts(file);
        if(strcmp(ext,'.mat'))
            load([path,file]);
%             if (exist('recSession','var') && isfield(recSession,'ramp'))
            if exist('recSession','var')
            else
                disp('That was not a valid recording session');
                errordlg('That was not a valid recording session','Error');
                return;
            end
        end
    end
    % create table
    set(handles.t_msg,'String','Calculating the proportional table...');
    propTable = CreatePRtable_ALCD(tW, iW, recSession);
    nCh = recSession.nCh;
    nM = recSession.nM+1;
    nameMovs = recSession.mov;
    nameMovs{nM} = 'rest';
    barh(propTable);
    legend(nameMovs);
    axis([0 max(max(propTable)) 0 nCh+1]);
    % Create GUI-window
    set(handles.t_msg,'String','Setup movements and prosthetic outputs...');
    figureH = figure;
    % Set up Vars used by GUI-code
    movValBoxes = zeros(1,nM);
    % Set up position and sizes for the different GUI-fields
    xPosNameBox = 20;
    yPosNameBox = 70;
    xSizeNameBox = 150;
    ySizeNameBox = 20;
    xPosValBox = xPosNameBox + xSizeNameBox + 10;
    yPosValBox = yPosNameBox;
    xSizeValBox = 150;
    ySizeValBox = ySizeNameBox;
    % Create UI objects for the prosthetic outputs
    for i = 1:nM
        % Create UI-name boxes from the parameters
        uicontrol('Style', 'text', 'String', nameMovs{nM-i+1},...
            'Position', [xPosNameBox yPosNameBox+(i-1)*ySizeNameBox, ...
            xSizeNameBox ySizeNameBox]);
        % Save value of the parameters
        if i == 1
            parameterValue = 0;
        else
            parameterValue = nM-i+1;
        end
        % Create UI-value boxes from the parameters
        movValBoxes(i) = uicontrol('Style', 'edit', 'String', parameterValue,...
            'Position', [xPosValBox yPosValBox+(i-1)*ySizeValBox, ...
            xSizeValBox ySizeValBox],...
            'Tag',nameMovs{nM-i+1});    
    end
    % Create a UI-title
    title = uicontrol('Style', 'text', 'String', ['Associate PR classes to prosthetic outputs'],...
        'Position', [(xPosNameBox+xPosValBox)/2 yPosNameBox+(i+1)*ySizeNameBox, ...
        250 65], ...
        'Tag', 'Title');
    % Set title fontsize
    set(title,'FontSize',15);
    % Create OK-button
    uicontrol('Style', 'pushbutton', 'String', 'Confirm',...
        'Position', [xPosValBox+xSizeValBox+20 yPosValBox 50 40], ...
        'Callback', {@UpdatePRtable,hObject,movValBoxes,propTable, nM, nCh});
    % Resize the GUI-window
    figurePos = get(figureH,'Position');
    figurePos(3:4) = [xSizeNameBox+xSizeValBox+50+2*xPosNameBox+20,...
        yPosNameBox+50+yPosNameBox+(i+1)*ySizeNameBox];
    set(figureH,'Position',figurePos,'MenuBar','none');
    

function UpdatePRtable(hObj, event, inObj, movValBoxes, propTable, nM, nCh)

    for i = 1:size(movValBoxes,2)
        prostheticOutputs(i) = str2double(get(movValBoxes(i),'String'));
    end
    prostheticOutputs = fliplr(prostheticOutputs);

    handles = guidata(inObj);
    % Get connection object
    if isfield(handles,'obj')
        obj = handles.obj;
    else
        set(handles.t_msg,'String','No connection obj found');   
        close(clf);
        return;
    end
    % Open the connection
    fopen(obj);
    % Start to send coeff float values
    fwrite(obj,'v','char');
    fwrite(obj,nM,'char');
    fwrite(obj,nCh,'char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'v')
        set(handles.t_msg,'String','Upload Start');
    else
        set(handles.t_msg,'String','Error Start');
        fclose(obj);
        return
    end
    % send table to the ALC-D
    tic;
    for i = 1:nM
        fwrite(obj,prostheticOutputs(i),'char');
    end
    for i = 1:nM-1
        for k = 1:nCh
            fwrite(obj,propTable(k,i),'float');
        end
    end
    toc;
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'v');
        set(handles.t_msg,'String','Upload completed');
    else
        set(handles.t_msg,'String','Error uploading');
        fclose(obj);
        return
    end
    fclose(obj);
    guidata(inObj, handles);
    close(clf);


% --------------------------------------------------------------------
function menu_downloadPRtable_Callback(hObject, eventdata, handles)
% hObject    handle to menu_downloadPRtable (see GCBO)
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

    % Ask for the PR table
    fwrite(obj,'V','char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'V')       
        nM = fread(obj,1,'uint8');
        nCh = fread(obj,1,'uint8');
        for i = 1:nM
            PRtable.prostheticOut(i) = fread(obj,1,'uint8');
        end
        for i = 1:nM-1
            for k = 1:nCh
                PRtable.channelsMVC(k,i) = fread(obj,1,'float32');
            end
        end
        replay = char(fread(obj,1,'char'));
        if strcmp(replay,'V')
            disp(obj)
            save('PRTABLE.mat','PRtable');  
            set(handles.t_msg,'String','PR-Table saved in PRTABLE.mat file');
        else
            set(handles.t_msg,'String','Error Reading PR-Table'); 
            fclose(obj);
            return
        end
    else
        set(handles.t_msg,'String','Error Reading PR-Table'); 
        fclose(obj);
        return
    end

    fclose(obj);


% --------------------------------------------------------------------
function loadFile_pb_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to loadFile_pb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    [file, path] = uigetfile({'*.mat';'*.csv'});
    if ~isequal(file, 0)
        [pathstr,name,ext] = fileparts(file);
        if(strcmp(ext,'.mat'))
            load([path,file]);
            if(exist('recSession','var')) 
                set(handles.t_msg,'String','Selected file is a recSession! Please use BioPatRec instead to load it.');
                return
            elseif(exist('allData','var'))
                nCh = size(allData,2);
            else
                set(handles.t_msg,'String','File not valid!');
            end
        end
    end

    sF = get(handles.pm_sF,'string');
    sF = str2num(sF{get(handles.pm_sF,'Value')});
    sT = length(allData)/sF;
    tv = 0:1/sF:sT-1/sF;
    
    % Offset the plot of the different channels to fit into the main figure
    ampPP     = 5;
    plotGain = ampPP/(2*(max(max(abs(allData)))));
    offVector = 0:nCh-1;
    offVector = offVector .* ampPP;
    
    % Print the data    
    for i = 1:sT*sF 
        for k = 1:nCh        
            sData(i,k) = allData(i,k)*plotGain + offVector(k);
        end 
    end
    plot(tv, sData);
    set(handles.a_t0,'YTick',offVector);
    set(handles.a_t0,'YTickLabel',1:nCh); 
    
    if get(handles.cb_FFT,'Value');
        % Plot FFT of acquired signals
        nS = length(sData(:,1));     
        nS = 2^nextpow2(nS);               % Find next power of 2
        X = fft(sData,nS);
        spectra2side = abs(X/nS);          % 2-side Magnitude Spectrum
        %phi = angle(X);                   % Phase (radians)
        %S = (X .^ 2);                     % Power Density Spectrum
        % 1-side Magnitude Spectrum
        spectra1side = spectra2side(1:nS/2+1,:);
        spectra1side(2:end-1) = 2*spectra1side(2:end-1);                                     
        % Offset and scale the data
        offVector = 0:nCh-1;
        for j = 1 : nCh
            fData(:,j) = spectra1side(:,j) + offVector(j);
        end
        % plot
        figure(1)
        f = sF*(0:(nS/2))/nS;
        a_f0 = plot(f,fData);
        title('Single-Sided Amplitude Spectrum')
        xlabel('f (Hz)')
        ylabel('|A(f)|')
        %set(a_f0,'YTick',offVector);
        %set(a_f0,'YTickLabel',0:nCh-1);
        %xlim(a_f0, [0,sF/2]);
    end
    
    set(handles.t_msg,'String','Recording Loaded');


% --------------------------------------------------------------------
function menu_IH2_Callback(hObject, eventdata, handles)
% hObject    handle to menu_IH2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_firstCalibration_Callback(hObject, eventdata, handles)
% hObject    handle to menu_firstCalibration (see GCBO)
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
    fwrite(obj,hex2dec('C1'),'char');
    replay = char(fread(obj,1,'char'));
    if replay == hex2dec('C1')
        replay = char(fread(obj,1,'char'));
        if replay == hex2dec('C1')
            set(handles.t_msg,'String','IH2 First Calibration');
        else
            set(handles.t_msg,'String','Error'); 
            fclose(obj);
            return
        end
    else
        set(handles.t_msg,'String','Error'); 
        fclose(obj);
        return
    end
    fclose(obj);

% --------------------------------------------------------------------
function menu_fastCalibration_Callback(hObject, eventdata, handles)
% hObject    handle to menu_fastCalibration (see GCBO)
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
    fwrite(obj,hex2dec('C2'),'char');
    replay = char(fread(obj,1,'char'));
    if replay == hex2dec('C2')
        replay = char(fread(obj,1,'char'));
        if replay == hex2dec('C2')
            set(handles.t_msg,'String','IH2 Fast Calibration');
        else
            set(handles.t_msg,'String','Error'); 
            fclose(obj);
            return
        end
    else
        set(handles.t_msg,'String','Error'); 
        fclose(obj);
        return
    end
    fclose(obj);

% --------------------------------------------------------------------
function menu_streamingMode_Callback(hObject, eventdata, handles)
% hObject    handle to menu_streamingMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    % Get connection object
    if isfield(handles,'obj')
        obj = handles.obj;
    else
        set(handles.t_msg,'String','No connection obj found');   
        return;
    end 
    % take the mode as input from user
    mode = menu('Choose a streaming mode for sensors','CURRENT_AND_POSITION','CURRENT','POSITION','EXTERNAL_SENSORS','TENDON_TENSION','TENDON_TENSION_AND_POSITION','POSITION_AND_EXTERNAL_SENSORS');
    % Open the connection
    fopen(obj);
    fwrite(obj,hex2dec('C3'),'char');
    fwrite(obj,mode,'char');
    replay = char(fread(obj,1,'char'));
    if replay == hex2dec('C3')
        replay = char(fread(obj,1,'char'));
        if replay == hex2dec('C3')
            set(handles.t_msg,'String','IH2 Streaming Mode Set');
        else
            set(handles.t_msg,'String','Error'); 
            fclose(obj);
            return
        end
    else
        set(handles.t_msg,'String','Error'); 
        fclose(obj);
        return
    end
    fclose(obj);

% --------------------------------------------------------------------
function menu_setGrasp_Callback(hObject, eventdata, handles)
% hObject    handle to menu_setGrasp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    % Get connection object
    if isfield(handles,'obj')
        obj = handles.obj;
    else
        set(handles.t_msg,'String','No connection obj found');   
        return;
    end
    % take the grasp/force/duration as input from user
    grasp = menu('Choose a predefined grasp','LATERAL_GRASP','BIDIGIT_GRASP','TRIDIGIT_GRASP','CYLINDRICAL_GRASP','RELAX','THREE_GRASP','PISTOL_GRASP','THUMB_UP_GRASP','TRIDIG_LASTDIG_EXT_GRASP','BIDIG_LASTDIG_EXT_GRASP','BUFFET_GRASP');
    if grasp == 5
        grasp = 0; % RELAX was pressed
    elseif grasp == 9
        grasp = 31; % TRIDIG_LASTDIG_EXT_GRASP was pressed
    elseif grasp == 10
        grasp = 21; % BIDIG_LASTDIG_EXT_GRASP was pressed
    elseif grasp == 11
        grasp = 11; % BUFFET_GRASP was pressed
    end
    prompt = {'Force of the grasp:','Duration of the grasp:'};
    dlg_title = 'Choose parameters for the predefined grasp';
    num_lines = 1;
    def = {'50','30'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    force = str2num(char(answer(1)));
    duration = str2num(char(answer(2)));
    % Open the connection
    fopen(obj);
    fwrite(obj,hex2dec('C4'),'char');
    fwrite(obj,grasp,'char');
    fwrite(obj,force,'char');
    fwrite(obj,duration,'char');
    replay = char(fread(obj,1,'char'));
    if replay == hex2dec('C4')
        replay = char(fread(obj,1,'char'));
        if replay == hex2dec('C4')
            set(handles.t_msg,'String','IH2 Grasp Set');
        else
            set(handles.t_msg,'String','Error'); 
            fclose(obj);
            return
        end
    else
        set(handles.t_msg,'String','Error'); 
        fclose(obj);
        return
    end
    fclose(obj);


% --------------------------------------------------------------------
function menu_setPosture_Callback(hObject, eventdata, handles)
% hObject    handle to menu_setPosture (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    % Get connection object
    if isfield(handles,'obj')
        obj = handles.obj;
    else
        set(handles.t_msg,'String','No connection obj found');   
        return;
    end
    % take the positions as input from user
    prompt = {'Position 0','Position 1','Position 2','Position 3','Position 4'};
    dlg_title = 'Insert the position for each motor';
    num_lines = 1;
    def = {'0','0','0','0','0'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    p0 = str2num(char(answer(1)));
    p1 = str2num(char(answer(2)));
    p2 = str2num(char(answer(3)));
    p3 = str2num(char(answer(4)));
    p4 = str2num(char(answer(5)));
    % Open the connection
    fopen(obj);
    fwrite(obj,hex2dec('C5'),'char');
    fwrite(obj,p0,'char');
    fwrite(obj,p1,'char');
    fwrite(obj,p2,'char');
    fwrite(obj,p3,'char');
    fwrite(obj,p4,'char');
    replay = char(fread(obj,1,'char'));
    if replay == hex2dec('C5')
        replay = char(fread(obj,1,'char'));
        if replay == hex2dec('C5')
            set(handles.t_msg,'String','IH2 Posture Set');
        else
            set(handles.t_msg,'String','Error'); 
            fclose(obj);
            return
        end
    else
        set(handles.t_msg,'String','Error'); 
        fclose(obj);
        return
    end
    fclose(obj);

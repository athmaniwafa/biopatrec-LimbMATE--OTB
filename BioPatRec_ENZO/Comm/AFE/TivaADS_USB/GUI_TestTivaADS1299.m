function varargout = GUI_TestTivaADS1299(varargin)
% GUI_TESTTIVAADS1299 MATLAB code for GUI_TestTivaADS1299.fig
%      GUI_TESTTIVAADS1299, by itself, creates a new GUI_TESTTIVAADS1299 or raises the existing
%      singleton*.
%
%      H = GUI_TESTTIVAADS1299 returns the handle to a new GUI_TESTTIVAADS1299 or the handle to
%      the existing singleton*.
%
%      GUI_TESTTIVAADS1299('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI_TESTTIVAADS1299.M with the given input arguments.
%
%      GUI_TESTTIVAADS1299('Property','Value',...) creates a new GUI_TESTTIVAADS1299 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI_TestTivaADS1299_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI_TestTivaADS1299_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUI_TestTivaADS1299

% Last Modified by GUIDE v2.5 30-Oct-2014 10:20:08

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_TestTivaADS1299_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_TestTivaADS1299_OutputFcn, ...
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


% --- Executes just before GUI_TestTivaADS1299 is made visible.
function GUI_TestTivaADS1299_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI_TestTivaADS1299 (see VARARGIN)

% Choose default command line output for GUI_TestTivaADS1299
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GUI_TestTivaADS1299 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GUI_TestTivaADS1299_OutputFcn(hObject, eventdata, handles) 
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
     RTfilterEnable = get(handles.FiltCheckBox,'Value');
     tW = str2double(get(handles.et_tW,'String'));
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
     LSBweight = double(4.5/(8388607));
     
     %Selected channels
     allCh = str2double(get(handles.lb_ch,'String'));
     vCh = allCh(get(handles.lb_ch,'Value')); % Vector of channels
     nCh = size(vCh,1);    
     
     %ampPP = 65535/(2^A);
     ampPP = 0.0005;
     
     if RTfilterEnable == 1
         NZEROS = 2;
         NPOLES = 2;
         GAIN   = 1.045431062e+00;
         xv = zeros(NZEROS+1, nCh);
         yv = zeros(NPOLES+1, nCh);
         GAIN_N = 1.015709255e+00;
         xv_N = zeros(NZEROS+1, nCh);
         yv_N = zeros(NPOLES+1, nCh);
     end
    
    
    % Setting for data peeking
    tv = 0:1/sF:tW-1/sF;                                                   % Create vector of time
    tWs = tW*sF;                                                           % Time window samples
    sData = zeros(tWs,nCh);                                                % tWs sized matrix useful for real time plot
    allData = zeros(sT*sF, nCh);                                           % sT*sF sized matrix used for keep all datas
    
    % Offset the data
    offVector = 0:nCh-1;
    offVector = offVector .* ampPP;
    for i = 1 : nCh
        sData(:,i) = sData(:,i) + offVector(i);
    end    
    
    % Draw figure
    p_t0 = plot(handles.a_t0, tv, sData);
    xlim([0,tW]);
%     ylim([-ampPP/2,(ampPP*nCh)-ampPP/2]);
    set(handles.a_t0,'YTick',offVector);
    set(handles.a_t0,'YTickLabel',0:nCh-1);   

    % Get connection object
    if isfield(handles,'obj')
        obj = handles.obj;
    else
        set(handles.t_msg,'String','No connection obj found');   
        return;
    end
    
    % Set up receiving buffer
%     obj.InputBufferSize = sT*sF*27;
%      obj.InputBufferSize = sT*sF*27*2;
    obj.InputBufferSize = sT*sF*32;
    
    % Open the connection
    fopen(obj);
    % Read available data and discard it
    if obj.BytesAvailable > 1
        fread(obj,obj.BytesAvailable,'uint8');    % Read the samples        
    end    
    disp(obj); 

%     % Set up the ADS1299 gain
%     fwrite(obj,'K','char');
%     replay = char(fread(obj,1,'char'));
%     if strcmp(replay,'K')
%         fwrite(obj,A,'char');
%         replay = char(fread(obj,1,'char'));
%         if strcmp(replay,'O');
%             set(handles.t_msg,'String','Gain set');
%         else
%             set(handles.t_msg,'String','Error Setting Gain'); 
%             fclose(obj);
%             return
%         end
%     else
%         set(handles.t_msg,'String','Error Setting Gain'); 
%         fclose(obj);
%         return
%     end
% 
%     % Set up the ADS1299 datarate output (and bandwidth)
%     fwrite(obj,'F','char');
%     replay = char(fread(obj,1,'char'));
%     if strcmp(replay,'F')
%         fwrite(obj,mode,'char');
%         replay = char(fread(obj,1,'char'));
%         if strcmp(replay,'O');
%             set(handles.t_msg,'String','DataRate set');
%         else
%             set(handles.t_msg,'String','Error Setting Mode'); 
%             fclose(obj);
%             return
%         end
%     else
%         set(handles.t_msg,'String','Error Setting Mode'); 
%         fclose(obj);
%         return
%     end
    
    sData = zeros(tWs, nCh);                                               % tWs sized vector used for offset and plot datas
    printFlag = 1; 

    % Start the acquisition
    fwrite(obj,'G','char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'G')
        set(handles.t_msg,'String','Start');
    else
        set(handles.t_msg,'String','Error Start'); 
        fclose(obj);
        return
    end
    
%     % Sync Procedure (looking for C0h header byte)
%     header = char(fread(obj,1,'char'));                                    % Read the 2nd byte status header
%     while ~strcmp(header,char(192))
%         header = char(fread(obj,1,'char'));                                % Read the 3rd byte status header
%     end 
%     fread(obj,26,'char');                                                  % throw away this sample
    
    tic;
    
    for i = 1:sT*sF
        
        byteData = fread(obj,8,'float32');
        
        % CAR filter
%         byteData = byteData - mean(byteData);
        
        allData(i,:) = byteData(1:nCh,:)';
        sData(printFlag,:) = byteData(1:nCh,:)';
        
%         for k = 1:nCh 
%             allData(i,k) = byteData(k);
%             sData(printFlag,k) = byteData(k);
%         end
        
        if RTfilterEnable == 1
            % Real Time Filter 
            % Butterworth HP @ 20Hz
            xv(1,k) = xv(2,k); 
            xv(2,k) = xv(3,k); 
            xv(3,k) = byteData(k) / GAIN;
            yv(1,k) = yv(2,k); 
            yv(2,k) = yv(3,k); 
            yv(3,k) = (xv(1,k)+ xv(3,k)) - 2*xv(2,k) + ( -0.9149758348*yv(1,k)) + (  1.9111970674*yv(2,k));
            value(k) = yv(3,k);
            % Butterworth NOTCH @ 50Hz     
            xv_N(1,k) = xv_N(2,k); 
            xv_N(2,k) = xv_N(3,k); 
            xv_N(3,k) = value(k) / GAIN_N;
            yv_N(1,k) = yv_N(2,k); 
            yv_N(2,k) = yv_N(3,k); 
            yv_N(3,k) = (xv_N(1,k) + xv_N(3,k)) - 1.9756204086*xv_N(2,k) + ( -0.9690674172*yv_N(1,k)) + (  1.9450648876*yv_N(2,k));
            value(k) = yv_N(3,k);
            RTxf(i,k) = value(k);
            sData(printFlag,k) = value(k);
        end 
        
        
        
%         % Acquire 27 bytes packet from Tiva (and from ADS1299)
%         % 3 status bytes + 3 byte (24bit) for each channel
%         byteData = fread(obj,27,'char'); 
% %       byteData = byteData(4:end);                                        % throw away status bytes from vector
%         value = [65536 256 1]*reshape(byteData(4:end), 3, 8);              % all channels data are now avalaible on value vector
%         
%         for k = 1:nCh 
%             if value(k) > 8388607                                          % the data must be converted from 2's complement
%                 value(k) = value(k) - 2^24;
%             end
%             
%             allData(i,k) = value(k) * LSBweight;
%             
%             if RTfilterEnable == 1
%                 % Real Time Filter 
%                 % Butterworth HP @ 20Hz
%                 xv(1,k) = xv(2,k); 
%                 xv(2,k) = xv(3,k); 
%                 xv(3,k) = value(k) / GAIN;
%                 yv(1,k) = yv(2,k); 
%                 yv(2,k) = yv(3,k); 
%                 yv(3,k) = (xv(1,k)+ xv(3,k)) - 2*xv(2,k) + ( -0.9149758348*yv(1,k)) + (  1.9111970674*yv(2,k));
%                 value(k) = yv(3,k);
%                 % Butterworth NOTCH @ 50Hz     
%                 xv_N(1,k) = xv_N(2,k); 
%                 xv_N(2,k) = xv_N(3,k); 
%                 xv_N(3,k) = value(k) / GAIN_N;
%                 yv_N(1,k) = yv_N(2,k); 
%                 yv_N(2,k) = yv_N(3,k); 
%                 yv_N(3,k) = (xv_N(1,k) + xv_N(3,k)) - 1.9756204086*xv_N(2,k) + ( -0.9690674172*yv_N(1,k)) + (  1.9450648876*yv_N(2,k));
%                 value(k) = yv_N(3,k);
%                 RTxf(i,k) = value(k) * LSBweight;
%             end 
%             
%             sData(printFlag,k) = value(k) * LSBweight;
%        
%         end      

        printFlag = printFlag + 1; 
        if printFlag >= tWs+1                                              % plot a new tWs sized window
            for j = 1 : nCh
                set(p_t0(j),'YData',sData(:,j)+ offVector(j));             % add offsets to plot channels in same graph
            end
            printFlag = 1;      
            drawnow;
        end
    end
    
    toc;
    
    % Stop the aquisition
    fwrite(obj,'G','char');
    
    % Close connection
    fclose(obj);
    
    disp(obj);
    
    % POST Filtering (if requested)
    % High Pass @ 20Hz
    Fcutoff = 20;
    Wn = 2*Fcutoff/sF;
    order = 1;
    [b, a] = butter(order, Wn, 'high');
    POSTxf = filtfilt(b, a, allData);
    % Notch @ 50 Hz
    Fnotch = 50;
    Q = 5;
    Wo = Fnotch/(sF/2);  
    bw = Wo/Q;
    [d, c] = iirnotch(Wo,bw);
    POSTxf = filtfilt(d, c, POSTxf);
    
    % Print the data    
    tv = 0:1/sF:sT-1/sF;                                                   % Create vector of time
    for i = 1:sT*sF 
        for k = 1:nCh
            if RTfilterEnable == 1
                sData(i,k) = RTxf(i,k) + offVector(k);
            else
                sData(i,k) = allData(i,k) + offVector(k);
            end
        end 
    end
    plot(tv, sData);

    % Update for all data
    %ylim([-ampPP/2,(ampPP*nCh)-ampPP/2]);
    set(handles.a_t0,'YTick',offVector);
    set(handles.a_t0,'YTickLabel',1:nCh);
    
    set(handles.t_msg,'String','');
   
    save('allData.mat','allData');                                         % save all original datas
    save('byteData.mat','byteData');                                       % to check the sync: the first 3 bytes must be 0x(C0 00 00)
    if RTfilterEnable == 1
        save('filtData.mat','POSTxf','RTxf');                              % save Real Time and Post filtered datas
    else
        save('filtData.mat','POSTxf');                                     % save only Post filtered datas
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


% --- Executes on button press in pb_connect.
function pb_connect_Callback(hObject, eventdata, handles)
% hObject    handle to pb_connect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % Close and delete availale
%    if instrfind('Type','tcpip')
%        close(instrfind('Type','tcpip'))
%    end
%    delete(instrfind('Type','tcpip'))

    set(handles.t_msg,'String','Testing connection...');   
    if isfield(handles,'obj')
        obj = handles.obj;
        disp(obj);
        fclose(obj);
    else
       % obj = tcpip('192.168.100.10',65100,'NetworkRole','client');
         obj = serial ('COM3', 'baudrate', 2000000, 'databits', 8, 'byteorder', 'bigEndian');
    end
    % Open connection
    fclose(obj);
    fopen(obj);
    fwrite(obj,'A','char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'A')
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

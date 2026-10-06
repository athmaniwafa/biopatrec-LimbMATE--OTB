function varargout = GUI_TestStellarisWiicomIntan(varargin)
% GUI_TESTSTELLARISWIICOMINTAN MATLAB code for GUI_TestStellarisWiicomIntan.fig
%      GUI_TESTSTELLARISWIICOMINTAN, by itself, creates a new GUI_TESTSTELLARISWIICOMINTAN or raises the existing
%      singleton*.
%
%      H = GUI_TESTSTELLARISWIICOMINTAN returns the handle to a new GUI_TESTSTELLARISWIICOMINTAN or the handle to
%      the existing singleton*.
%
%      GUI_TESTSTELLARISWIICOMINTAN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI_TESTSTELLARISWIICOMINTAN.M with the given input arguments.
%
%      GUI_TESTSTELLARISWIICOMINTAN('Property','Value',...) creates a new GUI_TESTSTELLARISWIICOMINTAN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI_TestStellarisWiicomIntan_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI_TestStellarisWiicomIntan_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUI_TestStellarisWiicomIntan

% Last Modified by GUIDE v2.5 19-Aug-2013 13:30:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_TestStellarisWiicomIntan_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_TestStellarisWiicomIntan_OutputFcn, ...
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


% --- Executes just before GUI_TestStellarisWiicomIntan is made visible.
function GUI_TestStellarisWiicomIntan_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI_TestStellarisWiicomIntan (see VARARGIN)

% Choose default command line output for GUI_TestStellarisWiicomIntan
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GUI_TestStellarisWiicomIntan wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GUI_TestStellarisWiicomIntan_OutputFcn(hObject, eventdata, handles) 
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
    sF = str2double(get(handles.et_sF,'String'));
    tW = str2double(get(handles.et_tW,'String'));
    %ampPP = 65535;  % = FFFF Hex
    A = str2double(get(handles.et_Ampp,'String'));
    ampPP = 65535/(2^A);
    
    %Selected channels
    allCh = str2double(get(handles.lb_ch,'String'));
    
    vCh = allCh(get(handles.lb_ch,'Value')); % Vector of channels
    nCh = size(vCh,1);
        
    % Setting for data peeking
    tv = 0:1/sF:tW-1/sF;    % Create vector of time
    tWs = tW*sF;            % Time window samples
    cData = zeros(tWs,nCh); % Current data
    allData = [];
    
    % Offset the data
    offVector = 0:nCh-1;
    offVector = offVector .* ampPP;
    sData = cData;
    for i = 1 : nCh
        sData(:,i) = cData(:,i) + offVector(i);
    end    
    
    % Draw figure
    p_t0 = plot(handles.a_t0, tv, sData);
    xlim([0,tW]);
    ylim([-ampPP/2,(ampPP*nCh)-ampPP/2]);
    set(handles.a_t0,'YTick',offVector);
    set(handles.a_t0,'YTickLabel',0:nCh-1);    
    
    % Create indices vectors
    for i = 1:nCh
        chIdx(:,i) = i:nCh:tWs*nCh;
    end

    % Get connection object
    if isfield(handles,'obj')
        % obj = tcpip('192.168.100.10',65100,'NetworkRole','client');
        obj = handles.obj;
    else
        set(handles.t_msg,'String','No connection obj found');   
        return;
    end
    
    % Set up recieving buffer
    obj.InputBufferSize = tWs*2*nCh;
    
    % Open the connection
    fopen(obj);
    % Read available data and discard it
    if obj.BytesAvailable > 1
        fread(obj,obj.BytesAvailable,'uint16');    % Read the samples        
    end    
    disp(obj);

    % Setup the selected channels
    fwrite(obj,'C','char');
    fwrite(obj,nCh,'uint8');
    for i = 1 : nCh    
      fwrite(obj,vCh(i),'uint8');
    end     
    replay = char(fread(obj,1,'char'));
    if ~strcmp(replay,'O')
        set(handles.t_msg,'String','Error setting the vector of channels'); 
        fclose(obj);        
        return
    else    
        set(handles.t_msg,'String','Channel vector set'); 
    end    
    
    % Set up frequency in the microcontroller    
    fwrite(obj,'F','char');
%    rSF = sF * nCh;
%    fwrite(obj,rSF/100,'uint8');
%    fwrite(obj,rSF,'uint16');    % Sampling frequency considering all
%    channels
    fwrite(obj,sF,'uint16');    
    replay = char(fread(obj,1,'char'));
    if ~strcmp(replay,'O')
        set(handles.t_msg,'String','Error setting the frequency'); 
        fclose(obj);        
        return
    else    
        set(handles.t_msg,'String','Frequency set'); 
    end
    % Send sampling time
    fwrite(obj,sT,'uint8');
    replay = char(fread(obj,1,'char'));
    if ~strcmp(replay,'O')
        set(handles.t_msg,'String','Error setting sampling time'); 
        fclose(obj);        
        return
    else    
        set(handles.t_msg,'String','Sampling time set'); 
    end
    
    % Start the aquisition    
    allData = zeros(nCh,sT*sF);
    cData = zeros(nCh,tW*sF);
    printFlag = 1;
    sTw = tW*sF;
    
    fwrite(obj,'S','char');
    tic;
    
    % Run through all samples. Samples per channel are considered since all
    % channels samples are recieved at once in the code below
    for i = 1:sT*sF
        
        % Find the right sequence of characters
%        if fread(obj,1,'uint8') == 83            % Verification step,
%        removed to improve speed.
            value16 = fread(obj,nCh,'uint16');    % Read the samples        
%            if fread(obj,1) == 69        
                centValue = value16 - 16384;       % Center the data
                cData(:,printFlag) = centValue;
                allData(:,i) = centValue;
                printFlag = printFlag +1;
%            end
%        end
                        
        if printFlag == sTw+1
            % Offset the data
            for j = 1 : nCh
                sData(:,j) = cData(j,:);
                set(p_t0(j),'YData',sData(:,j)+ offVector(j));
            end
            printFlag = 1;      
            drawnow;
        end


    end
    allData = allData';

    toc
    % Start the aquisition    
    fwrite(obj,'Q','char');    
    
    % Close connection
    fclose(obj);
    
    % Print the data    
    tv = 0:1/sF:sT-1/sF;                % Create vector of time
    cData = allData;
    p_t0 = plot(handles.a_t0,tv,cData);
    sData = zeros(size(cData));
    for i = 1 : nCh
        sData(:,i) = cData(:,i) + offVector(i);
        set(p_t0(i),'YData',sData(:,i));
    end     
    % Update for all data
    xlim([0,sT]);
    ylim([-ampPP/2,(ampPP*nCh)-ampPP/2]);
    set(handles.a_t0,'YTick',offVector);
    set(handles.a_t0,'YTickLabel',vCh);
    
    set(handles.t_msg,'String','');
    
    disp(size(sData,1));
    disp(sData(end));
    
    save('sData.mat','sData');


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
        obj = tcpip('192.168.100.10',65100,'NetworkRole','client');
    end
    % Open connection
    fclose(obj);
    fopen(obj);
    fwrite(obj,'A','char');
    fwrite(obj,'C','char')
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'C');
        set(handles.t_msg,'String','Connection stablished');
    else
        set(handles.t_msg,'String','Error');        
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



function et_Ampp_Callback(hObject, eventdata, handles)
% hObject    handle to et_Ampp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_Ampp as text
%        str2double(get(hObject,'String')) returns contents of et_Ampp as a double


% --- Executes during object creation, after setting all properties.
function et_Ampp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_Ampp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

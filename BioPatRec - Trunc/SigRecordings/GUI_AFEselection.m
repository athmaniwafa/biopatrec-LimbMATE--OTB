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
% [Give a short summary about the principle of your function here.]
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 20xx-xx-xx / Max Ortiz  / Creation
% 2013-08-23 / Morten Kristoffersen / Trimmed the interface down to one
% popup menu, reorganised the GUI_AFESelection data. 
% 2013-09-20 / Pontus Lövinger  / Added the option for ramp recording which
                        % calls the ramp recording functions
% 2014-11-10 / Enzo Mastinu / include the code for ADS1299 AFE, optimization of 
                        % ramp functions and their callings
% 2015-11-27 / Enzo Mastinu / It has been added the possibility to repeat 
                            % the same movement recording if you are not 
                            % happy with it.
% 2017-09-25 / Simon Nilsson  / Added AFE selection modes for HD-EMG and
                              % Biofeedback GUI. These modes return the
                              % AFE parameters to the caller and lets
                              % the caller perform the recording.
% 2018-02-24 / Adam Naber / Device name list is now set in this file,
                          % rather than being saved in the .fig. 
% 2019-03-06 / Bahareh Ahkami / Bar plot added to the system

function varargout = GUI_AFEselection(varargin)
% GUI_AFESELECTION MATLAB code for GUI_AFEselection.fig
%      GUI_AFESELECTION, by itself, creates a new GUI_AFESELECTION or raises the existing
%      singleton*.
%
%      H = GUI_AFESELECTION returns the handle to a new GUI_AFESELECTION or the handle to
%      the existing singleton*.
%
%      GUI_AFESELECTION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI_AFESELECTION.M with the given input arguments.
%
%      GUI_AFESELECTION('Property','Value',...) creates a new GUI_AFESELECTION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI_AFEselection_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI_AFEselection_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUI_AFEselection

% Last Modified by GUIDE v2.5 09-Dec-2019 16:43:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_AFEselection_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_AFEselection_OutputFcn, ...
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


% --- Executes just before GUI_AFEselection is made visible.
function GUI_AFEselection_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI_AFEselection (see VARARGIN)
% handles

%load the background image into Matlab
backgroundImage2 = importdata('Img/BioPatRec.png');
%select the axes
axes(handles.axes1);
%place image onto the axes
image(backgroundImage2);
%remove the axis tick marks
axis off

handles.varargin = varargin;

% Choose default command line output for GUI_AFEselection
handles.output = hObject;

% Initialize the LM connection field
handles.objLM  = [];
handles.lmName = '';

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GUI_AFEselection wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GUI_AFEselection_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



% --- Executes on button press in pb_record.
function pb_record_Callback(hObject, eventdata, handles)
% hObject    handle to pb_record (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% get(handles.cb_active0,'Value')

global offsetDelete;
offsetDelete = get(handles.cb_offset,'Value');

% AFE_settings.active=[get(handles.cb_active0,'Value');get(handles.cb_active1,'Value');get(handles.cb_active2,'Value')];
% AFE_settings.active

%if the devices are powered down then if not deleted, they will trouble
%if the devices are powered down then if not deleted, they will trouble
if not(isempty(instrfind('Status','open')))
    fclose(instrfind('Status','open'))
    delete(instrfind)
end

% Get devices name
dev = get(handles.pm_name,'String');
selDev = get(handles.pm_name,'Value');
AFE_settings.name = dev(selDev);
deviceName = AFE_settings.name;

% ---- LimbMate: ensure a connection exists, auto-open dialog if not ----
if isLimbMATE(deviceName)
    if ~isfield(handles, 'objLM') || isempty(handles.objLM)
        result = LimbMateDialog();
        if ~result.connected
            return;
        end
        handles.objLM  = result.objLM;
        handles.lmName = result.lmName;
        handles.lmPort = result.port;
        guidata(hObject, handles);
    end
    deviceName = {handles.lmName};
    AFE_settings.name = deviceName;
    
    % Pass the LM connection to the session file
    AFE_settings.objLM = handles.objLM;
end

% ---- Pass OTB object to the session if it exists ----
if isfield(handles, 'objOT') && ~isempty(handles.objOT)
    AFE_settings.objOT = handles.objOT;
end
% ---- Pass SQ+ object to the session if it exists ----
if isfield(handles, 'objSQ') && ~isempty(handles.objSQ)
    AFE_settings.objSQ = handles.objSQ;
end
%% Sampling frequency 
contents = cellstr(get(handles.pm_sampleRate, 'String'));
sF = str2double(contents{get(handles.pm_sampleRate,'Value')});

% AFE_settings.sampleRate=[SR0;SR1;SR2];
% AFE_settings.sampleRate

AFE_settings.sampleRate=sF;

%% Number of channels
if isfield(handles,'vCh')
    AFE_settings.channels = handles.nCh;
    AFE_settings.vChannels = handles.vCh;
    
    nCh = handles.nCh;
else
    AFE_settings.channels = str2double(get(handles.et_chs,'String'));
    nCh = AFE_settings.channels;
end

%% OTB400 HD electrode configuration
if isfield(handles, 'OTB400Electrodes')
    AFE_settings.OTB400Electrodes = handles.OTB400Electrodes;
end


%% Compression (only for ADS_BP and ALC-D 1.2)
AFE_settings.compressData = get(handles.cb_compressionEnable,'Value');

%%
% Communication Port

contents = cellstr(get(handles.ComPortType,'String'));
ComPortType=contents{get(handles.ComPortType,'Value')};
AFE_settings.ComPortType=ComPortType;

if strcmp(AFE_settings.ComPortType,'COM')
    ComPortName = get(handles.ComPortName,'String');
%     AFE_settings.ComPortType=strcat(ComPortType,ComPortName);
    if ispc
        AFE_settings.ComPortName=strcat(ComPortType,ComPortName);
    else
        AFE_settings.ComPortName=ComPortName;
    end
end

% ---- Override port if we connected via the LimbMATE dialog ----
if isfield(handles, 'lmPort') && ~isempty(handles.lmPort)
    AFE_settings.ComPortType = 'COM';
    AFE_settings.ComPortName = handles.lmPort;
end

% ---- If we connected via the LimbMATE dialog, use the real port ----
if strcmp(deviceName{1}, 'LM') || (isfield(handles,'lmPort') && ~isempty(handles.lmPort))
    if isfield(handles,'lmPort') && ~isempty(handles.lmPort)
        AFE_settings.ComPortType = 'COM';
        AFE_settings.ComPortName = handles.lmPort;
    end
end


%% Plot Type
plt = get(handles.pm13,'String');
plt_types= get(handles.pm13,'Value');
AFE_settings.plotType = plt(plt_types);
plotType = AFE_settings.plotType;

%% Feature Type
ftr = get(handles.pm12,'String');
ftr_types= get(handles.pm12,'Value');
AFE_settings.featureType = ftr(ftr_types);
AFE_settings.featureType = AFE_settings.featureType{1};
featureType = AFE_settings.featureType;




%% 
% AFE_settings.ComPortType

% AFE_settings.ADS.ComPortType=CPT0;
% AFE_settings.RHA.ComPortType=CPT1;
% % AFE_settings.NI.ComPortType=CPT2;

% AFE_settings.show=[get(handles.show0,'Value');get(handles.show1,'Value');get(handles.show2,'Value')];
% AFE_settings.show

% AFE_settings.ADS.show=get(handles.show0,'Value');
% % AFE_settings.ADS.show
% AFE_settings.RHA.show=get(handles.show1,'Value');
% % AFE_settings.RHA.show
% AFE_settings.NI.show=get(handles.show2,'Value');
% % AFE_settings.NI.show

AFE_settings.prepare      = get(handles.prepare,'Value');

% GUI_AFEselection(Fs,Ne,Nr,Tc,Tr,Psr,msg,EMG_AQhandle)
% cdata = recording_session(Fs,Ne,Nr,Tc,Tr,Psr,msg,EMG_AQhandle);

nM=handles.varargin{1};
nR=handles.varargin{2};
cT=handles.varargin{3};
rT=handles.varargin{4};
mov=handles.varargin{5};
hGUI_Rec=handles.varargin{6};
vreMovements = handles.varargin{7};
rampStatus = handles.varargin{8};
mode = handles.varargin{9};
if mode == 0
    movRepeatDlg = handles.varargin{10};
    useLeg = handles.varargin{11};
end
%useLeg = handles.varargin{11};

if isfield(handles, 'vCh')
    hGUI_Rec.vCh = handles.vCh;
end

AFE_settings.recFeatures   = get(handles.cb_recFeatures,'Value');
if(AFE_settings.recFeatures)
    FeaturesRecordingSession(nM,nR,cT,rT,mov,hGUI_Rec,AFE_settings,get(handles.cb_trainVRE,'Value'),vreMovements,get(handles.cb_VRELeftHand,'Value'),rampStatus);
    close(GUI_AFEselection);
    close(GUI_RecordingSession);
    return
end
AFE_settings.useAcceleGlove = get(handles.cb_acceleGlove,'Value');
AFE_settings.acceleGlovePort = get(handles.et_AGPort, 'String');

% for compatibility, delete previous temporary data
if(exist('cdata','var')) == 1
    delete(cdata);
end

switch mode
    case 0
        % If ramp training has been selected in GUI_RecordingSession the ramp
        % parameters should be obtained and the rampRecordingSession file is run
        if rampStatus
            [rampMin, minData] = ObtainRampMin(hGUI_Rec,AFE_settings,get(handles.cb_trainVRE,'Value'));%Fs,Ne,Nr,Tc,Tr,Psr,msg,EMG_AQhandle
            [rampMax, maxData] = ObtainRampMax(nM,mov,hGUI_Rec,AFE_settings,get(handles.cb_trainVRE,'Value'),vreMovements, get(handles.cb_VRELeftHand,'Value'));%Fs,Ne,Nr,Tc,Tr,Psr,msg,EMG_AQhandle
            rampParams =  {rampMin rampMax minData maxData};
            [cdata, sF, sdata] = RecordingSession(nM,nR,cT,rT,mov,hGUI_Rec,AFE_settings,get(handles.cb_trainVRE,'Value'),vreMovements,get(handles.cb_VRELeftHand,'Value'),movRepeatDlg,useLeg,rampStatus,rampParams);%Fs,Ne,Nr,Tc,Tr,Psr,msg,EMG_AQhandle,rampParams);
        else
            [cdata, sF, sdata] = RecordingSession(nM,nR,cT,rT,mov,hGUI_Rec,AFE_settings,get(handles.cb_trainVRE,'Value'),vreMovements,get(handles.cb_VRELeftHand,'Value'),movRepeatDlg,useLeg,rampStatus);%Fs,Ne,Nr,Tc,Tr,Psr,msg,EMG_AQhandle);
        end
        % Fs=handles.varargin{1};
        % Nr=handles.varargin{3};
        % Tc=handles.varargin{4};
        % Tr=handles.varargin{5};
        %Moved from Recoding Session Fig

        sT = (cT+rT)*nR;
        cdata = cdata(:,:,size(cdata,3));
        tempdata = cdata;
        save('cdata.mat','cdata','tempdata','sdata','sF','sT','nCh','ComPortType','deviceName','plotType','featureType');
        %close(GUI_AFEselection);
        close(GUI_RecordingSession);

        % close(recording_session_fig);

        % close(get(hObject,'Parent'))
    case 1
        % Fast recording session
        [cdata, sF, sT, sdata] = FastRecordingSession(hGUI_Rec,AFE_settings);
        tempdata = cdata;                                                      % variable useful for offline data processing
        save('cdata.mat','cdata','tempdata','sdata','sF','sT','nCh','ComPortType','deviceName','plotType','featureType');
    case 2
        % HD-EMG mode, recording performed by caller
        %handles.AFE_settings = AFE_settings;
        
        GUI_Recordings_Image('startRecording',hGUI_Rec,AFE_settings);
    case 3
        % Biofeedback mode, recording performed by caller
        startBiofeedback(hGUI_Rec,AFE_settings);
end

% --- Executes during object creation, after setting all properties.
function pb_record_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pb_record (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes on button press in pb_cancel.
function pb_cancel_Callback(hObject, eventdata, handles)
% hObject    handle to pb_cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(get(hObject,'Parent'))

% --- Executes during object creation, after setting all properties.
function pb_cancel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pb_cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in default.
function default_Callback(hObject, eventdata, handles)
% hObject    handle to default (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes during object creation, after setting all properties.
function default_CreateFcn(hObject, eventdata, handles)
% hObject    handle to default (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on selection change in pm_sampleRate.
function pm_sampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to pm_sampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pm_sampleRate contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pm_sampleRate


% --- Executes during object creation, after setting all properties.
function pm_sampleRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pm_sampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% ---------------------------------------------------------------
% Ensure '2048' is present in the sample-rate dropdown
% ---------------------------------------------------------------
existing = cellstr(get(hObject, 'String'));
if ~any(strcmp(existing, '2048'))
    set(hObject, 'String', [existing(:); {'2048'}]);
end

% Also ensure '2000' for the Sessantaquattro+
existing = cellstr(get(hObject, 'String'));
if ~any(strcmp(existing, '2000'))
    set(hObject, 'String', [existing(:); {'2000'}]);
end

existing = cellstr(get(hObject, 'String'));
if ~any(strcmp(existing, '1000'))
    set(hObject, 'String', [existing(:); {'1000'}]);
end

%%The function below detects the available COM porst, I just leave it there
%%for now in case that we need it. 
% --- Executes on selection change in ComPortType0.
%function ComPortType0_Callback(hObject, eventdata, handles)
% hObject    handle to ComPortType0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ComPortType0 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ComPortType0


% % --- Executes during object creation, after setting all properties.
% function ComPortType0_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to ComPortType0 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: popupmenu controls usually have a white background on Windows.
% %       See ISPC and COMPUTER.
% if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end
% 
% 
% s=instrhwinfo('serial');
% if not(isfield(s,'SerialPorts'))
%     s.SerialPorts = {'Not Available'};
% elseif isempty(s.SerialPorts)
%     s.SerialPorts = {'Not Available'};
% end
% set(hObject,'String',[s.SerialPorts]);


function bytesSamples2_Callback(hObject, eventdata, handles)
% hObject    handle to bytesSamples2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bytesSamples2 as text
%        str2double(get(hObject,'String')) returns contents of bytesSamples2 as a double


% --- Executes during object creation, after setting all properties.
function bytesSamples2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bytesSamples2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function bytesSamples1_Callback(hObject, eventdata, handles)
% hObject    handle to bytesSamples1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bytesSamples1 as text
%        str2double(get(hObject,'String')) returns contents of bytesSamples1 as a double


% --- Executes during object creation, after setting all properties.
function bytesSamples1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bytesSamples1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function bytesSamples0_Callback(hObject, eventdata, handles)
% hObject    handle to bytesSamples0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bytesSamples0 as text
%        str2double(get(hObject,'String')) returns contents of bytesSamples0 as a double


% --- Executes during object creation, after setting all properties.
function bytesSamples0_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bytesSamples0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function pm_name_Callback(hObject, eventdata, handles)
% hObject    handle to pm_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pm_name as text
%        str2double(get(hObject,'String')) returns contents of pm_name as a double
contents = cellstr(get(handles.pm_name,'String'));
deviceName = contents{get(handles.pm_name,'Value')};

% Reset previous channel selection
if isfield(handles, 'nCh')
    handles = rmfield(handles, 'nCh');
end

if isfield(handles, 'vCh')
    handles = rmfield(handles, 'vCh');
end

if isfield(handles, 'OTB400Electrodes')
    handles = rmfield(handles, 'OTB400Electrodes');
end

% settings based on deviceName
if strcmp(deviceName, 'Thalmic MyoBand')
    %CK: These are the default values for the MyoBand. Changing these might
    %lead to unwanted behaviour.
    set(handles.pm_sampleRate, 'Value', 9); %CK: The sample rate should be 200 Hz
    set(handles.ComPortType, 'Value', 1); %CK: I chose the NI ComPort because later in BPR it was easier to implement the MyoBand as an NI device, eventhough it isn't!
    set(handles.et_chs, 'String', '8');
end
if strcmp(deviceName, 'ALC-16chs')
    str = {'1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16'};
    vCh = listdlg('PromptString', 'Select recording channels for the ALC-16channels version:', 'SelectionMode', 'multiple', 'ListString', str);
    handles.nCh = size(vCh,2);
    handles.vCh = vCh;
    set(handles.et_chs,'String',num2str(handles.nCh));
    set(handles.ComPortType,'Value',3);
    set(handles.ComPortName,'Enable', 'on');
elseif strcmp(deviceName, 'ALC-24chs')
    str = {'1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23','24'};
    vCh = listdlg('PromptString', 'Select recording channels for the ALC:', 'SelectionMode', 'multiple', 'ListString', str);
    handles.nCh = size(vCh,2);
    handles.vCh = vCh;
    set(handles.et_chs,'String',num2str(handles.nCh));
    set(handles.ComPortType,'Value',3);
    set(handles.ComPortName,'Enable', 'on');
end

% ---- OTB (OT Bioelettronica EMG-USB2+) settings ----
if isOTB400(deviceName)
    if strcmp(deviceName, 'OTB400_HD')

        % Step 1: Select number of channels
        choice = questdlg('Select number of channels:', ...
                          'OTB400 HD', ...
                          '64', '128', '64');

        if isempty(choice)
            return;
        end

        nChSelected = str2double(choice);

        % Step 2: Select electrodes for each MULTIPLE input
        [electrodes, ok] = OTB400_SelectElectrodes(nChSelected);

        if ~ok
            return;
        end

        % Save channel configuration
        handles.nCh = nChSelected;
        handles.vCh = 1:nChSelected;

        % Save electrode configuration
        handles.OTB400Electrodes = electrodes;

        set(handles.et_chs, 'String', choice);

        fprintf('OTB400 HD: %d channels\n', handles.nCh);
        disp(handles.OTB400Electrodes);

    else % BIPOLAR

        handles.nCh = 8;
        handles.vCh = 1:8;

        if isfield(handles, 'OTB400Electrodes')
            handles = rmfield(handles, 'OTB400Electrodes');
        end

        set(handles.et_chs, 'String', '8');

    end

    % Sampling frequency
    srList = cellstr(get(handles.pm_sampleRate, 'String'));

    idxSR = find(strcmp(srList, '2048'), 1);

    if isempty(idxSR)
        srList{end+1} = '2048';
        set(handles.pm_sampleRate, 'String', srList);
        idxSR = numel(srList);
    end

    set(handles.pm_sampleRate, 'Value', idxSR);

    % COM configuration
    comList = cellstr(get(handles.ComPortType, 'String'));
    idxCOM = find(strcmp(comList, 'COM'), 1);

    if ~isempty(idxCOM)
        set(handles.ComPortType, 'Value', idxCOM);
    end

    set(handles.ComPortName, 'String', '3');
    set(handles.ComPortName, 'Enable', 'on');

    % ---- Create the OTB object now so we can pass it to the session ----
    % Use a generous 120-second buffer to ensure we don't run out of space
    otDuration = 120;
    try
        if contains(deviceName, 'HD')
            electrodeConfig = handles.OTB400Electrodes;
            objOT = OT_Acquire('hd', handles.nCh, otDuration, electrodeConfig);
        else
            objOT = OT_Acquire('bipolar', handles.nCh, otDuration);
        end
        handles.objOT = objOT;
        fprintf('OTB400 object created successfully\n');
    catch ME
        errordlg(sprintf('Failed to initialize OTB400: %s', ME.message), 'OTB400 Error');
    end
end

% ---- Sessantaquattro+ (TCP) settings ----
if strcmp(deviceName, 'SQ+')
    handles.nCh = 8;
    handles.vCh = 1:8;
    set(handles.et_chs, 'String', '8');

    srList = cellstr(get(handles.pm_sampleRate, 'String'));
    idxSR = find(strcmp(srList, '1000'), 1);
    if isempty(idxSR)
        srList{end+1} = '1000';
        set(handles.pm_sampleRate, 'String', srList);
        idxSR = numel(srList);
    end
    set(handles.pm_sampleRate, 'Value', idxSR);

    comList = cellstr(get(handles.ComPortType, 'String'));
    idxCOM = find(strcmp(comList, 'COM'), 1);
    if ~isempty(idxCOM)
        set(handles.ComPortType, 'Value', idxCOM);
    end
    set(handles.ComPortName, 'String', '3');
    set(handles.ComPortName, 'Enable', 'on');
        % ---- Create the SQ+ object now so we can pass it to the session ----
    sqDuration = 120; % Buffer size
    try
        objSQ = Sessantaquattro_Acquire(handles.nCh, sqDuration, 45454);
        handles.objSQ = objSQ;
        fprintf('SQ+ object created successfully\n');
    catch ME
        errordlg(sprintf('Failed to initialize SQ+: %s', ME.message), 'SQ+ Error');
    end
end

% ---- LimbMate: open the device-selection dialog ----
% ---- LimbMate: open the device-selection dialog ----
if strcmp(deviceName, 'LimbMate')
    result = LimbMateDialog();
    if result.connected
        handles.objLM  = result.objLM;
        handles.lmName = result.lmName;
        handles.lmPort = result.port;
        fprintf('Connected to %s on %s\n', result.lmName, result.port);
    else
        fprintf('LimbMate dialog cancelled\n');
    end
end

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function pm_name_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pm_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
deviceNames = {'AD2','AD3','MyoAmpF4F1','MyoAmpF4F2','MyoAmpF4F7','MyoAmpF4F7_Shielded','NeuroAmpF8F1','RHA2216','RHA2132','ADS1299','ADS_BP','Thalmic MyoBand','ALC-16chs','ALC-24chs', 'ADS_BP4', 'LimbMate', 'OTB400_HD', 'OTB400_bipolar', 'SQ+'};

set(hObject,'String',deviceNames);
set(hObject,'Value',5);

% --- Executes during object creation, after setting all properties.
function uipanel3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uipanel3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in prepare.
function prepare_Callback(hObject, eventdata, handles)
% hObject    handle to prepare (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of prepare


% --- Executes on button press in edit13.
function edit13_Callback(hObject, eventdata, handles)
% hObject    handle to edit13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of edit13


% --- Executes during object creation, after setting all properties.
function edit13_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



function edit14_Callback(hObject, eventdata, handles)
% hObject    handle to edit14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit14 as text
%        str2double(get(hObject,'String')) returns contents of edit14 as a double


% --- Executes during object creation, after setting all properties.
function edit14_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit15_Callback(hObject, eventdata, handles)
% hObject    handle to edit15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit15 as text
%        str2double(get(hObject,'String')) returns contents of edit15 as a double


% --- Executes during object creation, after setting all properties.
function edit15_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function et_chs_Callback(hObject, eventdata, handles)
% hObject    handle to et_chs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_chs as text
%        str2double(get(hObject,'String')) returns contents of et_chs as a double

% --- Executes during object creation, after setting all properties.
function et_chs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_chs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cb_trainVRE.
function cb_trainVRE_Callback(hObject, eventdata, handles)
% hObject    handle to cb_trainVRE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_trainVRE

set(handles.cb_VRELeftHand,'Enable', 'on');

% --- Executes on selection change in ComPortType.
function ComPortType_Callback(hObject, eventdata, handles)
% hObject    handle to ComPortType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ComPortType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ComPortType

contents = cellstr(get(handles.ComPortType,'String'));
ComPortType = contents{get(handles.ComPortType,'Value')};
if strcmp(ComPortType,'COM')
    set(handles.ComPortName,'Enable', 'on');
else
    set(handles.ComPortName,'Enable', 'off');
end

% --- Executes during object creation, after setting all properties.
function ComPortType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ComPortType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cb_VRELeftHand.
function cb_VRELeftHand_Callback(hObject, eventdata, handles)
% hObject    handle to cb_VRELeftHand (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_VRELeftHand



function ComPortName_Callback(hObject, eventdata, handles)
% hObject    handle to ComPortName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ComPortName as text
%        str2double(get(hObject,'String')) returns contents of ComPortName as a double


% --- Executes during object creation, after setting all properties.
function ComPortName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ComPortName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cb_offset.
function cb_offset_Callback(hObject, eventdata, handles)
% hObject    handle to cb_offset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_offset


% --- Executes on button press in cb_recFeatures.
function cb_recFeatures_Callback(hObject, eventdata, handles)
% hObject    handle to cb_recFeatures (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_recFeatures


% --- Executes on button press in cb_acceleGlove.
function cb_acceleGlove_Callback(hObject, eventdata, handles)
% hObject    handle to cb_acceleGlove (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(handles.cb_acceleGlove,'Value') == 1
    set(handles.et_AGPort, 'Visible', 'on');
    set(handles.lb_AGPort, 'Visible', 'on');
else
    set(handles.et_AGPort, 'Visible', 'off');
    set(handles.lb_AGPort, 'Visible', 'off');
end
% Hint: get(hObject,'Value') returns toggle state of cb_acceleGlove



function et_AGPort_Callback(hObject, eventdata, handles)
% hObject    handle to et_AGPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_AGPort as text
%        str2double(get(hObject,'String')) returns contents of et_AGPort as a double


% --- Executes during object creation, after setting all properties.
function et_AGPort_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_AGPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pm12.
function pm12_Callback(hObject, eventdata, handles)
% hObject    handle to pm12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pm12 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pm12


% --- Executes during object creation, after setting all properties.
function pm12_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pm12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pm13.
function pm13_Callback(hObject, eventdata, handles)
% hObject    handle to pm13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pm13 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pm13


% --- Executes during object creation, after setting all properties.
function pm13_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pm13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cb_compressionEnable.
function cb_compressionEnable_Callback(hObject, eventdata, handles)
% hObject    handle to cb_compressionEnable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_compressionEnable
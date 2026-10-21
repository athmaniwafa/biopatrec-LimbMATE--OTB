% ---------------------------- Copyright Notice ---------------------------
% This file is part of BioPatRec © which is open and free software under 
% the GNU Lesser General Public License (LGPL). See the file "LICENSE" for 
% the full license governing this code and copyrights.
%
% BioPatRec was initially developed by Max J. Ortiz C. at Integrum AB and 
% Chalmers University of Technology. All authors’ contributions must be kept
% acknowledged below in the section "Updates % Contributors". 
% -------------------------- Function Description -------------------------
% GUI for AFE Selection

function varargout = GUI_AFEselection(varargin)
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
backgroundImage2 = importdata('Img/BioPatRec.png');
axes(handles.axes1);
image(backgroundImage2);
axis off

handles.varargin = varargin;
handles.output = hObject;

handles.objLM  = [];
handles.lmName = '';
handles.lmPort = '';
handles.objOT  = [];
handles.objSQ  = [];
handles.adapter = [];

guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = GUI_AFEselection_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


% --- Executes on button press in pb_record.
function pb_record_Callback(hObject, eventdata, handles)
global offsetDelete;
offsetDelete = get(handles.cb_offset,'Value');

if not(isempty(instrfind('Status','open')))
    fclose(instrfind('Status','open'))
    delete(instrfind)
end

% Get devices name
dev = get(handles.pm_name,'String');
selDev = get(handles.pm_name,'Value');
AFE_settings.name = dev(selDev);
deviceName = AFE_settings.name;

% ---- LimbMate: ensure a connection exists ----
if isLimbMATE(deviceName)
    if ~isfield(handles, 'objLM') || isempty(handles.objLM)
        result = LimbMateDialog();
        if ~result.connected
            return;
        end
        handles.objLM  = result.objLM;
        
        % SAFE PORT EXTRACTION
        try
            portVal = result.port;
            while iscell(portVal), portVal = portVal{1}; end
            if isnumeric(portVal)
                handles.lmPort = ['COM' num2str(portVal)];
            else
                portValStr = char(portVal);
                if ~startsWith(upper(portValStr), 'COM')
                    portValStr = ['COM' portValStr];
                end
                handles.lmPort = portValStr;
            end
        catch
            handles.lmPort = 'COM4';
        end
        
        handles.lmName = 'LimbMATE';
        guidata(hObject, handles);
    end
    deviceName = {'LimbMATE'};
    AFE_settings.name = deviceName;
end

% ---- Pass objects to the session ----
if isfield(handles, 'objOT') && ~isempty(handles.objOT)
    AFE_settings.objOT = handles.objOT;
else
    AFE_settings.objOT = [];
end

if isfield(handles, 'objSQ') && ~isempty(handles.objSQ)
    AFE_settings.objSQ = handles.objSQ;
else
    AFE_settings.objSQ = []; 
end

if isfield(handles, 'objLM') && ~isempty(handles.objLM)
    AFE_settings.objLM = handles.objLM;
else
    AFE_settings.objLM = []; 
end

%% Sampling frequency 
contents = cellstr(get(handles.pm_sampleRate, 'String'));
sF = str2double(contents{get(handles.pm_sampleRate,'Value')});
AFE_settings.sampleRate = sF;

%% Number of channels
if isfield(handles,'vCh') && ~isempty(handles.vCh)
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

%% Compression
AFE_settings.compressData = get(handles.cb_compressionEnable,'Value');

% Communication Port
contents = cellstr(get(handles.ComPortType,'String'));
ComPortType = contents{get(handles.ComPortType,'Value')};

% FAIL-SAFE
if strcmp(char(deviceName{1}), 'SQ+') || isSQplus(deviceName) || isLimbMATE(deviceName) || isOTB400(deviceName)
    ComPortType = 'COM';
end
AFE_settings.ComPortType = ComPortType;

if strcmp(AFE_settings.ComPortType,'COM')
    ComPortName = get(handles.ComPortName,'String');
    if ispc
        AFE_settings.ComPortName = strcat(ComPortType, ComPortName);
    else
        AFE_settings.ComPortName = ComPortName;
    end
end

% ---- Override port if we connected via the LimbMATE dialog ----
if isfield(handles, 'lmPort') && ~isempty(handles.lmPort)
    AFE_settings.ComPortType = 'COM';
    AFE_settings.ComPortName = handles.lmPort;
end

%% Plot Type
plt = get(handles.pm13,'String');
plt_types = get(handles.pm13,'Value');
AFE_settings.plotType = plt(plt_types);
plotType = AFE_settings.plotType;

%% Feature Type
ftr = get(handles.pm12,'String');
ftr_types = get(handles.pm12,'Value');
AFE_settings.featureType = ftr(ftr_types);
AFE_settings.featureType = AFE_settings.featureType{1};
featureType = AFE_settings.featureType;

AFE_settings.prepare = get(handles.prepare,'Value');

nM = handles.varargin{1};
nR = handles.varargin{2};
cT = handles.varargin{3};
rT = handles.varargin{4};
mov = handles.varargin{5};
hGUI_Rec = handles.varargin{6};
vreMovements = handles.varargin{7};
rampStatus = handles.varargin{8};
mode = handles.varargin{9};
if mode == 0
    movRepeatDlg = handles.varargin{10};
    useLeg = handles.varargin{11};
end

% --- HD-EMG CHECK ---
if (strcmp(char(deviceName{1}), 'SQ+') || isSQplus(deviceName)) && nCh == 64
    mode = 2; 
    fprintf('[GUI] Switching to HD-EMG Heatmap (Mode 2)\n');
end

if isfield(handles, 'vCh')
    hGUI_Rec.vCh = handles.vCh;
end

AFE_settings.recFeatures = get(handles.cb_recFeatures,'Value');
if AFE_settings.recFeatures
    FeaturesRecordingSession(nM,nR,cT,rT,mov,hGUI_Rec,AFE_settings,get(handles.cb_trainVRE,'Value'),vreMovements,get(handles.cb_VRELeftHand,'Value'),rampStatus);
    close(GUI_AFEselection);
    close(GUI_RecordingSession);
    return
end

AFE_settings.useAcceleGlove = get(handles.cb_acceleGlove,'Value');
AFE_settings.acceleGlovePort = get(handles.et_AGPort, 'String');

if(exist('cdata','var')) == 1
    delete(cdata);
end

% ---------------------------------------------------------
% ADAPTER PATTERN: Instantiate the Adapter via the Factory
% ---------------------------------------------------------
if isfield(handles, 'adapter') && ~isempty(handles.adapter)
    try, handles.adapter.disconnect(); catch, end
    handles.adapter = [];
end

% Force a fresh SQ+ object
if strcmp(char(deviceName{1}), 'SQ+') || isSQplus(deviceName)
    handles.objSQ = [];
end

handles.adapter = DeviceFactory(deviceName, nCh, sF, handles, AFE_settings);
guidata(hObject, handles);
AFE_settings.adapter = handles.adapter;

% Pass objects to the recording GUI
hGUI_Rec.objSQ   = handles.objSQ;
hGUI_Rec.objOT   = handles.objOT;
hGUI_Rec.objLM   = handles.objLM;
hGUI_Rec.adapter = handles.adapter;

switch mode
    case 0
        if rampStatus
            [rampMin, minData] = ObtainRampMin(hGUI_Rec,AFE_settings,get(handles.cb_trainVRE,'Value'));
            [rampMax, maxData] = ObtainRampMax(nM,mov,hGUI_Rec,AFE_settings,get(handles.cb_trainVRE,'Value'),vreMovements, get(handles.cb_VRELeftHand,'Value'));
            rampParams = {rampMin rampMax minData maxData};
            [cdata, sF, sdata] = RecordingSession(nM,nR,cT,rT,mov,hGUI_Rec,AFE_settings,get(handles.cb_trainVRE,'Value'),vreMovements,get(handles.cb_VRELeftHand,'Value'),movRepeatDlg,useLeg,rampStatus,rampParams);
        else
            [cdata, sF, sdata] = RecordingSession(nM,nR,cT,rT,mov,hGUI_Rec,AFE_settings,get(handles.cb_trainVRE,'Value'),vreMovements,get(handles.cb_VRELeftHand,'Value'),movRepeatDlg,useLeg,rampStatus);
        end
        sT = (cT+rT)*nR;
        cdata = cdata(:,:,size(cdata,3));
        tempdata = cdata;
        save('cdata.mat','cdata','tempdata','sdata','sF','sT','nCh','ComPortType','deviceName','plotType','featureType');
        close(GUI_RecordingSession);
    case 1
        % --- SAVE EVERYTHING FOR THE NEXT RUN ---
        global GLOBAL_ADAPTER;
        global GLOBAL_AFE_SETTINGS;
        GLOBAL_ADAPTER = handles.adapter;
        GLOBAL_AFE_SETTINGS = AFE_settings; 
        
        [cdata, sF, sT, sdata] = FastRecordingSession(hGUI_Rec,AFE_settings);
        tempdata = cdata;
        save('cdata.mat','cdata','tempdata','sdata','sF','sT','nCh','ComPortType','deviceName','plotType','featureType');
    case 2
        try
            % Force GUI_Recordings_Image to open/return its exact current handles
            [~, hGUI_Rec] = GUI_Recordings_Image();
        catch ME
            errordlg(['Could not fetch HD-EMG handles: ' ME.message]);
            return;
        end
        GUI_Recordings_Image('startRecording', hGUI_Rec, AFE_settings);
    case 3
        startBiofeedback(hGUI_Rec,AFE_settings);
end

% --- Executes during object creation, after setting all properties.
function pb_record_CreateFcn(hObject, eventdata, handles)
function pb_cancel_Callback(hObject, eventdata, handles)
close(get(hObject,'Parent'))
function pb_cancel_CreateFcn(hObject, eventdata, handles)
function default_Callback(hObject, eventdata, handles)
function default_CreateFcn(hObject, eventdata, handles)
function pm_sampleRate_Callback(hObject, eventdata, handles)

function pm_sampleRate_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
existing = cellstr(get(hObject, 'String'));
if ~any(strcmp(existing, '2048')), set(hObject, 'String', [existing(:); {'2048'}]); end
existing = cellstr(get(hObject, 'String'));
if ~any(strcmp(existing, '2000')), set(hObject, 'String', [existing(:); {'2000'}]); end
existing = cellstr(get(hObject, 'String'));
if ~any(strcmp(existing, '1000')), set(hObject, 'String', [existing(:); {'1000'}]); end

function bytesSamples2_Callback(hObject, eventdata, handles)
function bytesSamples2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function bytesSamples1_Callback(hObject, eventdata, handles)
function bytesSamples1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function bytesSamples0_Callback(hObject, eventdata, handles)
function bytesSamples0_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pm_name_Callback(hObject, eventdata, handles)
contents = cellstr(get(handles.pm_name,'String'));
deviceName = char(contents{get(handles.pm_name,'Value')});

if isfield(handles, 'nCh'), handles = rmfield(handles, 'nCh'); end
if isfield(handles, 'vCh'), handles = rmfield(handles, 'vCh'); end
if isfield(handles, 'OTB400Electrodes'), handles = rmfield(handles, 'OTB400Electrodes'); end
handles.adapter = []; 
handles.objSQ = [];

if strcmp(deviceName, 'Thalmic MyoBand')
    set(handles.pm_sampleRate, 'Value', 9);
    set(handles.ComPortType, 'Value', 1);
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

if isOTB400(deviceName)
    if strcmp(deviceName, 'OTB400_HD')
        choice = questdlg('Select number of channels:', 'OTB400 HD', '64', '128', '64');
        if isempty(choice), return; end
        nChSelected = str2double(choice);
        [electrodes, ok] = OTB400_SelectElectrodes(nChSelected);
        if ~ok, return; end
        handles.nCh = nChSelected;
        handles.vCh = 1:nChSelected;
        handles.OTB400Electrodes = electrodes;
        set(handles.et_chs, 'String', choice);
    else
        handles.nCh = 8;
        handles.vCh = 1:8;
        set(handles.et_chs, 'String', '8');
    end
    
    srList = cellstr(get(handles.pm_sampleRate, 'String'));
    idxSR = find(strcmp(srList, '2048'), 1);
    if isempty(idxSR)
        srList{end+1} = '2048';
        set(handles.pm_sampleRate, 'String', srList);
        idxSR = numel(srList);
    end
    set(handles.pm_sampleRate, 'Value', idxSR);
    comList = cellstr(get(handles.ComPortType, 'String'));
    idxCOM = find(strcmp(comList, 'COM'), 1);
    if ~isempty(idxCOM), set(handles.ComPortType, 'Value', idxCOM); end
    set(handles.ComPortName, 'String', '3');
    set(handles.ComPortName, 'Enable', 'on');

    otDuration = 120;
    try
        if contains(deviceName, 'HD')
            electrodeConfig = handles.OTB400Electrodes;
            objOT = OT_Acquire('hd', handles.nCh, otDuration, electrodeConfig);
        else
            objOT = OT_Acquire('bipolar', handles.nCh, otDuration);
        end
        handles.objOT = objOT;
    catch ME
        errordlg(sprintf('Failed to initialize OTB400: %s', ME.message), 'OTB400 Error');
    end
end

if strcmp(deviceName, 'SQ+')
    choice = questdlg('Select SQ+ configuration:', 'SQ+ Mode', ...
                      '8 Channels (Bipolar)', '64 Channels (Matrix)', '8 Channels (Bipolar)');
    if isempty(choice), choice = '8 Channels (Bipolar)'; end
    
    if strcmp(choice, '64 Channels (Matrix)')
        handles.nCh = 64;
        handles.vCh = 1:64;
        set(handles.et_chs, 'String', '64');
    else
        handles.nCh = 8;
        handles.vCh = 1:8;
        set(handles.et_chs, 'String', '8');
    end
    
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
    if ~isempty(idxCOM), set(handles.ComPortType, 'Value', idxCOM); end
    handles.objSQ = [];
end

guidata(hObject, handles);

function pm_name_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
deviceNames = {'AD2','AD3','MyoAmpF4F1','MyoAmpF4F2','MyoAmpF4F7','MyoAmpF4F7_Shielded','NeuroAmpF8F1','RHA2216','RHA2132','ADS1299','ADS_BP','Thalmic MyoBand','ALC-16chs','ALC-24chs', 'ADS_BP4', 'LimbMate', 'OTB400_HD', 'OTB400_bipolar', 'SQ+'};
set(hObject,'String',deviceNames);
set(hObject,'Value',5);

function uipanel3_CreateFcn(hObject, eventdata, handles)
function prepare_Callback(hObject, eventdata, handles)
function edit13_Callback(hObject, eventdata, handles)
function edit13_CreateFcn(hObject, eventdata, handles)
function edit14_Callback(hObject, eventdata, handles)
function edit14_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit15_Callback(hObject, eventdata, handles)
function edit15_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function et_chs_Callback(hObject, eventdata, handles)
function et_chs_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function cb_trainVRE_Callback(hObject, eventdata, handles)
set(handles.cb_VRELeftHand,'Enable', 'on');

function ComPortType_Callback(hObject, eventdata, handles)
contents = cellstr(get(handles.ComPortType,'String'));
ComPortType = contents{get(handles.ComPortType,'Value')};
if strcmp(ComPortType,'COM')
    set(handles.ComPortName,'Enable', 'on');
else
    set(handles.ComPortName,'Enable', 'off');
end

function ComPortType_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function cb_VRELeftHand_Callback(hObject, eventdata, handles)
function ComPortName_Callback(hObject, eventdata, handles)
function ComPortName_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function cb_offset_Callback(hObject, eventdata, handles)
function cb_recFeatures_Callback(hObject, eventdata, handles)

function cb_acceleGlove_Callback(hObject, eventdata, handles)
if get(handles.cb_acceleGlove,'Value') == 1
    set(handles.et_AGPort, 'Visible', 'on');
    set(handles.lb_AGPort, 'Visible', 'on');
else
    set(handles.et_AGPort, 'Visible', 'off');
    set(handles.lb_AGPort, 'Visible', 'off');
end

function et_AGPort_Callback(hObject, eventdata, handles)
function et_AGPort_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function pm12_Callback(hObject, eventdata, handles)
function pm12_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function pm13_Callback(hObject, eventdata, handles)
function pm13_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function cb_compressionEnable_Callback(hObject, eventdata, handles)
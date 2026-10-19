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
% GUI for AFE Selection
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 20xx-xx-xx / Max Ortiz  / Creation
% 2013-08-23 / Morten Kristoffersen / Trimmed the interface down to one
% 2013-09-20 / Pontus Lövinger  / Added the option for ramp recording
% 2014-11-10 / Enzo Mastinu / include the code for ADS1299 AFE
% 2015-11-27 / Enzo Mastinu / It has been added the possibility to repeat
% 2017-09-25 / Simon Nilsson  / Added AFE selection modes for HD-EMG
% 2018-02-24 / Adam Naber / Device name list is now set in this file
% 2019-03-06 / Bahareh Ahkami / Bar plot added to the system

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
handles.objOT  = [];
handles.objSQ  = [];
handles.adapter = [];

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GUI_AFEselection wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GUI_AFEselection_OutputFcn(hObject, eventdata, handles) 
% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pb_record.
function pb_record_Callback(hObject, eventdata, handles)
global offsetDelete;
offsetDelete = get(handles.cb_offset,'Value');

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

% Communication Port
contents = cellstr(get(handles.ComPortType,'String'));
ComPortType=contents{get(handles.ComPortType,'Value')};
AFE_settings.ComPortType=ComPortType;

if strcmp(AFE_settings.ComPortType,'COM')
    ComPortName = get(handles.ComPortName,'String');
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

AFE_settings.prepare      = get(handles.prepare,'Value');

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
% --- DIAGNOSTIC ---
fprintf('\n=== DEBUG pb_record_Callback ===\n');
fprintf('deviceName: class=%s, value=%s\n', class(deviceName), char(deviceName));
fprintf('handles.lmName: "%s"\n', handles.lmName);
fprintf('handles.objLM: class=%s, isempty=%d\n', class(handles.objLM), isempty(handles.objLM));
if isfield(AFE_settings, 'objLM')
    fprintf('AFE_settings.objLM: class=%s, isempty=%d\n', class(AFE_settings.objLM), isempty(AFE_settings.objLM));
else
    fprintf('AFE_settings.objLM: NOT PRESENT\n');
end
fprintf('isLimbMATE(char(deviceName)): %d\n', isLimbMATE(char(deviceName)));
fprintf('================================\n\n');

% ---------------------------------------------------------
% ADAPTER PATTERN: Instantiate the Adapter via the Factory
% ---------------------------------------------------------
% ---------------------------------------------------------
% ADAPTER PATTERN: Instantiate the Adapter via the Factory
% ---------------------------------------------------------
if ~isfield(handles, 'adapter') || isempty(handles.adapter)
    handles.adapter = DeviceFactory(deviceName, nCh, sF, handles, AFE_settings);
    guidata(hObject, handles);
end
AFE_settings.adapter = handles.adapter;

switch mode
    case 0
        if rampStatus
            [rampMin, minData] = ObtainRampMin(hGUI_Rec,AFE_settings,get(handles.cb_trainVRE,'Value'));
            [rampMax, maxData] = ObtainRampMax(nM,mov,hGUI_Rec,AFE_settings,get(handles.cb_trainVRE,'Value'),vreMovements, get(handles.cb_VRELeftHand,'Value'));
            rampParams =  {rampMin rampMax minData maxData};
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
        [cdata, sF, sT, sdata] = FastRecordingSession(hGUI_Rec,AFE_settings);
        tempdata = cdata;
        save('cdata.mat','cdata','tempdata','sdata','sF','sT','nCh','ComPortType','deviceName','plotType','featureType');
    case 2
        GUI_Recordings_Image('startRecording',hGUI_Rec,AFE_settings);
    case 3
        startBiofeedback(hGUI_Rec,AFE_settings);
end

% --- Executes during object creation, after setting all properties.
function pb_record_CreateFcn(hObject, eventdata, handles)

% --- Executes on button press in pb_cancel.
function pb_cancel_Callback(hObject, eventdata, handles)
close(get(hObject,'Parent'))

% --- Executes during object creation, after setting all properties.
function pb_cancel_CreateFcn(hObject, eventdata, handles)

% --- Executes on button press in default.
function default_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function default_CreateFcn(hObject, eventdata, handles)

% --- Executes on selection change in pm_sampleRate.
function pm_sampleRate_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function pm_sampleRate_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

existing = cellstr(get(hObject, 'String'));
if ~any(strcmp(existing, '2048'))
    set(hObject, 'String', [existing(:); {'2048'}]);
end

existing = cellstr(get(hObject, 'String'));
if ~any(strcmp(existing, '2000'))
    set(hObject, 'String', [existing(:); {'2000'}]);
end

existing = cellstr(get(hObject, 'String'));
if ~any(strcmp(existing, '1000'))
    set(hObject, 'String', [existing(:); {'1000'}]);
end

function bytesSamples2_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function bytesSamples2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function bytesSamples1_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function bytesSamples1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function bytesSamples0_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function bytesSamples0_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pm_name_Callback(hObject, eventdata, handles)
contents = cellstr(get(handles.pm_name,'String'));
deviceName = contents{get(handles.pm_name,'Value')};

% Reset previous channel selection and adapters
if isfield(handles, 'nCh'), handles = rmfield(handles, 'nCh'); end
if isfield(handles, 'vCh'), handles = rmfield(handles, 'vCh'); end
if isfield(handles, 'OTB400Electrodes'), handles = rmfield(handles, 'OTB400Electrodes'); end
handles.adapter = []; 

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
    if ~isempty(idxCOM), set(handles.ComPortType, 'Value', idxCOM); end
    set(handles.ComPortName, 'String', '3');
    set(handles.ComPortName, 'Enable', 'on');
    
    sqDuration = 120;
    try
        objSQ = Sessantaquattro_Acquire(handles.nCh, sqDuration, 45454);
        handles.objSQ = objSQ;
    catch ME
        errordlg(sprintf('Failed to initialize SQ+: %s', ME.message), 'SQ+ Error');
    end
end

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
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
deviceNames = {'AD2','AD3','MyoAmpF4F1','MyoAmpF4F2','MyoAmpF4F7','MyoAmpF4F7_Shielded','NeuroAmpF8F1','RHA2216','RHA2132','ADS1299','ADS_BP','Thalmic MyoBand','ALC-16chs','ALC-24chs', 'ADS_BP4', 'LimbMate', 'OTB400_HD', 'OTB400_bipolar', 'SQ+'};
set(hObject,'String',deviceNames);
set(hObject,'Value',5);

% --- Executes during object creation, after setting all properties.
function uipanel3_CreateFcn(hObject, eventdata, handles)

% --- Executes on button press in prepare.
function prepare_Callback(hObject, eventdata, handles)

% --- Executes on button press in edit13.
function edit13_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function edit13_CreateFcn(hObject, eventdata, handles)

function edit14_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function edit14_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit15_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function edit15_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function et_chs_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function et_chs_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in cb_trainVRE.
function cb_trainVRE_Callback(hObject, eventdata, handles)
set(handles.cb_VRELeftHand,'Enable', 'on');

% --- Executes on selection change in ComPortType.
function ComPortType_Callback(hObject, eventdata, handles)
contents = cellstr(get(handles.ComPortType,'String'));
ComPortType = contents{get(handles.ComPortType,'Value')};
if strcmp(ComPortType,'COM')
    set(handles.ComPortName,'Enable', 'on');
else
    set(handles.ComPortName,'Enable', 'off');
end

% --- Executes during object creation, after setting all properties.
function ComPortType_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in cb_VRELeftHand.
function cb_VRELeftHand_Callback(hObject, eventdata, handles)

function ComPortName_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function ComPortName_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in cb_offset.
function cb_offset_Callback(hObject, eventdata, handles)

% --- Executes on button press in cb_recFeatures.
function cb_recFeatures_Callback(hObject, eventdata, handles)

% --- Executes on button press in cb_acceleGlove.
function cb_acceleGlove_Callback(hObject, eventdata, handles)
if get(handles.cb_acceleGlove,'Value') == 1
    set(handles.et_AGPort, 'Visible', 'on');
    set(handles.lb_AGPort, 'Visible', 'on');
else
    set(handles.et_AGPort, 'Visible', 'off');
    set(handles.lb_AGPort, 'Visible', 'off');
end

function et_AGPort_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function et_AGPort_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in pm12.
function pm12_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function pm12_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in pm13.
function pm13_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function pm13_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in cb_compressionEnable.
function cb_compressionEnable_Callback(hObject, eventdata, handles)
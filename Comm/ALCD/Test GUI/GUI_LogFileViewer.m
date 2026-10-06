function varargout = GUI_LogFileViewer(varargin)
% GUI_LOGFILEVIEWER MATLAB code for GUI_LogFileViewer.fig
%      GUI_LOGFILEVIEWER, by itself, creates a new GUI_LOGFILEVIEWER or raises the existing
%      singleton*.
%
%      H = GUI_LOGFILEVIEWER returns the handle to a new GUI_LOGFILEVIEWER or the handle to
%      the existing singleton*.
%
%      GUI_LOGFILEVIEWER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI_LOGFILEVIEWER.M with the given input arguments.
%
%      GUI_LOGFILEVIEWER('Property','Value',...) creates a new GUI_LOGFILEVIEWER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI_LogFileViewer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI_LogFileViewer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUI_LogFileViewer

% Last Modified by GUIDE v2.5 28-Jun-2016 10:35:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_LogFileViewer_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_LogFileViewer_OutputFcn, ...
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


% --- Executes just before GUI_LogFileViewer is made visible.
function GUI_LogFileViewer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI_LogFileViewer (see VARARGIN)

% Choose default command line output for GUI_LogFileViewer
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GUI_LogFileViewer wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GUI_LogFileViewer_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pb_load.
function pb_load_Callback(hObject, eventdata, handles)
% hObject    handle to pb_load (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
    clear all
    close all

    % Dialog box to open a LogFile
    [file, path] = uigetfile({'*.mat'});
    if ~isequal(file, 0)
        [pathstr,name,ext] = fileparts(file);
        if(strcmp(ext,'.mat'))
            load([path,file]);
            if (~exist('LogFile_raw','var') && ~exist('SDcardValues','var'))   
                disp('Not a valid LogFile');
                errordlg('Not a valid LogFile','Error');
                return;   
            end
        else
            disp('Not a valid LogFile');
            errordlg('Not a valid LogFile','Error');
            return; 
        end
    end
    
    control = questdlg('DC or PR control?',	'Specify Control','Direct Control','Pattern Recognition','');
    if(strcmp(control,'Direct Control'))
        % Dialog box to open a SETTINGS file
        [file, path] = uigetfile({'*.mat'});
        if ~isequal(file, 0)
            [pathstr,name,ext] = fileparts(file);
            if(strcmp(ext,'.mat'))
                load([path,file]);
                if (~exist('movs','var'))   
                    disp('Not a valid Settings file');
                    errordlg('Not a valid Settings file','Error');
                    return;   
                end
            else
                disp('Not a valid Settings file');
                errordlg('Not a valid Settings file','Error');
                return; 
            end
        end
    else
        movs = 0;
    end
    
    if exist('LogFile_raw','var')
        processedLogFile = loadLogFile(control, LogFile_raw, movs);     
        
    else 
        processedLogFile = loadLogFile(control, SDcardValues, movs);     
    end
      
    save('processedLogFile.mat','processedLogFile');
    
    plotLogFile(control, processedLogFile); 
 
      
%% LOG FILE 
% LogUnitOB 3/01/2017
% typedef struct
% {
% 	unsigned char powerOn;
% 	unsigned char outIdx;
% 	unsigned char activLevel;
% 	unsigned char stimFreq;
% 	unsigned char sensors[4];
% 	float32_t vBattery;
% 	float32_t temperature;
% 	int32_t imuSample[6];
% 	float32_t tmabs1;
% 	float32_t tmabs2;
% } logUnitOB;
function processedLogFile = loadLogFile(control, LogFile_raw, movs)
    %% Convert data from SD card into bytes structure
    numBlocks = size(LogFile_raw,1);       
    dimLogUnit = 48;
    numLogUnits = 1;
    LogUnits_raw = [];
    for i = 1:numBlocks
        indxs = 1:dimLogUnit:480;
        temp = LogFile_raw(i,1:indxs(end)+(dimLogUnit-1));
        LogUnits_raw = [LogUnits_raw ; reshape(temp,dimLogUnit,size(indxs,2))'];
    end
    LogUnits_raw(LogUnits_raw(:,1)==0,:) = [];
    numLogUnits = size(LogUnits_raw,1);
    powerOns = sum(LogFile_raw(:,1)>127);
    
    %% Convert LogUnits_raw into more readable LogUnits
    % powerOn
    powerOn = zeros(1,numLogUnits);
    powerOn(LogUnits_raw(:,1)==255) = 1;
    LogUnits.powerOn = powerOn';
    % outIdx
    LogUnits.outIdx = LogUnits_raw(:,2);
    % activLevel
    LogUnits.activLevel = LogUnits_raw(:,3);
    % stimFreq
    LogUnits.stimFreq = LogUnits_raw(:,4);
    % sensors
    LogUnits.sensors.pad1 = LogUnits_raw(:,5);
    LogUnits.sensors.pad2 = LogUnits_raw(:,6);
    LogUnits.sensors.pad3 = LogUnits_raw(:,7);
    LogUnits.sensors.strom = LogUnits_raw(:,8);
    % vBattery
    for i = 1:numLogUnits
        vBattery(i) = typecast(uint8(LogUnits_raw(i,9:12)),'single');
    end
    LogUnits.vBattery = vBattery';
    % vBattery
    for i = 1:numLogUnits
        temperature(i) = typecast(uint8(LogUnits_raw(i,13:16)),'single');
    end
    LogUnits.sensors.temperature = temperature';
    % IMU accX
    for i = 1:numLogUnits
        accX(i) = typecast(uint8(LogUnits_raw(i,17:20)),'int32');
    end
    LogUnits.sensors.accX = accX';
    % IMU accY
    for i = 1:numLogUnits
        accY(i) = typecast(uint8(LogUnits_raw(i,21:24)),'int32');
    end
    LogUnits.sensors.accY = accY';
    % IMU accZ
    for i = 1:numLogUnits
        accZ(i) = typecast(uint8(LogUnits_raw(i,25:28)),'int32');
    end
    LogUnits.sensors.accZ = accZ';
    % IMU gyrX
    for i = 1:numLogUnits
        gyrX(i) = typecast(uint8(LogUnits_raw(i,29:32)),'int32');
    end
    LogUnits.sensors.gyrX = gyrX';
    % IMU gyrY
    for i = 1:numLogUnits
        gyrY(i) = typecast(uint8(LogUnits_raw(i,33:36)),'int32');
    end
    LogUnits.sensors.gyrY = gyrY';
    % IMU gyrZ
    for i = 1:numLogUnits
        gyrZ(i) = typecast(uint8(LogUnits_raw(i,37:40)),'int32');
    end
    LogUnits.sensors.gyrZ = gyrZ';
    % tmabs1
    for i = 1:numLogUnits
        tmabs1(i) = typecast(uint8(LogUnits_raw(i,41:44)),'single');
    end
    LogUnits.tmabs1 = tmabs1';
    % tmabs2
    for i = 1:numLogUnits
        tmabs2(i) = typecast(uint8(LogUnits_raw(i,45:48)),'single');
    end
    LogUnits.tmabs2 = tmabs2';
    
    if(strcmp(control,'Direct Control'))
        if(movs.openHand.active)
            movements.openHand.channel = movs.openHand.CHinput;
            movements.openHand.MVClevel = movs.openHand.MVClevel;
            movements.openHand.motorThresh = movs.openHand.motorThresh;
        end
        if(movs.closeHand.active)
            movements.closeHand.channel = movs.closeHand.CHinput;
            movements.closeHand.MVClevel = movs.closeHand.MVClevel;
            movements.closeHand.motorThresh = movs.closeHand.motorThresh;
        end
        processedLogFile.movements = movements;
    end
    
    sF = 1/0.05;                                           % Prediction (and updateLog) every 50ms
    time = numLogUnits*0.05;                               % Overall time in seconds
    processedLogFile.time = time;      
    processedLogFile.tv = 0:1/sF:time-1/sF;                % Create vector of time
    processedLogFile.numLogUnits = numLogUnits;
    processedLogFile.LogUnits = LogUnits;
    processedLogFile.dimLogUnit = dimLogUnit;
    processedLogFile.powerOns = powerOns;
    
    
function plotLogFile(control, processedLogFile)

    %% plot tmabs/thresholds/activation vs time
    figure(1)
    plot(processedLogFile.tv, processedLogFile.LogUnits.tmabs2, 'r')
    ylabel('tmabs')
    xlabel('time [s]')
    hold
    if(strcmp(control,'Direct Control'))
        %% plot thresholds of activation
        MVCopen = ones(processedLogFile.numLogUnits,1)*processedLogFile.movements.openHand.MVClevel;
        MVCclose = ones(processedLogFile.numLogUnits,1)*processedLogFile.movements.closeHand.MVClevel;
        threshopen = ones(processedLogFile.numLogUnits,1)*processedLogFile.movements.openHand.motorThresh;
        threshclose = ones(processedLogFile.numLogUnits,1)*processedLogFile.movements.closeHand.motorThresh;
        plot(processedLogFile.tv, MVCopen, 'k--')
        plot(processedLogFile.tv, MVCclose, 'r--')
        plot(processedLogFile.tv, threshopen, 'k-.')
        plot(processedLogFile.tv, threshclose, 'r-.')
        plot(processedLogFile.tv, processedLogFile.LogUnits.tmabs1, 'k')
        title('open and close hand movements vs time')
        legend('open hand channel (tmabs)', 'close hand channel (tmabs)', 'MVC open hand', 'MVC close hand', 'activation threshold open hand', 'activation threshold close hand')
    else
        title('tmabs1 and tmabs2 vs time')
        legend('tmabs1', 'tmabs2')
    end
    
    %% plot sensors vs time
    figure(2)
    ax1 = subplot(2,1,1);
    plot(processedLogFile.tv, processedLogFile.LogUnits.sensors.strom, 'b')
    title('current sensor vs time')
    ylabel('value')
    xlabel('time [s]')
    legend('CURRENT')
    ax2 = subplot(2,1,2);
    plot(processedLogFile.tv, processedLogFile.LogUnits.sensors.pad1, 'r')
    hold
    plot(processedLogFile.tv, processedLogFile.LogUnits.sensors.pad2, 'm')
    plot(processedLogFile.tv, processedLogFile.LogUnits.sensors.pad3, 'c')
    title('pad sensor values vs time')
    ylabel('value')
    xlabel('time [s]')
    legend('PAD1', 'PAD2', 'PAD3')
    linkaxes([ax1,ax2],'xy');
    
    if(strcmp(control,'Direct Control'))
        %% plot tmabs/thresholds/activation/strom vs time
        figure(3) 
        threshopen_norm = threshopen/(max(processedLogFile.LogUnits.tmabs1)/max(processedLogFile.LogUnits.sensors.strom));
        threshclose_norm = threshclose/(max(processedLogFile.LogUnits.tmabs1)/max(processedLogFile.LogUnits.sensors.strom));
        tmabs1_norm = processedLogFile.LogUnits.tmabs1/(max(processedLogFile.LogUnits.tmabs1)/max(processedLogFile.LogUnits.sensors.strom));
        tmabs2_norm = processedLogFile.LogUnits.tmabs2/(max(processedLogFile.LogUnits.tmabs1)/max(processedLogFile.LogUnits.sensors.strom));
        plot(processedLogFile.tv, threshopen_norm, 'k-.')
        hold
        plot(processedLogFile.tv, threshclose_norm, 'r-.')
        plot(processedLogFile.tv, tmabs1_norm, 'k')
        plot(processedLogFile.tv, tmabs2_norm, 'r') 
        plot(processedLogFile.tv, processedLogFile.LogUnits.sensors.strom, 'b')
        title('current sensor vs time')
        ylabel('Sensor Value')
        xlabel('time [s]')
        legend('activation threshold open hand', 'activation threshold close hand', 'open hand channel (tmabs)', 'close hand channel (tmabs)', 'current')
    end
    
    %% plot vBattery vs time
    figure(4)
    vBatt = processedLogFile.LogUnits.vBattery;
    plot(processedLogFile.tv, vBatt)
    powerONs = find(processedLogFile.LogUnits.powerOn == 1)*0.05;
    if size(powerONs,1) >= 1 
        for i = 1:size(powerONs,1)
            line([powerONs(i) powerONs(i)],[min(vBatt)-0.5 max(vBatt)+0.5],'Color',[1 0 0]);
        end
        set(gca,'YLim', [min(vBatt)-0.5 max(vBatt)+0.5]);
    end 
    title('battery voltage vs time')
    ylabel('[V]')
    xlabel('time [s]')
    legend('vBattery', 'system powerONs')
    
    %% plot temperature vs time
    figure(5)
    temp = processedLogFile.LogUnits.sensors.temperature;
    plot(processedLogFile.tv, temp)
    powerONs = find(processedLogFile.LogUnits.powerOn == 1)*0.05;
    if size(powerONs,1) >= 1 
        for i = 1:size(powerONs,1)
            line([powerONs(i) powerONs(i)],[min(temp)-0.5 max(temp)+0.5],'Color',[1 0 0]);
        end
        set(gca,'YLim', [min(temp)-0.5 max(temp)+0.5]);
    end 
    title('MCU temperature vs time')
    ylabel('[V]')
    xlabel('time [s]')
    legend('temperature', 'system powerONs')
    
    %% plot accelerometer vs time
    figure(6)
    subplot(3,1,1)
    suptitle('Accelerometer vs time')
    plot(processedLogFile.tv, LogUnits.sensors.accX)
    ylabel('X')
    xlabel('time [s]')
    subplot(3,1,2)
    plot(processedLogFile.tv, LogUnits.sensors.accY)
    ylabel('Y')
    xlabel('time [s]')
    subplot(3,1,3)
    plot(processedLogFile.tv, LogUnits.sensors.accZ)
    ylabel('Z')
    xlabel('time [s]')
    
    %% plot gyroscope vs time
    figure(7)
    subplot(3,1,1)
    suptitle('Gyroscope vs time')
    plot(processedLogFile.tv, LogUnits.sensors.gyrX)
    ylabel('X')
    xlabel('time [s]')
    subplot(3,1,2)
    plot(processedLogFile.tv, LogUnits.sensors.gyrY)
    ylabel('Y')
    xlabel('time [s]')
    subplot(3,1,3)
    plot(processedLogFile.tv, LogUnits.sensors.gyrZ)
    ylabel('Z')
    xlabel('time [s]')

    
%     %% plot close/stimFreq vs time
%     figure(7)
%     tmabs2_norm = processedLogFile.LogUnits.tmabs2/(max(processedLogFile.LogUnits.tmabs1)/max(processedLogFile.LogUnits.stimFreq));
%     threshclose_norm = threshclose/(max(processedLogFile.LogUnits.tmabs1)/max(processedLogFile.LogUnits.stimFreq));
%     plot(processedLogFile.tv, threshclose_norm, 'r-.')
%     hold
%     plot(processedLogFile.tv, tmabs2_norm, 'r') 
%     plot(processedLogFile.tv, processedLogFile.LogUnits.stimFreq, 'b')
%     title('stimulation frequency for sensory feedback vs time')
%     ylabel('[Hz]')
%     xlabel('time [s]')
%     legend('activation threshold close hand', 'close hand channel (tmabs)', 'stimulation frequency')
 
    
    
%% Routines to clean the LogFile from useless data, zeros, etc

% t = (SDcardValues(:,1)>0);
% LogFile_raw = SDcardValues((SDcardValues(:,1)>0),:);

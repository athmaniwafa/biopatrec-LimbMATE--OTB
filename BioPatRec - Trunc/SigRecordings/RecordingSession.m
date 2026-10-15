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
% ------------------- Function Description ------------------
% Function to Record Exc Sessions
%
% --------------------------Updates--------------------------
% 2009-04-17 / Max Ortiz  / Creation
% 2009-06-29 / Max Ortiz  / A dummy repeticion added before start recording
% 2011-06-00 / Per and Gustav  / Added the analog front end sections
% 2011-06-29 / Max Ortiz  / Optimization to be integrated in the whole system and Fixed to new coding standard.
% Any filtering was removed from this routine
% Filtering and any other signal processing should be done in
% a singal treatment routine
% 2011-08-04 / Max Ortiz  / The 10% of extra indication for the user
% to contract was removed.
% 2012-02-xx / Max Ortiz  / Upgrade DAQ routines for MATLAB R2011b, SBI
% Old version was kept as:
% RecordinSession_Legacy
% 2012-03-27 / Max Ortiz  / Bug fixed when an arbitrary selection of channels
% However, the NI doesn't allow to skip channels
% 2012-04-30 / Max Ortiz  / The possibility of simultaneous recordings was
% was removed since it didn't worked with the SBI
% in the current implementation. To see how the
% simultaneus recordings were done, see
% RecordingSession_Legacy
% 2012-12-07 / Nichlas Sander / Added VRE as an option during training.
% Movements to display are loaded in
% varargin{8}. This since previous movements
% were simply loaded as strings.
% 2013-03-07 / Nichlas Sander / When training Arm Flex/Extend the system
% will automatically change the view so the
% user can see the movement.
% 2013-08-23 / Morten Kristoffersen / Updated the recording sessions to support
% the new GUI_AFESelection structure
% 2014-11-10 / Enzo Mastinu / include routines for ADS1299 AFE recordings using
% the "afeSettings.name" property to differentiate them,
% add the ramp routines, set the time window
% size to be samplingTime/100, delete the
% peeking time field in the GUI, RMS mean is done
% "manually" for Matlab compatibility
% reasons
% 2015-01-12 / Enzo Mastinu / Divided the RecordingSession function into
% several functions: ConnectDevice(),
% SetDeviceStartAcquisition(),
% Acquire_tWs(), StopAcquisition().
% These functions has been moved into COMM/AFE
% folder in separate files. All the parameters
% pass and global variables has been optimized
% due to the new functions. Now this file is
% totally independent from the inner working of
% the all devices. In this way, to introduce a
% new device for acquisition you need to modify
% the files in COMM folder, leaving the recording
% session file almost inalterate.
% 2015-01-26 / Enzo Mastinu / A new GUI_Recordings has been developed for the
% BioPatRec_TRE release. Now it is possible to
% plot more then 8 channels at the same moment, for
% time and frequency plots both. It is faster and
% perfectly compatible with the ramp recording
% session. At the end of the recording session it
% is possible to check all channels individually,
% apply offline data process as feature extraction or filter etc.
% 2015-10-28 / Martin Holder / >2014b plot interface fixes
% 2015-11-27 / Enzo Mastinu  / It has been added the possibility to repeat 
%                              the same movement recording if needed.
% 2016-05-11 / Niclas Nilsson / DataAnalysis was added
% 2017-02-28 / Simon Nilsson / Changed time window size to 200 samples
                            % when acquiring data using the RHA2132 for
                            % the buffered acquisition mode to work well.
% 2018-07-09 / Andreas Eiler / Added function to change current folder to load
                            % Myo.dll file correctly
% 2018-09-26 / Adam naber / Added sensorData field for additional sensors
% 2019-03-06 / Bahareh Ahkami / Bar plot added to the system                         
% 20xx-xx-xx / Author  / Comment



function [cdata, sF, sensorData] = RecordingSession(varargin)

global       handles;
global       allData;
global       timeStamps;
global       samplesCounter;
allData      = [];
nM           = varargin{1};
nR           = varargin{2};
cT           = varargin{3};
rT           = varargin{4};
% mov          = varargin{5};
handles      = varargin{6};
afeSettings  = varargin{7};
trainWithVr  = varargin{8};
vreMovements = varargin{9};
vreLeftHand  = varargin{10};
movRepeatDlg = varargin{11};
useLeg      = varargin{12};
rampStatus   = varargin{13};
saveRec     = true;

handles.OTBRecordingMap = OTB400_OpenRecordingMap(afeSettings, handles);

if sum(strcmp(varargin,'replace')) > 0
    saveRec = false;
end

% Get required informations from afeSettings structure
nCh          = afeSettings.channels;
sF           = afeSettings.sampleRate;
deviceName   = afeSettings.name;
ComPortType  = afeSettings.ComPortType;
plotType     = afeSettings.plotType;
featureType  = afeSettings.featureType;

% --- Diagnostic: shows exactly what deviceName BioPatRec passes to the LM branch ---
fprintf('DEBUG deviceName=[%s]  length=%d  class=%s\n', ...
        char(deviceName), numel(char(deviceName)), class(deviceName));

if isfield(afeSettings,'compressData')
        compressData = afeSettings.compressData;
    else
        compressData = 0;
    end
if isfield(afeSettings,'vChannels')
    vCh = afeSettings.vChannels;
    handles.vCh = vCh;
end
if strcmp(ComPortType, 'COM')
    ComPortName = afeSettings.ComPortName;
end

% Save back acquisition parameters to the handles
handles.nR          = nR;
handles.cT          = cT;
handles.rT          = rT;
handles.nCh         = nCh;
handles.sF          = sF;
handles.plotType    = plotType;
handles.featureType = featureType;
handles.ComPortType = ComPortType;
handles.compressData = compressData;
if strcmp(ComPortType, 'COM')
    handles.ComPortName = ComPortName;
end
handles.deviceName  = deviceName;
handles.rampStatus  = rampStatus;
handles.fast        = 0;

% Initialization of sampling time
sTall         = (cT+rT)*nR;
sT            = cT+rT;
handles.sTall = sTall;
handles.sT    = sT;

% Setting for data peeking
% Time window size
% Window of 100 samples works usually well
if contains(deviceName, 'OTB400')
    tWs = 256; % Time window samples
    tW = tWs/sF;

elseif strcmp(deviceName, 'SQ+')
    tWs = 200; % 200 ms at 1000 Hz
    tW = tWs/sF;

else
    tW = 100/sF;
    if tW < 0.1
	    tW = 0.1; % to avoid delays due to graphics
    end
    
    if mod(sT,tW) > 0
        errordlg('Please, the time window size must be a multiple of the recording time. Select a proper time window size!')
        return
    end
    tWs           = tW*sF;   % Time window samples
end

handles.tWs = tWs;
timeStamps = (0:tWs-1)/sF; % Create vector of time

if contains(deviceName, 'OTB400')

    nWindows = sT * sF / tWs;

    if abs(nWindows - round(nWindows)) > 1e-9
        error(['OTB400: recording time must be a multiple of %.3f seconds.'], tW);
    end

end

%% Start the connection with Limb-MATE
if (strcmp(deviceName, 'LM 1') || strcmp(deviceName, 'LM 2')  || strcmp(deviceName, 'LM 3') || strcmp(deviceName, 'LM 14'))
    % Create object for device and connection
    objLM = LimbMATE();

    % Disable the driver's built-in plotting path.
    % BioPatRec draws its own plots; the driver must run "headless".
    objLM.graphical_information.enable_graph = 0;
    objLM.graphical_information_session.enable_graph = 0;

    % Connect to Bluetooth USB stick
    objLM.connectBTdongle(ComPortName);

    % Find Bluetooth Devices and Connect to BT device with name "LMATE"
    BTspeed = "2";
    objLM.connectBTdevice(deviceName{1,1}, BTspeed);

    % Read the acquisition parameters currently stored on the board.
    % The LimbMATE GUI calls this right after connecting; BioPatRec must
    % do the same, otherwise properties like packages_per_TW_increment
    % remain at defaults and the sample reader loops forever.
    objLM.getAcquisitionParams();

    % --- diagnostic ---
    fprintf('DEBUG tw_samples (decoded) = %d, two_samples (decoded) = %d\n', ...
            objLM.tw_samples, objLM.two_samples);
    fprintf('DEBUG channels_encoded = %d, enable_testmode = %d, enabled_filters = %d\n', ...
            objLM.channels_encoded, objLM.enable_testmode, objLM.enabled_filters);

    % --- BioPatRec EMG-only setup ---
    % Force test mode OFF so BioPatRec does not record the onboard
    % square wave. Must be set before startAcquisitionEMG, which sends
    % this value to the board.
    objLM.enable_testmode = 0;

    % Configure the AFE: sample rate from BioPatRec settings, gain 4,
    % differential (gel) electrodes.
    objLM.setSampleFreqGain(sF, 4);
    objLM.setElectrodesConfig("Differential");

    % All 8 channels enabled. Encoded as bitmask byte 0xFF.
    active_channels_encoded = uint8(255);

    % One BioPatRec time window, no overlap.
    samples_tw_encoded         = uint8(tWs);
    samples_tw_overlap_encoded = uint8(0);

    % Start streaming to the PC.
    objLM.startAcquisitionEMG(1, active_channels_encoded, ...
                              samples_tw_encoded, samples_tw_overlap_encoded);

    % Manually populate the TW bookkeeping that getEMG_data_samples_float_plot
    % would normally set. BioPatRec bypasses that function and calls
    % startAcquisitionEMG directly, so these must be provided here.
    % Driver granularity is 5 samples per BT packet.
    objLM.packages_per_TW           = tWs / 5;
    objLM.packages_per_TW_increment = tWs / 5;

    fprintf('DEBUG packages_per_TW = %d, packages_per_TW_increment = %d\n', ...
            objLM.packages_per_TW, objLM.packages_per_TW_increment);
end

%% Start connection with OTB400

if contains(deviceName, 'OTB400')

    otDuration = max(120, sTall + 20);

    if contains(deviceName, 'HD')
        % Read electrode configuration from GUI
        if ~isfield(afeSettings, 'OTB400Electrodes')
            error('OTB400 HD: electrode configuration missing.');
        end

        electrodeConfig = afeSettings.OTB400Electrodes;

        objOT = OT_Acquire('hd', nCh, otDuration, electrodeConfig);

        fprintf('OTB400 HD: %d channels configured\n', nCh);
        disp(objOT.config);

    else
        % Bipolar acquisition
        objOT = OT_Acquire('bipolar', nCh, otDuration);
    end
    handles.objOT = objOT;
end

%% Start connection with Sessantaquattro+ (TCP)
if strcmp(deviceName, 'SQ+')
    sqDuration = max(120, sTall + 20);
    objSQ = Sessantaquattro_Acquire(nCh, sqDuration, 45454);
    handles.objSQ = objSQ;
end

% Safely assign handles.objLM even when the LM branch did not run
if exist('objLM', 'var')
    handles.objLM = objLM;
else
    handles.objLM = [];
end

%% Initialize GUI..

% Initialization of the VRE for training if required
if trainWithVr
    % Parameters for the movement in the VRE
    distance = 60;
    numJumps = 30;
    % Open and connect to the VRE
    open('Virtual Reality.exe');
    handles.vreCommunication = tcpip('127.0.0.1',23068,'NetworkRole','server');
    fopen(handles.vreCommunication);
    
    %Set up VRE to not return any data. This will speed up the
    %communication.
    fwrite(handles.vreCommunication,sprintf('%c%c%c%c%c','c',char(7),char(0),char(0),char(0)));
    
    if(useLeg == 1)
        fwrite(handles.vreCommunication,sprintf('%c%c%c%c','c',char(1),char(2),char(1)));
    else
        fwrite(handles.vreCommunication,sprintf('%c%c%c%c','c',char(1),char(1),char(1)));
    end
    
    % Send value to show Arm if that value is chosen.
    sent = 0;
    for i = 1:nM
        for j = 1:length(vreMovements{i})
            movement = vreMovements{i}{j};
            if ismember(movement.id,[20 21]) && sent == 0
                % The pauses is to fix a bug where the VRE would not
                % react to the commands. I believe this is because a
                % lot of commands are sent directly after each other.
                pause(0.1);
                fwrite(handles.vreCommunication,sprintf('%c%c%c%c%c','c',char(6),char(1),char(0),char(0)));
                pause(0.1);
                sent = 1;
            end
        end
    end
    
    if vreLeftHand
        fwrite(handles.vreCommunication,sprintf('%c%c%c%c%c','c',char(5),char(1),char(0),char(0)));
        pause(0.1);
    end
end

pause on;

% Offset the data on plots
ampPP = 5;
ymin = -ampPP*2/3;
ymax =  ampPP * nCh - ampPP*1/3;
sData = zeros(tWs,nCh);
fData = zeros(tWs,nCh);
offVector = 0:nCh-1;
offVector = offVector .* ampPP;
for i = 1 : nCh
    sData(:,i) = sData(:,i) + offVector(i);
    fData(:,i) = fData(:,i) + offVector(i);
end

if rampStatus
    rampParams = varargin{14};
    % make the ramp objects visible
    set(handles.a_effortPlot,'Visible','on');
    set(handles.txt_effortPlot,'Visible','on');
    % Init the effort tracking plot and draw the guide line
    if rampStatus == 1
        p_effortPlot = plot(handles.a_effortPlot,linspace(0,cT,sF*cT),linspace(0,100,sF*cT),'LineWidth',2);
        xlim(handles.a_effortPlot, [0 cT]);
    else
        p_effortPlot = plot(handles.a_effortPlot,[linspace(0,3,sF*3) linspace(3,5,sF*2) linspace(5,8,sF*3)],[linspace(0,60,sF*3) linspace(60,60,sF*2) linspace(60,0,sF*3)],'LineWidth',2);
        xlim(handles.a_effortPlot, [0 8]);
        cT = 8;
        sTall         = (cT+rT)*nR;
        sT            = cT+rT;
        handles.cT    = cT;
        handles.sTall = sTall;
        handles.sT    = sT;
    end
    ylim(handles.a_effortPlot, [0 100]);
    handles.p_effortPlot = p_effortPlot;
    axes(handles.a_effortPlot)
    hLine = line('XData', 0, 'YData', 0, 'Color', 'r', 'Marker', 'o', 'MarkerSize', 8, 'LineWidth', 2);
    handles.hLine = hLine;
end

% Initialization of progress bar
xpatch = [0 0 0 0];
ypatch = [0 0 1 1];
axes(handles.a_prog);
axis(handles.a_prog,'off');
set(handles.a_prog,'XLimMode','manual');
handles.hPatch = patch( ...
    'Parent', handles.a_prog, ...
    'XData', xpatch, ...
    'YData', ypatch, ...
    'FaceColor', 'b', ...
    'EdgeColor', 'b', ...
    'Visible', 'on');
drawnow update

% Allocation of resource to improve speed, total data
recSessionData = zeros(sF*sTall, nCh, nM);
if isfield(afeSettings,'useAcceleGlove') && afeSettings.useAcceleGlove == 1
    useAcceleGlove = 1;
    sensorData.accelerometers = zeros(18,sT/tW);
    ag_port = afeSettings.acceleGlovePort;
else
    useAcceleGlove = 0;
    sensorData.accelerometers = [];
end


%% Starting Session..

% Warning to the user
set(handles.t_msg,'String','Get ready to start: 3');
pause(1);
set(handles.t_msg,'String','Get ready to start: 2');
pause(1);
set(handles.t_msg,'String','Get ready to start: 1');
pause(1);
if(useLeg == 1) % Import Image
    relax = importdata('Img/relaxLeg.jpg');
else
    relax = importdata('Img/relax.jpg');
end
drawnow;

% Run all movements or exercise
ex = 1;
while ex <= nM
    
    timeStamps = (0:tWs-1)/sF;                                     % Timestamps used the time vector
    currentTv = 1;                                                     % Current time vector
    tV = timeStamps(currentTv):1/sF:(tW-1/sF)+timeStamps(currentTv);   % Time vector used for drawing graphics
    currentTv = currentTv - 1 + tWs;                                   % Updated everytime tV is updated
    acquireEvent.TimeStamps = tV';
    
    if rampStatus
        % Update ramp params for this exercise
        handles.RampMin = rampParams{1};
        handles.currentRampMax = rampParams{2}(ex);
    end
    
    disp(['Start ex: ' num2str(ex) ])
    
    % Warning to the user
    fileName = ['Img/' char(mov(ex)) '.jpg'];
    if ~exist(fileName,'file')
        fileName = ['Img/' 'noImage' '.png'];%'Img/relax.jpg';
    end
    
    movI = importdata(fileName);                                       % Import Image
    set(handles.a_pic,'Visible','on');                                 % Turn on visibility
    pic = image(movI,'Parent',handles.a_pic);                          % set image
    axis(handles.a_pic,'off');                                         % Remove axis tick marks
    
    % Show warning to prepare
    set(handles.t_msg,'String',['Get ready for ' mov(ex) ' in 3 s']);
    pause(1);
    set(handles.t_msg,'String',['Get ready for ' mov(ex) ' in 2 s']);
    pause(1);
    set(handles.t_msg,'String',['Get ready for ' mov(ex) ' in 1 s']);
    pause(1);
    
    % Dummy Contraction
    set(handles.t_msg,'String',mov(ex));
    if afeSettings.prepare
        if trainWithVr
            numberOfMovements = length(vreMovements{ex});
            tempJumps = numJumps/numberOfMovements;
            tempDistance = round(distance/tempJumps);
            vreString = '';
            for i = 1:numberOfMovements
                movement = vreMovements{ex}{i};
                vreString = sprintf('%s%c%c%c%c%c',vreString,char(1),char(movement.idVRE),char(movement.vreDir),char(tempDistance),char(1));
            end
            for j = 1:tempJumps
                fwrite(handles.vreCommunication,vreString);
            end
        end
        
        pause(cT);
        set(handles.t_msg,'String','Relax');
        if trainWithVr
            fwrite(handles.vreCommunication,sprintf(sprintf('%c%c%c%c%c','r',char(1),char(1),char(1),char(1))));
        end
        pic = image(relax,'Parent',handles.a_pic);                     % set image
        axis(handles.a_pic,'off');                                     % Remove axis tick marks
        pause(rT);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Draw figure
    
    p_f0 = plot(handles.a_f0, timeStamps, fData);
    handles.p_f0 = p_f0;
    xlim(handles.a_f0, [0,sF/2]);
    ylim(handles.a_f0, [ymin ymax]);
    set(handles.a_f0,'YTick',offVector);
    set(handles.a_f0,'YTickLabel',0:nCh-1);
    
    if strcmp(handles.plotType,'Raw Signal')
        p_t0 = plot(handles.a_t0, timeStamps, sData);
        handles.p_t0 = p_t0;
        xlim(handles.a_t0, [0,tW]);
        ylim(handles.a_t0, [ymin ymax]);
        set(handles.a_t0,'YTick',offVector);
        set(handles.a_t0,'YTickLabel',0:nCh-1);
    end
    
    if strcmp(handles.plotType,'Bar Chart')
        fID=handles.featureType;
        features = ExtractSigFeatureOnline(sData,sF,fID);
        p_t0 = bar(handles.a_t0, features);
        
        handles.p_t0 = p_t0;
        set(handles.a_t0,'YTick',offVector);
        set(handles.a_t0,'YTickLabel',0:nCh-1);
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Repetitions
    %%%%% NI DAQ card %%%%%
    if strcmp (ComPortType, 'NI')
        
        % Init SBI
        sCh = 1:nCh;
        
        if strcmp(deviceName, 'Thalmic MyoBand')
            %CK: init MyoBand
            originFolder = pwd;
            changeFolderToMyoDLL();
            pause (0.5);
            s = MyoBandSession(sF, sTall, sCh);
            cd (originFolder);
        else
            s = InitSBI_NI(sF,sTall,sCh);
        end
        s.NotifyWhenDataAvailableExceeds = tWs;                        % PEEK time
        lh = s.addlistener('DataAvailable', @RecordingSession_ShowData);
        
        % Start DAQ
        cData = zeros(sF*sTall, nCh, nM);
        s.startBackground();                                           % Run in the backgroud
        
        for rep = 1 : nR
            handles.rep = rep;
            % Contraction
            set(handles.t_msg,'String',mov(ex));
            pic = image(movI,'Parent',handles.a_pic);                  % set image
            axis(handles.a_pic,'off');                                 % Remove axis tick marks
            handles.contraction = 1;
            startContractionTic = tic;
            if trainWithVr
                numberOfMovements = length(vreMovements{ex});
                tempJumps = numJumps/numberOfMovements;
                tempDistance = round(distance/tempJumps);
                vreString = '';
                for i = 1:numberOfMovements
                    movement = vreMovements{ex}{i};
                    vreString = sprintf('%s%c%c%c%c%c',vreString,char(1),char(movement.idVRE),char(movement.vreDir),char(tempDistance),char(1));
                end
                for j = 1:tempJumps
                    fwrite(handles.vreCommunication,vreString);
                end
            end
            pause(cT - toc(startContractionTic));
            % Relax
            set(handles.t_msg,'String','Relax');
            startRelaxingTic = tic;
            if trainWithVr
                for i = 1:numJumps
                    fwrite(handles.vreCommunication,sprintf(sprintf('%c%c%c%c%c',char(1),char(14),char(1),char(distance/numJumps),char(1))));
                end
            end
            pic = image(relax,'Parent',handles.a_pic);                 % set image
            axis(handles.a_pic,'off');                                 % Remove axis tick marks
            handles.contraction = 0;
            pause(rT - toc(startRelaxingTic));
        end
        
        % Repetitions other devices
    else
        
        % Connect to AcceleGlove, and start acquisition
        if useAcceleGlove
            acceleGlove = AcceleGlove(ag_port);
            if acceleGlove.status == acceleGlove.SUCCESS
                acceleGlove.start_acquisition();
                
                if acceleGlove.status == acceleGlove.ERROR
                    useAcceleGlove = 0;
                    fprintf('Unable to start AcceleGlove acquisition\n');
                end
            else
                useAcceleGlove = 0;
                fprintf('Unable to open port to AcceleGlove\n');
            end
        end
        
        % Connect the chosen device, it returns the connection object
        obj = ConnectDevice(handles);
        
        % Set the selected device and Start the acquisition
        SetDeviceStartAcquisition(handles, obj);
        
        for rep = 1 : nR
            
            rep
            handles.rep = rep;
            handles.contraction = 1;                                   % 1 means contraction, 0 means relaxation
            samplesCounter = 1;                                        % variable used to track the progressing time of the recording session
            UpdateGUI = 1;
            cData = zeros(tWs, nCh);
            
            tic
            for timeWindowNr = 1:sT/tW
                
                if useAcceleGlove
                    acceleGlove.update();
                end

                if contains(deviceName, 'OTB400') || strcmp(deviceName, 'SQ+')
                    cData = obj.getEMG_data_TW_float(tWs);
                    error = 0;
                else
                    [cData, error] = Acquire_tWs(deviceName, obj, nCh, tWs, compressData);    % acquire a new time window of samples
                end

                acquireEvent.Data = cData;
            
                % Wait up to 100ms for data from AcceleGlove, if timeout
                % occurs, cancel accelerometer recording.
                if useAcceleGlove
                    tmp_data = acceleGlove.wait_for_data(0.1);
                    if isempty(tmp_data)
                        useAcceleGlove = 0;
                        fprintf('Received Timeout from AcceleGlove!\n');
                    else
                        sensorData.accelerometers(:,timeWindowNr) = tmp_data;
                    end
                end

                RecordingSession_ShowData(0, acquireEvent);            % plot data and add cData to allData vector
                
                samplesCounter = samplesCounter + tWs;
                switch handles.contraction
                    case 1
                        % CONTRACTION
                        if (samplesCounter/sF) <= cT
                            % contraction time not expired yet
                            if UpdateGUI == 1
                                % new contraction, the GUI must be updated
                                set(handles.t_msg,'String',mov(ex));
                                pic = image(movI,'Parent',handles.a_pic);    % set image
                                axis(handles.a_pic,'off');                   % Remove axis tick marks
                                drawnow;
                                if trainWithVr
                                    numberOfMovements = length(vreMovements{ex});
                                    tempJumps = numJumps/numberOfMovements;
                                    tempDistance = round(distance/tempJumps);
                                    vreString = '';
                                    for i = 1:numberOfMovements
                                        movement = vreMovements{ex}{i};
                                        vreString = sprintf('%s%c%c%c%c%c',vreString,char(1),char(movement.idVRE),char(movement.vreDir),char(tempDistance),char(1));
                                    end
                                    for j = 1:tempJumps
                                        fwrite(handles.vreCommunication,vreString);
                                    end
                                end
                                UpdateGUI = 0;
                            end
                        else
                            % contraction time expired
                            handles.contraction = 0;                    % 1 means contraction, 0 means relaxation
                            UpdateGUI = 1;
                            samplesCounter = 1;
                        end
                    case 0
                        % RELAXATION
                        if (samplesCounter/sF) <= rT
                            % relaxation time not expired yet
                            if UpdateGUI == 1
                                % new relaxation, the GUI must be updated
                                set(handles.t_msg,'String','Relax');
                                pic = image(relax,'Parent',handles.a_pic);   % set image
                                axis(handles.a_pic,'off');                   % Remove axis tick marks
                                drawnow;
                                if trainWithVr
                                    for i = 1:numJumps
                                        fwrite(handles.vreCommunication,sprintf(sprintf('%c%c%c%c%c',char(1),char(14),char(1),char(distance/numJumps),char(1))));
                                    end
                                end
                                UpdateGUI = 0;
                            end
                        else
                            % relaxation time expired
                            handles.contraction = 1;                % 1 means contraction, 0 means relaxation
                            if rep ~= nR
                                UpdateGUI = 1;
                            end
                            samplesCounter = 1;
                        end
                    otherwise
                        set(handles.t_msg,'String','Error with the Contraction-Relaxation switch statement');
                end
            end
            toc
        end
        
        % Stop acquisition
        StopAcquisition(deviceName, obj);
        if useAcceleGlove
            acceleGlove.stop_acquisition();
        end
    end
    
    % NI DAQ card: "You must delete the listener once the operation is complete"
    if strcmp(ComPortType,'NI');
        error = 0;
        if ~s.IsDone                                                   % check if is done
            s.wait();
        end
        
        %CK: Since variable lh is not used in the MyoBandSession, we cannot
        %delete it this way. But for any other device lh will be deleted.
        if ~strcmp(deviceName, 'Thalmic MyoBand')
            delete(lh);
        end
        %CK: Stop sampling from MyoBand
        if strcmp(deviceName, 'Thalmic MyoBand')
             MyoClient('StopSampling');
        end
    end
    
    if error == 1
        errordlg('Error occurred during the acquisition!','Error');
        return
    else
        % Plot movement just recorded
        DataShow(handles, allData, sF, sTall);
        
        if movRepeatDlg
            prompt = {'Do you want to record this movement again? (y/n)'};
            dlg_title = 'Repeat?';
            num_lines = 1;
            def = {'n'};
            answer = inputdlg(prompt,dlg_title,num_lines,def);
            if strcmp(answer, 'n')
                % Save and go ahead with the next movement..
                recSessionData(:,:,ex) = allData(:,:);
                % Increase loop index
                ex = ex + 1;
            end
        else
            % Save and go ahead with the next movement..
            recSessionData(:,:,ex) = allData(:,:);
            % Increase loop index
            ex = ex + 1;
        end
        % Clean global data
        allData = [];
    end
    
end


%% Session finish..

% Save data into cdata output matrix
if strcmp(deviceName, 'LM 1') || strcmp(deviceName, 'LM 2') || strcmp(deviceName, 'LM 3') || strcmp(deviceName, 'LM 14')
    try
        objLM.stopAcquisitionEMG();
    catch
        % If the acquisition already stopped on the board, ignore
    end
    objLM.disconnectBTdevice();
    delete(objLM.serialObj);
    handles.objLM = [];
end

% Cleanup for OTB
if contains(deviceName, 'OTB400')
    if isfield(handles,'objOT') && ~isempty(handles.objOT)
        try
            handles.objOT.disconnectBTdevice();
        catch ME
            fprintf('OT cleanup warning: %s\n', ME.message);
        end
        handles.objOT = [];
    end
end

% Cleanup for Sessantaquattro+
if strcmp(deviceName, 'SQ+')
    if isfield(handles,'objSQ') && ~isempty(handles.objSQ)
        try
            handles.objSQ.disconnectBTdevice();
        catch ME
            fprintf('SQ cleanup warning: %s\n', ME.message);
        end
        handles.objSQ = [];
    end
end

% Save data into cdata output matrix
cdata = recSessionData(:,:,:);

if saveRec                                                             % Saved in DataAnalysis
    
    set(handles.t_msg,'String','Session Terminated');                  % Show message about acquisition completed
    fileName = 'Img/Agree.jpg';
    movI = importdata(fileName);                                       % Import Image
    set(handles.a_pic,'Visible','on');                                 % Turn on visibility
    pic = image(movI,'Parent',handles.a_pic);                          % set image
    axis(handles.a_pic,'off');                                         % Remove axis tick marks
    
    % Save Session to file
    recSession.sF       = sF;
    recSession.sT       = sTall;
    recSession.cT       = cT;
    recSession.rT       = rT;
    recSession.nM       = nM;
    recSession.nR       = nR;
    recSession.nCh      = nCh;
    if isfield(handles,'vCh')
        recSession.vCh = handles.vCh;
    end
    recSession.dev      = deviceName;
    recSession.comm     = ComPortType;
    if strcmp(ComPortType, 'COM')
        recSession.comn     = ComPortName;
    end
    recSession.useAcceleGlove = useAcceleGlove;
    if useAcceleGlove
        recSession.sensorData = sensorData;
        recSession.ag_port = ag_port;
    end
    recSession.mov      = mov;
    recSession.date     = fix(clock);
    recSession.cmt      = inputdlg('Additional comment on the recording session','Comments');
    if rampStatus
        recSession.ramp.rampMin = rampParams{1};                 % Save the ramp parameters to the file
        recSession.ramp.rampMax = rampParams{2};
        recSession.ramp.minData = rampParams{3};
        recSession.ramp.maxData = rampParams{4};
        recSession.ramp.rampFeature = 'tmabs';              % what is being used in ramp training - mean absolute value. hard coded, may be editable later
    end
    
    [filename, pathname] = uiputfile({'*.mat','MAT-files (*.mat)'},'Save as', 'Untitled.mat');
    if isequal(filename,0) || isequal(pathname,0)
        recSession.tdata = recSessionData;
        disp('User pressed cancel')
    else
        disp(['User selected ', fullfile(pathname, filename)])
        recSession.tdata = recSessionData;
        save([pathname,filename],'recSession');
        disp(recSession);
    end
    
    if trainWithVr
        fclose(handles.vreCommunication);
    end
    
    % Turn OFF visibility
    set(handles.a_prog,'visible','off');
    if(rampStatus)
        set(handles.a_effortPlot,'visible','off');
        set(handles.txt_effortPlot,'visible','off');
        set(p_effortPlot,'visible','off');
        set(handles.hLine,'visible','off');
    end
    set(handles.hPatch,'Xdata',[0 0 0 0]);
    
    % Set visible the offline plot and process panels
    set(handles.uipanel9,'Visible','on');
    set(handles.uipanel10,'Visible','on');
    set(handles.uibuttongroup1,'Visible','on');
    set(handles.uipanel7,'Visible','on');
    set(handles.uipanel8,'Visible','on');
    set(handles.txt_it,'visible','on');
    set(handles.txt_ft,'visible','on');
    set(handles.et_it,'visible','on');
    set(handles.et_ft,'visible','on');
    set(handles.txt_if,'visible','on');
    set(handles.txt_ff,'visible','on');
    set(handles.et_if,'visible','on');
    set(handles.et_ff,'visible','on');
    
    chVector = 0:nCh-1;
    set(handles.lb_channels, 'String', chVector);
    
    %GUI_DataAnalysis(recSession,varargin);
    dlgTitle    = 'Analyze Data';
    dlgQuestion = 'Would you like to analyze and correct this recording session';
    choice = questdlg(dlgQuestion,dlgTitle,'Yes','No', 'Yes');
    if strcmp(choice,'Yes')
        GUI_DataAnalysis(recSession,varargin)
    end
end
end
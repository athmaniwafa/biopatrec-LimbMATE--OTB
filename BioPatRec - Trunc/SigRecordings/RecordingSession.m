% ---------------------------- Copyright Notice ---------------------------
% This file is part of BioPatRec © which is open and free software under
% the GNU Lesser General Public License (LGPL). See the file "LICENSE" for
% the full license governing this code and copyrights.
%
% BioPatRec was initially developed by Max J. Ortiz C. at Integrum AB and
% Chalmers University of Technology. All authors’ contributions must be kept
% acknowledged below in the section "Updates % Contributors".
% ------------------- Function Description ------------------
% Function to Record Exc Sessions
%
% --------------------------Updates--------------------------
% 2009-04-17 / Max Ortiz  / Creation
% 2015-01-12 / Enzo Mastinu / Divided the RecordingSession function

function [cdata, sF, sensorData] = RecordingSession(varargin)

recordingWindow=varargin{6};
recordingFigure=recordingWindow.output;
uiCleanup=RecordingSession_Cleanup('ui',recordingFigure); %#ok<NASGU>
global       handles;
global       allData;
global       timeStamps;
global       samplesCounter;
allData      = [];
nM           = varargin{1};
nR           = varargin{2};
cT           = varargin{3};
rT           = varargin{4};
mov          = varargin{5};
handles      = varargin{6};
afeSettings  = varargin{7};
trainWithVr  = varargin{8};
vreMovements = varargin{9};
vreLeftHand  = varargin{10};
movRepeatDlg = varargin{11};
useLeg       = varargin{12};
rampStatus   = varargin{13};
saveRec     = true;

% The gate (OTB400_HD / SQ+ "Session + map") lives inside this function.
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

% STRICT FAIL-SAFE: Never let these devices use NI DAQ
if isSQplus(deviceName) || isLimbMATE(deviceName) || isOTB400(deviceName)
    ComPortType = 'COM';
end

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

% Time window size
if isOTB400(deviceName)
    tWs = 256;
    tW = tWs/sF;
elseif isSQplus(deviceName)
    tWs = 200;
    tW = tWs/sF;
else
    tW = 100/sF;
    if tW < 0.1
        tW = 0.1;
    end
    if mod(sT,tW) > 0
        errordlg('Please, the time window size must be a multiple of the recording time. Select a proper time window size!')
        return
    end
    tWs = tW*sF;
end

handles.tWs = tWs;
timeStamps = (0:tWs-1)/sF;

%% Initialize GUI..
if trainWithVr
    distance = 60;
    numJumps = 30;
    open('Virtual Reality.exe');
    handles.vreCommunication = tcpip('127.0.0.1',23068,'NetworkRole','server');
    fopen(handles.vreCommunication);
    fwrite(handles.vreCommunication,sprintf('%c%c%c%c%c','c',char(7),char(0),char(0),char(0)));
    if(useLeg == 1)
        fwrite(handles.vreCommunication,sprintf('%c%c%c%c','c',char(1),char(2),char(1)));
    else
        fwrite(handles.vreCommunication,sprintf('%c%c%c%c','c',char(1),char(1),char(1)));
    end
    sent = 0;
    for i = 1:nM
        for j = 1:length(vreMovements{i})
            movement = vreMovements{i}{j};
            if ismember(movement.id,[20 21]) && sent == 0
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
    set(handles.a_effortPlot,'Visible','on');
    set(handles.txt_effortPlot,'Visible','on');
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

% --- START THE HARDWARE NOW (Pops up the mode selection) ---
if isfield(afeSettings, 'adapter') && ~isempty(afeSettings.adapter) && ~isOTB400(deviceName)
    fprintf('[RecordingSession] Starting hardware adapter...\n');
    afeSettings.adapter.start(afeSettings);
end

set(handles.t_msg,'String','Get ready to start: 3'); pause(1);
set(handles.t_msg,'String','Get ready to start: 2'); pause(1);
set(handles.t_msg,'String','Get ready to start: 1'); pause(1);
if(useLeg == 1)
    relax = importdata('Img/relaxLeg.jpg');
else
    relax = importdata('Img/relax.jpg');
end
drawnow;

% Run all movements or exercise
ex = 1;
while ex <= nM
    
    timeStamps = (0:tWs-1)/sF;
    currentTv = 1;
    tV = timeStamps(currentTv):1/sF:(tW-1/sF)+timeStamps(currentTv);
    currentTv = currentTv - 1 + tWs;
    acquireEvent.TimeStamps = tV';
    
    if rampStatus
        handles.RampMin = rampParams{1};
        handles.currentRampMax = rampParams{2}(ex);
    end
    
    disp(['Start ex: ' num2str(ex) ])
    
    fileName = ['Img/' char(mov(ex)) '.jpg'];
    if ~exist(fileName,'file')
        fileName = ['Img/' 'noImage' '.png'];
    end
    
    movI = importdata(fileName);
    set(handles.a_pic,'Visible','on');
    pic = image(movI,'Parent',handles.a_pic);
    axis(handles.a_pic,'off');
    
    set(handles.t_msg,'String',['Get ready for ' mov(ex) ' in 3 s']); pause(1);
    set(handles.t_msg,'String',['Get ready for ' mov(ex) ' in 2 s']); pause(1);
    set(handles.t_msg,'String',['Get ready for ' mov(ex) ' in 1 s']); pause(1);
    
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
        pic = image(relax,'Parent',handles.a_pic);
        axis(handles.a_pic,'off');
        pause(rT);
    end

    %% Draw figure
    if isvalid(handles.a_f0)
        p_f0 = plot(handles.a_f0, timeStamps, fData);
        handles.p_f0 = p_f0;
        xlim(handles.a_f0, [0,sF/2]);
        ylim(handles.a_f0, [ymin ymax]);
        set(handles.a_f0,'YTick',offVector);
        set(handles.a_f0,'YTickLabel',0:nCh-1);
    end
    
    if strcmp(handles.plotType,'Raw Signal') && isvalid(handles.a_t0)
        p_t0 = plot(handles.a_t0, timeStamps, sData);
        handles.p_t0 = p_t0;
        xlim(handles.a_t0, [0,tW]);
        ylim(handles.a_t0, [ymin ymax]);
        set(handles.a_t0,'YTick',offVector);
        set(handles.a_t0,'YTickLabel',0:nCh-1);
    end
    
    if strcmp(handles.plotType,'Bar Chart') && isvalid(handles.a_t0)
        fID=handles.featureType;
        features = ExtractSigFeatureOnline(sData,sF,fID);
        p_t0 = bar(handles.a_t0, features);
        handles.p_t0 = p_t0;
        set(handles.a_t0,'YTick',offVector);
        set(handles.a_t0,'YTickLabel',0:nCh-1);
    end

    %% Repetitions
    if strcmp (ComPortType, 'NI')
        sCh = 1:nCh;
        if strcmp(deviceName, 'Thalmic MyoBand')
            originFolder = pwd;
            changeFolderToMyoDLL();
            pause (0.5);
            s = MyoBandSession(sF, sTall, sCh);
            cd (originFolder);
        else
            s = InitSBI_NI(sF,sTall,sCh);
        end
        s.NotifyWhenDataAvailableExceeds = tWs;
        lh = s.addlistener('DataAvailable', @RecordingSession_ShowData);
        
        cData = zeros(sF*sTall, nCh, nM);
        s.startBackground();
        
        for rep = 1 : nR
            handles.rep = rep;
            set(handles.t_msg,'String',mov(ex));
            pic = image(movI,'Parent',handles.a_pic);
            axis(handles.a_pic,'off');
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
            set(handles.t_msg,'String','Relax');
            startRelaxingTic = tic;
            if trainWithVr
                for i = 1:numJumps
                    fwrite(handles.vreCommunication,sprintf(sprintf('%c%c%c%c%c',char(1),char(14),char(1),char(distance/numJumps),char(1))));
                end
            end
            pic = image(relax,'Parent',handles.a_pic);
            axis(handles.a_pic,'off');
            handles.contraction = 0;
            pause(rT - toc(startRelaxingTic));
        end
    else
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
        
        % --- ADAPTER PATTERN ---
        dev = afeSettings.adapter;
        if isOTB400(deviceName)
            movementCleanup=RecordingSession_Cleanup('device',dev); %#ok<NASGU>
            dev.start(afeSettings);
        end

        % Discard data that piled up during countdown / plot setup,
        % so the plot starts at "now" instead of fast-forwarding.
        if ismethod(dev,'flush'), dev.flush(); end
        
        for rep = 1 : nR
            rep
            handles.rep = rep;
            handles.contraction = 1;
            samplesCounter = 1;
            UpdateGUI = 1;
            cData = zeros(tWs, nCh);
            
            tic
            for timeWindowNr = 1:sT/tW
                if useAcceleGlove
                    acceleGlove.update();
                end

                if ~isgraphics(recordingFigure) || getappdata(recordingFigure,'RecordingStopRequested')
                    error('BioPatRec:RecordingCancelled','Registrazione arrestata.');
                end
                try
                    cData = dev.read(tWs);
                catch ME
                    if strcmp(ME.identifier,'OT_Acquire:Stopped') && ...
                            (~isgraphics(recordingFigure) || getappdata(recordingFigure,'RecordingStopRequested'))
                        error('BioPatRec:RecordingCancelled','Registrazione arrestata.');
                    end
                    rethrow(ME);
                end
                acquireEvent.Data = cData;
            
                if useAcceleGlove
                    tmp_data = acceleGlove.wait_for_data(0.1);
                    if isempty(tmp_data)
                        useAcceleGlove = 0;
                        fprintf('Received Timeout from AcceleGlove!\n');
                    else
                        sensorData.accelerometers(:,timeWindowNr) = tmp_data;
                    end
                end

                RecordingSession_ShowData(0, acquireEvent);

                % SQ+ matrix "Session + map": live amplitude heatmap
                if isappdata(handles.output,'SQHeatmapUpdate')
                    try
                        updateHeatFcn = getappdata(handles.output,'SQHeatmapUpdate');
                        updateHeatFcn(cData);
                    catch
                    end
                end
                
                samplesCounter = samplesCounter + tWs;
                switch handles.contraction
                    case 1
                        if (samplesCounter/sF) <= cT
                            if UpdateGUI == 1
                                set(handles.t_msg,'String',mov(ex));
                                pic = image(movI,'Parent',handles.a_pic);
                                axis(handles.a_pic,'off');
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
                            handles.contraction = 0;
                            UpdateGUI = 1;
                            samplesCounter = 1;
                        end
                    case 0
                        if (samplesCounter/sF) <= rT
                            if UpdateGUI == 1
                                set(handles.t_msg,'String','Relax');
                                pic = image(relax,'Parent',handles.a_pic);
                                axis(handles.a_pic,'off');
                                drawnow;
                                if trainWithVr
                                    for i = 1:numJumps
                                        fwrite(handles.vreCommunication,sprintf(sprintf('%c%c%c%c%c',char(1),char(14),char(1),char(distance/numJumps),char(1))));
                                    end
                                end
                                UpdateGUI = 0;
                            end
                        else
                            handles.contraction = 1;
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
        if isOTB400(deviceName)
            clear movementCleanup;
        else

        % Stop acquisition. SQ+ keeps its connection open between
        % movements (it is stopped once, after the last movement).
        if ~isSQplus(deviceName)

            dev.stop();
        end
        if useAcceleGlove
            acceleGlove.stop_acquisition();
        end
    end
    
    if strcmp(ComPortType,'NI')
        error = 0;
        if ~s.IsDone
            s.wait();
        end
        if ~strcmp(deviceName, 'Thalmic MyoBand')
            delete(lh);
        end
        if strcmp(deviceName, 'Thalmic MyoBand')
             MyoClient('StopSampling');
        end
    end
    
    if exist('error', 'var') && error == 1
        errordlg('Error occurred during the acquisition!','Error');
        return
    else
        if isvalid(handles.a_t0)
            DataShow(handles, allData, sF, sTall);
        end
        
        if movRepeatDlg
            prompt = {'Do you want to record this movement again? (y/n)'};
            dlg_title = 'Repeat?';
            num_lines = 1;
            def = {'n'};
            answer = inputdlg(prompt,dlg_title,num_lines,def);
            if strcmp(answer{1}, 'n')
                recSessionData(:,:,ex) = allData(:,:);
                ex = ex + 1;
            end
        else
            recSessionData(:,:,ex) = allData(:,:);
            ex = ex + 1;
        end
        allData = [];
    end
end

% SQ+: all movements done, now stop the stream and close the connection
if isSQplus(deviceName) && exist('dev','var') && ~isempty(dev)
    dev.stop();
end

%% Session finish..
cdata = recSessionData(:,:,:);
delete(findall(0,'Tag','SQHeatFig'));

if saveRec
    if isvalid(handles.t_msg), set(handles.t_msg,'String','Session Terminated'); end
    fileName = 'Img/Agree.jpg';
    movI = importdata(fileName);
    if isvalid(handles.a_pic)
        set(handles.a_pic,'Visible','on');
        pic = image(movI,'Parent',handles.a_pic);
        axis(handles.a_pic,'off');
    end
    
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
        recSession.comn = ComPortName;
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
        recSession.ramp.rampMin = rampParams{1};
        recSession.ramp.rampMax = rampParams{2};
        recSession.ramp.minData = rampParams{3};
        recSession.ramp.maxData = rampParams{4};
        recSession.ramp.rampFeature = 'tmabs';
    end
    
    [filename, pathname] = uiputfile({'*.mat','MAT-files (*.mat)'},'Save as', 'Untitled.mat');
    if isequal(filename,0) || isequal(pathname,0)
        recSession.tdata = recSessionData;
        disp('User pressed cancel')
    else
        disp(['User selected ', fullfile(pathname, filename)])
        recSession.tdata = recSessionData;
        save([pathname,filename],'recSession');
    end
    
    if trainWithVr
        fclose(handles.vreCommunication);
    end
    
    if isvalid(handles.a_prog), set(handles.a_prog,'visible','off'); end
    if rampStatus && isvalid(handles.a_effortPlot)
        set(handles.a_effortPlot,'visible','off');
        set(handles.txt_effortPlot,'visible','off');
        if isvalid(p_effortPlot), set(p_effortPlot,'visible','off'); end
        if isvalid(handles.hLine), set(handles.hLine,'visible','off'); end
    end
    if isfield(handles,'hPatch') && isvalid(handles.hPatch)
        set(handles.hPatch,'Xdata',[0 0 0 0]);
    end
    
    if isvalid(handles.uipanel9), set(handles.uipanel9,'Visible','on'); end
    if isvalid(handles.uipanel10), set(handles.uipanel10,'Visible','on'); end
    if isvalid(handles.uibuttongroup1), set(handles.uibuttongroup1,'Visible','on'); end
    if isvalid(handles.uipanel7), set(handles.uipanel7,'Visible','on'); end
    if isvalid(handles.uipanel8), set(handles.uipanel8,'Visible','on'); end
    
    if isvalid(handles.txt_it), set(handles.txt_it,'visible','on'); end
    if isvalid(handles.txt_ft), set(handles.txt_ft,'visible','on'); end
    if isvalid(handles.et_it), set(handles.et_it,'visible','on'); end
    if isvalid(handles.et_ft), set(handles.et_ft,'visible','on'); end
    if isvalid(handles.txt_if), set(handles.txt_if,'visible','on'); end
    if isvalid(handles.txt_ff), set(handles.txt_ff,'visible','on'); end
    if isvalid(handles.et_if), set(handles.et_if,'visible','on'); end
    if isvalid(handles.et_ff), set(handles.et_ff,'visible','on'); end
    
    if isvalid(handles.lb_channels)
        chVector = 0:nCh-1;
        set(handles.lb_channels, 'String', chVector);
    end
    
    dlgTitle    = 'Analyze Data';
    dlgQuestion = 'Would you like to analyze and correct this recording session';
    choice = questdlg(dlgQuestion,dlgTitle,'Yes','No', 'Yes');
    if strcmp(choice,'Yes')
        GUI_DataAnalysis(recSession,varargin)
    end
end
end
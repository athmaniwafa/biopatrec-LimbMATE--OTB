% ---------------------------- Copyright Notice ---------------------------
% This file is part of BioPatRec © which is open and free software under 
% the GNU Lesser General Public License (LGPL). See the file "LICENSE" for 
% the full license governing this code and copyrights.
%
% BioPatRec was initially developed by Max J. Ortiz C. at Integrum AB and 
% Chalmers University of Technology. All authors’ contributions must be kept
% acknowledged below in the section "Updates % Contributors". 
% ------------------- Function Description ------------------
% Function to Record Exc Sessions (Fast Mode)

function [cdata, sF, sT, sensorData] = FastRecordingSession(varargin)

    recordingWindow=varargin{1};
    recordingFigure=recordingWindow.output;
    uiCleanup=RecordingSession_Cleanup('ui',recordingFigure); %#ok<NASGU>
    global       handles;
    global       allData;
    global       timeStamps;
    global       samplesCounter;
    allData      = [];
    handles      = varargin{1};
    afeSettings  = varargin{2};
    handles.OTBRecordingMap = OTB400_OpenRecordingMap(afeSettings, handles);

    % Get required informations from afeSettings structure
    nCh          = afeSettings.channels;
    sF           = afeSettings.sampleRate;
    deviceName   = afeSettings.name;
    ComPortType  = afeSettings.ComPortType;
    if isfield(afeSettings,'compressData')
        compressData = afeSettings.compressData;
    else
        compressData = 0;
    end
        if strcmp(ComPortType, 'COM')
        if isfield(afeSettings, 'ComPortName')
            ComPortName = afeSettings.ComPortName;
        else
            ComPortName = 'COM4'; % Fallback if missing
        end
    end    
    % Save back acquisition parameters to the handles
    if isfield(afeSettings,'vChannels')
        handles.vCh     = afeSettings.vChannels;
    end
    handles.nCh         = nCh;
    handles.sF          = sF;
    handles.ComPortType = ComPortType;
    handles.compressData = compressData;
    if strcmp(ComPortType, 'COM')
        handles.ComPortName = ComPortName;     
    end
    handles.deviceName  = deviceName;
    % To avoid bugs in RecordingSession_ShowData function
    handles.fast        = 1;
    handles.rep         = 1;                                               
    handles.cT          = 0;
    handles.rT          = 0;
    handles.rampStatus  = 0;
    handles.featureType = afeSettings.featureType;
    handles.plotType    = afeSettings.plotType;
    
    % STRICT FAIL-SAFE: Never let these devices use NI DAQ
    if isSQplus(deviceName) || isLimbMATE(deviceName) || isOTB400(deviceName)
        ComPortType = 'COM';
        handles.ComPortType = 'COM';
    end
    
    % Setting for data peeking
    if isfield(afeSettings, 'sT') && ~isempty(afeSettings.sT)
        sT = afeSettings.sT;
    else
        sT = handles.sT;
    end
    handles.sT    = sT;
    handles.sTall = sT;

    if isOTB400(deviceName)
        tWs = 256;
        tW = tWs / sF;
    elseif isSQplus(deviceName)
        tWs = 200;
        tW = tWs / sF;
    else
        tW = handles.tW;
        tWs = round(tW*sF);
    end

    handles.tWs = tWs;
    timeStamps = (0:tWs-1)/sF;
    
    if mod(sT,tW) > 0
        errordlg('Please, the time window size must be a multiple of the recording time. Select a proper time window size!')
        return
    end
    
    %% Initialize GUI..
    pause on;
    
    ampPP = 5;
    sData = zeros(tWs,nCh);   
    fData = zeros(tWs,nCh);
    offVector = 0:nCh-1;
    offVector = offVector .* ampPP;
    for i = 1 : nCh
        sData(:,i) = sData(:,i) + offVector(i);
        fData(:,i) = fData(:,i) + offVector(i);
    end
    
    % Draw figure (only if the GUI is still open)
    if isvalid(handles.a_t0)
        ymin = -ampPP*2/3;
        ymax =  ampPP * nCh - ampPP*1/3;
        p_t0 = plot(handles.a_t0, timeStamps, sData);
        handles.p_t0 = p_t0;
        xlim(handles.a_t0, [timeStamps(1) timeStamps(end)]);
        set(handles.a_t0,'XTick',0:numel(timeStamps)-1);
        set(handles.a_t0,'XTickLabel',timeStamps);
        ylim(handles.a_t0, [ymin ymax]);
        set(handles.a_t0,'YTick',offVector);
        set(handles.a_t0,'YTickLabel',0:nCh-1);
        p_f0 = plot(handles.a_f0,timeStamps,fData);
        handles.p_f0 = p_f0;  
        xlim(handles.a_f0, [0,sF/2]);
        ylim(handles.a_f0, [ymin ymax]);
        set(handles.a_f0,'YTick',offVector);
        set(handles.a_f0,'YTickLabel',0:nCh-1);
        
        xpatch = [0 0 0 0];
        ypatch = [0 0 1 1];
        axes(handles.a_prog);
        axis(handles.a_prog,'off');
        set(handles.a_prog, 'XLim',[0 1], 'YLim',[0 1], 'XLimMode','manual', 'YLimMode','manual');
        handles.hPatch = patch( ...
        'Parent', handles.a_prog, ...
        'XData', xpatch, ...
        'YData', ypatch, ...
        'FaceColor', 'b', ...
        'EdgeColor', 'b', ...
        'Visible', 'on');
        drawnow update
    end

    recSessionData = zeros(sF*sT, nCh);
    if isfield(afeSettings,'useAcceleGlove') && afeSettings.useAcceleGlove == 1
        useAcceleGlove = 1;
        sensorData.accelerometers = zeros(18,sT/tW);
        ag_port = afeSettings.acceleGlovePort;
    else
        useAcceleGlove = 0;
        sensorData.accelerometers = [];
    end

    %% Starting Session..
    if isvalid(handles.t_msg), set(handles.t_msg,'String','start'); end
    drawnow;

    currentTv = 1;
    tV = timeStamps(currentTv):1/sF:(tW-1/sF)+timeStamps(currentTv);
    currentTv = currentTv - 1 + tWs;
    acquireEvent.TimeStamps = tV';

    %%%%% NI DAQ card %%%%%
    if strcmp (ComPortType, 'NI')
        sCh = 1:nCh;
        if strcmp(deviceName, 'Thalmic MyoBand')
            originFolder = pwd;
            changeFolderToMyoDLL();
            pause (0.5);
            s = MyoBandSession(sF, sT, sCh);
            cd (originFolder);
        else
            s = InitSBI_NI(sF,sT,sCh);
        end
        s.NotifyWhenDataAvailableExceeds = tWs;
        lh = s.addlistener('DataAvailable', @RecordingSession_ShowData);   

        cdata = zeros(sF*sT, nCh);
        s.startBackground();

        startTimerTic = tic;
        pause(sT - toc(startTimerTic));

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
        deviceCleanup=RecordingSession_Cleanup('device',dev); %#ok<NASGU>
        dev.start(afeSettings);
        
        samplesCounter = 0;

        tic
        for timeWindowNr = 1:sT/tW
            if useAcceleGlove
                acceleGlove.update();
            end
            
            if ~isgraphics(recordingFigure) || getappdata(recordingFigure,'RecordingStopRequested')
                break;
            end
            try
                cdata = dev.read(tWs);
            catch ME
                if strcmp(ME.identifier,'OT_Acquire:Stopped') && ...
                        (~isgraphics(recordingFigure) || getappdata(recordingFigure,'RecordingStopRequested'))
                    break;
                end
                rethrow(ME);
            end
            acquireEvent.Data = cdata;
            
            if useAcceleGlove
                tmp_data = acceleGlove.wait_for_data(0.1);
                if isempty(tmp_data)
                    useAcceleGlove = 0;
                    fprintf('Received Timeout from AcceleGlove!\n');
                else
                    sensorData.accelerometers(:,timeWindowNr) = tmp_data;
                end
            end
            
            samplesCounter = samplesCounter + size(cdata,1);
            RecordingSession_ShowData(0, acquireEvent);
        end
        toc

        % Stop acquisition (leaves TCP socket open for SQ+)
        clear deviceCleanup;
        if useAcceleGlove
            acceleGlove.stop_acquisition();
        end
    end

    % NI DAQ card: "You must delete the listener once the operation is complete"
    if strcmp(ComPortType,'NI')  
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

    cdata = allData;
    allData = [];                                                      
    
    if ~isgraphics(recordingFigure), return; end
    %% Session finish..
    if isvalid(handles.t_msg)
        set(handles.t_msg,'String','Session Terminated');
    end
    fileName = 'Img/Agree.jpg';
    movI = importdata(fileName);
    if isvalid(handles.a_pic)
        set(handles.a_pic,'Visible','on');
        image(movI,'Parent',handles.a_pic);
        axis(handles.a_pic,'off');
    end
    if isvalid(handles.a_prog), set(handles.a_prog,'visible','off'); end
    if isfield(handles,'hPatch') && isvalid(handles.hPatch)
        set(handles.hPatch,'Xdata',[0 0 0 0]);
    end

    if ~isempty(cdata) && isvalid(handles.a_t0)
        DataShow(handles,cdata,sF,sT);
    end
    
    % Set visible the offline plot and process panels
    if isvalid(handles.uipanel9), set(handles.uipanel9,'Visible','on'); end
    if isvalid(handles.uipanel10), set(handles.uipanel10,'Visible','on'); end
    if isvalid(handles.uibuttongroup1), set(handles.uibuttongroup1,'Visible','on'); end
    if isvalid(handles.uipanel7), set(handles.uipanel7,'Visible','on'); end
    if isvalid(handles.uipanel8), set(handles.uipanel8,'Visible','on'); end
    
    chVector = 0:nCh-1;
    if isvalid(handles.lb_channels)
        set(handles.lb_channels, 'String', chVector);
    end
end
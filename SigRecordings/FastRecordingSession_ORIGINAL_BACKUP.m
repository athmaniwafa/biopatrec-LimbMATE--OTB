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
% 2015-01-26 / Enzo Mastinu / A new GUI_Recordings has been developed for the
                            % BioPatRec_TRE release. Now it is possible to
                            % plot more then 8 channels at the same moment, for 
                            % time and frequency plots both. It is faster and
                            % perfectly compatible with the ramp recording 
                            % session. At the end of the recording session it 
                            % is possible to check all channels individually, 
                            % apply offline data process as feature extraction or filter etc.
% 2015-10-28 / Martin Holder / >2014b plot interface fixes

% 2017-09-25 / Simon Nilsson  / Added warning dialog if acquisition error occurs

% 2018-07-09 / Andreas Eiler / Added function to change current folder to load
                            % Myo.dll file correctly

% 2018-09-26 / Adam naber / Added sensorData field for additional sensors

% 2019-03-06 / Bahareh Ahkami / Bar plot added to the system

function [cdata, sF, sT, sensorData] = FastRecordingSession(varargin)

    global       handles;
    global       allData;
    global       timeStamps;
    global       samplesCounter;
    allData      = [];
    handles      = varargin{1};
    afeSettings  = varargin{2};

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
        ComPortName = afeSettings.ComPortName;  
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
    
    % Setting for data peeking
    sT            = handles.sT;
    handles.sT    = sT;
    handles.sTall = sT;
    tW            = handles.tW;
    tWs           = tW*sF;                                                 % Time window samples
    handles.tWs   = tWs;
    timeStamps    = 0:1/sF:tW-1/sF;                                        % Create vector of time
    
    if mod(sT,tW) > 0
        errordlg('Please, the time window size must be a multiple of the recording time. Select a proper time window size!')
        return
    end
    
    %% Initialize GUI..

    pause on;
    
    % Initialize plots, offset the data
    ampPP = 5;
    sData = zeros(tWs,nCh);   
    fData = zeros(tWs,nCh);
    offVector = 0:nCh-1;
    offVector = offVector .* ampPP;
    for i = 1 : nCh
        sData(:,i) = sData(:,i) + offVector(i);
        fData(:,i) = fData(:,i) + offVector(i);
    end
    
    % Draw figure
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
    
    % Initialization of progress bar
    xpatch = [0 0 0 0];
    ypatch = [0 0 1 1];
    axes(handles.a_prog);
    axis(handles.a_prog,'off');
    set(handles.a_prog,'XLimMode','manual');
    handles.hPatch = patch(xpatch,ypatch,'b','EdgeColor','b','visible','on');
    drawnow update % 2014b figure updates

    % Allocation of resource to improve speed, total data 
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
    
    % Warning to the user
    set(handles.t_msg,'String','start');
    drawnow;

    % Run 
    currentTv = 1;                                                     % Current time vector
    tV = timeStamps(currentTv):1/sF:(tW-1/sF)+timeStamps(currentTv);   % Time vector used for drawing graphics
    currentTv = currentTv - 1 + tWs;                                   % Updated everytime tV is updated
    acquireEvent.TimeStamps = tV';

    %%%%% NI DAQ card %%%%%
    if strcmp (ComPortType, 'NI')

        % Init SBI
        sCh = 1:nCh;
        if strcmp(deviceName, 'Thalmic MyoBand')
            %CK: init MyoBand
            originFolder = pwd;
            changeFolderToMyoDLL();
            pause (0.5);
            s = MyoBandSession(sF, sT, sCh);
            cd (originFolder);
        else
            s = InitSBI_NI(sF,sT,sCh);
        end
        s.NotifyWhenDataAvailableExceeds = tWs;                        % PEEK time
        lh = s.addlistener('DataAvailable', @RecordingSession_ShowData);   

        % Start DAQ
        cdata = zeros(sF*sT, nCh);
        s.startBackground();                                           % Run in the backgroud

        startTimerTic = tic;
        pause(sT - toc(startTimerTic));

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

        %% Start the connection with Limb-MATE
        if any(strcmp(deviceName, {'LM 1','LM 2','LM 3','LM 14'}))
            % Create object for device and connection
            objLM = LimbMATE_BioPatRec();
        
            % Connect to Bluetooth USB stick
            objLM.connectBTdongle(ComPortName);
        
            % Find Bluetooth Devices and Connect to BT device with name "LMATE"
            BTspeed = "2";
            objLM.connectBTdevice(deviceName{1,1}, BTspeed);

            % Store on handles for later cleanup
            handles.objLM = objLM;
        end

        % Connect the chosen device, it returns the connection object
        obj = ConnectDevice(handles);
        if ~any(strcmp(deviceName, {'LM 1','LM 2','LM 3','LM 14'}))
            if strcmp(get(obj,'Status'),'closed')   % Make sure port opened correctly
                return;
            end
        end
        
        % Set the selected device and Start the acquisition
        SetDeviceStartAcquisition(handles, obj);
        if ~any(strcmp(deviceName, {'LM 1','LM 2','LM 3','LM 14'}))
            if strcmp(get(obj,'Status'),'closed')   % StartAcquisition closes the port on failure
                return;
            end
        end
        
        samplesCounter = 1;

        tic
        for timeWindowNr = 1:sT/tW
            if useAcceleGlove
                acceleGlove.update();
            end
            [cdata, error] = Acquire_tWs(deviceName, obj, nCh, tWs, compressData);    % acquire a new time window of samples  
            if error == 1
                errordlg('Error occurred during the acquisition!','Error');
                return
            end
            acquireEvent.Data = cdata;
            
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
%             samplesCounter = samplesCounter + tWs;
        end
        toc

        % Stop acquisition
        StopAcquisition(deviceName, obj); 
        if useAcceleGlove
            acceleGlove.stop_acquisition();
        end
        
    end

    % NI DAQ card: "You must delete the listener once the operation is complete"
    if strcmp(ComPortType,'NI')  
        if ~s.IsDone                                                   % check if is done
            s.wait();
        end
        if ~strcmp(deviceName, 'Thalmic MyoBand')
            delete(lh);
        end
        %CK: Stop sampling from MyoBand
        if strcmp(deviceName, 'Thalmic MyoBand')
%             s.stop(); 
            MyoClient('StopSampling');
        end
    end

    % Save data into cdata output matrix
    if any(strcmp(deviceName, {'LM 1','LM 2','LM 3','LM 14'}))
        if isfield(handles,'objLM') && ~isempty(handles.objLM)
            try
                handles.objLM.disconnectBTdevice();
                delete(handles.objLM.serialObj);
            catch ME
                fprintf('Cleanup warning: %s\n', ME.message);
            end
            handles.objLM = [];
        end
    end
    % Save Data
    cdata = allData;
    allData = [];                                                      % clean global data for next movement
    
    %% Session finish..
    set(handles.t_msg,'String','Session Terminated');                  % Show message about acquisition completed     
    fileName = 'Img/Agree.jpg';
    movI = importdata(fileName);                                       % Import Image
    set(handles.a_pic,'Visible','on');                                 % Turn on visibility
    image(movI,'Parent',handles.a_pic);                          % set image
    axis(handles.a_pic,'off');                                         % Remove axis tick marks
    set(handles.a_prog,'visible','off');
    set(handles.hPatch,'Xdata',[0 0 0 0]);

    % Data Plot
    DataShow(handles,cdata,sF,sT);
    
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
end
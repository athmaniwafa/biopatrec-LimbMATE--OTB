%%% Single System Test function for the ALC-D system
function testData = ALCDsingleTest( commObj, newPredictionTime, movement2execute, strength, neurostimulator, plots )
    %% prepare the NI 6212 card with 2 analog output channels
    disp('ALC-D system test: single run');
    disp('Preparing the analog output...');
    %set(handles.t_msg,'String','Preparing the analog output...');
    devices = daq.getDevices;
    if isempty(devices)
       disp('(ERRORCODE 1) No NI card identified! Please, check connections.');
       %set(handles.t_msg,'String','(ERRORCODE 1) No NI card identified! Please, check connections.');  
       return;
    end
    s = daq.createSession('ni');
    s.addAnalogOutputChannel('dev5','ao0','Voltage');
    s.addAnalogOutputChannel('dev5','ao1','Voltage');
    s.Rate = 1000;         
    sF = 1000;
%     plot(movement2execute);
%     xlabel('Time');
%     ylabel('Voltage');
%     legend('Analog Output');

    %% set the ALC-D into COMMAND_MODE
%     if isfield(handles,'commObj')
%         commObj = handles.commObj;
%     else
%         %set(handles.t_msg,'String','(ERRORCODE 2) No connection object found'); 
%         disp('(ERRORCODE 2) No connection object found');
%         return;
%     end
    fopen(commObj);
    % Set up the COMMAND MODE enable
    fwrite(commObj,hex2dec('AA'),'char');
    replay = char(fread(commObj,4,'char')');
    if strcmp(replay,'COMM')
        %set(handles.t_msg,'String','ALC-D COMMAND MODE enabled...');
        disp('ALC-D COMMAND MODE enabled...');
    else
        %set(handles.t_msg,'String','(ERRORCODE 3) Error Setting COMMAND MODE');
        disp('(ERRORCODE 3) Error Setting COMMAND MODE');
        fclose(commObj);
        return
    end

    %% read the current pointer (block index) for the logFile in the ALC-D
    %set(handles.t_msg,'String','Retrieving last memory location used...');
    disp('Retrieving last memory location used (before test)...');
    blockDimension = 512;
    fwrite(commObj,'n','char');
    replay = char(fread(commObj,1,'char'));
    if strcmp(replay,'n')
        startLocation = fread(commObj,1,'uint32');
        replay = char(fread(commObj,1,'char'));
        if strcmp(replay,'n')
            message = sprintf('ALC-D memory state: %0.0fB on %0.0fGB, %d, block Idx = %0.0f ', startLocation*blockDimension, 2, (startLocation*blockDimension*100/16000000000), startLocation);
            %set(handles.t_msg,'String', message);
            disp(message);
            drawnow;
        else
            %set(handles.t_msg,'String','(ERRORCODE 4) Error reading ALC-D SDcard'); 
            fclose(commObj);
            return
        end
    else
        %set(handles.t_msg,'String','(ERRORCODE 4) Error reading ALC-D SDcard'); 
        fclose(commObj);
        return
    end
    
    %% prepare the oscilloscope (if neurostimulator included in test)
    if neurostimulator
        %set(handles.t_msg,'String','Preparing the oscilloscope...');
        disp('Preparing the oscilloscope...');
        myScope = oscilloscope();
        myScope.Resource = 'USB0::0x0699::0x0408::C016987::0::INSTR';
        connect(myScope);
        set(myScope,'AcquisitionTime',length(movement2execute)/sF);
        set(myScope, 'WaveformLength',1e6);
        enableChannel(myScope, 'CH1');
    end

    %% start the CONTROL_MODE on the ALC-D
    fwrite(commObj,hex2dec('EE'),'char');
    replay = char(fread(commObj,4,'char')');
    if strcmp(replay,'CTRL')
        %set(handles.t_msg,'String','ALC-D CONTROL MODE enabled...'); 
        disp('ALC-D CONTROL MODE enabled...');
    else
        %set(handles.t_msg,'String','(ERRORCODE 5) Error Setting CONTROL MODE'); 
        disp('(ERRORCODE 5) Error Setting CONTROL MODE');
        fclose(commObj);
        return
    end
    
    %% output the selected movement (pseudoEMG) on the analog output of the NIcard
    %set(handles.t_msg,'String','Generate pseudoEMG signals...');
    disp('Generate pseudoEMG signals...');
    queueOutputData(s,movement2execute*(strength/100));
    s.startForeground;
    %s.wait;

    %% stop the CONTROL_MODE on the ALC-D (COMMAND MODE again)
    fwrite(commObj,hex2dec('AA'),'char');
    replay = char(fread(commObj,4,'char')');
    if strcmp(replay,'COMM')
        %set(handles.t_msg,'String','ALC-D COMMAND MODE enabled...');
        disp('ALC-D COMMAND MODE enabled...');
    else
        %set(handles.t_msg,'String','(ERRORCODE 6) Error Setting COMMAND MODE');
        disp('(ERRORCODE 6) Error Setting COMMAND MODE');
        fclose(commObj);
        return
    end
    
    %% stop the NIcard output
    disp('Stop pseudoEMG signals...');
    queueOutputData(s,[0 0]);
    s.startForeground;
    
    %% download data from the oscilloscope (if neurostimulator included in test)
    if neurostimulator
        %set(handles.t_msg,'String','Downloading oscilloscope data...');
        disp('Downloading oscilloscope data...');
        oscilloscopeData = getWaveform(myScope);
        disconnect(myScope);     
    end
    
    %% read the current pointer (block index) for the logFile in the ALC-D
    %set(handles.t_msg,'String','Retrieving last memory location used...');
    disp('Retrieving last memory location used (after test)...');
    blockDimension = 512;
    fwrite(commObj,'n','char');
    replay = char(fread(commObj,1,'char'));
    if strcmp(replay,'n')
        LastLocationUsed = fread(commObj,1,'uint32');
        replay = char(fread(commObj,1,'char'));
        if strcmp(replay,'n')
            message = sprintf('ALC-D memory state: %0.0fB on %0.0fGB, %d, block Idx = %0.0f ', LastLocationUsed*blockDimension, 2, (LastLocationUsed*blockDimension*100/16000000000), LastLocationUsed);
            %set(handles.t_msg,'String', message);
            disp(message);
            drawnow;
        else
            %set(handles.t_msg,'String','(ERRORCODE 4) Error reading ALC-D SDcard'); 
            fclose(commObj);
            return
        end
    else
        %set(handles.t_msg,'String','(ERRORCODE 4) Error reading ALC-D SDcard'); 
        fclose(commObj);
        return
    end

    %% download the logFile
    %set(handles.t_msg,'String','Downloading ALC-D LogFile...');
    disp('Downloading ALC-D LogFile...');
%     numBlocks = (length(movement2execute)/sF)/newPredictionTime;
    numBlocks = LastLocationUsed - startLocation;
    address = startLocation;
    logFile_raw = zeros(numBlocks,blockDimension);
    w = warning('error', 'instrument:fread:unsuccessfulRead');
    fwrite(commObj,'m','char');
    replay = char(fread(commObj,1,'char'));
    if strcmp(replay,'m')
        fwrite(commObj,numBlocks,'uint32');
        fwrite(commObj,address,'uint32');
        for i = 1:numBlocks 
            try
                logFile_raw(i,:) = fread(commObj,blockDimension,'uint8');
                message = sprintf('The download might take some minutes... %d on %d', i, numBlocks);
                %set(handles.t_msg,'String', message);
                drawnow;
            catch 
               %set(handles.t_msg,'String','(ERRORCODE 7) Error in communication: not all blocks were downloaded'); 
               disp('(ERRORCODE 7) Error in communication: not all blocks were donwloaded');
               delete(commObj);
               return
            end
            warning(w)
        end
        replay = char(fread(commObj,1,'char'));
        if strcmp(replay,'m')
            %set(handles.t_msg,'String','ALC-D SDcard read successful');
        else
            %set(handles.t_msg,'String','(ERRORCODE 8) Error while reading ALC-D SDcard'); 
        end
    else
        %set(handles.t_msg,'String','(ERRORCODE 9) Error while reading ALC-D SDcard'); 
    end
    disp(commObj);
    fclose(commObj);
    
    %% interpret the logFile
    logFile = loadLogFile(logFile_raw, newPredictionTime);
    
    %% prepare the structure to be returned
    testData.movement2execute = movement2execute;
    testData.strength = strength;
    testData.logFile = logFile;
    if neurostimulator
        testData.oscilloscopeData = oscilloscopeData;
    end
    % Plot results
    if plots
        % signals vs movements
        sF = 1000;
        time = length(movement2execute)/sF;
        tv = 0:1/sF:time-1/sF;
        figure
        set(gcf,'color','white')
        ax1 = subplot(4,1,1);
        plot(tv, movement2execute)
        title('input signals vs time')
        ylabel('[V]')
        xlabel('time [s]')
        legend('OPEN', 'CLOSE')
        sF = 1/newPredictionTime;
        time = logFile.numLogUnits*newPredictionTime;
        tv = 0:1/sF:time-1/sF;
        ax2 = subplot(4,1,2);
        plot(tv, [logFile.LogUnits.tmabs1 logFile.LogUnits.tmabs2])
        title('processed signals vs time')
        ylabel('[V]')
        xlabel('time [s]')
        legend('OPEN', 'CLOSE')
        ax3 = subplot(4,1,3);
        plot(tv, logFile.LogUnits.outIdx, 'x-b')
        title('predicted movement vs time')
        ylabel('[Class]')
        xlabel('time [s]')
        ax4 = subplot(4,1,4);
        plot(tv, logFile.LogUnits.activLevel, 'x-b')
        title('predicted strength vs time')
        ylabel('[Value]')
        xlabel('time [s]')
        % sensors vs stimulation
        sF = 1/newPredictionTime;
        time = logFile.numLogUnits*newPredictionTime;
        tv = 0:1/sF:time-1/sF;
        figure
        set(gcf,'color','white')
        ax1 = subplot(3,1,1);
        plot(tv, logFile.LogUnits.sensors.pad1, 'r')
        hold
        plot(tv, logFile.LogUnits.sensors.pad2, 'm')
        plot(tv, logFile.LogUnits.sensors.pad3, 'c')
        title('pad sensor values vs time')
        ylabel('value')
        xlabel('time [s]')
        legend('PAD1', 'PAD2', 'PAD3')
        if neurostimulator
            ax3 = subplot(3,1,3);
            plot(tv, logFile.LogUnits.stimFreq, 'x-r')
            title('stimulation frequency vs time')
            ylabel('[Hz]')
            xlabel('time [s]')
            sF = 1000;
            time = length(movement2execute)/sF;
            sF = 1e6/time;
            tv = 0:1/sF:time-1/sF;
            ax2 = subplot(3,1,2);
            plot(tv, oscilloscopeData, 'x-r')
            title('stimulation vs time')
            ylabel('[V]')
            xlabel('time [s]')
            linkaxes([ax1,ax2,ax3],'x');
        end
        % battery and temperature
        sF = 1/newPredictionTime;
        time = logFile.numLogUnits*newPredictionTime;
        tv = 0:1/sF:time-1/sF;
        figure
        set(gcf,'color','white')
        ax1 = subplot(2,1,1);
        plot(tv, logFile.LogUnits.vBattery, 'x-g')
        title('battery voltage vs time')
        ylabel('[V]')
        xlabel('time [s]')
        ax1 = subplot(2,1,2);
        plot(tv, logFile.LogUnits.sensors.temperature, 'x-')
        title('temperature vs time')
        ylabel('[Celsius degrees]')
        xlabel('time [s]')
    end
    %set(handles.t_msg,'String','ALC-D system test: single run completed!');
    disp('ALC-D system test: single run completed!');  
    
end


%%% Convert the raw logFile from bytes to a readable structure 
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
function processedLogFile = loadLogFile(LogFile_raw, newPredictionTime)
    %% Convert raw data from SD card into bytes structure (logUnits)
    numBlocks = size(LogFile_raw,1);       
    dimLogUnit = 48;
    indxs = 1:dimLogUnit:480;
    LogUnits_raw = [];
    for i = 1:numBlocks
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
   
    %% prepare the structure to be returned
    processedLogFile.time = numLogUnits*newPredictionTime;      
    processedLogFile.numLogUnits = numLogUnits;
    processedLogFile.LogUnits = LogUnits;
    processedLogFile.dimLogUnit = dimLogUnit;
    processedLogFile.powerOns = powerOns;

end

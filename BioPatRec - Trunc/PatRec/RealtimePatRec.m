function handlesX = RealtimePatRec(patRecX, handlesX)
% Real-time pattern recognition: LimbMATE, SQ+/OTB400 adapter, NI, legacy.
% Optional Mia hand control (works with any acquisition device).

    clear global;
    clear persistent;

    global patRec handles nTW procT motorCoupling vreCoupling TAC;
    global pwmIDs pwmAs pwmBs tempData outVectorMotorLast currentDegPerMovLast;
    global thresholdGUIData outMovs tSets;
    global miaHand miaVoter;

    %% ---- User settings ----
    miaPort     = 6;       % TEST: hardcoded. Use 'ask' for a remembered port / selection dialog
    useMia      = true;    % set false to disable Mia completely
    miaSelfTest = false;   % true: force Close at ~2 s and Open at ~6 s (LimbMATE only)

    patRec   = patRecX;
    handles  = handlesX;
    nTW      = 1;
    procT    = [];
    tempData = [];
    outMovs  = [];
    tSets    = [];
    outVectorMotorLast   = zeros(patRec.nOuts,1);
    currentDegPerMovLast = zeros(patRec.nOuts,1);

    % Get needed info from patRec structure
    if isfield(patRec,'vCh'), handles.vCh = patRec.vCh; end
    sF          = patRec.sF;
    trainedCh   = patRec.nCh;            % channel indices (or count) used in training
    nCh         = length(patRec.nCh);
    ComPortType = patRec.comm;
    deviceName  = patRec.dev;

    sT  = str2double(get(handles.et_testingT,'String'));
    tW  = patRec.tW;
    tWs = round(tW*sF);
    iW  = patRec.wOverlap;
    iWs = max(1, round(iW*sF));
    oW  = tW - iW;

    %% ---- Mia hand (optional, connect + calibrate BEFORE streaming starts) ----
    miaHand  = [];
    miaVoter = MiaVote();
    miaCleanup = []; %#ok<NASGU>
    if useMia
        try
            miaPortName = resolveMiaPort(miaPort, patRec);

            if ~isempty(miaPortName) && any(strcmpi(cellstr(serialportlist("all")), miaPortName))
                fprintf('[Mia] using %s\n', miaPortName);
                miaHand = MiaHand(miaPortName);
                miaHand.calibrate();     % blocking ~8 s, must not run while streaming
                setpref('BioPatRec','MiaPort',miaPortName);   % remember for next time
                miaCleanup = onCleanup(@cleanupMia);
            elseif ~isempty(miaPortName)
                fprintf('[Mia] %s not found, Mia disabled.\n', miaPortName);
            end
        catch ME
            warning('[Mia] disabled: %s', ME.message);
            cleanupMia();
        end
    end

    %% ---- Decide acquisition route ----
    useAdapter = isSQplus(deviceName) || isOTB400(deviceName);
    useLM      = isLimbMATE(deviceName);
    lmCleanup  = []; %#ok<NASGU>

    %% ---- LimbMATE: scan, connect, configure ----
    if useLM
        objLM = LimbMATE_BioPatRec();
        objLM.connectBTdongle(patRec.comn);
        objLM.scanDevicesStart();
        objLM.scanDevicesStop();
        objLM.getDevicesInfo();

        lmIdx = 0;
        for k = 1:numel(objLM.BTdevices)
            nameK = char(objLM.BTdevices(k).DeviceName);
            if startsWith(upper(nameK),'LM') || startsWith(upper(nameK),'LIMBMATE')
                lmIdx = k;
                fprintf('[RealtimePatRec] Auto-picked BT device "%s"\n', nameK);
                break
            end
        end
        if lmIdx == 0
            try, delete(objLM.serialObj); catch, end
            error('RealtimePatRec:LMNotFound', ...
                  'No LM-prefixed device in scan. Saw: %s', ...
                  strjoin(arrayfun(@(b) string(char(b.DeviceName)), objLM.BTdevices, 'UniformOutput', false), ', '));
        end
        objLM.BTindex = lmIdx;
        objLM.connectFoundBTmodule();
        lmCleanup = onCleanup(@() safeStopLM(objLM));   % guarantees disconnect on any error
        pause(1.5);
        try, objLM.setSpeedBT("2");     catch ME, warning('setSpeedBT: %s', ME.message); end
        try, objLM.getDeviceName();     catch ME, warning('getDeviceName: %s', ME.message); end
        try, objLM.getDeviceFirmware(); catch ME, warning('getDeviceFirmware: %s', ME.message); end

        if isfield(patRec,'gains') && ~isempty(patRec.gains)
            g = patRec.gains;
        else
            g = 2 * ones(1,8);
        end
        fprintf('[RealtimePatRec] Forcing sample rate %d Hz, gain %d\n', patRec.sF, g(1));
        try
            objLM.setSampleFreqGain(patRec.sF, g);
        catch ME
            warning('setSampleFreqGain failed: %s', ME.message);
        end
        % Use the same electrode configuration as the recording
        if isfield(patRec,'config') && ~isempty(patRec.config)
            try, objLM.setElectrodesConfig(patRec.config); catch, end
        else
            try, objLM.setElectrodesConfig("Differential"); catch, end
        end

        handles.objLM = objLM;
        fprintf('[RealtimePatRec] LimbMATE connected on %s\n', patRec.comn);
    end

    %% ---- SQ+ / OTB400 adapter ----
    if useAdapter
        afeLocal = struct();
        afeLocal.name         = deviceName;
        afeLocal.channels     = nCh;
        afeLocal.sampleRate   = sF;
        afeLocal.ComPortType  = ComPortType;
        afeLocal.plotType     = 'Raw Signal';
        afeLocal.featureType  = 'MAV';
        afeLocal.prepare      = 0;
        afeLocal.compressData = 0;
        afeLocal.objOT        = [];
        afeLocal.objSQ        = [];
        % Release an adapter left open by the recording GUI (the OTB device
        % cannot be opened twice)
        if isfield(handles,'adapter') && ~isempty(handles.adapter)
            try, handles.adapter.disconnect(); catch, end
        end

        % DeviceFactory only wraps afeSettings.objOT, so real-time must create it
        % (same device type and electrodes as the recording).
        if isOTB400(deviceName)
            [selection, ok] = OTB400_SelectInputs(deviceName);
            if ~ok, error('RealtimePatRec:OTBCancelled','User cancelled OTB selection.'); end
            afeLocal.objOT = OT_Acquire('inputs', selection, max(60,sT+10));
        elseif isSQplus(deviceName) && isempty(afeLocal.objSQ)
            warning('[SQ+] afeLocal.objSQ is empty; SQPlusAdapter may have nothing to read from.');
        end

        handles.adapter = DeviceFactory(deviceName, nCh, sF, handles, afeLocal);
        adapterCleanup = onCleanup(@() safeStopAdapter(handles.adapter)); %#ok<NASGU>

        % OTB400Adapter.start() is empty and OT_Acquire.getEMG_data_TW_float
        % errors until the stream is started. startAcquisitionEMG is idempotent.
        if isOTB400(deviceName)
            try
                ot = handles.adapter.objOT;
                if ~isempty(ot), ot.startAcquisitionEMG(); end
            catch ME
                warning('[OTB] start failed: %s', ME.message);
            end
        end
    end

    %% ---- Threshold GUI ----
    if isfield(patRec.patRecTrained,'thOut')
        thresholdGUI = GUI_Threshold;
        thresholdGUIData = guidata(thresholdGUI);
        set(GUI_Threshold,'CloseRequestFcn','set(GUI_Threshold, ''Visible'', ''off'')');
        xpatch = [1 1 0 0];
        ypatch = [0 0 0 0];
        for i = 0:patRec.nOuts-1
            s  = sprintf('movementSelector%d',i);
            s0 = sprintf('thPatch%d',i);
            s1 = sprintf('meter%d',i);
            axes(thresholdGUIData.(s1));
            handles.(s0) = patch(xpatch,ypatch,'b','EdgeColor','b','EraseMode','normal','visible','on');
            ylim(thresholdGUIData.(s1),[0 1]);
            xlim('auto');
            set(thresholdGUIData.(s),'String',patRec.mov(patRec.indMovIdx));
            if size(patRec.mov(patRec.indMovIdx),1) < i+1
                set(thresholdGUIData.(s),'Value',size(patRec.indMovIdx,2));
            else
                set(thresholdGUIData.(s),'Value',i+1);
            end
        end
    end

    %% ---- VRE / motor coupling ----
    vreCoupling = 0;
    if isfield(handles,'vre_Com')
        vreCoupling = strcmp(handles.vre_Com.Status,'open');
    end
    if isfield(handles,'cb_motorCoupling')
        motorCoupling = get(handles.cb_motorCoupling,'Value');
    else
        motorCoupling = 0;
    end
    if motorCoupling
        if ~isfield(handles,'Control_obj')
            set(handles.t_msg,'String','No connection obj found');
            return;
        end
        if ~strcmp(handles.Control_obj.status,'open')
            fopen(handles.Control_obj);
        end
    end

    cData = zeros(iWs,nCh); %#ok<NASGU>

    %%%%% NI DAQ %%%%%
    if strcmp(ComPortType,'NI')
        sCh = patRec.nCh;
        if strcmp(deviceName,'Thalmic MyoBand')
            s = MyoBandSession(sF,sT,sCh);
        else
            s = InitSBI_NI(sF,sT,sCh);
        end
        s.NotifyWhenDataAvailableExceeds = iWs;
        lh = s.addlistener('DataAvailable',@RealtimePatRec_OneShot);
        s.startBackground();
        if ~s.IsDone, s.wait(); end
        if ~strcmp(deviceName,'Thalmic MyoBand'), delete(lh); end
        if strcmp(deviceName,'Thalmic MyoBand'), MyoClient('StopSampling'); end

    %%%%% LimbMATE %%%%%
    elseif useLM
        if tWs <= 100
            samples_tw_encoded = uint8(1);
        elseif tWs <= 200
            samples_tw_encoded = uint8(2);
        else
            error('RealtimePatRec:TWsTooLarge', ...
                  'LimbMATE firmware supports max 200 samples per TW; tWs = %d', tWs);
        end
        active_channels_encoded    = uint8(255);
        samples_tw_encoded         = samples_tw_encoded;
        samples_tw_overlap_encoded = uint8(0);

        try
            handles.objLM.startAcquisitionEMG(1, active_channels_encoded, ...
                samples_tw_encoded, samples_tw_overlap_encoded);
        catch ME
            error('RealtimePatRec:LMStart','startAcquisitionEMG failed: %s',ME.message);
        end

        handles.objLM.packages_per_TW           = tWs / 5;
        handles.objLM.packages_per_TW_increment = tWs / 5;
        fprintf('[RealtimePatRec] packages_per_TW = %d, tWs = %d, trainedCh = %s\n', ...
                handles.objLM.packages_per_TW, tWs, mat2str(trainedCh));

        % Each iteration reads a full window of tWs samples (tW seconds)
        max_num_iteration = floor(sT / tW);

        for timeWindowNr = 1:max_num_iteration
            raw = handles.objLM.getEMG_data_TW_float(tWs);   % [8 x tWs]

            % Only the channel(s) the model was trained on
            if size(raw,1) >= max(trainedCh)
                cData = raw(trainedCh,:)';                   % [tWs x numel(trainedCh)]
            else
                cData = raw(1:nCh,:)';
            end

            if mod(timeWindowNr,10) == 0
                fprintf('[diag] win %3d\n  mean=%s\n  std =%s\n', timeWindowNr, ...
                    mat2str(round(mean(raw,2)'),5), mat2str(round(std(raw,0,2)',1),5));
            end

            acquireEvent.Data = cData;
            RealtimePatRec_OneShot(0,acquireEvent);

            if miaSelfTest && ~isempty(miaHand)
                if timeWindowNr == 10, miaHand.act('Close Hand'); end
                if timeWindowNr == 30, miaHand.act('Open Hand');  end
            end
        end

        % Flush leftover frames so the stop reply is not confused with EMG data
        try, flush(handles.objLM.serialObj,"input"); catch, end
        try, handles.objLM.stopAcquisitionEMG(); catch, end

        try
            integrity = handles.objLM.getRecordingIntegrity();
            if isfield(integrity,'replacedSamples') && integrity.replacedSamples > 0
                warning('LM:ReplacedSamples', ...
                    'LimbMATE: %d samples replaced during this session.', ...
                    integrity.replacedSamples);
            end
        catch
        end

    %%%%% SQ+ / OTB400 adapter %%%%%
    elseif useAdapter
        if iW == 0
            max_num_iteration = sT - oW;
        else
            max_num_iteration = (sT - oW) / iW;
        end
        for timeWindowNr = 1:max_num_iteration
            cData = handles.adapter.read(iWs);
            % The device returns all channels (8, 64 or 128); keep only the trained ones
            if size(cData,2) > numel(trainedCh) && max(trainedCh) <= size(cData,2)
                cData = cData(:,trainedCh);
            end
            acquireEvent.Data = cData;
            RealtimePatRec_OneShot(0,acquireEvent);
        end
        try, handles.adapter.stop();       catch, end
        try, handles.adapter.disconnect(); catch, end

    %%%%% Legacy %%%%%
    else
        handles.deviceName  = deviceName;
        handles.ComPortType = ComPortType;
        if strcmp(ComPortType,'COM')
            handles.ComPortName = patRec.comn;
        end
        handles.sF    = sF;
        handles.sT    = sT;
        handles.nCh   = nCh;
        handles.sTall = sT;

        if isfield(handles,'obj')
            delete(handles.obj);
        end
        if strcmp(deviceName,'OTB400_bipolar')
            handles.objOT = OT_Acquire('bipolar',max(patRec.nCh),max(60,sT+10));
            otCleanup = onCleanup(@() handles.objOT.disconnectBTdevice()); %#ok<NASGU>
        end

        obj = ConnectDevice(handles);
        handles.obj = obj;
        handles = SetDeviceStartAcquisition(handles,obj);

        if iW == 0
            max_num_iteration = sT - oW;
        else
            max_num_iteration = (sT - oW) / iW;
        end
        for timeWindowNr = 1:max_num_iteration
            if strcmp(deviceName,'OTB400_bipolar')
                cData = obj.getEMG_data_TW_float(iWs);
                cData = cData(:,patRec.nCh);
            else
                cData = Acquire_tWs(deviceName,obj,nCh,iWs);
            end
            acquireEvent.Data = cData;
            RealtimePatRec_OneShot(0,acquireEvent);
        end
        StopAcquisition(deviceName,obj);
    end

    %% ---- Stop motors ----
    if motorCoupling
        if ~strcmp(handles.Control_obj.status,'open')
            fopen(handles.Control_obj);
        end
        if isfield(handles,'movList')
            for i = 1:length(handles.movList)
                [handles.motors,~] = MotorsOff(handles.Control_obj,handles.movList(i),handles.motors);
            end
        else
            ActivateMotors(handles.com,pwmIDs,pwmAs,pwmBs,0);
        end
    end

    if numel(procT) > 1
        set(handles.et_avgProcTime,'String',num2str(mean(procT(2:end))));
    end

    if isfield(patRec.patRecTrained,'thOut')
        for i = 0:patRec.nOuts-1
            s0 = sprintf('thPatch%d',i);
            set(handles.(s0),'YData',[0 0 0 0]);
        end
    end

    % Release Mia (onCleanup also covers error paths); hand opens in delete()
    cleanupMia();

    % Do not hand a deleted LimbMATE object back to the GUI
    if isfield(handles,'objLM'), handles.objLM = []; end
    handlesX = handles;

    %% ---- Report ----
    fprintf('\n--- Real-time PatRec: predicted windows ---\n');
    for movementIndex = 1:numel(patRec.mov)
        fprintf('%s: %d\n', char(patRec.mov(movementIndex)), nnz(outMovs == movementIndex));
    end
    fprintf('VRE connected during test: %d\n', vreCoupling);
    fprintf('Movement degrees: ');
    disp(patRec.control.currentDegPerMov);

    if numel(procT) > 1
        figure();
        hist(procT(2:end));
    end
    set(handles.pb_RealtimePatRec,'Enable','on');
end


function RealtimePatRec_OneShot(src,event) %#ok<INUSL>

    global patRec nTW procT motorCoupling vreCoupling handles TAC;
    global pwmIDs pwmAs pwmBs tempData outVectorMotorLast currentDegPerMovLast;
    global thresholdGUIData outMovs tSets miaHand miaVoter;

    tempData = [tempData; event.Data];
    outVectorMotor = zeros(patRec.nOuts,1);
    outChanged = [];

    if size(tempData,1) >= round(patRec.sF*patRec.tW)

        if isfield(patRec,'addArtifact')
            timeLength = str2double(handles.et_testingT.String);
            tempDataArt = AddArtifactRealtime(tempData,timeLength);
            tData = tempDataArt(end-round(patRec.sF*patRec.tW)+1:end,:);
        else
            tData = tempData(end-round(patRec.sF*patRec.tW)+1:end,:);
        end

        procTimeS = tic;

        [outMov, outVector, tSet, patRec, handles] = OneShotRealtimePatRec(tData,patRec,handles,thresholdGUIData); %#ok<ASGLU>
        outMovs(nTW) = outMov(1);
        tSets(nTW,:) = tSet;

        % --- Mia: majority vote -> command (Rest and unknown are ignored) ---
        if ~isempty(miaHand) && isvalid(miaHand) && ~isempty(outMov)
            cmd = '';
            if outMov(1) ~= 0
                cmd = char(patRec.mov{outMov(1)});
            end
            v = miaVoter.push(cmd);
            if ~isempty(v) && ~strcmp(v,'Rest')
                try
                    miaHand.act(v);
                catch ME
                    warning('MiaHand error: %s',ME.message);
                end
            end
        end

        if get(handles.cb_keys,'Value') && outMov(1) ~= 0
            keys = zeros(patRec.nM,1);
            keys(outMov) = 1;
            savedKeys = [];
            if isfield(handles,'savedKeys'), savedKeys = handles.savedKeys; end
            SendKeys(keys,savedKeys);
        end

        if get(handles.cb_controls,'Value') && outMov(1) ~= 0
            controls = zeros(patRec.nM,1);
            controls(outMov) = 1;
            savedControls = [];
            if isfield(handles,'savedControls'), savedControls = handles.savedControls; end
            SendControls(controls,savedControls);
        end

        if isfield(handles,'movList')
            if motorCoupling
                outVectorMotor(outMov) = 1;
                outChanged = find(xor(outVectorMotor,outVectorMotorLast));
                speedChanged = find(transpose(patRec.control.currentDegPerMov) - currentDegPerMovLast);
                outChanged = union(outChanged,speedChanged);
                for i = 1:size(outChanged,1)
                    if outVectorMotor(outChanged(i))
                        [handles.motors,~] = MotorsOn(handles.Control_obj,handles.movList(outChanged(i)),handles.motors,patRec.control.currentDegPerMov(outChanged(i)));
                    else
                        [handles.motors,~] = MotorsOff(handles.Control_obj,handles.movList(outChanged(i)),handles.motors);
                    end
                end
            end

            if vreCoupling
                for i = 1:length(outMov)
                    speed = patRec.control.currentDegPerMov(outMov(i));
                    perfMov = handles.movList(outMov(i));
                    if VREActivation(handles.vre_Com,speed,[],perfMov.idVRE,perfMov.vreDir,get(handles.cb_moveTAC,'Value'))
                        TAC.acktimes = TAC.acktimes + 1;
                    end
                end
            end
        else
            if motorCoupling
                ActivateMotors(handles.com,pwmIDs,pwmAs,pwmBs,outMov);
            end

            if vreCoupling
                dof = round(outMov/2);
                dofs = [9,7,8,0,10];
                dir = mod(outMov,2);
                if dof == 1 && dir == 1
                    dof = 5;
                end
                if dir == 1
                    dir = 0;
                else
                    dir = 1;
                end
                if VREActivation(handles.vre_Com,25,[],dofs(dof),dir,get(handles.cb_moveTAC,'Value')) == 1
                    TAC.ackTimes = TAC.ackTimes + 1;
                end
            end
        end

        nTW = nTW + 1;
        outVectorMotorLast = outVectorMotor;
        currentDegPerMovLast = transpose(patRec.control.currentDegPerMov);
        procT(nTW) = toc(procTimeS);

        if motorCoupling && isfield(handles,'movList')
            for i = 1:size(outChanged,1)
                if or(handles.movList(outChanged(i)).motor == 8, ...
                      handles.movList(outChanged(i)).motor == 7)
                    outVectorMotorLast(outChanged(i)) = 0;
                end
            end
        end
    end
end


function name = resolveMiaPort(setting, patRec)
    % Returns the Mia serial port name, or '' to disable Mia.
    % setting: number (6), name ('COM6'), or 'ask' / 'auto'.
    name = '';
    if isnumeric(setting) && ~isempty(setting)
        name = sprintf('COM%d', setting);
        return
    end
    setting = char(setting);
    if ~any(strcmpi(setting, {'ask','auto'}))
        name = setting;
        return
    end

    % Free serial ports, without the EMG device's own port
    ports = cellstr(serialportlist("available"));
    if isfield(patRec,'comn') && ~isempty(patRec.comn)
        ports = ports(~strcmpi(ports, char(patRec.comn)));
    end
    if isempty(ports)
        fprintf('[Mia] no free serial port found. Mia disabled.\n');
        return
    end

    % Port that worked last time on this machine
    if ispref('BioPatRec','MiaPort')
        saved = getpref('BioPatRec','MiaPort');
        if any(strcmpi(ports, saved))
            name = saved;
            return
        end
    end

    % Otherwise let the user choose (once; remembered after a successful connection)
    items = [ports(:); {'No Mia hand'}];
    [idx, ok] = listdlg('PromptString','Select the Mia hand serial port:', ...
        'SelectionMode','single','ListString',items,'ListSize',[260 120]);
    if ok && idx <= numel(ports)
        name = ports{idx};
    end
end


function cleanupMia()
    global miaHand
    try
        if ~isempty(miaHand) && isvalid(miaHand)
            delete(miaHand);    % MiaHand.delete sends the Open command
        end
    catch
    end
    miaHand = [];
end


function safeStopAdapter(a)
    try, a.stop();       catch, end
    try, a.disconnect(); catch, end
end


function safeStopLM(objLM)
    try
        if ~isempty(objLM) && isvalid(objLM) && isprop(objLM,'emg_acquisition') && objLM.emg_acquisition
            objLM.stopAcquisitionEMG();
        end
    catch
    end
    try, objLM.disconnectBTdevice(); catch, end
    try, delete(objLM.serialObj);    catch, end
end


function plotDataTest(src,event) %#ok<DEFNU,INUSL>
    persistent tempData;
    global data
    if isempty(tempData)
        tempData = [];
        figure();
    end
    plot(event.TimeStamps,event.Data)
    tempData = [tempData; event.Data];
    data = tempData;
end

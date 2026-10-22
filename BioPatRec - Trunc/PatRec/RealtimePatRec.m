% ---------------------------- Copyright Notice ---------------------------
% This file is part of BioPatRec © which is open and free software under 
% the GNU Lesser General Public License (LGPL). See the file "LICENSE" for 
% the full license governing this code and copyrights.
%
% BioPatRec was initially developed by Max J. Ortiz C. at Integrum AB and 
% Chalmers University of Technology. All authors? contributions must be kept
% acknowledged below in the section "Updates % Contributors". 
%
% Would you like to contribute to science and sum efforts to improve 
% amputees? quality of life? Join this project! or, send your comments to:
% maxo@chalmers.se.
%
% The entire copyright notice must be kept in this or any source file 
% linked to BioPatRec. This will ensure communication with all authors and
% acknowledge contributions here and in the project web page (optional).
%
% -------------------------- Function Description -------------------------
% Function to execute real-time patrec using the offline trained algorithm
% which information is stored in patRec
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2011-07-27 / Max Ortiz  / Creation
% 2011-08-03 / Max Ortiz  / Separation of "SignalProcessing_RealtimePatRec"
% 2011-11-17 / Max Ortiz  / Added the motors coupling
% 2011-12-07 / Nichlas Sander / Added VRE Coupling and VRE commands.
% 2011-12-07 / Max Ortiz  / Upgrade to Session-based interface for DAQ, the
%                           prevous version was called RealtimePatRec_Legacy.m
% 2012-08-13 / Morten Kristoffersen  / Added GUI interface to see and control 
% 									   the threshold values for the MLP ThOut algorithm.
% 2012-10-05 / Joel Falk-Dahlin / Changed inputs and outputs of
%                                 ApplyControl to work with updated version.
%                                 Removed InitControl since it is
%                                 performed inside the GUI
% 2012-10-26 / Joel Falk-Dahlin / Added ApplyProportionalControl
% 2012-11-06 / Max Ortiz        / Create RealimePatRec_OneShot to concentrate
%                                 critical routines of realtimepatrec
% 2012-11-23 / Joel Falk-Dahlin / Moved speeds from handles to patRec,
%                                 changed VRE to use the new speeds
% 2013-04-17 / Max Ortiz        / Made independent routines for control of
%                                 differend devices
% 2013-06-03 / Max Ortiz        / Addition of necessary routines to control
%                                 Standard proshetic components (SPC) using wifi.
% 2014-11-12 / Enzo Mastinu     / Added code for ADS1299 AFE RealTime PatRec
% 2015-01-20 / Enzo Mastinu     / All this function has been re-organized
%                                 to be compatible with the functions
%                                 placed into COMM/AFE folder. For more
%                                 details read about RecordingSession.m with 
%                                 other custom devices for BioPatRec_TRE.
% 2016-02-10 / Max Ortiz        / change the initialization of the NI card
%                                 to use the vector of channels rather than only the number
% 2016-04-15 / Julian Maier     / Artificial artifact inseration (Line 268)   
% 2018-02-23/ James Austin      / Added window overlap as the cycletime for real time
%                                 pattern recognition implementation from
%                                 NI devices (replacing tWs for PEEK time). 
%                               / Added currentDegPerMovLast array to induce program
%                                 to send a new signal to the motors of an
%                                 external device whenever either the movement class
%                                 *or* the velocity changes (i.e. external
%                                 devices will now work with velocity ramp
%                                 or other velocity-variant control methods).
% 20xx-xx-xx / Author  / Comment on update

function handlesX = RealtimePatRec(patRecX, handlesX)

    clear global;
    clear persistent;

    global patRec;
    global handles;
    global nTW;
    global procT;
    global motorCoupling;
    global vreCoupling;
    global pwmIDs;
    global pwmAs;
    global pwmBs;
    global tempData;
    global outVectorMotorLast;
    
    %global data;            % only needed for testing
    global thresholdGUIData;
    global outMovs;
    global tSets;

    patRec   = patRecX;
    handles  = handlesX;
    nTW      = 1;
    procT    = [];
    tempData = [];
    outVectorMotorLast = zeros(patRec.nOuts,1);
    currentDegPerMovLast = zeros(patRec.nOuts,1);
    
    % Get needed info from patRec structure
    if isfield(patRec,'vCh')
        handles.vCh = patRec.vCh;
    end
    sF                  = patRec.sF;
    nCh                 = length(patRec.nCh);       
    ComPortType         = patRec.comm;
    deviceName          = patRec.dev;
                         
    % Get sampling time
    sT = str2double(get(handles.et_testingT,'String'));
    tW = patRec.tW;                                                        % Time window size
    tWs = round(tW*sF);                                                           % Time window samples
    iW = patRec.wOverlap;
    iWs = max(1, round(iW*sF));
    oW = tW-iW;                                                  % Timestep length from window overlap
    oWs = tWs-iWs;                                                           % Overlap samples

    % Initialze control algorithms
    %patRec = InitControl(patRec); % No longer needed, Initialization is done in GUI

    %% Start the connection with Limb-MATE
    if (strcmp(deviceName, 'LM 1') || strcmp(deviceName, 'LM 2') || strcmp(deviceName, 'LM 3') )
        % Create object for device and connection
        objLM = LimbMATE_BioPatRec();
    
        % Connect to Bluetooth USB stick
    %              obj.disconnectBTdevice();
        ComPortName = patRec.comn;
        objLM.connectBTdongle(ComPortName);
    
        % Find Bluetooth Devices and Connect to BT device with name "LMATE"
        BTspeed = "2";
        objLM.connectBTdevice(deviceName{1,1}, BTspeed);
    
        % Check MIA connession
        objLM.enable_MIA_connection(get(handles.cb_MIA,'Value'))
    end
    if exist('objLM','var')
        handles.objLM = objLM;
    else
        handles.objLM = [];
    end

    %% Is threshold (thOut) used?
    if(isfield(patRec.patRecTrained,'thOut'));
        %Threshold GUI init
        thresholdGUI = GUI_Threshold; 
        thresholdGUIData = guidata(thresholdGUI);
        set(GUI_Threshold,'CloseRequestFcn', 'set(GUI_Threshold, ''Visible'', ''off'')');
        xpatch = [1 1 0 0];
        ypatch = [0 0 0 0];
            for i=0:patRec.nOuts-1
                s = sprintf('movementSelector%d',i);
                s0 = sprintf('thPatch%d',i);
                s1 = sprintf('meter%d',i);
                axes(thresholdGUIData.(s1));
                handles.(s0) = patch(xpatch,ypatch,'b','EdgeColor','b','EraseMode','normal','visible','on');
                ylim(thresholdGUIData.(s1), [0 1]);
                xlim('auto');
                set(thresholdGUIData.(s),'String',patRec.mov(patRec.indMovIdx));
                if (size(patRec.mov(patRec.indMovIdx),1) < i+1); 
                    set(thresholdGUIData.(s),'Value',size(patRec.indMovIdx,2));
                else
                    set(thresholdGUIData.(s),'Value',i+1);
                end
            end
    end

    %% Is the VRE selected?
    vreCoupling = 0;
    if isfield(handles,'vre_Com');  
        %If there is a vre communication, is it open?
        vreCoupling = strcmp(handles.vre_Com.Status,'open');
    end

    %% Is there an option for coupling with the motors?
    if isfield(handles,'cb_motorCoupling') %&& ~isfield(handles,'com')
        motorCoupling = get(handles.cb_motorCoupling,'Value');    
    else
        motorCoupling = 0;
    end

%     % Init variables for hard-coded control (not using objects) %% CHECK
%     if motorCoupling && ~isfield(handles,'movList')
%         if deviceID == 1 % Multifunctinal prosthesis with DC motors 
%             [pwmIDs pwmAs pwmBs] = InitMF_Hand_DC_Hardcoded(handles);        
%         elseif deviceID == 3  % Standard prosthetic units (wireless)
% 
%         end
%     end
    
    % Get connection object for control external robotic devices
    if motorCoupling
        if ~isfield(handles,'Control_obj')
            set(handles.t_msg,'String','No connection obj found');   
            return;
        end
        if ~strcmp(handles.Control_obj.status,'open')
            fopen(handles.Control_obj);
        end        
    end

    cData = zeros(iWs,nCh);
    
    %%%%% Real Time PatRec with NI DAQ card %%%%%
    if strcmp (ComPortType, 'NI')

        % Init SBI
        sCh = patRec.nCh;                                                  % Vector of channels
        if strcmp(deviceName, 'Thalmic MyoBand')
            %CK: init MyoBand
            s = MyoBandSession(sF, sT, sCh);
        else
            s = InitSBI_NI(sF,sT,sCh); 
        end 
        s.NotifyWhenDataAvailableExceeds = iWs;                            % PEEK time
        lh = s.addlistener('DataAvailable', @RealtimePatRec_OneShot); 

        % Start DAQ
        s.startBackground();                                               % Run in the backgroud

        if ~s.IsDone                                                       % check if is done
            s.wait();
        end
        
        
        if ~strcmp(deviceName, 'Thalmic MyoBand')
            delete(lh);
        end
        %CK: Stop sampling from MyoBand
        if strcmp(deviceName, 'Thalmic MyoBand')
            MyoClient('StopSampling');
        end
    %%%%% Real Time PatRec with other custom device %%%%%   
    else

        % Prepare handles for next function calls
        handles.deviceName  = deviceName;
        handles.ComPortType = ComPortType;
        if strcmp (ComPortType, 'COM')
            handles.ComPortName = patRec.comn;
        end
        handles.sF          = sF;
        handles.sT          = sT;
        handles.nCh         = nCh;
        handles.sTall       = sT;

        % Delete connection object
        if isfield(handles,'obj')
            delete(handles.obj);
        end

        % Open the bipolar adapter before using the shared acquisition path.
        if strcmp(deviceName, 'OTB400_bipolar')
            handles.objOT = OT_Acquire('bipolar', max(patRec.nCh), max(60,sT+10));
            otCleanup = onCleanup(@() handles.objOT.disconnectBTdevice());
        end

        % Connect the chosen device, it returns the connection object
        obj = ConnectDevice(handles);
        handles.obj = obj;

        % Set the selected device and Start the acquisition
        handles = SetDeviceStartAcquisition(handles, obj);

        % Deal when no overlap is selected
        if (iW == 0)
            max_num_iteration = sT-oW;
        else
            max_num_iteration = (sT-oW)/iW;
        end
        for timeWindowNr = 1:max_num_iteration

            if strcmp(deviceName, 'OTB400_bipolar')
                cData = obj.getEMG_data_TW_float(iWs);
                cData = cData(:,patRec.nCh);
            else
                cData = Acquire_tWs(deviceName, obj, nCh, iWs);
            end            % acquire a new time window of samples
            acquireEvent.Data = cData;
            RealtimePatRec_OneShot(0, acquireEvent);                       
        end

        % Stop acquisition
        StopAcquisition(deviceName, obj);
    end

    % Disconnect the LimbMate Device
    if strcmp(deviceName, 'LM 1') || strcmp(deviceName, 'LM 2') || strcmp(deviceName, 'LM 3')
        l1 = length(handles.obj.temp_streamed_control);
        LM_outMovs = zeros(1, l1);
        for i=1:l1
            LM_outMovs(i) = handles.obj.temp_streamed_control(i).outIndex;
            if  LM_outMovs(i) == 0
                LM_outMovs(i) = patRec.nM;
            end
        end
        acc = sum(outMovs==LM_outMovs(1:end-4+1))/(l1-3);
        figure, 
        plot(1:l1-3, outMovs, 'go', 'LineWidth', 2), hold on, plot(1:l1-3, LM_outMovs(1:l1-3), 'bo', 'LineWidth', 2), legend('PC','MCU'), title(['Comparison Classification PC-LM - Mutual ACC:', num2str(acc)])
        
        % Disable MIA connession
        objLM.enable_MIA_connection(0)
        objLM.disconnectBTdevice();
        delete(objLM.serialObj);
        handles.objLM = [];
    end
    
    %Stop motors
    if motorCoupling
        if ~strcmp(handles.Control_obj.status,'open')
            fopen(handles.Control_obj);
        end   
        if(isfield(handles,'movList')) % Is the movement obj used?
            for i=1 : length(handles.movList)
                [handles.motors, ~] = MotorsOff(handles.Control_obj, handles.movList(i), handles.motors);
            end
        else % from hardcoded GUI GUI_TestPatRec
            ActivateMotors(handles.com, pwmIDs, pwmAs, pwmBs, 0);
        end
    end

    % Write the average processing time
    set(handles.et_avgProcTime,'String',num2str(mean(procT(2:end))));

    handlesX = handles;

    %Reset Threshold GUI 
    if(isfield(patRec.patRecTrained,'thOut'));
        for i=0:patRec.nOuts-1
            s0 = sprintf('thPatch%d',i);
            set(handles.(s0), 'YData', [0 0 0 0]);
            %delete(GUI_Threshold);
        end
    end

    % Report actual predictions separately from processing-time statistics.
    fprintf('\n--- Real-time PatRec: predicted windows ---\n');
    for movementIndex = 1:numel(patRec.mov)
        fprintf('%s: %d\n', char(patRec.mov(movementIndex)), ...
            nnz(outMovs == movementIndex));
    end
    fprintf('VRE connected during test: %d\n', vreCoupling);
    fprintf('Movement degrees: ');
    disp(patRec.control.currentDegPerMov);

    %Plot processing time
    figure();
    hist(procT(2:end));
    set(handles.pb_RealtimePatRec, 'Enable', 'on');   

    

end


function RealtimePatRec_OneShot(src,event)

    global patRec;
    global nTW;
    global procT;
    global motorCoupling;
    global vreCoupling;
    global handles;
    global TAC;
    global pwmIDs;
    global pwmAs;
    global pwmBs;    
    global tempData;
    global outVectorMotorLast;
    global currentDegPerMovLast; 
	global thresholdGUIData;
    global outMovs;
    global tSets;
    

    %Keep saving all recorded data
    tempData = [tempData; event.Data];
    
    %Output vector
    outVectorMotor = zeros(patRec.nOuts,1);
    
    %Only considered the data once it has at least the size of time window
    if size(tempData,1) >= round(patRec.sF*patRec.tW)
		
		% Add artifact if required
        if isfield(patRec,'addArtifact')
            timeLength=str2double(handles.et_testingT.String);
            tempDataArt = AddArtifactRealtime(tempData,timeLength);
            tData = tempDataArt(end-round(patRec.sF*patRec.tW)+1:end,:);
        else % Copy the temporal data to the test data
            tData = tempData(end-round(patRec.sF*patRec.tW)+1:end,:);
        end

        % Start of processing time
        procTimeS = tic;

        % General routine for RealtimePatRec
        [outMov outVector tSet patRec handles] = OneShotRealtimePatRec(tData, patRec, handles, thresholdGUIData);
        outMovs(nTW) = outMov;
        tSets(nTW,:) = tSet;
        % GUI and control Updates
        
        % Game control        
        if get(handles.cb_keys,'Value') && outMov(1) ~= 0
            keys = zeros(patRec.nM,1);
            keys(outMov) = 1;
            savedKeys = [];
            if isfield(handles,'savedKeys')
               savedKeys = handles.savedKeys; 
            end
            SendKeys(keys,savedKeys);
        end
        
        
        % Robot control
        if get(handles.cb_controls,'Value') &&outMov(1) ~=0
            controls = zeros(patRec.nM,1);
            controls(outMov) = 1;
            savedControls = [];
            if isfield(handles,'savedControls')
               savedControls = handles.savedControls; 
            end
            SendControls(controls,savedControls);
        end
                
        % Send vector to the motors
        if(isfield(handles,'movList'))
            if motorCoupling
                % Update outvectorMotor
                outVectorMotor(outMov) = 1;
                % Check if the state has change
                outChanged = find(xor(outVectorMotor, outVectorMotorLast));
                % Check if the velocity has changed by finding non-zero
                % differences between current velocity and previous
                % velocity (currentDegPerMovLast)
                speedChanged = find(transpose(patRec.control.currentDegPerMov) - currentDegPerMovLast);
                outChanged = union(outChanged, speedChanged);
                % Only send information to the motors that have changed state
                for i = 1 : size(outChanged,1)
                    if outVectorMotor(outChanged(i))
                        [handles.motors, ~] = MotorsOn(handles.Control_obj, handles.movList(outChanged(i)), handles.motors, patRec.control.currentDegPerMov(outChanged(i)));
                    else
                        [handles.motors, ~] = MotorsOff(handles.Control_obj, handles.movList(outChanged(i)), handles.motors);
                    end
                end    
            end  
            
            % VRE
            if vreCoupling
                for i = 1:length(outMov)
                    speed = patRec.control.currentDegPerMov(outMov(i));
                    perfMov = handles.movList(outMov(i));
                    if VREActivation(handles.vre_Com, speed, [], perfMov.idVRE, perfMov.vreDir, get(handles.cb_moveTAC,'Value'))
                       TAC.acktimes = TAC.acktimes + 1; 
                    end
                end
            end
        else % alternative way for motor control (hard-coded)
            if motorCoupling
                ActivateMotors(handles.com, pwmIDs, pwmAs, pwmBs, outMov);
            end

            if vreCoupling
                dof = round(outMov/2);
                dofs = [9,7,8,0,10];
                dir = mod(outMov,2);

                if (dof == 1 && dir == 1)
                   dof = 5; 
                end

               if (dir == 1)
                  dir = 0;
               else
                  dir = 1;
               end           

                if VREActivation(handles.vre_Com, 25, [], dofs(dof), dir, get(handles.cb_moveTAC,'Value')) == 1
                   % TAC Test Completed
                   TAC.ackTimes = TAC.ackTimes + 1;
                end
            end
        end

        % Next cycle
        nTW = nTW + 1;
        outVectorMotorLast = outVectorMotor;
        currentDegPerMovLast = transpose(patRec.control.currentDegPerMov);
        % Finish of processing time
        procT(nTW) = toc(procTimeS);
        
        % quick and dirty patch to keep the servos moving
        % this is provisional
        if motorCoupling
            for i = 1 : size(outChanged,1)
                if or(handles.movList(outChanged(i)).motor == 8, ...
                   handles.movList(outChanged(i)).motor == 7)     
                    outVectorMotorLast(outChanged(i)) = 0;
                end
            end        
        end
        
        
    end
 end

 function plotDataTest(src,event)
    persistent tempData;
    global data 
    if(isempty(tempData))
         tempData = [];
         figure();
     end
     plot(event.TimeStamps, event.Data)
     tempData = [tempData;event.Data];
     data = tempData;
 end






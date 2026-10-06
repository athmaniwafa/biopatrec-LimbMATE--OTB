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
% Function to test the control routines of ALC-D
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2016-12-01 / Enzo Mastinu  / Creation: this function adapts GUI_TestPatRec_Mov2Mov
%                            / to work with predictions read from ALCD.
                                
% 20xx-xx-xx / Author  / Comment on update

function handlesX = ControlTestALCD(patRecX, handlesX)

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

    patRec   = patRecX;
    handles  = handlesX;
    nTW      = 1;
    procT    = [];
    tempData = [];
    outVectorMotorLast = zeros(patRec.nOuts,1);
                         
    % Get needed info from patRec structure
    nCh                 = length(patRec.nCh);       
    ComPortType         = patRec.comm;
    deviceName          = patRec.dev;
    sF                  = patRec.sF;       
                         
    % Get sampling time
    sT = str2double(get(handles.et_testingT,'String'));
    tW = patRec.tW;                                                        % Time window size
    tWs = tW*sF;                                                           % Time window samples
    timePrediction = patRec.wOverlap;
    handles.timePrediction = timePrediction;

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

    % Connect the chosen device, it returns the connection object
    obj = ConnectDevice(handles);   
    
    % Start the PatRec
    fwrite(obj,'L','char');
    fwrite(obj,nCh,'char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'L')
        set(handles.t_msg,'String','ALC-D Control-Test Start');
    else
        set(handles.t_msg,'String','Error Start'); 
        fclose(obj);
        return
    end

    tic
    for timeWindowNr = 1:round(sT/timePrediction)
        handles.obj = obj;
        RealTimeControlALCD(handles);                       
    end
    toc

    % Stop acquisition
    StopAcquisition(deviceName, obj);  
    
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
    if(isfield(patRec.patRecTrained,'thOut'))
        for i=0:patRec.nOuts-1
            s0 = sprintf('thPatch%d',i);
            set(handles.(s0), 'YData', [0 0 0 0]);
            %delete(GUI_Threshold);
        end
    end

    %Plot processing time
    figure();
    hist(procT(2:end));
    set(handles.pb_RealtimePatRec, 'Enable', 'on');   
end


function RealTimeControlALCD(handles)

    global patRec;
    global nTW;
    global procT;
    global motorCoupling;
    global vreCoupling;
    global TAC;
    global pwmIDs;
    global pwmAs;
    global pwmBs;    
    global outVectorMotorLast;
    
    % Output vector reset
    outVectorMotor = zeros(patRec.nOuts,1);
    outVector      = zeros(patRec.nOuts,1);
    
    % Start of processing time
    procTimeS = tic;
    
    % Read the predicted movement from ALC-D
    % Movements are hardcoded accordingly to this definition:
    % #define REST 			  		0
    % #define OPENHAND 			  	1
    % #define CLOSEHAND			  	2
    % #define PRONATION            	3
    % #define SUPINATION            4
    % #define SWITCH1	            5
    % Conversion of the ALC-D output is needed because:
    %  - zero index
    %  - REST is usually the last one in BioPatRec
    outMov = fread(handles.obj,1,'char');
    % in case of controldecisionstep of the majority vote algorithm
    if(outMov == 199)
        return;
    end
    activLevel = fread(handles.obj,1,'char');
    if outMov == 0
        outMov = patRec.nM;
    end
    
    outVectorMotor(outMov) = 1;
    outVector(outMov) = 1;
    
    %% Convert the predicted strength into VRE speed (from 1 to maxDegPerMov)
    patRec.control.currentDegPerMov = patRec.control.maxDegPerMov*activLevel/100;
    
    %% Control algorithm
    [patRec, outMov] = ApplyControl(patRec, outMov, outVector);
    
    %% Update result on the GUI
    set(handles.lb_movements,'Value',outMov);
    set(eval(strcat('handles.et_speed',num2str(outMov))),'String',num2str(activLevel));
    drawnow;
    
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

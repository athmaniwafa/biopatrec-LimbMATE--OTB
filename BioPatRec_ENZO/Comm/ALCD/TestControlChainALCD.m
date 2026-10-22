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
% Function to execute the Offline traning once selected from the GUI in
% Matlab
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2016-09-19 / Enzo Mastinu / Creation: test offline accuracy onboard. The
%                           / test set used in training is trasmitted to the 
%                           / ALCD and the predictions are read out.
%                           / Confusion matrix is plot at the end.

function [strength outLabels] = TestControlChainALCD(handles, sigFeatures, tSets, tOuts)

    %% patRec structure initialization

    nM           = size(sigFeatures.mov,1);
    nCh          = size(sigFeatures.nCh,2);
	nFeatures    = 4; % FIX
    sizeFeatVect = size(tSets,2);
    nWindows     = size(tSets,1);
    
    [a trueLabels] = find(tOuts>0);
        
    if isfield(sigFeatures, 'comm') 
        patRec.comm = sigFeatures.comm;
        if isfield(sigFeatures, 'comn') 
            patRec.comn = sigFeatures.comn;
        end
    else
        patRec.comm = 'N/A';
    end

    ComMode     = sigFeatures.comm;
    Device      = sigFeatures.dev;
    if strcmp(Device, 'ADS_BP') || strcmp(Device, 'ALCD')
        set(handles.t_msg,'String','Testing connection...');   
        if strcmp(ComMode, 'WiFi')
            obj = tcpip('192.168.100.10',65100,'NetworkRole','client');        % WIICOM
        elseif strcmp(ComMode, 'COM')
            ComPortName = sigFeatures.comn;
            obj = serial (ComPortName, 'baudrate', 460800, 'databits', 8, 'byteorder', 'bigEndian');
        else
            set(handles.t_msg,'String','No connection available');   
            return;
        end
    else
        set(handles.t_msg,'String','No connection available');   
        return;
    end
    % Open and test connection
    fclose(obj);
    % Set warnings to temporarily issue error (exceptions)
    s = warning('error', 'instrument:fread:unsuccessfulRead');
    try
        fopen(obj);
        fwrite(obj,'A','char');
        fwrite(obj,'C','char');
        replay = char(fread(obj,1,'char'));
    catch exception
       set(handles.t_msg,'String','Error, device is not responding or COM port is changed!'); 
       delete(obj);
       return
    end
    %Set warning back to normal state
    warning(s);
    if strcmp(replay,'C')
        set(handles.t_msg,'String','Connection Established');
    else
        set(handles.t_msg,'String','Error, device is not responding or COM port is changed!');        
    end
    fclose(obj);
    handles.obj = obj; 
    
    % Open the connection
    fopen(obj);
    
    % Read available data and discard it
    if obj.BytesAvailable > 1
        fread(obj,obj.BytesAvailable,'uint8');    % Read the samples        
    end  
    
    % Start counting the test time
    trStart = tic;
    % Send features vectors and read the controller outputs
    fwrite(obj,'i','char');
    fwrite(obj,nWindows,'float');
    outLabels = zeros(1,nWindows);
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'i')
        set(handles.t_msg,'String','Test Start');
    else
        set(handles.t_msg,'String','Error Start'); 
        fclose(obj);
        return
    end
    for z = 1:nWindows
        for i = 1:sizeFeatVect
            fwrite(obj,tSets(z,i),'float');
        end
        outLabels(z) = fread(obj,1,'char');
        strength(z) = fread(obj,1,'char');
    end
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'i');
        set(handles.t_msg,'String','Test ALCD control-chain completed');
    else
        set(handles.t_msg,'String','Error during test'); 
        fclose(obj);
        return
    end
    
    % Close connection
    fclose(obj);
   
    % Compute validation time
    disp('Validation time:');
    patRec.trTime = toc(trStart)
    
    outLabels = outLabels';
    strength = strength';
    
    %% Compute accuracy of the patRec onboard
%     disp('ALCD onboard control Accuracy:');
    accuracy = (size(find(outLabels == trueLabels),1)/nWindows)*100;
    
    %[performance confMat tTime] = Accuracy_patRec(patRec, tSets, tOuts, confMatFlag);
    % Init variables
    sM      = size(tOuts,1)/nM;          % Sets per movement
    good    = zeros(size(tSets,1),1);    % Keep track of the good prediction
    nOut    = size(tOuts,2);             % Number of outputs
    confMat = zeros(nM,nOut+1);
    % prediction metrics
    maskMat = zeros(size(tSets,1),nOut);
    FN      = zeros(size(tSets,1),nOut);
    TN      = zeros(size(tSets,1),nOut);
    TP      = zeros(size(tSets,1),nOut);
    FP      = zeros(size(tSets,1),nOut);
    confMatFlag = 1;
    
    for i = 1 : size(tSets,1)
        %% Classification
        outMov = outLabels(i);
        
        %% Count the number of correct predictions
        if ~isempty(outMov)
            if outMov ~= 0
                % Create a mask to match the correct output
                mask = zeros(1,nOut);
                mask(outMov) = 1;
                % Save the mask for future computation of prediction metrics
                maskMat(i,:)=mask;
                % Are these the right movements?
                if tOuts(i,:) == mask
                    good(i) = 1;
                else
                    %stop for debuggin purposes
                end
                
                %             %Evaluate a single movement only / not suitable for simult.
                %               if tOut(i,outMov) == 1
                %                   good(i) = 1;
                %               end
                
            else
                %If outMov = 0, then count it for the confusion matrix as no
                %prediction in an additional output
                outMov = nOut+1;
            end
        else
            %If outMov = empty, then count it for the confusion matrix as no
            %prediction in an additional output
            outMov = nOut+1;
        end
        
        %Confusion Matrix
        if confMatFlag
            expectedOutIdx = fix((i-1)/sM)+1;   % This will only work if there is an equal number of sets per class
            confMat(expectedOutIdx,outMov) = confMat(expectedOutIdx,outMov) + 1;
        end
    end
    
    % Verify that dimension of maskMat and tOut match
    if size(tSets,1) ~= size(maskMat,1)
        disp('error in maskMat');
    end
    if size(tSets,1) ~= size(tOuts,1)
        disp('error in tOuts');
    end
    % Compute the FP, FN, TP, TN using the saved maskMat
    for m=1:size(tSets,1)
        for n=1:nOut
            if tOuts(m,n) == maskMat(m,n)
                if tOuts(m,n) == 1
                    TP(m,n) = 1;
                else
                    TN(m,n) = 1;
                end
            else
                if tOuts(m,n) == 1
                    FN(m,n) = 1;
                else
                    FP(m,n) = 1;
                end
            end
        end
    end
    
    % get total
    tPs=sum(sum(TP));
    fPs=sum(sum(FP));
    tNs=sum(sum(TN));
    fNs=sum(sum(FN));
    
    % Compute metrics per movement/class
    % This will only work if there are the same number of movements
    acc     = zeros(nM+1,1);
    tPvec   = zeros(nOut,nM);
    tNvec   = zeros(nOut,nM);
    fPvec   = zeros(nOut,nM);
    fNvec   = zeros(nOut,nM);
    
    for i = 1 : nM
        s = 1+((i-1)*sM);
        e = sM*i;
        acc(i) = sum(good(s:e))/sM;
        tPvec(:,i)=sum(TP(s:e,:));
        tNvec(:,i)=sum(TN(s:e,:));
        fPvec(:,i)=sum(FP(s:e,:));
        fNvec(:,i)=sum(FN(s:e,:));
        
        if tPvec(:,i) > sM
            disp('Error on Ture Possitives');
        end
        if tNvec(:,i) > size(tSets,1)-sM
            disp('Error on Ture Negatives');
        end
        
    end
    acc(i+1) = sum(good) / size(tSets,1);
    tPvec = sum(tPvec)';
    tNvec = sum(tNvec)';
    fPvec = sum(fPvec)';
    fNvec = sum(fNvec)';
    
    %Compute the precision per movement
    precision = tPvec ./(tPvec+fPvec);
    precision(end+1) = tPs/(tPs+fPs);
    
    %Compute the recall per movement
    recall = tPvec ./(tPvec+fNvec);
    recall(end+1) = tPs/(tPs+fNs);
    
    %Compute the specificity per movement
    specificity=tNvec ./(tNvec+fPvec);
    specificity(end+1)=tNs/(tNs+fPs);
    
    %Compute the npv per movement
    npv=tNvec ./(tNvec+fNvec);
    npv(end+1)=tNs/(tNs+fNs);
    
    %Compute the f1 per movement
    f1=(2.*precision.*recall)./(precision+recall);
    
    % True accuracy / global accuracy
    accTrue=(tPvec+tNvec)./(tPvec+fPvec+fNvec+tNvec);
    accTrue(end+1)=(tPs+tNs)/(tNs+tPs+fPs+fNs);
    
    % Save performance metrics
    performance.algorithm = handles.patRec.patRecTrained.algorithm;
    performance.training = handles.patRec.patRecTrained.training;
    performance.accV = handles.patRec.patRecTrained.accV;
    performance.nM = nM;
    performance.nCh = nCh;
    performance.nFeatures = nFeatures;
    performance.nWindows = nWindows;
    performance.acc = acc*100;
    performance.accTrue = accTrue*100;
    performance.precision = precision*100;
    performance.recall = recall*100;    % Sensitivity
    performance.f1 = f1;
    performance.specificity= specificity*100;
    performance.npv = npv*100;
    %save('accuracyControlALCD.mat','performance');
    
    % Print confusion matrix
    if confMatFlag
        confMat = confMat ./ sM; % This will only work if there is an equal number of sets per class
        figure;
        imagesc(confMat);
        title('ALCD Control-Chain Confusion Matrix')
        xlabel('Executed Movements');
        ylabel('Input Movement Class');
    end
end


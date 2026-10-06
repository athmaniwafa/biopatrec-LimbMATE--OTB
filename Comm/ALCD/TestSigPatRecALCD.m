% ---------------------------- Copyright Notice ---------------------------
% This file is part of BioPatRec © which is open and free software under 
% the GNU Lesser General Public License (LGPL). See the file "LICENSE" for 
% the full license governing this code and copyrights.
%
% BioPatRec was initially developed by Max J. Ortiz C. at Integrum AB and 
% Chalmers University of Technology. All authors contributions must be kept
% acknowledged below in the section "Updates % Contributors". 
%
% Would you like to contribute to science and sum efforts to improve 
% amputees quality of life? Join this project! or, send your comments to:
% maxo@chalmers.se.
%
% The entire copyright notice must be kept in this or any source file 
% linked to BioPatRec. This will ensure communication with all authors and
% acknowledge contributions here and in the project web page (optional).
%
% -------------------------- Function Description -------------------------
% Function to execute the Offline traning once selected from the GUI in
% Matlab. Uses the raw EMG signal.
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2017-02-01 / Adam Naber / Creation: Test offline accuraccy onboard. The
%                         / test set (EMG signal) used in training is
%                         / transmitted to the ALCD for filtering,
%                         / feature extraction, and prediction. Predictions
%                         / are read out. Confusion matrix is plot at the end.

function [accuracy, outLabels] = TestSigPatRecALCD(handles, sigTreated)

    nM          = sigTreated.nM;
    nCh         = numel(sigTreated.nCh);
    nSets       = sigTreated.tSets;
    nWindows    = nSets * nM;
    tData       = sigTreated.tDataRaw;
    windowLen   = size(tData,1);
    accuracy    = 0;
    outLabels   = zeros(1,nWindows);
    trueLabels  = reshape(repmat(1:nM,nSets,1),1,nWindows);
    
    % Get COM Port from user
    hwInfo = instrhwinfo('serial');
    comPorts = hwInfo.AvailableSerialPorts;
    if ~numel(comPorts)
        set(handles.t_msg,'String','No connection available');
        return;
    end

    [comIdx,valid] = listdlg('PromptString','Select a COM Port:', ...
            'ListSize',[160 100], ...
            'SelectionMode','single', ...
            'ListString',comPorts);
    if ~valid
        set(handles.t_msg,'String','Invalid COM Port selection');
        return;
    end
    comPort = comPorts{comIdx};

    % Assume ALCD
    obj = serial(comPort, 'BaudRate', 460800, 'DataBits', 8, 'ByteOrder', 'bigEndian');
    fclose(obj);
    try
        % Test the connection
        fopen(obj);
        fwrite(obj,'AC','char');
        replay = fread(obj,1,'char');
        if ~strcmp(char(replay),'C')
            set(handles.t_msg,'String','Error, device is not responding');
            fclose(obj);
            delete(obj);
            return;
        end
    catch
        set(handles.t_msg,'String','Error, device is not responding');
        delete(obj);
        return;
    end
    
    % Open the connection and discard any buffered data
    handles.obj = obj;
    if obj.BytesAvailable
        fread(obj,obj.BytesAvailable,'char');
    end
    
    %% Initialize the device with signal treatment settings
    
    % DSP Filters
    if strcmp(sigTreated.fFilter{1}, 'EMG 20-500')
        alcdParams.dspEnable = 1;
    else
        alcdParams.dspEnable = 0;
    end
    
    % SWT Denoising/Artifact Reduction
    if isfield(sigTreated,'sigDenoising')
        rule = sigTreated.sigDenoising.thresholdShrink;
        switch rule
            case 'soft'
                alcdParams.swtType = 3;
            case 'hard'
                alcdParams.swtType = 4;
            case 'hyperbolic'
                alcdParams.swtType = 5;
            case 'adaptive'
                alcdParams.swtType = 6;
            case 'non-negative'
                alcdParams.swtType = 7;
            otherwise
                alcdParams.swtType = 1; % None
        end
    elseif isfield(sigTreated,'mFilter') && strcmp(sigTreated.mFilter.type,'ALCD')
        alcdParams.swtType = 2; % Motion artifact reduction only
    else
        alcdParams.swtType = 1; % None
    end
    
    % Lead-off not needed for simulated data
    alcdParams.loffEnable = 0;
    
    % Feature extraction parameters
    alcdParams.wLength  = windowLen;
    % We are sending full windows, so the overlap is always 0
    alcdParams.wOverlap = 0;
    
    if ~isfield(handles,'sF')
        handles.sF = 1000;
    end

    if SetSignalProcessingParametersALCD(handles, alcdParams)
        delete(obj);
        return;
    end

    % Start counting the test time
    trStart = tic;
    % Send signal and read classified outputs
    fwrite(obj,'C','char');
    replay = fread(obj,1,'char');
    if ~strcmp(char(replay),'C')
        set(handles.t_msg,'String','Error starting test');
        fclose(obj);
        delete(obj);
        return;
    end
    fwrite(obj,nM,'char');
    fwrite(obj,nCh,'char');
    fwrite(obj,nWindows,'uint32');
    fwrite(obj,windowLen,'uint32');

    for mov = 1 : nM
        for tSet = 1 : nSets
            for sample = 1 : windowLen
                for ch = 1 : nCh
                    fwrite(obj,tData(sample,ch,mov,tSet),'float32');
                end
            end
            outLabels((mov-1)*nSets + tSet) = fread(obj,1,'uint8');
        end
    end
    replay = fread(obj,1,'char');
    if ~strcmp(char(replay),'C')
        set(handles.t_msg,'String','Error stopping test');
        fclose(obj);
        delete(obj);
        return;
    end

    % Close the connection
    fclose(obj);

    % Compute validation time
    disp('Validation time:');
    patRec.trTime = toc(trStart);
    fprintf('Validation time: %f seconds\n', patRec.trTime);

    % Compute accuracy of on-board PatRec
    outLabels = outLabels + 1;
    accuracy = 100*(sum(outLabels == trueLabels)/nWindows);
    fprintf('ALCD on-board PR Accuracy: %.02f%%\n', accuracy);
    
    set(handles.t_msg,'String','ALCD PR Complete');

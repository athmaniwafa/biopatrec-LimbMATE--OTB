% UPDATE COEFFICIENTS FUNCTION
function UpdateCoefficientsALCD(handles)

    ComMode     = handles.patRec.comm;
    Device      = handles.patRec.dev;

    set(handles.t_msg,'String','Testing connection...');   
    if strcmp(ComMode, 'WiFi')
        obj = tcpip('192.168.100.10',65100,'NetworkRole','client');        % WIICOM
    else
        if strcmp(Device, 'LM 1') || strcmp(Device, 'LM 2') || strcmp(Device, 'LM 3')
            obj = handles.objLM;
        else
            if isfield(handles.patRec, 'comn')
                ComPortName = handles.patRec.comn;
            else
                ComPortName = 'INVALID';
            end
    
            % Get COM Port from user if saved one is not present
            hwInfo = instrhwinfo('serial');
            comPorts = hwInfo.AvailableSerialPorts;
            portExists = cellfun(@(s) ~isempty(strfind(ComPortName,s)), comPorts);
            if ~any(portExists) && ~isempty(comPorts)
                [comIdx,valid] = listdlg('PromptString','Select a COM Port:', ...
                        'ListSize',[160 100], ...
                        'SelectionMode','single', ...
                        'ListString',comPorts);
                if ~valid
                    set(handles.t_msg,'String','Invalid COM Port selection');
                    return;
                end
                ComPortName = comPorts{comIdx};
            elseif ~any(portExists)
                set(handles.t_msg,'String','No connection available');   
                return;
            end
    
            obj = serial (ComPortName, 'baudrate', 460800, 'databits', 8, 'byteorder', 'bigEndian');
        end
    end
        
    if strcmp(Device, 'LM 1') || strcmp(Device, 'LM 2') || strcmp(Device, 'LM 3')
    else
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
    end
    
    % Set the parameters for features extraction
    % tWs = handles.patRec.sF*handles.patRec.tW;
    % oWs = handles.patRec.sF*handles.patRec.tW - handles.patRec.sF*handles.patRec.wOverlap;
    tWs = handles.patRec.sF*0.2;    % default values are written in the MCU
    oWs = handles.patRec.sF*0.15;
    
    FeaturesEnables = zeros(1,5);
    if strcmp(Device, 'LM 1') || strcmp(Device, 'LM 2') || strcmp(Device, 'LM 3')
        % Compatibility with BioPatRec
        if sum(strcmp(handles.patRec.selFeatures,'tmabs')==1)
            FeaturesEnables(1) = 1; end
        if sum(strcmp(handles.patRec.selFeatures,'tstd')==1)
            FeaturesEnables(2) = 1; end
        if sum(strcmp(handles.patRec.selFeatures,'twl')==1)
            FeaturesEnables(3) = 1; end
        if sum(strcmp(handles.patRec.selFeatures,'tzc')==1)    
            FeaturesEnables(4) = 1; end
        if sum(strcmp(handles.patRec.selFeatures,'tslpch2')==1)
            FeaturesEnables(5) = 1; end
        
    else
        if sum(strcmp(handles.patRec.selFeatures,'tmabs')==1)
            FeaturesEnables(1) = 1; end
        if sum(strcmp(handles.patRec.selFeatures,'twl')==1)
            FeaturesEnables(2) = 1; end
        if sum(strcmp(handles.patRec.selFeatures,'tzc')==1)    
            FeaturesEnables(3) = 1; end
        if sum(strcmp(handles.patRec.selFeatures,'tslpch2')==1)
            FeaturesEnables(4) = 1; end
        if sum(strcmp(handles.patRec.selFeatures,'tstd')==1)
            FeaturesEnables(5) = 1; end

        SetFeaturesExtractionParametersALCD(handles, tWs, oWs, FeaturesEnables);
    end
    
    % Load coefficients depending on the training algorithm used
    switch handles.patRec.patRecTrained.algorithm
        case 'DA'
            coeff = handles.patRec.patRecTrained.coeff;
            dimCOEFF = size(coeff,2);
            dimLINEAR = size(coeff(1,2).linear,1);
            floorNoise = handles.patRec.floorNoise;
            % Start to send coeff float values
            if strcmp(Device, 'LM 1') || strcmp(Device, 'LM 2') || strcmp(Device, 'LM 3')
            else
                fwrite(obj,'U','char');
                fwrite(obj,dimCOEFF,'char');
                fwrite(obj,dimLINEAR,'char');
                fwrite(obj,floorNoise,'float');
                replay = char(fread(obj,1,'char'));
                if strcmp(replay,'U')
                    set(handles.t_msg,'String','Upload Start');
                else
                    set(handles.t_msg,'String','Error Start'); 
                    fclose(obj);
                    return
                end
            end
            
            % Optimization: normal vectors are pre-calculated on the PC side
            for i = 1:dimCOEFF
                L = zeros(dimLINEAR,1);
                K = 0;
                for j = 1 : dimCOEFF
                    if i ~= j
                        L = L + coeff(i,j).linear;
                        K = K + coeff(i,j).const;
                    end
                end
                w(i).L = L;     
                k(i).K = K;
            end   
            
            % send normal vectors to the ALC-D
            tic;
            if strcmp(Device, 'LM 1') || strcmp(Device, 'LM 2') || strcmp(Device, 'LM 3')
            else
                for i = 1:dimCOEFF
                    fwrite(obj,k(i).K,'float');
                    for z = 1:dimLINEAR
                        fwrite(obj,w(i).L(z),'float');
                    end
                end
                toc;
                replay = char(fread(obj,1,'char'));
                if strcmp(replay,'U');
                    set(handles.t_msg,'String','Upload completed');
                else
                    set(handles.t_msg,'String','Error uploading'); 
                    fclose(obj);
                    return
                end
            end

            if strcmp(Device, 'LM 1') || strcmp(Device, 'LM 2') || strcmp(Device, 'LM 3')
                obj.LDA_params = [];
                % Take the general parameters
                nFeatures = sum(FeaturesEnables(:));
                nClasses = dimCOEFF;
                nChannels = dimLINEAR/nFeatures;
                % Save the Data Into the LimbMate Struct
                obj.LDA_params.FeaturesEnables = FeaturesEnables';
                obj.LDA_params.nFeatures = nFeatures;
                obj.LDA_params.nClasses = nClasses;
                obj.LDA_params.nChannels = nChannels;
                obj.LDA_params.floorNoise = floorNoise;
                bias = zeros(length(k(1).K), nClasses);
                weights = zeros(length(w(1).L), nClasses);
                for iDimCOEFF = 1:nClasses
                    bias(:,iDimCOEFF) = k(iDimCOEFF).K;
                    weights(:,iDimCOEFF) = w(iDimCOEFF).L;
                end
                obj.LDA_params.bias = bias;
                obj.LDA_params.weights = weights;

                % Send the Data through BT
                obj.set_LDA_params()
            end

            
        case 'SVM'
            % Optimization: normal vectors are pre-calculated on the PC side
            classes = length(handles.patRec.patRecTrained.SVM);
            b = zeros(1,classes);
            if isCell(handles.patRec.patRecTrained.SVM)
                for iClasses = 1:classes
                    svm_struct = handles.patRec.patRecTrained.SVM{iClasses};
                    w(iClasses,:) = -svm_struct.Beta';
                    b(iClasses) = -svm_struct.Bias;
                end 
                shift = -svm_struct.Mu;
                scale = 1./svm_struct.Sigma;
            else % Maintain compatibility for old system (not in R2019+)
                for iClasses = 1:classes
                    svm_struct = handles.patRec.patRecTrained.SVM(:,iClasses);
                    sv = svm_struct.SupportVectors;
                    alphaHat = svm_struct.Alpha;
                    w(iClasses,:) = alphaHat'*sv;
                    b(iClasses) = svm_struct.Bias;
                end 
                shift = svm_struct.ScaleData.shift;
                scale = svm_struct.ScaleData.scaleFactor;
            end
            midrange = handles.patRec.normSets.midrange;
            range = handles.patRec.normSets.range;
            nMovements = classes;
            dimLINEAR = size(w,2);
            
            % Start communication
            fwrite(obj,'u','char');
            fwrite(obj,nMovements,'char');
            fwrite(obj,dimLINEAR,'char');
            
            % Send first normalization parameters
            for k = 1:dimLINEAR
                fwrite(obj,midrange(k),'float');
                fwrite(obj,range(k),'float');
                fwrite(obj,shift(k),'float');
                fwrite(obj,scale(k),'float');
            end
            
            % Start to send coeff float values
            fwrite(obj,handles.patRec.floorNoise,'float');
            replay = char(fread(obj,1,'char'));
            if strcmp(replay,'u')
                set(handles.t_msg,'String','Upload Start');
            else
                set(handles.t_msg,'String','Error Start'); 
                fclose(obj);
                return
            end
            tic;
            for i = 1:nMovements
                fwrite(obj,b(i),'float');
                for k = 1:dimLINEAR
                    fwrite(obj,w(i,k),'float');
                end
            end
            toc;
            replay = char(fread(obj,1,'char'));
            if strcmp(replay,'u');
                set(handles.t_msg,'String','Upload completed');
            else
                set(handles.t_msg,'String','Error uploading'); 
                fclose(obj);
                return
            end
    end
    
   if strcmp(Device, 'LM 1') || strcmp(Device, 'LM 2') || strcmp(Device, 'LM 4')
   else
   % Close connection
   fclose(obj);
    end
    
end

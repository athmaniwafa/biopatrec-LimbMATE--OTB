% UPDATE COEFFICIENTS FUNCTION
function LM_parameter_transmission = UpdateCoefficientsLimbMATE(handles)

    ComMode     = handles.patRec.comm;
    Device      = handles.patRec.dev;

    set(handles.t_msg,'String','Testing connection...');   
    
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
    end
       
    
    % Load coefficients depending on the training algorithm used
    switch handles.patRec.patRecTrained.algorithm
        case 'DA'
            coeff = handles.patRec.patRecTrained.coeff;
            dimCOEFF = size(coeff,2);
            dimLINEAR = size(coeff(1,2).linear,1);
            floorNoise = handles.patRec.floorNoise;
            % Start to send coeff float values
            
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
                LM_parameter_transmission = [];
                % Take the general parameters
                nFeatures = sum(FeaturesEnables(:));
                nClasses = dimCOEFF;
                nChannels = dimLINEAR/nFeatures;
                % Save the Data Into the LimbMate Struct
                LM_parameter_transmission.LDA_params.FeaturesEnables = FeaturesEnables;
                LM_parameter_transmission.ChannelsEnables = ones(8,1);
                LM_parameter_transmission.LDA_params.nFeatures = nFeatures;
                LM_parameter_transmission.LDA_params.nClasses = nClasses;
                LM_parameter_transmission.LDA_params.nChannels = nChannels;
                LM_parameter_transmission.LDA_params.floorNoise = floorNoise;
                bias = zeros(length(k(1).K), nClasses);
                weights = zeros(length(w(1).L), nClasses);
                for iDimCOEFF = 1:nClasses
                    bias(:,iDimCOEFF) = k(iDimCOEFF).K;
                    weights(:,iDimCOEFF) = w(iDimCOEFF).L;
                end
                LM_parameter_transmission.LDA_params.bias = bias;
                LM_parameter_transmission.LDA_params.weights = weights;

                % Update handles structure
                return
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
    
end

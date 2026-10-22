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
%  Function to classifies the testing sets
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2014-11-07 / Le Khong     / Creation
% 2015-12-29 / Max Ortiz    / Rename to fit coding standard
% 20xx-xx-xx / Author       / Comment on update

function [SVM, accV] = SVMAnalysis(dType, trSets, trOuts, vSets, vOuts, mov, movIdx)
nM = size(movIdx,2);
nTr = size(trSets,1);
nVal = size(vSets,1);
default = 1;    % set default = 0 to optimise SVM parameters, or default = 1 to use default mode
contourplot = 0; % contourplot = 1 or 0 to show/NOT show contourplot of grid search, applied when default = 0
svmStruct = cell(nM,1);
accV = zeros(nM,1);

%%%%% Validate Inputs
if ~any(strcmp(dType, {'gaussian','rbf','linear','polynomial'}))
    fprintf('Invalid kernel function.\n');
    fprintf('Valid types are: gaussian, rbf, linear, polynomial.\n');
    fprintf('See "help fitcsvm" for details\n');
    SVM = [];
    accV = [];
    return;
end

for i = 1:nM
    % modify target vectors
    groupVec = zeros(nM,1);
    groupVec(i) = i;
    trGroup = trOuts*groupVec;
    vGroup = vOuts*groupVec;
    
    %trGroup = zeros(nTr,1);
    %vGroup = zeros(nVal,1);
    %tr = find(trOuts(:,i)); % find the target class i for training
    %val = find(vOuts(:,i)); % find the target class i for validation
    %trGroup(tr,1) = 1;
    %vGroup(val,1) = 1;
    %---------------------------------------------------------------
    if default == 1 % use default parameters
        svmStruct{i} = fitcsvm(trSets,trGroup, ...
                                'KernelFunction', dType, ...
                                'BoxConstraint', 1, ...
                                'Standardize', 'on');
        % Validate SVM
        vClass = predict(svmStruct{i},vSets);
        vGood = find(vClass==vGroup);
        accV(i) = size(vGood,1) / nVal;
    %---------------------------------------------------------------
    else % validate tuning parameters
        
        if strcmp(dType,'linear')
            C = [0.1, 0.3, 0.5, 0.7, 0.8, 0.9, 1, 1.1, 1.2];
            % coarse search for C
            vAcc = zeros(length(C),1);
            svmVal = cell(length(C),1);
            for j = 1:length(C)
                svmVal{i} = fitcsvm(trSets,trGroup, ...
                                    'KernelFunction', dType, ...
                                    'BoxConstraint', C(j), ...
                                    'Standardize', 'on');
                % Validate SVM
                vClass = predict(svmVal{j},vSets);
                vGood = find(vClass==vGroup);
                vAcc(j) = size(vGood,1) / nVal;
            end
            [~,idx] = max(vAcc);
            fine = [0.05; 0.1; 0.15; 0.2];
            tmpC = C(idx)*fine;
            pos = C(idx)+tmpC;
            neg = C(idx)-tmpC; 
            finedC = [neg;C(idx);pos];
            foundC = C(idx);
            % fine search for C
            vAcc = zeros(length(finedC),1);
            for j = 1:length(finedC)
                svmVal{i} = fitcsvm(trSets,trGroup, ...
                                    'KernelFunction', dType, ...
                                    'BoxConstraint', finedC(j), ...
                                    'Standardize', 'on');
                % Validate SVM
                vClass = predict(svmVal{idx},vSets);
                vGood = find(vClass==vGroup);
                vAcc(j) = size(vGood,1) / nVal;
            end
            [~,bestidx] = max(vAcc);
            bestC = finedC(bestidx);
            svmStruct{i} = svmVal{bestidx};
        
            % Validate SVM
            vClass = predict(svmStruct{i},vSets);
            vGood = find(vClass==vGroup);
            accV(i) = size(vGood,1) / nVal;
        
        elseif strcmp(dType,'quadratic')
            % grid search for C and d
            [C, d] = meshgrid(0.1:0.3:4, 1:6);
            vAcc = zeros(numel(C),1);
            for j=1:numel(C)
                svmVal{i} = fitcsvm(trSets,trGroup, ...
                                    'KernelFunction', 'polynomial', ...
                                    'BoxConstraint', C(j), ...
                                    'PolynomialOrder', 2, ...
                                    'Standardize', 'on');
                vClass = predict(svmVal{j},vSets);
                vGood = find(vClass==vGroup);
                vAcc(j) = size(vGood,1) / nVal;
            end
            [~,idx] = max(vAcc);
            svmStruct{i} = svmVal{idx};
            accV(i) = vAcc(idx);
            best_C = C(idx);
            best_d = d(idx);
            
            % contour plot of paramter selection
            if contourplot == 1
            figure(2)
            contour(C, d, reshape(100*vAcc,size(C))), colorbar
            hold on
            plot(C(idx), d(idx), 'rx')
            text(C(idx), d(idx), sprintf('Acc = %.2f %%',100*vAcc(idx)), ...
                'HorizontalAlign','left', 'VerticalAlign','top')
            hold off
            xlabel('C'), ylabel('d'), title('Average Accuracy')
            end
        
        elseif strcmp(dType,'polynomial')
            % grid search for C and d
            [C, d] = meshgrid(0.1:0.3:4, 1:6);
            vAcc = zeros(numel(C),1);
            for j=1:numel(C)
                svmVal{i} = fitcsvm(trSets,trGroup, ...
                                    'KernelFunction', dType, ...
                                    'BoxConstraint', C(j), ...
                                    'PolynomialOrder', d(j), ...
                                    'Standardize', 'on');
                vClass = predict(svmVal{j},vSets);
                vGood = find(vClass==vGroup);
                vAcc(j) = size(vGood,1) / nVal;
            end
            [~,idx] = max(vAcc);
            svmStruct{i} = svmVal{idx};
            accV(i) = vAcc(idx);
            best_C = C(idx);
            best_d = d(idx);
            
            % contour plot of paramter selection
            if contourplot == 1
            figure(2)
            contour(C, d, reshape(100*vAcc,size(C))), colorbar
            hold on
            plot(C(idx), d(idx), 'rx')
            text(C(idx), d(idx), sprintf('Acc = %.2f %%',100*vAcc(idx)), ...
                'HorizontalAlign','left', 'VerticalAlign','top')
            hold off
            xlabel('C'), ylabel('d'), title('Average Accuracy')
            end
        
        elseif strcmp(dType,'rbf')
            % grid search for C and sigma
            [C, sigma] = meshgrid(0.1:0.3:4, 1:10);
            vAcc = zeros(numel(C),1);
            for j=1:numel(C)
                svmVal{i} = fitcsvm(trSets,trGroup, ...
                                    'KernelFunction', dType, ...
                                    'BoxConstraint', C(j), ...
                                    'KernelScale', sigma(j), ...
                                    'Standardize', 'on');
                vClass = predict(svmVal{j},vSets);
                vGood = find(vClass==vGroup);
                vAcc(j) = size(vGood,1) / nVal;
            end
            [~,idx] = max(vAcc);
            svmStruct{i} = svmVal{idx};
            accV(i) = vAcc(idx);
            best_C = C(idx);
            best_sigma = sigma(idx);
            
            % contour plot of paramter selection
            if contourplot == 1
            figure(2)
            contour(C, sigma, reshape(100*vAcc,size(C))), colorbar
            hold on
            plot(C(idx), sigma(idx), 'rx')
            text(C(idx), sigma(idx), sprintf('Acc = %.2f %%',100*vAcc(idx)), ...
                'HorizontalAlign','left', 'VerticalAlign','top')
            hold off
            xlabel('C'), ylabel('sigma'), title('Average Accuracy')
            end
        %% MLP is no longer supported as a kernel function 
%        elseif strcmp(dType,'mlp')
%            % grid search for C, P1 and P2
%            [P1, P2, C] = meshgrid(0.1:0.3:2, -1.9:0.3:-0.1, 0.1:0.3:4);
%            vAcc = zeros(numel(C),1);
%            for j=1:numel(P1)
%                svmVal{j} = svmtrain(trSets,trGroup,...
%                                     'kernel_function', dType,...
%                                     'boxconstraint',C(j),...
%                                     'mlp_params', [P1(j) P2(j)], ...
%                                     'Standardize', 'on');
%                vClass = predict(svmVal{j},vSets);
%                vGood = find(vClass==vGroup);
%                vAcc(j) = size(vGood,1) / nVal;
%            end
%            [~,idx] = max(vAcc);
%            svmStruct{i} = svmVal{idx};
%            accV(i) = vAcc(idx);
%            best_C = C(idx);
%            best_P1 = P1(idx);
%            best_P2 = P2(idx);
%
%             % contour plot of paramter selection
%            if contourplot == 1
%            figure(2)            
%            contourslice(P1, P2, C, reshape(100*vAcc,size(P1)),[0:2], [-2:0], [0:4]), colorbar
%            view(3)
%            hold on
%            scatter3(P1(idx), P2(idx), C(idx), 40,'r','filled')
%            text(P1(idx), P2(idx), C(idx), sprintf('Acc = %.2f %%',100*vAcc(idx)), ...
%                'HorizontalAlign','left', 'VerticalAlign','top')            
%            hold off
%            xlabel('P1'), ylabel('P2'), zlabel('C'), title('Average Accuracy')
%            end
        end
                
    end
    %---------------------------------------------------------------
    
end
accV(nM+1) = mean(accV);
SVM = svmStruct;

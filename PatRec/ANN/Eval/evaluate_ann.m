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
%                             evaluate_ann.m
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 20xx-xx-xx / Max Ortiz  / Creation
% 2009-07-22 / Max Ortiz  / Modify to hanlde the new ANN MLP

function ANN = evaluate_ann(inputs, ANN)
    
    if strcmp(ANN.Type,'MLP')
        ll = length(ANN.nHn);
        %First Inpute Layer
        for i=1:ANN.nHn(1)
            ANN.v(i,1) = sum(ANN.w(1:length(inputs),i,1) .* inputs') + ANN.b(i,1);    % Induced local field
            ANN.phi(i,1) = 1 /(1 + exp(-ANN.a * ANN.v(i,1)));    
        end
        %Hiden Layers Layer
        for j=2:ll
            for i=1:ANN.nHn(j)
                ANN.v(i,j) = sum(ANN.w(1:ANN.nHn(j-1),i,j) .* ANN.phi(1:ANN.nHn(j-1),j-1)) + ANN.b(i,j);    % Induced local field
                ANN.phi(i,j) = 1 /(1 + exp(-ANN.a * ANN.v(i,j)));    
            end
        end
        %Output layer neuron
        ol = ll + 1;
        for i=1:ANN.nOn
            ANN.v(i,ol) = sum(ANN.w(1:ANN.nHn(end),i,ol) .* ANN.phi(1:ANN.nHn(end),ll)) + ANN.b(i,ol);    % Induced local field
            ANN.o(i)    = 1 /(1 + exp(-ANN.a * ANN.v(i,ol)));    
        end
 
    elseif strcmp(ANN.Type,'SLP')
        %1st layer neurons
        for i=1:ANN.nHn
            ANN.z1(i) = sum(ANN.w1(:,i) .* inputs') + ANN.b1(i);    % Induced local field
            ANN.o1(i) = 1 /(1 + exp(-ANN.a * ANN.z1(i)));    
        end

        %2nd layer neuron
        for i=1:ANN.nOn
            ANN.z2(i) = sum(ANN.w2(:,i) .* ANN.o1) + ANN.b2(i);
            ANN.o2(i) = 1 /(1 + exp(-ANN.a * ANN.z2(i)));
        end        
    end

    %1st layer neurons
    %for i=1:ANN.nHn
    %    zsum = 0;
    %    for j=1:ANN.nIn
    %       zsum = zsum + ANN.w1(j,i) * inputs(j); 
    %    end
    %    ANN.z1(i) = zsum + ANN.b1(i);
    %    ANN.o1(i) = 1 /(1 + exp(-c*ANN.z1(i)));    
    %end    
    
    %2nd layer neuron
    %zsum = 0;
    %for i=1:ANN.nHn
    %    zsum = zsum + ANN.w2(i) * ANN.o1(i); 
    %end

    
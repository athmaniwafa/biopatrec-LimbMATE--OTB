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
% Particle Validation or in this case, validation of the ANN's weights
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 20xx-xx-xx / Max Ortiz  / Creation
% 2010-05-16 / Max Ortiz  / New vertion to return both Accuracies

% 
function [v, fitness, d, an, ap] = validate_ann(ANN,x,y) 
        
    Nsets = length(x(:,1));
    Nouts = ANN.nOn;

    %Get the deviation
    d = zeros(Nsets,Nouts);            % This vector is used to validate output

    %Assume that it startes validated                                                          
    v = 1;

    dsum=0;
    for i = 1:Nsets
        ANN = evaluate_ann(x(i,:),ANN);
        if strcmp(ANN.Type,'SLP') 
            d(i,:)= ANN.o2;
        else
            d(i,:)= ANN.o;
        end
        dsum = dsum + sum((d(i,:)-y(i,:)).^2);
    end

    if ~isempty(find(abs(d-y) > 0.45,1))
        v=0;
    end
    
    % Each output firing / total firings
     an = (1 - (length(find(round(d)-round(y))) / (size(d,1)*size(d,2)))) * 100;
    
    % Correct neuron firing only / total sets
     er = find(sum(abs(round(d)-round(y)),2) >= 1);
     ap = (1 - (length(er)/Nsets)) * 100;

    fitness = sqrt(dsum/(Nsets*Nouts)); % for minimum
    %fitness = 1/(sqrt(dsum/Nsets)) for maximum
    
    
    
    
    
    
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
% Particle Evaluation or in this case, evaluation of the ANN's weights
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 20xx-xx-xx / Max Ortiz  / Creation
% 20xx-xx-xx / Author  / Comment on update

function fitness = evaluate_p(ANN,x,y) 

    Nsets = length(x(:,1));
    
    dsum=0;
    for i = 1:Nsets
        ANN = evaluate_ann(x(i,:),ANN);
        %dsum = dsum + sum((ANN.o2'-y(i,:)).^2); 
        dsum = dsum + sum((ANN.o'-y(i,:)).^2); 
    end
    fitness = sqrt(dsum/(Nsets*ANN.nOn)); % for minimum
    %fitness = 1/(sqrt(dsum/Nsets)) for maximum
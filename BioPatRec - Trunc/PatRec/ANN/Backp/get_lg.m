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
% Funtion to compute the local gradient for the back-propagation algorithm
% The right most index is the layer
% The middle is the neuron
% The left most is the input
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 20xx-xx-xx / Max Ortiz  / Creation
% 20xx-xx-xx / Author  / Comment on update

function ANN = get_lg(out, ANN)
    
    if strcmp(ANN.Type,'MLP')
        ll = length(ANN.nHn);
        ol = ll + 1;
        %Output layer neuron
        for i=1:ANN.nOn
            ANN.lg(i,ol) = ANN.a * (out(i) - ANN.o(i)) * ANN.o(i) * (1 - ANN.o(i)); 
        end
        %Hiden Layers Layer
        for j=ll : 1 :-1
            for i=1:ANN.nHn(j)
                ANN.lg(i,j) = ANN.a * (1-ANN.phi(i,j)) * ANN.phi(i,j) *  sum(ANN.lg(:,j+1) * ANN.w(:,j+1));
            end
        end
    end
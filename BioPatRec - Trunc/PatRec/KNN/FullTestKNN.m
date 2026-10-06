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
% This function classify the validation sets and it return the RMSE and accuracy 
% for each mov.
% 
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2012-09-01 / Ali Fouad  / Creation
% 20xx-xx-xx / Author  / Comment on update

function [accP rmse]=FullTestKNN(KNN,vOut,x)

k=KNN.k;

% Number of data sets.
nSets=size(x,1);

% Number of movements.
nM=size(KNN.trOut,2);
nSetPerMov = nSets/nM ;     % Number of sets per movement.
setIdx=1;
% loop over all validation data.
for i=1:nM
    
    % square Error.
    sqErr=0;
    cP=0;
    
    for j = 1 : nSetPerMov
        
        % evaluate KNN
        [KNNOut ,~]=K_NearestNeighbor(x(setIdx,:), KNN.trData, k, KNN.trOut, KNN.distFunc);
        
        % correct Movement
        
        cM= length(find(sum(abs(KNNOut-vOut(setIdx,:)),2) >= 1));
        if cM==0
            correct=1;
        else
            correct=0;
        end
        cP = cP + correct;
        % sum of square Error.
        sqErr = sqErr + sum((KNNOut-vOut(setIdx,:)).^2);
        setIdx=setIdx+1;
    end
    accP(i) = cP / nSetPerMov;
    rmse(i) = sqrt(sqErr/(nSetPerMov*nM));
    
end
accP(end + 1) = mean(accP);
rmse(end + 1) = mean(rmse);

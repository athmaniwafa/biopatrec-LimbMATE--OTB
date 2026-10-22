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
% Function to clssify the validation sets
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2012-07-01 / Ali Fouad  / Creation
% 20xx-xx-xx / Author  / Comment on update

function [accP rmse]=FastTestKNN(vOut,vSets,KNN,k)
nSets=size(vSets,1);
nMov=size(vOut,2);
% square Error.
sqErr=0;


% loop over all validation data
for i=1:size(vSets,1)
    %evaluate KNN
    [KNNOut(i,:), ~]=K_NearestNeighbor(vSets(i,:), KNN.trData, k, KNN.trOut, KNN.distFunc);
    % sum of square Error.
    sqErr = sqErr + sum((KNNOut(i,:)-vOut(i,:)).^2);
end
% error.
er   = find(sum(abs(KNNOut-vOut),2) >= 1);
% accuracy.
accP = (1 - (length(er)/nSets)) * 100;
% root mean square error.
rmse = sqrt(sqErr/(nSets*nMov));




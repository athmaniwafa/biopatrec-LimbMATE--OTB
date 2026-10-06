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
% 2012-07-01 / Ali Fouad  / Creation
% 20xx-xx-xx / Author  / Comment on update

function [outMov votingVec]=KNNTest(patRecTrained,tSet)
% Check if there is any NaN value
tKnownNaN = ~isnan(tSet);
if ~isempty(find(tKnownNaN==0, 1))
    error('You have NaN value in Testing sets');
end
% Check if there is any Inf value
tKnownInf = ~isinf(tSet);
if ~isempty(find(tKnownInf==0, 1))
    error('You have Inf value in Testing sets');
end
% Check if there is any Complex number
tKnownComplex = ~isreal(tSet);
if ~isempty(find(tKnownComplex==1, 1))
    error('You have Complex number in Testing sets');
end

trData=patRecTrained.KNN.trData;
trOut=patRecTrained.KNN.trOut;
k=patRecTrained.KNN.k;
distFunc=patRecTrained.KNN.distFunc;

[KNNOut votingVec]=K_NearestNeighbor(tSet, trData, k, trOut, distFunc);
votingVec=votingVec./k;
outMov=find(round(KNNOut))';
end


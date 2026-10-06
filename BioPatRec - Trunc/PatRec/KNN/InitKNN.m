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
% Function to initialize KNN and to label the data
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2012-07-01 / Ali Fouad  / Creation
% 20xx-xx-xx / Author  / Comment on update

function KNN=InitKNN(trSet,trOut,vSet,vOut,tType)

% Check if there is any NaN value in training sets
trKnownNaN = ~isnan(trSet);
if ~isempty(find(trKnownNaN==0, 1))
    error('You have NaN value in Training sets');
end
% Check if there is any Inf value in training sets
trKnownInf = ~isinf(trSet);
if ~isempty(find(trKnownInf==0, 1))
    error('You have Inf value in Training sets');
end
% Check if there is any Complex number in training sets
trKnownComplex = ~isreal(trSet);
if ~isempty(find(trKnownComplex==1, 1))
    error('You have Complex number in Training sets');
end
% Check if there is any NaN value in validation sets
vKnownNaN = ~isnan(vSet);
if ~isempty(find(vKnownNaN==0, 1))
    error('You have NaN value in Validation sets');
end
% Check if there is any Inf value in validation sets
vKnownInf = ~isinf(vSet);
if ~isempty(find(vKnownInf==0, 1))
    error('You have Inf value in Validation sets');
end
% Check if there is any Complex number in Validation sets
vKnownComplex = ~isreal(vSet);
if ~isempty(find(vKnownComplex==1, 1))
    error('You have Complex number in Validation sets');
end
nIndividualMov=size(find(sum(trOut,2)==1),1);
nWin=ceil(nIndividualMov/size(trOut,2));

if strcmp(tType,'Euclidean')
    KNN.distFunc = @EuclidDistKNN;
else
    KNN.distFunc = @ManhattanDistKNN;
end

KNN.trOut=trOut;
KNN.trData=trSet;
KNN.k=nWin;
%choosing k=1 here is just for redusing the traning time
%KNN.k=1;
KNN.apV=0;
KNN.fV=Inf;

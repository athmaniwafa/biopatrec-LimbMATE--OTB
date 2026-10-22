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
%  KNN Algorithm 
% 
% ------------------------- Updates & Contributors ------------------------ 
% [Contributors are welcome to add their email] 
% 2012-07-01 / Ali Fouad  / Creation 
% 2013-03-03 / Ali Fouad  / Removed minDist
% 2015-12-02 / Max Ortiz  / Renamed EuclidDist to EuclidDistAKK so it doesn't interfeer with the VRE-TAC routines 
% 20xx-xx-xx / Author  / Comment on update 

function [KNNOut, votingVec] = K_NearestNeighbor(x, trData, k, trOut, distFunc)

nClass = size(trOut,2);
%KNNOut=zeros(1,nClass);


% Calculate distances between traning data and input pattern
d = distFunc(x, trData);

% sorting the distance.
[~, winIndxLable] = sort(d');
% Index of K closest 
winIndxLable = winIndxLable(:,1:k);

% Find all class labels of K closest 
[~, nWinClassLable]=find(trOut(winIndxLable,:)==1);

nClassLable=[1:nClass];
% do the voting
for i = 1:nClass
    votingVec(:,i) = sum(nWinClassLable == nClassLable(i));
end
% the winning momvent with highest voting.
 KNNOut=round(votingVec./k);

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

function [outMov, outVector] = SVMTest(patRecTrained, tSet)
svmStruct = patRecTrained.SVM;
nM = length(svmStruct);
outVector = zeros(nM,1);

for i = 1:nM
    if iscell(svmStruct)
        outVector(i) = predict(svmStruct{i},tSet);
    elseif verLessThan('matlab','9.6')
        outVector(i) = svmclassify(svmStruct(i),tSet);
    end
end
outMov = find(outVector);

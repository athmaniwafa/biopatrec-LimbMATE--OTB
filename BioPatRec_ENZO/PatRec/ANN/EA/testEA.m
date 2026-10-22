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
% Funtion to test the SOP
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 20xx-xx-xx / Max Ortiz  / Creation
% 20xx-xx-xx / Author  / Comment on update


%Inputs and Outputs
x = [-1 -1 -1; -1 -1 1; -1 1 -1; -1 1 1; 1 -1 -1; 1 -1 1; 1 1 -1 ; 1 1 1];
y = [0;1;1;0;1;0;0;1];

%Artificial Neural Network
ANN.nIn     = 3;
ANN.nHn     = 5;
ANN.nOn     = 1;
ANN.w1      = zeros(ANN.nIn,ANN.nHn);
ANN.b1      = zeros(ANN.nHn,1);
ANN.w2      = zeros(ANN.nHn,ANN.nOn);
ANN.b2      = zeros(ANN.nOn,1);
ANN.z1      = zeros(ANN.nHn,1);
ANN.o1      = zeros(ANN.nHn,1);
ANN.z2      = zeros(ANN.nOn,1);
ANN.o2      = zeros(ANN.nOn,1);

EA = init_ea(ANN);
[EA, ANN] = ea(EA,ANN,x,y);

[v, fitness, d] = validate_ann(ANN,x,y);
v
fitness
d

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
% Thest Routine for the Back-Propagation Algorithm using the X-OR function
%
% Activation Function: Logistic Funtion:
% phi = 1 / (1 + exp(-c * v))
% 
% The derivate of the logistic function is:
% phi' = (c * exp(-c*v)) / (1 + exp(-c * v))^2
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 20xx-xx-xx / Max Ortiz  / Creation
% 20xx-xx-xx / Author  / Comment on update



%% Settings
Nephocs = 1000;                 % Number of simulations
eta     = 0.6;                  % Eta: Learning rate
alpha   = 0.1;                    % Alpha, momentum
in      = [0 0; 0 1; 1 0; 1 1]; % Inputs
out     = [  0;   1;   1;   0]; % Outputs

nOn = 1;        % Outputs neurons
nIn = 2;        % Inputs neurons
nHn = [6 6];    % Hidden neurons

%% Initialization
backpANN  = init_ANN_MLP(nIn,nHn,nOn,8000,1,[],0,[],[],[]);

backpANN.w(1:max([nHn nIn nOn]),1:max([nHn nIn nOn]),1:length(nHn)+1) = -1 + rand(max([nHn nIn nOn]),max([nHn nIn nOn]),length(nHn)+1) .* 2;  % weight
backpANN.b(1:max(nHn),1:length(nHn)+1)                                = -1 + rand(max(nHn),length(nHn)+1) .* 2;        % bias

%backpANN.w(1:2,1:2,1) = [1 2  ;1 2];              %Layer 1
%backpANN.w(1:2,1:3,2) = [1 2 3;1 2 3];            %Layer 2
%backpANN.w(1:3,1:2,3) = [1 2  ;1 2  ;1 2];        %Layer 3
%backpANN.w(1:2,1,4)   = [4; 4];                   %Layer 4
%backpANN.b(1:2,1)     = [1 1];
%backpANN.b(1:3,2)     = [2 2 2];
%backpANN.b(1:2,3)     = [3 3];
%backpANN.b(1,4)       = 4;

%% Pass Foward

for e = 1 : Nephocs
    p = randperm(4);
    for i = 1 : 4
        backpANN = evaluate_ann(in(p(i),:), backpANN);
        backpANN = backp(in(p(i),:),out(p(i),:),backpANN,eta, alpha);
    end
    [v, fitness, d, a] = validate_ann(backpANN,in,out);
    fitness
end

for i = 1 : 4
    backpANN = evaluate_ann(in(i,:), backpANN);
    backpANN.o
end

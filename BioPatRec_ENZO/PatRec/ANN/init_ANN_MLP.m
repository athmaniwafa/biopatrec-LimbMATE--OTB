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
% Function to initialize the Artificial Neural Network
% Note: The struct and evaluation algorithms could be shorter but less
% comprehensible
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2009-07-23 / Max Ortiz  / Creation
% 2009-11-09 / Max Ortiz / Initialization of v, phi and lg to consider a number
% of output higer than the number of neurons in the hiden layer

function ANN = init_ANN_MLP(nIn,nHn,nOn,Fs,tw,filters,normalize,cIdx,Chrs,oname)

ANN.Type    = 'MLP';
ANN.nIn     = nIn;
ANN.nHn     = nHn;
ANN.nOn     = nOn;
ANN.w       = zeros(max([nHn nIn nOn]),max([nHn nIn nOn]),length(nHn)+1);  % weight
ANN.b       = zeros(max([nHn nOn]),length(nHn)+1);        % bias
ANN.o       = zeros(nOn,1);                         % output
ANN.a       = 1;                                    % amplitud for activation function

% Back Propagation Algorithm
%ANN.v       = zeros(max(nHn),length(nHn)+1);        % induced activation field
%ANN.phi     = zeros(max(nHn),length(nHn));          % activation function or output
%ANN.lg      = zeros(max(nHn),length(nHn)+1);        % local gradient (lower delta)
ANN.v       = zeros(max([nHn nOn]),length(nHn)+1);        % induced activation field
ANN.phi     = zeros(max([nHn nOn]),length(nHn));          % activation function or output
ANN.lg      = zeros(max([nHn nOn]),length(nHn)+1);        % local gradient (lower delta)
ANN.dw      = zeros(max([nHn nIn nOn]),max([nHn nIn nOn]),length(nHn)+1);  % capital delta weight or change in weight
ANN.db      = zeros(max([nHn nOn]),length(nHn)+1);                              % capital delta weight or change in weight of bias

% Evolutionary Algorithms
ANN.Atr     = 0;
ANN.Av      = 0;
ANN.At      = 0;
ANN.Aptr     = 0;
ANN.Apv      = 0;
ANN.Apt      = 0;
ANN.Ftr     = inf;
ANN.Fv      = inf;
ANN.Ft      = inf;

% Signal recording characteristics
ANN.Fs      = Fs;       % Sampled Frequency
ANN.tw      = tw;       % time window used for the training
ANN.cIdx    = cIdx;     % Numerical Index
ANN.Chrs    = Chrs;     % Characteristics name
ANN.filters = filters;
ANN.normalize = normalize;
ANN.oname   = oname;    % Output Name


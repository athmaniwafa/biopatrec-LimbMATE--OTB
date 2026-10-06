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
% Function to train the Artificial Neural Network using the so called Back
% Propagation Algorithm
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2009-07-22 / Max Ortiz  / Creation
% 2009-10-27 / Author  / Reset update


function backpANN = train_ann_backp(handles, treated_data, cIdx)

%% Settings
Nrf       = str2double(get(handles.et_Nrf,'String'));        % Number of repeated fitness before restart
maxsims   = str2double(get(handles.et_maxsims,'String'));    % Maximum number of simulations in this case it will be ephocs
eta       = str2double(get(handles.et_eta,'String'));      
alpha     = str2double(get(handles.et_alpha,'String'));      
normalize = get(handles.cb_normalize,'Value');              % Flag to know if data was normalized

%% Get Signal Characteristics Index
allChrs = fieldnames(treated_data.trdata);
Chrs = allChrs(cIdx);    
set(handles.t_tchrs,'UserData',cIdx);        
set(handles.lb_chrs,'String',Chrs);             

%% Get Training and validtion Sets
disp('%%%%%%%%%%% Getting Sets %%%%%%%%%%%%%');
set(handles.t_msg,'String','Getting Sets..');
drawnow;

[trset, trout, vset, vout, tset, tout] = get_Sets(treated_data,Chrs);
set(handles.t_tchrs,'String',num2str(size(trset,2)));

% Normalize to zero mean and unit variance
if normalize == 1 
    allsets = trset;
    allsets(length(trset(:,1))+1 : length(trset(:,1))+length(vset(:,1)),:) = vset;
    allsets(length(trset(:,1))+length(vset(:,1))+1 : length(trset(:,1))+length(vset(:,1))+length(tset(:,1)),:) = tset;
    mn = mean(allsets,1);
    vr = var(allsets);
    trset = (trset - mn(ones(size(trset,1), 1), :)) ./ vr(ones(size(trset,1), 1), :);
    vset  = (vset  - mn(ones(size(vset, 1), 1), :)) ./ vr(ones(size(vset, 1), 1), :);
    tset  = (tset  - mn(ones(size(tset, 1), 1), :)) ./ vr(ones(size(tset, 1), 1), :);
    set(handles.t_allsets,'UserData',allsets);
    set(handles.t_allsets,'String',num2str(size(allsets,1)));
end
set(handles.cb_normalize,'UserData',normalize);     % Save the value for test_ann


%% Initialize Artificial Neural Network, PSO and EA
    
nOn = size(treated_data.trdata,2);    
nIn = length(trset(1,:));
nHn = nIn*3;
backpANN  = init_ANN_MLP(nIn,nHn,nOn,treated_data.Fs,treated_data.tw,treated_data.filters,normalize,cIdx,Chrs,treated_data.msg);

% Randomize weights -+1 
backpANN.w(1:max([nHn nIn nOn]),1:max([nHn nIn nOn]),1:length(nHn)+1) = -1 + rand(max([nHn nIn nOn]),max([nHn nIn nOn]),length(nHn)+1) .* 2;  % weight
backpANN.b(1:max(nHn),1:length(nHn)+1)                                = -1 + rand(max(nHn),length(nHn)+1) .* 2;        % bias
bbackpANN = backpANN;

% Variables for the run
bpF = zeros(1,maxsims);
sim = 0;
eval = 0;
bpVv = 0;
bpRes = 0;                
set(handles.t_bpRes,'String',num2str(bpRes));

%% Train and test the ANN

while sim <= maxsims && get(handles.cb_break,'Value') == 0 && bpVv == 0
        
    sim = sim + 1;
    set(handles.t_bpsims,'String',num2str(sim,4));
    p = randperm(length(trout(:,1)));
    for i = 1 : treated_data.trN;
        backpANN = evaluate_ann(trset(p(i),:), backpANN);
        eval = eval + 1;
        backpANN = backp(trset(p(i),:),trout(p(i),:),backpANN, eta, alpha);
    end
    set(handles.t_bpeval,'String',num2str(eval,4));

    % For visualization proposes
    [bpVtr, bpFtr, bpDtr, bpAtr, bpAptr] = validate_ann(backpANN,trset,trout);
    set(handles.lb_bpDtr,'String',num2str(round(bpDtr),2));
    set(handles.lb_bpDtr,'UserData',bpDtr);
    set(handles.t_bpFtr,'String',num2str(bpFtr,4));    
    set(handles.t_bpAtr,'String',num2str(bpAtr,4));    
    set(handles.t_bpAptr,'String',num2str(bpAptr,4));    
    backpANN.Atr = bpAtr;
    backpANN.Aptr = bpAptr;
    backpANN.Ftr = bpFtr;
    
    % Required for training stop
    [bpVv, bpF(sim), bpDv, bpAv,bpApv] = validate_ann(backpANN,vset,vout);
    set(handles.lb_bpDv,'String',num2str(round(bpDv),2));
    set(handles.t_bpFv,'String',num2str(bpF(sim),4));
    set(handles.t_bpAv,'String',num2str(bpAv,4));
    set(handles.t_bpApv,'String',num2str(bpApv,4));
    backpANN.Av = bpAv;
    backpANN.Apv = bpApv;
    backpANN.Fv = bpF(sim);    
    drawnow;

    % Save best bpANN so far
    if backpANN.Apv >= bbackpANN.Apv && backpANN.Fv <= bbackpANN.Fv 
        bbackpANN = backpANN;    
    end

    % Stop training if Fitness is les than 1 for both Tr and V
    if backpANN.Ftr < 0.1 && backpANN.Fv < 0.1 
        bpVv = 1;
    end

    % Reset Back P
    if sim >= 1 + Nrf * (bpRes + 1)
        %if mean(bpF(sim-Nrf:sim)) < bpF(sim))                          % Original
        if mean(bpF(sim-round(Nrf/4):sim)) < mean(bpF(sim-10:sim))      % Consider the last 1/4 of the training to 
            if bpFtr < 0.1 && (min(bpF(sim-5)) < 0.1 || bpAv > 95)
                bpVv = 1;
            else
                set(handles.t_msg,'String','Reset BP...');        
                bpRes = bpRes + 1;
                set(handles.t_bpRes,'String',num2str(bpRes));
                backpANN.w(1:max([nHn nIn nOn]),1:max([nHn nIn nOn]),1:length(nHn)+1) = -1 + rand(max([nHn nIn nOn]),max([nHn nIn nOn]),length(nHn)+1) .* 2;  % weight
                backpANN.b(1:max(nHn),1:length(nHn)+1)                                = -1 + rand(max(nHn),length(nHn)+1) .* 2;        % bias
            end
        end
    end
    
end

set(handles.t_bpsims,'String',num2str(sim,4));
set(handles.t_bpeval,'String',num2str(eval,4));

% TEST of the ANNs
backpANN = bbackpANN;
[bpVt, bpFt, bpDt, bpAt, bpApt] = validate_ann(backpANN,tset,tout);
set(handles.lb_bpDt,'String',num2str(round(bpDt),2));
set(handles.lb_bpDt,'UserData',bpDt);
set(handles.t_bpFt,'String',num2str(bpFt,4));    
set(handles.t_bpAt,'String',num2str(bpAt,4));    
set(handles.t_bpApt,'String',num2str(bpApt,4));    
backpANN.At = bpAt;
backpANN.Ft = bpFt;


if bpVv
    disp('%%%%%%%%%%% ANN training completed %%%%%%%%%%%%%');
    set(handles.t_msg,'String','ANNs training done');
else
    set(handles.t_msg,'String','ANNs training not successful');
end

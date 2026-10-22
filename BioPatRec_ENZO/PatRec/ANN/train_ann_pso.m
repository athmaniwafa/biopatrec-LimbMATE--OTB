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
% Function to train the Artificial Neural Network using PSO
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 20xx-xx-xx / Author  / Creation
% 2009-07-24 / Max Ortiz /Modification from original train_ann to include
%                         the struct of MLP ann and improve speed
% 20xx-xx-xx / Author  / Comment on update 

function [psoANN, PSO] = train_ann_pso(handles, treated_data, cIdx, PSO)

%% Settings
Nrf       = str2double(get(handles.et_Nrf,'String'));        % Number of repeated fitness before restart
einit     = str2double(get(handles.et_einit,'String'));      % First initial number of evolutions
estep     = str2double(get(handles.et_estep,'String'));      % Steps of evolutions before validation
maxsims   = str2double(get(handles.et_maxsims,'String'));    % Maximum number of simulations
normalize = get(handles.cb_normalize,'Value');              % Flag to know if data was normalized

eval = 0;
sims = 0;

%% Get Signal Characteristics Index
allChrs = fieldnames(treated_data.trdata);
Chrs = allChrs(cIdx);    
set(handles.t_tchrs,'UserData',cIdx);        
set(handles.lb_chrs,'String',Chrs);             

%% Get the effective number of set to be used
treated_data.etrN = str2double(get(handles.et_trN,'String'));
treated_data.evN = str2double(get(handles.et_vN,'String'));
treated_data.etN = str2double(get(handles.et_tN,'String'));

%% Get Training and validtion Sets
disp('%%%%%%%%%%% Getting Sets %%%%%%%%%%%%%');
set(handles.t_msg,'String','Getting Sets..');
drawnow;
[trset, trout, vset, vout, tset, tout] = get_Sets(treated_data,Chrs);
set(handles.t_tchrs,'String',num2str(size(trset,2)));

% Normalize
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
psoANN  = init_ANN_MLP(nIn,nHn,nOn,treated_data.Fs,treated_data.tw,treated_data.filters,normalize,cIdx,Chrs,treated_data.msg);
bpsoANN = psoANN;   % Best of PSO ANNs

if ~exist('PSO','var')
    PSO = init_pso(psoANN);
elseif isempty(PSO)
    PSO = init_pso(psoANN);
end

PSO.maxsimulations  = estep;

%% Train and test the ANN (EA or SOP)
% Validation plus training
psoF = 1:round(Nrf/estep);
i=1;
psoVv  = 0;
psoRes = 0;
set(handles.t_psoRes,'String',num2str(psoRes));        

while psoVv == 0 && sims <= maxsims && get(handles.cb_break,'Value') == 0
        
    set(handles.t_psosims,'String',num2str(sims,4));        
    set(handles.t_msg,'String','Applying PSO...');    
    [PSO psoANN psoeval] = pso(PSO,psoANN,trset,trout);
    eval = eval + psoeval;              % Increase the evaluation counter
    sims = sims + PSO.maxsimulations;   % Increase the simulations counter
    set(handles.t_psoeval,'String',num2str(eval,4));

    [psoVtr, psoFtr, psoDtr, psoAtr] = validate_ann(psoANN,trset,trout);   % Validation of the training set (for testing proposes)    
    set(handles.lb_psoDtr,'String',num2str(round(psoDtr),2));                 
    set(handles.t_psoFtr,'String',num2str(psoFtr,4));
    set(handles.t_psoAtr,'String',num2str(psoAtr,2));
    psoANN.Atr = psoAtr;
    psoANN.Ftr = psoFtr;
        
    [psoVv, psoF(i), psoDv, psoAv] = validate_ann(psoANN,vset,vout);
    set(handles.lb_psoDv,'String',num2str(round(psoDv),2));
    set(handles.t_psoFv,'String',num2str(psoF(i),4));
    set(handles.t_psoAv,'String',num2str(psoAv,2));
    psoANN.Av = psoAv;
    psoANN.Fv = psoF(i);
    drawnow;        
        
    % Save best psoANN so far
    if psoANN.Av >= bpsoANN.Av && psoANN.Fv <= bpsoANN.Fv 
        bpsoANN = psoANN;    
    end


    % Reset PSO
    if abs(mean(psoF) - psoF(1)) < .00001 && psoVv == 0 
        if psoFtr < 0.1 && (min(psoF) < 0.1 || psoAv > 95)     
            psoVv = 1;
        else        
            disp('%%%%%%%%%%% Reset of PSO %%%%%%%%%%%%%');
            set(handles.t_msg,'String','Reset PSO...');
            psoRes = psoRes + 1;
            set(handles.t_psoRes,'String',num2str(psoRes));
            drawnow;
            PSO = init_pso(psoANN);
            PSO.maxsimulations  = einit;
            [PSO psoANN psoeval] = pso(PSO,psoANN,trset,trout);    
            eval = eval + psoeval;
            sims = sims + PSO.maxsimulations;
            PSO.maxsimulations  = estep;
        end
    end

    % Reset and increas index
    if i >= round(Nrf/estep)
        i=1;
    else
        i=i+1;
    end
    
end

set(handles.t_psosims,'String',num2str(sims,4));
set(handles.t_psoeval,'String',num2str(eval,4));

% TEST of the ANNs
    
psoANN = bpsoANN;
[psoVt, psoFt, psoDt, psoAt] = validate_ann(psoANN,tset,tout);       % Use the best psoANN
set(handles.lb_psoDt,'String',num2str(round(psoDt),2));
set(handles.lb_psoDt,'UserData',psoDt);
set(handles.t_psoFt,'String',num2str(psoFt,4));    
set(handles.t_psoAt,'String',num2str(psoAt,2));
psoANN.At = psoAt;    
psoANN.Ft = psoFt;

if psoVv == 1
    disp('%%%%%%%%%%% ANN training completed %%%%%%%%%%%%%');
    set(handles.t_msg,'String','ANNs training done');
else
    set(handles.t_msg,'String','ANNs training not successful');
end

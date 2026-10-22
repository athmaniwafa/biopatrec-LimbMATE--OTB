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
% Pattern Recognition (PR)
% Function to train the Artificial Neural Network
% Input:    Handles for the GUI
%           Normalize, it is a flag to know if data should be normalized
%           trdata and vdata
%           cIdx is the index of the signal attributes to be used to train
%           PSO or EA to start from
% Outout:   sims number of simulations required to reach trainning
%           psoANN, is the ANN trinned by PSO
%           eaANN is the ANN trainned by AE
%           PSO and EA structure]
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2009-05-04 / Max Ortiz  / Creation
% 2009-07-21 / Max Ortiz  / To handle the treated_data struct
%
function [sims, psoANN, eaANN, PSO, EA] = train_ann(handles, treated_data, cIdx, PSO, EA)

%% Settings
%Nrf = 10;      % Number of repeated fitness, this will be an indicator that there is no progress on optimization
Nrf      = str2double(get(handles.et_Nrf,'String'));        % Number of repeated fitness before restart
einit    = str2double(get(handles.et_einit,'String'));      % First initial number of evolutions
estep    = str2double(get(handles.et_estep,'String'));      % Steps of evolutions before validation
maxsims  = str2double(get(handles.et_maxsims,'String'));    % Maximum number of simulations

normalize = get(handles.cb_normalize,'Value');              % Flag to know if data was normalized
fpso    = get(handles.cb_pso,'Value');                      % Flag to know if PSO will be used
fea     = get(handles.cb_ea,'Value');                       % Flag to know if EA will be used
%ss      = get(handles.lb_msg,'UserData');

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
    allsets(length(trset(:,1))+length(vset(:,1))+1 : length(trset(:,1))+length(vset(:,1))+length(tset(:,1)),:) = vset;
    mn = mean(allsets,1);
    vr = var(allsets);
    trset = (trset - mn(ones(size(trset,1), 1), :)) ./ vr(ones(size(trset,1), 1), :);
    vset  = (vset  - mn(ones(size(vset, 1), 1), :)) ./ vr(ones(size(vset, 1), 1), :);
    tset  = (tset  - mn(ones(size(tset, 1), 1), :)) ./ vr(ones(size(tset, 1), 1), :);
    set(handles.t_allsets,'UserData',allsets);
    set(handles.t_allsets,'String',num2str(size(allsets,1)));
end
set(handles.cb_normalize,'UserData',normalize);     % Save the value for test_ann

%filters.PLH = get(handles.cb_PLHf,'Value');
%filters.BP = get(handles.cb_BPf,'Value');

%oname = get(handles.lb_msg,'String');

%% Initialize Artificial Neural Network, PSO and EA
    
nOn = size(treated_data.trdata,2);    
nIn = length(trset(1,:));
nHn = nIn*3;
psoANN  = init_ANN(nIn,nHn,nOn,treated_data.Fs,treated_data.eTs,treated_data.filters,normalize,cIdx,Chrs,treated_data.msg);
eaANN   = psoANN;
bpsoANN = psoANN;   % Best of PSO ANNs
beaANN  = psoANN;    % Best of EA ANNs

if ~exist('PSO','var')
    PSO = init_pso(psoANN);
elseif isempty(PSO)
    PSO = init_pso(psoANN);
end
if ~exist('EA','var')
    EA  = init_ea(eaANN);
elseif isempty(EA)
    EA  = init_ea(eaANN);
end

PSO.maxsimulations  = estep;
EA.maxgenerations   = estep;

%% Train and test the ANN (EA or SOP)
% Validation plus training
psoF=1:round(Nrf/estep);
eaF = psoF;
i=1;
if fpso
    psoval  = 0;
else
    psoval  = 1;
end
if fea
    eaval   = 0;
else
    eaval   = 1;
end

psoRes = 0;
eaRes = 0;
set(handles.t_psoRes,'String',num2str(psoRes));        
set(handles.t_eaRes,'String',num2str(eaRes)); 

while (psoval == 0 || eaval == 0) && sims <= maxsims && get(handles.cb_break,'Value') == 0
        
    set(handles.t_psosims,'String',num2str(sims,4));

    if psoval == 0 && fpso
        set(handles.t_msg,'String','Applying PSO...');
        drawnow;
        [PSO psoANN] = pso(PSO,psoANN,trset,trout);    

        [psovaltr, psoFtr, psoDtr, psoAtr] = validate_ann(psoANN,trset,trout);   % Validation of the training set (for testing proposes)
        set(handles.lb_psoDtr,'String',num2str(round(psoDtr),2));             
        set(handles.t_psoFtr,'String',num2str(psoFtr,4));
        set(handles.t_psoAtr,'String',num2str(psoAtr,2));
        psoANN.Atr = psoAtr;
        psoANN.Ftr = psoFtr;
        [psoval, psoF(i), psoDv, psoAv] = validate_ann(psoANN,vset,vout);
        set(handles.lb_psoDv,'String',num2str(round(psoDv),2));
        set(handles.t_psoFv,'String',num2str(psoF(i),4));
        set(handles.t_psoAv,'String',num2str(psoAv,2));
        psoANN.Av = psoAv;
        psoANN.Fv = psoF(i);
        drawnow;

        sims = sims + PSO.maxsimulations;   % Increase simulations counter
        % Save best psoANN so far
        if psoval == 1 || psoANN.Av >= bpsoANN.Av 
            bpsoANN = psoANN;
        end
    end

    if eaval == 0 && fea
        set(handles.t_msg,'String','Applying EA..');
        drawnow;
        [EA eaANN] = ea(EA,eaANN,trset,trout);    

        [eavaltr, eaFtr, eaDtr, eaAtr] = validate_ann(eaANN,trset,trout);   % Validation of the training set (for testing proposes)
        set(handles.lb_eaDtr,'String',num2str(round(eaDtr),2));             
        set(handles.t_eaFtr,'String',num2str(eaFtr,4));
        set(handles.t_eaAtr,'String',num2str(eaAtr,2));
        [eaval, eaF(i), eaDv, eaAv] = validate_ann(eaANN,vset,vout);
        set(handles.lb_eaDv,'String',num2str(round(eaDv),2));
        set(handles.t_eaFv,'String',num2str(eaF(i),4));                     % Use for reset
        set(handles.t_eaAv,'String',num2str(eaAv,2));
        drawnow;

        sims = sims + EA.maxgenerations;
        % Save best eaANN so far
        if eaval == 1 || eaANN.Av >= beaANN.Av 
            beaANN = eaANN;
        end
    end

    % Reset PSO
    if abs(mean(psoF) - psoF(1)) < .00001 && psoval == 0 
        disp('%%%%%%%%%%% Reset of PSO %%%%%%%%%%%%%');
        set(handles.t_msg,'String','Reset PSO...');
        psoRes = psoRes + 1;
        set(handles.t_psoRes,'String',num2str(psoRes));
        drawnow;
        PSO = init_pso(psoANN);
        PSO.maxsimulations  = einit;
        [PSO psoANN] = pso(PSO,psoANN,trset,trout);    
        sims = sims + PSO.maxsimulations;
        PSO.maxsimulations  = estep;
    end
    % Reset EA
    if abs(mean(eaF) - eaF(1)) < .00001 && eaval == 0
        disp('%%%%%%%%%%% Reset of EA %%%%%%%%%%%%%');
        set(handles.t_msg,'String','Reset EA...');
        eaRes = eaRes + 1;
        set(handles.t_eaRes,'String',num2str(eaRes));
        drawnow;
        EA = init_ea(eaANN);
        EA.maxgenerations   = einit;
        [EA eaANN] = ea(EA,eaANN,trset,trout);    
        sims = sims + EA.maxgenerations;
        EA.maxgenerations   = estep;
    end

    % Reset and increas index
    if i >= round(Nrf/estep)
        i=1;
    else
        i=i+1;
    end
    
end

set(handles.t_psosims,'String',num2str(sims,4));

% TEST of the ANNs
if fpso
    psoANN = bpsoANN;
    [psovalt, psoFt, psoDt, psoAt] = validate_ann(psoANN,tset,tout);       % Use the best psoANN
    set(handles.lb_psoDt,'String',num2str(round(psoDt),2));
    set(handles.lb_psoDt,'UserData',psoDt);
    set(handles.t_psoFt,'String',num2str(psoFt,4));    
    set(handles.t_psoAt,'String',num2str(psoAt,2));
    psoANN.At = psoAt;
    psoANN.Ft = psoFt;
end

if fea
    eaANN = beaANN;
    [eavalt, eaFt, eaDt, eaAt] = validate_ann(eaANN,tset,tout);            % Use the best eaANN
    set(handles.lb_eaDt,'String',num2str(round(eaDt),2));
    set(handles.lb_eaDt,'UserData',eaDt);
    set(handles.t_eaFt,'String',num2str(eaFt,4));   
    set(handles.t_eaAt,'String',num2str(eaAt,2));
    eaANN.At = eaAt;
    eaANN.Ft = eaFt;
end

if (psoval == 1 && eaval == 1)
    disp('%%%%%%%%%%% ANN training completed %%%%%%%%%%%%%');
    set(handles.t_msg,'String','ANNs training done');
else
    set(handles.t_msg,'String','ANNs training not successful');
end

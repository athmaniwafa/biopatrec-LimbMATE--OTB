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
% % Pattern Recognition (PR)
% Inputs:   cIdx
%           ss
%           Normalize
%           ANNs
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2009-06-17 / Max Ortiz  / Creation
% 2009-07-21 / Max Ortiz  / Inlcude the new struc of ANNs and use of peek to analyze
% 2009-09-13 / Max Ortiz  / Use both ANNs to compute the result
%   
% 

function test_ann(handles)

%% Get Artificial Neural Network and Settings
fpso    = get(handles.cb_pso,'Value');
fea     = get(handles.cb_ea,'Value');
fbp     = get(handles.cb_backp,'Value');
buffer  = str2double(get(handles.et_buffer,'String'));

if fpso
    psoANN              = get(handles.t_pso,'UserData');
    if isempty(psoANN)  
        set(handles.t_msg,'String','No psoANN');
        errordlg('No psoANN, eaANN or bpANN loaded','Error');
        return
    end
    ANN                 = psoANN;
%    Tp                  = psoANN.tw;
%    Fs                  = psoANN.Fs;    
%    normalize           = psoANN.normalize;
%    cIdx(psoANN.cIdx)   = 1;
%    Chrs                = psoANN.Chrs;
%    filters             = psoANN.filters;
    psoRes              = zeros(buffer,length(ANN.o));
    psoOut              = zeros(1,ANN.nOn);    
    set(handles.t_psoFt,'String',num2str(psoANN.Ft,4));
    set(handles.t_psoAt,'String',num2str(psoANN.At,4));
end
if fbp
    bpANN               = get(handles.t_bp,'UserData');
    if isempty(bpANN)  
        set(handles.t_msg,'String','No bpANN');
        errordlg('No psoANN, eaANN or bpANN loaded','Error');
        return
    end
    ANN                 = bpANN;
    bpRes               = zeros(buffer,length(ANN.o));
    bpOut               = zeros(1,ANN.nOn);
    set(handles.t_bpFt,'String',num2str(bpANN.Ft,4));    
    set(handles.t_bpAt,'String',num2str(bpANN.At,4));
end
if fea
    eaANN               = get(handles.t_ea,'UserData');
    if isempty(eaANN)  
        set(handles.t_msg,'String','No eaANN');
        errordlg('No psoANN, eaANN or bpANN loaded','Error');
        return
    end
    ANN                 = eaANN;
    eaRes               = zeros(buffer,length(ANN.o));
    eaOut               = zeros(1,ANN.nOn);
    set(handles.t_eaFt,'String',num2str(eaANN.Ft,4));    
    set(handles.t_eaAt,'String',num2str(eaANN.At,4));
end

Ts              = str2double(get(handles.et_Ts,'String'));
Tp              = ANN.tw;
cIdx            = zeros(1,21);    
cIdx(ANN.cIdx)  = 1;


%% Validations
if fpso && fbp
    if psoANN.Fs ~= bpANN.Fs || psoANN.tw ~= bpANN.tw || psoANN.normalize ~= bpANN.normalize... 
    || binvec2dec(psoANN.cIdx) ~= binvec2dec(bpANN.cIdx) || psoANN.filters.PLH ~= bpANN.filters.PLH || psoANN.filters.BP ~= bpANN.filters.BP
        errordlg('PSO and BP ANNs have different parameters','Error');
        return        
    end
end
if fpso && fea
    if psoANN.Fs ~= eaANN.Fs || psoANN.tw ~= eaANN.tw || psoANN.normalize ~= eaANN.normalize... 
    || binvec2dec(psoANN.cIdx) ~= binvec2dec(eaANN.cIdx) || psoANN.filters.PLH ~= eaANN.filters.PLH || psoANN.filters.BP ~= eaANN.filters.BP
        errordlg('PSO and EA ANNs have different parameters','Error');
        return        
    end
end
if fea && fbp
    if eaANN.Fs ~= bpANN.Fs || eaANN.tw ~= bpANN.tw || eaANN.normalize ~= bpANN.normalize... 
    || binvec2dec(eaANN.cIdx) ~= binvec2dec(bpANN.cIdx) || eaANN.filters.PLH ~= bpANN.filters.PLH || eaANN.filters.BP ~= bpANN.filters.BP
        errordlg('EA and BP ANNs have different Fs','Error');
        return        
    end
end

%% Settings
treated_data.etrN = 1;
treated_data.vdata  = [];
treated_data.tdata  = [];
bIdx = 1;                       % Buffer index

%% Get Data
set(handles.t_msg,'String','Starting...');
drawnow;

% Initi NI daq card
ai = init_ai_fast(ANN.Fs,Ts);
% Start DAQ
start(ai);
% Wait until the first samples are aquired
while ai.SamplesAcquired < ANN.Fs*Tp
end
while ai.SamplesAcquired < ANN.Fs*Ts
    
    %Data Peek
    data = peekdata(ai,ANN.Fs*Tp);     

    % filtering
    if ANN.filters.PLH
        data  = BSbutterPLHarmonics(ANN.Fs, data);
    end
    if ANN.filters.BP
        data  = FilterBP_EMG(ANN.Fs, data);    
    end

    % signal analysis
    treated_data.trdata = analyze_signal(data,ANN.Fs,cIdx);
    trset = get_Sets(treated_data,ANN.Chrs);

    % Normalize
    if ANN.normalize == 1
        allsets = get(handles.t_allsets,'UserData');
        allsets(length(allsets(:,1))+1 : length(allsets(:,1))+length(trset(:,1)),:) = trset;
        mn = mean(allsets,1);
        vr = var(allsets);
        trset = (trset - mn(ones(size(trset,1), 1), :)) ./ vr(ones(size(trset,1), 1), :);
    end
    
    %% Test ANN (EA, PSO or BP)
    set(handles.t_msg,'String','Testing ANNs...');
    drawnow;    
    if fpso
        psoANN          = evaluate_ann(trset, psoANN);
        psoRes(bIdx,:)  = psoANN.o';
        psoOut          = round(mean(psoRes));
        % Rounded with threshold
%        psoRes(bIdx,:)  = round(psoANN.o)';
%        psoResS         = sum(psoRes);
%        psoNewOn        = psoResS==buffer;
%        psoNewOff       = psoResS==0;
%        psoOut(psoNewOn) = 1;
%        psoOut(psoNewOff) = 0;
        annOut          = psoOut;
        set(handles.lb_psoDt,'String',num2str(psoOut,2));
    end
    if fbp
        bpANN           = evaluate_ann(trset, bpANN);
        bpRes(bIdx,:)   = bpANN.o';
        bpOut           = round(mean(bpRes));
        annOut          = bpOut;
        set(handles.lb_bpDt,'String',num2str(round(bpOut),2));
    end
    if fpso && fbp
        cOut    = round(mean([psoRes ; bpRes],1));
        annOut  = cOut;
        set(handles.lb_output,'String',num2str(cOut,2));
    end
    
    set(handles.lb_msg,'value',find(annOut));
    set(handles.t_msg,'String','Test Done...');
    drawnow;    
    
    if bIdx == buffer
        bIdx = 1;
    else
        bIdx = bIdx+1;
    end
end
set(handles.t_msg,'String','Test finished');

stop(ai);
delete(ai);
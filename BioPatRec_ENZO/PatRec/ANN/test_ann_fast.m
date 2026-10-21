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
% Inputs:   cIdx
%           ss
%           Normalize
%           ANNs
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2009-06-17 / Max Ortiz  / Creation
% 20xx-xx-xx / Author  / Comment on update

function test_ann_fast(handles)

%% Get Artificial Neural Network
if get(handles.cb_pso,'Value')
    psoANN  = get(handles.t_pso,'UserData');
end
if get(handles.cb_ea,'Value')
    eaANN   = get(handles.t_ea,'UserData');
end

if isempty(psoANN) && isempty(eaANN)
    set(handles.t_msg,'String','No psoANN or eaANN loaded');
    errordlg('No psoANN or eaANN loaded','Error');
    return
end

%% Settings

cIdx = psoANN.cIdx;
Chrs = psoANN.Chrs;
set(handles.t_tchrs,'UserData',cIdx);   % Transform to get the chars from readings          
set(handles.lb_chrs,'String',Chrs);             
tm = zeros(1,21);
tm(cIdx) = 1;
cIdx = tm;

%cIdx = get(handles.t_tchrs,'UserData');             
%Chrs = get(handles.lb_chrs,'String');             
%if isempty(cIdx) || isempty(Chrs)
%    set(handles.t_msg,'String','No cIdx loaded');
%    return
%end

Fs = psoANN.Fs;
eTs = psoANN.eTs;  % Time of contraction x percentage to be use
normalize = psoANN.normalize;
filters = psoANN.filters;
set(handles.lb_msg,'String',psoANN.oname);

%% Test
% Initi NI daq card
[ai,chp] = init_ai_fast(Fs,eTs);

    % Data aquisition
    set(handles.t_msg,'String','Contract!');
    drawnow;
    pause(eTs);
    data = daq_nonshow(ai,chp,Fs,eTs);
    set(handles.t_msg,'String','Relax');
    drawnow;

    %% Data Treatment
    % set(handles.t_msg,'String','Filtering and Treating Data...');
    % drawnow;
    % filtering
    %if get(handles.cb_PLHf,'Value')
    if filters.PLH
        data  = BSbutterPLHarmonics(Fs,data);
    end
    %if get(handles.cb_BPf,'Value')
    if filters.BP
        data  = FilterBP_EMG(Fs,data);
    end
    % signal analysis
    trdata = analyze_signal(data,Fs,cIdx);

    %% Get Training Sets
    %disp('%%%%%%%%%%% Getting Sets %%%%%%%%%%%%%');
    %set(handles.t_msg,'String','Getting Sets...');
    %drawnow;
    trset = get_Sets(trdata,[],[],Chrs);

    % Normalize
    if normalize == 1
        allsets = get(handles.t_allsets,'UserData');
        allsets(length(allsets(:,1))+1 : length(allsets(:,1))+length(trset(:,1)),:) = trset;
        mn = mean(allsets,1);
        vr = var(allsets);
        trset = (trset - mn(ones(size(trset,1), 1), :)) ./ vr(ones(size(trset,1), 1), :);
    end
    
    %% Test ANN (EA or SOP)
    set(handles.t_msg,'String','Testing ANNs...');
    if get(handles.cb_pso,'Value')
        psoANN = evaluate_ann(trset, psoANN);
        set(handles.lb_psoDt,'String',num2str(round(psoANN.o2)',2));
        set(handles.lb_msg,'value',find(round(psoANN.o2')))
        set(handles.t_psoFt,'String',num2str(psoANN.Ft,4));
        set(handles.t_psoAt,'String',num2str(psoANN.At,4));
    end
    if get(handles.cb_ea,'Value')
        eaANN  = evaluate_ann(trset, eaANN);
        set(handles.lb_eaDt,'String',num2str(eaANN.o2',2));
        set(handles.t_eaFt,'String',num2str(eaANN.Ft,4));
    end        
    if get(handles.cb_pso,'Value') && get(handles.cb_ea,'Value') 
        res = mean([psoANN.o2 eaANN.o2],2);
        set(handles.lb_output,'String',num2str(res',2));
        set(handles.lb_msg,'value',find(round(res')));
    end
    drawnow;

set(handles.t_msg,'String','Test Done!');

stop(ai);
delete(ai);
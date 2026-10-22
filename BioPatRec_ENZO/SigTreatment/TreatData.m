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
% Function to treat the raw data
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2009-07-20 / Max Ortiz  / Creation
% 2011-07-27 / Max Ortiz  / Update to coding standard
% 2011-07-27 / Max Ortiz  / Moved the "updated sigTreated" instructions out
%                           of the GUI push bottom
% 2016-03-01 / Eva Lendaro / Moved filtering after segmentation
% 2016-02-01 / Julian Maier / Added signal separation and wavelet denoising
% 2016-03-01 / Julian Maier / Application of conventional filtering after
%                             signal segmenation.
% 2016-04-01 / Julian Maier / Added motion reduction filter
% 20xx-xx-xx / Author  / Comment on update

function sigTreated = TreatData(handles, sigTreated)

%% Update sigTreated
fFilters            = get(handles.pm_frequencyFilters,'String');
fFiltersSel         = get(handles.pm_frequencyFilters,'Value');
sigTreated.fFilter  = fFilters(fFiltersSel);

sFilters            = get(handles.pm_spatialFilters,'String');
sFiltersSel         = get(handles.pm_spatialFilters,'Value');
sigTreated.sFilter  = sFilters(sFiltersSel);

sigTreated.eCt      = sigTreated.cT * sigTreated.cTp;      % Effective contraction time
sigTreated.tW       = str2double(get(handles.et_tw,'String'));
sigTreated.nW       = str2double(get(handles.et_nw,'String'));
sigTreated.trSets   = str2double(get(handles.et_trN,'String'));
sigTreated.vSets    = str2double(get(handles.et_vN,'String'));
sigTreated.tSets    = str2double(get(handles.et_tN,'String'));

twSegMethods            = get(handles.pm_twSegMethod,'String');
twSegMethodsSel         = get(handles.pm_twSegMethod,'Value');
sigTreated.twSegMethod  = twSegMethods(twSegMethodsSel);

if twSegMethodsSel == 1 % Non-overlapped windows
    sigTreated.wOverlap = 0;
else
    sigTreated.wOverlap = str2double(get(handles.et_wOverlap,'String'));
end

if get(handles.pm_SignalSeparation,'Value') ~=1,
    allSigSeparaAlg             = get(handles.pm_SignalSeparation,'String');
    selSigSeparaAlg             = allSigSeparaAlg(get(handles.pm_SignalSeparation,'Value'));
    sigTreated.sigSeparation.Alg= selSigSeparaAlg;
end

if ~isempty(get(handles.t_denoiseParams,'UserData'))
    sigTreated.sigDenoising = get(handles.t_denoiseParams,'UserData');
    if isfield(sigTreated,'plotFlag')
        sigTreated.sigDenoising.plotFlag = true;
        clear sigTreated.plotFlag
    end
end

if get(handles.pm_motionFilt,'Value') ~=1,  
    selMotionFilt = get(handles.pm_motionFilt,'Value');
    strMotionFilt = get(handles.pm_motionFilt,'String');
    sigTreated.mFilter.type = strMotionFilt{selMotionFilt};
    sigTreated.mFilter.alg = get(handles.pm_motionFilt,'UserData');
end


%% Signal Separation Alg - Compute
if isfield(sigTreated,'sigSeparation')

	alg = cell2mat(sigTreated.sigSeparation.Alg);
    if ~strcmp(alg,'segPCA'),
        set(handles.t_msg,'String','Computing SP...');
        disp('Computing signal separation...');
        dataRaw = sigTreated.trData(1:size(sigTreated.trData,1)...
            *sigTreated.cTp,:,:);
        dataRaw = permute(dataRaw,[2 1 3]);
        data = reshape(dataRaw,size(dataRaw,1),[]);     
        [~,W,~]=ComputeSigSep(data,alg,sigTreated.sF);       
        sigTreated.sigSeparation.W = W';
    end
end

%% Split the data into the time windows
set(handles.t_msg,'String','Segmenting data...');
[trData, vData, tData] = GetData(sigTreated);
%Remove raw treated data
sigTreated = rmfield(sigTreated,'trData');
%Save raw testing data
sigTreated.tDataRaw = tData;
set(handles.t_msg,'String','Data segmented');
disp('Data segmented.');


%% Frequency Filters
set(handles.t_msg,'String','Applying filters segmentwise...');
[trData, vData, tData] = ApplyFiltersEpochs(sigTreated, trData, vData, tData);
disp('Selected filters applied to each segment.');


%% Clean the data with motionFilt
if isfield(sigTreated,'mFilter')
    
    set(handles.t_msg,'String','Artifact reduction...');
    h = waitbar(0,'Artifact reduction...');
    dataAll = cat(4,trData, vData, tData);
    nNb = size(dataAll,4);
    for iNb = 1:nNb
        waitbar(iNb/nNb) 
        for iMov = 1:sigTreated.nM   
            currData = dataAll(:,:,iMov,iNb);
            currData = MotionFilt(currData',sigTreated.sF,sigTreated.mFilter.type,sigTreated.mFilter.alg);
            dataAll(:,:,iMov,iNb) = currData;
        end               
    end
    close(h)
    [trData,vData,tData] = SplitCatData(dataAll,sigTreated);
    disp('Artifact reduction applied.')
end

%% Wavelet De-Noising
if isfield(sigTreated,'sigDenoising')
    set(handles.t_msg,'String','Wavelet de-noising...');
    [trData, vData, tData, stopFlag]=ApplySignalDenoising(sigTreated,trData, vData, tData);
    if stopFlag
        sigTreated.stopFlag = true;
        return
    end
    disp('Wavelet de-noising applied');
end

%% Sig Separation - Apply calculated ICA unmixing Matrix W
if isfield(sigTreated,'sigSeparation')
    [trData, vData, tData]=ICAPreprocess(sigTreated,trData,vData,tData);
    disp('Signal separation applied.')
end

% add the new sets of tw for tr, v and t
sigTreated.trData = trData;
sigTreated.vData = vData;
sigTreated.tData = tData;

end

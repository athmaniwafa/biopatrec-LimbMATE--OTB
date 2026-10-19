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
% ------------------- Function Description ------------------
% Function to Record Exc Sessions
%
% --------------------------Updates--------------------------
% 2015-01-26 / Enzo Mastinu / A new GUI_Recordings has been developed for the
% BioPatRec_TRE release. Now it is possible to
% plot more then 8 channels at the same moment, for
% time and frequency plots both. It is faster and
% perfectly compatible with the ramp recording
% session. At the end of the recording session it
% is possible to check all channels individually,
% apply offline data process as feature extraction or filter etc.
% 2015-02-20 / Enzo Mastinu / Added the scaling of the data: now every channel plot will be
% dynamically and automatically resize to fit in the proper portion
% of the main plot. This is to avoid overlapping of channels
% waveforms and to have always the best zoom for every channel.
% 2015-02-23 / Enzo Mastinu / The scale of every channel plot is now the
% same scale of the channel which has the
% maximum absolute value
% 2015-02-24 / Enzo Mastinu / Now it is possible to choose if delete or not
% the offset introduced by the AFE from the time
% window plot
% 2015-10-28 / Martin Holder / >2014b plot interface fixes
% 2019-03-06 / Bahareh Ahkami / Bar plot added to the system
%20xx-xx-xx / Author  / Comment



function RecordingSession_ShowData(src, event)

global      handles;
global      allData;
global      timeStamps;
global      samplesCounter;
global      offsetDelete;
global      plotGain;
global      barChartParams;

% Get required info from handles
sF              = handles.sF;
nCh             = handles.nCh;
rep             = handles.rep;
cT              = handles.cT;
rT              = handles.rT;
sT              = handles.sT;
ComPortType     = handles.ComPortType;
rampStatus      = handles.rampStatus;
featureType     = handles.featureType;
plotType        = handles.plotType;
if rampStatus
    rampMin     = handles.RampMin;
    rampMax     = handles.currentRampMax;
end
p_t0 = handles.p_t0;
p_f0 = handles.p_f0;

% Get data from tempData and add to allData global vector
lmPreallocated = isfield(handles,'lmRecordedSamples') && ~isempty(handles.lmRecordedSamples);
if isempty(allData) || (lmPreallocated && handles.lmRecordedSamples == 0)                                                   % Fist DAQ callback
    % First data frame
    timeStamps = [];
    
    % Reset all parameters of the bar chart
    barChartParams = [];
    barChartParams.min = 0;
    barChartParams.max = 1e-12;
    
    % the variable plotGain must be reloaded on every starting of a new
    % recording, the reason of set it on a huge values is that in this
    % way we are sure that this value will be overwritten with a lower
    % value, see the code below for more details
    plotGain = 10000000;
end
tempData = event.Data;

if isfield(handles, 'OTBRecordingMap') && ...
        isscalar(handles.OTBRecordingMap) && isgraphics(handles.OTBRecordingMap)

    mapAx = getappdata(handles.OTBRecordingMap, 'RecordingMapAxes');

    if isgraphics(mapAx, 'axes') && ~isempty(tempData)
        OTB400_ChannelMap('preview', mapAx, tempData);
    end
end

if lmPreallocated
    lastSample = handles.lmRecordedSamples + size(tempData,1);
    if lastSample > size(allData,1)
        error('LM:RecordingCapacity','Recording exceeds its preallocated duration.');
    end
    allData(handles.lmRecordedSamples+1:lastSample,:) = tempData;
    handles.lmRecordedSamples = lastSample;
else
    allData = [allData; tempData];
end
timeStamps = [timeStamps; event.TimeStamps];

% Reading and checkpointing continue at full rate; redraw at most 10 Hz.
if lmPreallocated
    if isfield(handles,'lmLastPlotTic') && toc(handles.lmLastPlotTic) < 0.1 && ...
            handles.lmRecordedSamples < size(allData,1)
        return;
    end
    handles.lmLastPlotTic = tic;
end


%% Status bar update
if handles.fast
    if strcmp(ComPortType,'NI')
        % NI DAQ card
        x = 1-(timeStamps(end)/sT);
    else
        x = 1-(samplesCounter/(sT*sF));
    end
else
    if strcmp(ComPortType,'NI')
        % NI DAQ card
        if handles.contraction
            thisToc = timeStamps(end) - ((rep-1)*(cT+rT));
            lastToc = cT;
        else
            thisToc = timeStamps(end) - ((rep*cT)+((rep-1)*rT));
            lastToc = rT;
        end
        x = 1-(thisToc/lastToc);
    else
        % other devices
        if handles.contraction
            x = 1-(samplesCounter/(cT*sF));
        else
            x = 1-(samplesCounter/(rT*sF));
        end
    end
end
if ~isfield(handles,'hPatch') || ...
        ~isscalar(handles.hPatch) || ...
        ~isgraphics(handles.hPatch,'patch') || ...
        ~isequal(get(handles.hPatch,'Parent'), handles.a_prog)

    handles.hPatch = patch( ...
        'Parent', handles.a_prog, ...
        'XData', [0 x x 0], ...
        'YData', [0 0 1 1], ...
        'FaceColor', 'b', ...
        'EdgeColor', 'b', ...
        'Visible', 'on');
else
    set(handles.hPatch,'XData',[0 x x 0]);
end


if rampStatus
    %% Uppdate ramp effort tracker
    % Absolute value over all the channels and the current data
    if handles.contraction
        chAvgRMS = mean(sqrt(mean((tempData.^2),2)));                  % RMS Mean value on all Chs (compatible with old version of Matlab)
        effortRatio = 100*(abs((chAvgRMS-rampMin)/(rampMax-rampMin)));
        if effortRatio > 100
            effortRatio = 100;
        end
        if strcmp(ComPortType,'NI')
            x = timeStamps(end)-(rep-1)*(cT+rT);
        else
            x = (samplesCounter/sF);
        end
        set(handles.hLine,'XData', x,'Ydata', effortRatio);
    else
        set(handles.hLine,'XData', 0,'Ydata', 0);
    end
end


%% Display peeked Data

aNs = length(tempData(:,1));
NFFT = 2^nextpow2(aNs);                                                % Next power of 2 from number of samples
f = sF/2*linspace(0,1,NFFT/2);
dataf = fft(tempData(1:aNs,:),NFFT)/aNs;
m = 2*abs(dataf((1:NFFT/2),:));
set(p_f0,'XData',f);

% Offset the plot of the different channels to fit into the main figure
ampPP     = 5;
offVector = 0:nCh-1;
offVector = offVector .* ampPP;

if offsetDelete
    % delete the offset of the AFE and add offsets to plot channels in same graph
    offset = mean(tempData);
    for j = 1 : nCh
        tempData(:,j) = tempData(:,j) - offset(j);
    end
end
% calculate single channel's plot gain for frequency window
Kf = ampPP/(2*(max(max(abs(m)))));
% calculate single channel's plot gain for time window
% the idea is that the gain is automatically scaled depending on the absolute maximum
% value found in this new recording. In this way the gain will be changed
% dynamically to be able to discern a "rest" from a "contraction" plot
K = ampPP/(2*(max(max(abs(tempData)))));
if K < plotGain
    % if the signals in the different windows is getting bigger the gain
    % must be reduced consequently, the channels plots must always fit
    % the main plot
    plotGain = K;
end
%% plot a new tWs sized window
if strcmp(plotType,'Raw Signal')
    for j = 1 : nCh
        set(p_t0(j),'YData',tempData(:,j)*plotGain + offVector(j));              % add offsets to plot channels in same graph
        set(p_f0(j),'YData',m(:,j)*Kf + offVector(j));
    end
end
if strcmp(plotType,'Bar Chart')
    
    for j = 1 : nCh
        set(p_f0(j),'YData',m(:,j)*Kf + offVector(j));
    end
    
    fID=handles.featureType;
    features = ExtractSigFeatureOnline(tempData,sF,fID);
    p_t0 = bar(handles.a_t0, features);
    
    featMin = min(features);
    featMax = max(features);
    if featMin < barChartParams.min
        barChartParams.min = featMin;
    else
        %barChartParams.min = barChartParams.min * 0.9 + featMin * 0.1;
    end
    if featMax > barChartParams.max
        barChartParams.max = featMax;
    else
        %barChartParams.max = barChartParams.max * 0.9 + featMax * 0.1;
    end
    handles.p_t0 = p_t0;
    ylim(handles.a_t0, [barChartParams.min barChartParams.max]); 
    
    set(handles.a_t0,'XTick',offVector);
    set(handles.a_t0,'XTickLabel',0:nCh-1);
end

% Reapply the selection after each RT update.
mainFig = ancestor(handles.a_t0,'figure');

if strcmp(plotType,'Raw Signal') && ...
        isappdata(mainFig,'OTBRecordingRefresh')
    refreshTrace = getappdata(mainFig,'OTBRecordingRefresh');
    refreshTrace();
end

drawnow expose

end
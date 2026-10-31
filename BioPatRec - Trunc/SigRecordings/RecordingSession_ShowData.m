function RecordingSession_ShowData(src, event)
% ---------------------------- Copyright Notice ---------------------------
% This file is part of BioPatRec © which is open and free software under
% the GNU Lesser General Public License (LGPL). See the file "LICENSE" for
% the full license governing this code and copyrights.
%
% BioPatRec was initially developed by Max J. Ortiz C. at Integrum AB and
% Chalmers University of Technology. All authors’ contributions must be kept
% acknowledged below in the section "Updates % Contributors".
% ------------------- Function Description ------------------
% Function to Record Exc Sessions
% --------------------------Updates--------------------------

global      handles;
global      allData;
global      timeStamps;
global      samplesCounter;
global      offsetDelete;
global      plotGain;
global      barChartParams;

% Check if GUI window is still alive
if isempty(handles) || ~isstruct(handles) || ~isfield(handles, 'a_t0') || ~isvalid(handles.a_t0)
    return;
end

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

% Initialize plots if they don't exist yet (for Fast Recording)
if ~isfield(handles, 'p_t0') || isempty(handles.p_t0)
    if isvalid(handles.a_t0)
        handles.p_t0 = plot(handles.a_t0, zeros(100, nCh));
    end
end
if ~isfield(handles, 'p_f0') || isempty(handles.p_f0)
    if isvalid(handles.a_f0)
        handles.p_f0 = plot(handles.a_f0, zeros(100, nCh));
    end
end

p_t0 = handles.p_t0;
p_f0 = handles.p_f0;

% Get data from tempData and add to allData global vector
firstWindow=isempty(allData);
if(firstWindow)                                                   % Fist DAQ callback
    timeStamps = [];
    barChartParams = [];
    barChartParams.min = 0;
    barChartParams.max = 1e-12;
    plotGain = 10000000;
end
tempData = event.Data;
% Store every window, even when rendering is throttled.
allData = [allData; tempData];
timeStamps = [timeStamps; event.TimeStamps];
if isfield(handles,'deviceName') && isOTB400(handles.deviceName)
    if ~firstWindow && isfield(handles,'lastOTBRender') && toc(handles.lastOTBRender)<0.25
        return;
    end
    % Restart the render timer only after the GUI has finished drawing.
end

% --- FIX FOR LIMBMATE / OTB MAP CRASH ---
mapAx = [];
if isfield(handles, 'deviceName') && isLimbMATE(handles.deviceName)
    % Do nothing, LimbMATE doesn't have an OTB map
else
    if isfield(handles, 'OTBRecordingMap') && ~isempty(handles.OTBRecordingMap)
        try
            mapAx = getappdata(handles.OTBRecordingMap, 'RecordingMapAxes');
        catch
            mapAx = []; 
        end
    end
end

if isscalar(mapAx) && isgraphics(mapAx, 'axes') && ~isempty(tempData)
    OTB400_ChannelMap('preview', mapAx, tempData);
end
% ----------------------------------------

%% Status bar update
if isfield(handles, 'fast') && handles.fast
    if strcmp(ComPortType,'NI')
        x = 1-(timeStamps(end)/sT);
    else
        x = 1-(samplesCounter/(sT*sF));
    end
else
    if strcmp(ComPortType,'NI')
        if handles.contraction
            thisToc = timeStamps(end) - ((rep-1)*(cT+rT));
            lastToc = cT;
        else
            thisToc = timeStamps(end) - ((rep*cT)+((rep-1)*rT));
            lastToc = rT;
        end
        x = 1-(thisToc/lastToc);
    else
        if handles.contraction
            x = 1-(samplesCounter/(cT*sF));
        else
            x = 1-(samplesCounter/(rT*sF));
        end
    end
end

if isvalid(handles.a_prog)
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
end

if rampStatus && isvalid(handles.a_effortPlot)
    %% Uppdate ramp effort tracker
    if handles.contraction
        chAvgRMS = mean(sqrt(mean((tempData.^2),2))); 
        effortRatio = 100*(abs((chAvgRMS-rampMin)/(rampMax-rampMin)));
        if effortRatio > 100
            effortRatio = 100;
        end
        if strcmp(ComPortType,'NI')
            x = timeStamps(end)-(rep-1)*(cT+rT);
        else
            x = (samplesCounter/sF);
        end
        if isvalid(handles.hLine)
            set(handles.hLine,'XData', x,'Ydata', effortRatio);
        end
    else
        if isvalid(handles.hLine)
            set(handles.hLine,'XData', 0,'Ydata', 0);
        end
    end
end

%% Display peeked Data
aNs = length(tempData(:,1));
NFFT = 2^nextpow2(aNs);                                                
f = sF/2*linspace(0,1,NFFT/2);
dataf = fft(tempData(1:aNs,:),NFFT)/aNs;
m = 2*abs(dataf((1:NFFT/2),:));
if isvalid(p_f0(1)), set(p_f0,'XData',f); end

% Offset the plot of the different channels to fit into the main figure
ampPP     = 5;
offVector = 0:nCh-1;
offVector = offVector .* ampPP;

% --- FORCE OFFSET REMOVAL ONLY FOR LIMBMATE ---
if isfield(handles, 'deviceName') && isLimbMATE(handles.deviceName)
    offset = mean(tempData);
    for j = 1 : nCh
        tempData(:,j) = tempData(:,j) - offset(j);
    end
elseif offsetDelete
    offset = mean(tempData);
    for j = 1 : nCh
        tempData(:,j) = tempData(:,j) - offset(j);
    end
end

% Prevent division by zero if the signal is perfectly flat
if max(max(abs(tempData))) == 0
    K = 1; 
else
    K = ampPP/(2*(max(max(abs(tempData)))));
end

Kf = ampPP/(2*(max(max(abs(m)))));
if K < plotGain
    plotGain = K;
end

%% plot a new tWs sized window
if strcmp(plotType,'Raw Signal')
    rawGains=repmat(plotGain,1,nCh);
    frequencyGains=repmat(Kf,1,nCh);
    plotFigure=ancestor(handles.a_t0,'figure');
    if isappdata(plotFigure,'OTBChannelLayout')
        channelLayout=getappdata(plotFigure,'OTBChannelLayout');
        rawGains=OTB400_DisplayScale(tempData,channelLayout,ampPP);
        frequencyGains=OTB400_DisplayScale(m,channelLayout,ampPP);
    end
    for j = 1 : nCh
        if isvalid(p_t0(j)), set(p_t0(j),'YData',tempData(:,j)*rawGains(j) + offVector(j)); end
        if isvalid(p_f0(j)), set(p_f0(j),'YData',m(:,j)*frequencyGains(j) + offVector(j)); end
    end
end

if strcmp(plotType,'Bar Chart')
    for j = 1 : nCh
        if isvalid(p_f0(j)), set(p_f0(j),'YData',m(:,j)*Kf + offVector(j)); end
    end
    
    fID=handles.featureType;
    features = ExtractSigFeatureOnline(tempData,sF,fID);
    
    if isvalid(handles.a_t0)
        p_t0 = bar(handles.a_t0, features);
    end
    
    featMin = min(features);
    featMax = max(features);
    if featMin < barChartParams.min
        barChartParams.min = featMin;
    end
    if featMax > barChartParams.max
        barChartParams.max = featMax;
    end
    handles.p_t0 = p_t0;
    if isvalid(handles.a_t0)
        ylim(handles.a_t0, [barChartParams.min barChartParams.max]); 
        set(handles.a_t0,'XTick',offVector);
        set(handles.a_t0,'XTickLabel',0:nCh-1);
    end
end

mainFig = ancestor(handles.a_t0,'figure');
setappdata(handles.a_t0,'OTBOffsetsAreNative',true);
if strcmp(plotType,'Raw Signal') && isappdata(mainFig,'OTBRecordingRefresh')
    refreshTrace = getappdata(mainFig,'OTBRecordingRefresh');
    refreshTrace();
end
OTB400_ApplyChannelLabels(handles, plotType);
drawnow expose
if isfield(handles,'deviceName') && isOTB400(handles.deviceName)
    handles.lastOTBRender=tic;
end
end
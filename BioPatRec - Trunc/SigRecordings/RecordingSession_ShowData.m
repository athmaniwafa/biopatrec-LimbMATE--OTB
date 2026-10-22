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
if ~isvalid(handles.a_t0)
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
p_t0 = handles.p_t0;
p_f0 = handles.p_f0;

% Get data from tempData and add to allData global vector
if(isempty(allData))                                                   % Fist DAQ callback
    timeStamps = [];
    barChartParams = [];
    barChartParams.min = 0;
    barChartParams.max = 1e-12;
    plotGain = 10000000;
end
tempData = event.Data;

if isfield(handles, 'OTBRecordingMap') && all(isgraphics(handles.OTBRecordingMap))
    mapAx = getappdata(handles.OTBRecordingMap, 'RecordingMapAxes');
    if isgraphics(mapAx, 'axes') && ~isempty(tempData)
        OTB400_ChannelMap('preview', mapAx, tempData);
    end
end

allData = [allData; tempData];
timeStamps = [timeStamps; event.TimeStamps];

%% Status bar update
if handles.fast
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
    for j = 1 : nCh
        if isvalid(p_t0(j)), set(p_t0(j),'YData',tempData(:,j)*plotGain + offVector(j)); end
        if isvalid(p_f0(j)), set(p_f0(j),'YData',m(:,j)*Kf + offVector(j)); end
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
if strcmp(plotType,'Raw Signal') && isappdata(mainFig,'OTBRecordingRefresh')
    refreshTrace = getappdata(mainFig,'OTBRecordingRefresh');
    refreshTrace();
end
drawnow expose
end
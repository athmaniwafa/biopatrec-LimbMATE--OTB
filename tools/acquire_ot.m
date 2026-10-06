function R = acquire_ot(mode,Duration,nBipolar)

if nargin < 1
    mode = 'hd2';
end

if nargin < 2
    Duration = 20;
end

if nargin < 3
    nBipolar = 1;
end

mode = lower(char(mode));

Fs = 2048;
EventsPerSecond = 16;
PlotWindow = 1;
PlotDecimation = 8;
PlotPeriod = 0.125;
RawShiftCounts = 4500;

[~,out] = system('tasklist | findstr /I "OTBioLab"');

if ~isempty(strtrim(out))
    error('Chiudi OTBioLab+ prima di acquisire.');
end

NET.addAssembly('C:\Program Files\OT BioLab+\OTComm.dll');

switch mode

    case 'hd1'
        [dev,config] = config_hd1();

    case 'hd2'
        [dev,config] = config_hd2();

    case 'bipolar'
        [dev,config] = config_bipolar(nBipolar);

    otherwise
        error('Modalita non valida. Usa hd1, hd2 oppure bipolar.');

end

dev.NewDataAvailableEventsPerSecond = EventsPerSecond;

TargetFrames = round(Duration * Fs);

listenerData = [];

cleanupObj = onCleanup(@cleanupDevice);

fprintf('\n');
fprintf('Modalita: %s\n',mode);
fprintf('Fs: %d Hz\n',Fs);
fprintf('Durata: %.1f s\n',Duration);

dev.OpenDevice();

fprintf('OpenDevice OK\n');

dev.InitializeDevice();

fprintf('InitializeDevice OK\n');

acquired = double(dev.GetAcquiredChannels());
acquired = acquired(:);

Nch = numel(acquired);

fprintf('Canali acquisiti: %d\n',Nch);

if Nch ~= config.NumChannels
    error('Attesi %d canali, ricevuti %d.',config.NumChannels,Nch);
end

try
    xmlConfig = char(dev.GetDeviceXMLConfiguration());
catch
    xmlConfig = '';
end

rawBuffer = zeros(TargetFrames,Nch,'int16');

writeIndex = 0;
eventCount = 0;
done = false;

%% REALTIME

offsets = (0:Nch-1) * RawShiftCounts;

fig = figure('Name',['OTComm realtime - ' mode],'NumberTitle','off');

ax = axes(fig);

hold(ax,'on');

lines = gobjects(Nch,1);

for ch = 1:Nch
    lines(ch) = plot(ax,nan,nan);
end

xlabel(ax,'Tempo [s]');
ylabel(ax,'Canali RAW shiftati');
grid(ax,'on');

if strcmp(mode,'hd2')
    title(ax,'HD 2x64 | M1: CH 1-64 | M2: CH 65-128');
elseif strcmp(mode,'hd1')
    title(ax,'HD 1x64');
else
    title(ax,sprintf('Bipolari: %d canali',Nch));
end

xlim(ax,[0 PlotWindow]);

ylim(ax,[-RawShiftCounts/2 offsets(end)+RawShiftCounts/2]);

if Nch <= 16
    tickChannels = 1:Nch;
else
    tickChannels = 1:8:Nch;
end

yticks(ax,offsets(tickChannels));

tickLabels = arrayfun(@num2str,tickChannels,'UniformOutput',false);

yticklabels(ax,tickLabels);

drawnow

%% LISTENER

listenerData = addlistener(dev,'OnNewDataAvailable',@receiveData);

%% START

dev.StartAcquisition();

fprintf('Acquisizione avviata\n');

timerStart = tic;
plotTimer = tic;

while ~done

    pause(0.01);

    currentWriteIndex = writeIndex;

    fprintf('\rFrame %d / %d',currentWriteIndex,TargetFrames);

    if currentWriteIndex > 0 && toc(plotTimer) >= PlotPeriod

        firstFrame = max(1,currentWriteIndex-round(PlotWindow*Fs)+1);

        plotIndices = firstFrame:PlotDecimation:currentWriteIndex;

        x = (plotIndices-1)' / Fs;

        y = double(rawBuffer(plotIndices,:));

        if isgraphics(fig)

            for ch = 1:Nch
                set(lines(ch),'XData',x,'YData',y(:,ch)+offsets(ch));
            end

            currentTime = currentWriteIndex / Fs;

            xStart = max(0,currentTime-PlotWindow);

            xEnd = max(PlotWindow,currentTime);

            xlim(ax,[xStart xEnd]);

            drawnow limitrate nocallbacks

        end

        plotTimer = tic;

    end

    if toc(timerStart) > Duration + 10
        fprintf('\nTimeout acquisizione\n');
        break
    end

end

fprintf('\n');

try
    dev.StopAcquisition();
catch
end

try
    delete(listenerData);
    listenerData = [];
catch
end

N = writeIndex;

raw = rawBuffer(1:N,:);

t = (0:N-1)' / Fs;

fprintf('Frame registrati: %d\n',N);
fprintf('Durata reale: %.3f s\n',N/Fs);

%% ============================================================
% PLOT FINALE DI TUTTI I SEGNALI
%% ============================================================

FinalShift = 4500;

offsetsFinal = (0:Nch-1) * FinalShift;

figure('Name',['Registrazione finale - ' mode],'NumberTitle','off');

axFinal = axes;

hold(axFinal,'on');

for ch = 1:Nch

    y = double(raw(:,ch));

    y = y - mean(y);

    y = y + offsetsFinal(ch);

    plot(axFinal,t,y);

end

xlabel(axFinal,'Tempo [s]');

ylabel(axFinal,'Canali shiftati');

grid(axFinal,'on');

xlim(axFinal,[0 t(end)]);

ylim(axFinal,[-FinalShift/2 offsetsFinal(end)+FinalShift/2]);

if Nch <= 16

    tickChannels = 1:Nch;

else

    tickChannels = 1:8:Nch;

end

yticks(axFinal,offsetsFinal(tickChannels));

tickLabels = arrayfun(@(x) sprintf('CH %d',x),tickChannels,'UniformOutput',false);

yticklabels(axFinal,tickLabels);

if strcmp(mode,'hd2')

    title(axFinal,'Registrazione finale - HD 2x64');

elseif strcmp(mode,'hd1')

    title(axFinal,'Registrazione finale - HD 1x64');

else

    title(axFinal,'Registrazione finale - Bipolari');

end

%% OUTPUT SPECIFICO

matrix1 = [];
matrix2 = [];

if strcmp(mode,'hd1')
    matrix1 = raw(:,1:64);
end

if strcmp(mode,'hd2')
    matrix1 = raw(:,1:64);
    matrix2 = raw(:,65:128);
end

config.Mode = mode;
config.Fs = Fs;
config.Duration = Duration;
config.AcquiredChannels = acquired;
config.XML = xmlConfig;

timestamp = datestr(now,'yyyymmdd_HHMMSS');

filename = sprintf('OT_%s_%s.mat',mode,timestamp);

save(filename,'raw','matrix1','matrix2','t','Fs','config','-v7.3');

fprintf('Salvato: %s\n',fullfile(pwd,filename));

R.raw = raw;
R.t = t;
R.Fs = Fs;
R.config = config;
R.filename = fullfile(pwd,filename);

if strcmp(mode,'hd1')
    R.matrix1 = matrix1;
end

if strcmp(mode,'hd2')
    R.matrix1 = matrix1;
    R.matrix2 = matrix2;
end

%% CALLBACK

    function receiveData(~,eventData)

        if done
            return
        end

        eventCount = eventCount + 1;

        D = eventData.Data;

        u = uint16(D.data16);
        u = u(:);

        s = typecast(u,'int16');
        s = s(:);

        nFrames = floor(numel(s) / Nch);

        if nFrames < 1
            return
        end

        s = s(1:nFrames*Nch);

        block = reshape(s,Nch,nFrames)';

        remaining = TargetFrames - writeIndex;

        nTake = min(nFrames,remaining);

        if nTake <= 0
            done = true;
            return
        end

        i1 = writeIndex + 1;
        i2 = writeIndex + nTake;

        rawBuffer(i1:i2,:) = block(1:nTake,:);

        writeIndex = i2;

        if writeIndex >= TargetFrames
            done = true;
        end

    end

%% CLEANUP

    function cleanupDevice

        try
            if ~isempty(listenerData)
                delete(listenerData);
            end
        catch
        end

        try
            dev.StopAcquisition();
        catch
        end

        try
            dev.CloseDevice();
        catch
        end

    end

end
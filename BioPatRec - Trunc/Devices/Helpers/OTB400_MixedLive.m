function OTB400_MixedLive(ot)
% Live mixed preview with device-local labels and an always-visible HD map.
    if isempty(ot) || ~ismember(ot.mode, {'mixed','inputs'})
        error('OTB400:MixedLive', 'Select and initialize the OTB inputs first.');
    end
    fig = figure('Name', 'OTB400 - Live ingressi', ...
        'NumberTitle', 'off', 'Position', [180 100 1000 720]);
    cleanup = onCleanup(@() finishPreview(ot, fig)); %#ok<NASGU>
    ax = axes('Parent', fig, 'Position', [.39 .16 .57 .73]);
    layout = OTB400_ChannelLayout(ot.config);
    afe = struct('name','OTB400_mixed','channels',ot.Nch,'objOT',ot, ...
        'OTB400Electrodes',ot.config.Electrodes);
    mapPanel = OTB400_OpenRecordingMap(afe,struct('output',fig,'a_t0',ax));
    set(mapPanel,'Position',[.01 .16 .26 .73]);
    mapAx = getappdata(mapPanel,'RecordingMapAxes');
    uicontrol(fig, 'Style', 'text', 'Units', 'normalized', ...
        'Position', [.04 .93 .92 .05], ...
        'String', strjoin(layout.GroupNames,' | '));
    signalStatus=uicontrol(fig,'Style','text','Units','normalized', ...
        'Position',[.04 .895 .92 .03],'String','');
    stopButton = uicontrol(fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
        'Position', [.65 .03 .22 .06], 'String', 'Stop', ...
        'Callback', @(~,~) setappdata(fig, 'Stop', true));
    setappdata(fig, 'Stop', false);
    history = zeros(ot.Fs, ot.Nch, 'single');
    t = (0:ot.Fs-1)' / ot.Fs;
    ot.startAcquisitionEMG();
    while isgraphics(fig) && ~getappdata(fig, 'Stop')
        block = ot.getEMG_data_TW_float(256);
        history = [history(257:end,:); block];
        if ~isgraphics(fig), break; end
        cols = 1:ot.Nch;
        data = double(history(:,cols));
        data = data - mean(data,1);
        gains = OTB400_DisplayScale(data,layout,1);
        offsets = 0:numel(cols)-1;
        plot(ax, t, data .* gains + offsets);
        setappdata(ax,'OTBTraceColumns',cols);
        setappdata(ax,'OTBTraceSpacing',1);
        setappdata(ax,'OTBOffsetsAreNative',true);
        set(ax, 'YTick', offsets, 'YTickLabel', layout.Labels(cols), ...
            'YLim', [-.7 numel(cols)-.3], 'XLim', [0 1]);
        xlabel(ax, 'Tempo (s)');
        title(ax, 'Ultimo secondo | scala indipendente per ingresso');
        groupLevels=cell(1,numel(layout.GroupNames));
        for k=1:numel(groupLevels)
            values=abs(data(:,layout.GroupColumns{k}));
            groupLevels{k}=sprintf('%s: picco %.0f ADC',layout.GroupNames{k},max(values(:)));
        end
        set(signalStatus,'String',strjoin(groupLevels,' | '));
        grid(ax, 'on');
        if isgraphics(mapAx,'axes'), OTB400_ChannelMap('preview',mapAx,history); end
        refresh = getappdata(fig,'OTBRecordingRefresh');
        refresh();
        drawnow;
    end
    ot.stopAcquisitionEMG();
    if isgraphics(fig)
        set(stopButton, 'Enable', 'off');
        title(ax, 'Acquisizione arrestata');
    end
end

function finishPreview(ot, fig)
    ot.stopAcquisitionEMG();
    if isgraphics(fig), setappdata(fig, 'Stop', true); end
end

function panel = OTB400_OpenRecordingMap(afeSettings, h)

panel = [];

if ~isfield(h, 'output') || ~isscalar(h.output) || ...
        ~isgraphics(h.output, 'figure')
    error('OTB400:InvalidGUI', ...
        'La finestra di registrazione non è valida.');
end

mainFig = h.output;
if isappdata(mainFig,'OTBChannelLabels'), rmappdata(mainFig,'OTBChannelLabels'); end
if isappdata(mainFig,'OTBChannelLayout'), rmappdata(mainFig,'OTBChannelLayout'); end
layout = [];
if isOTB400(afeSettings.name)
    if isfield(afeSettings,'objOT') && ~isempty(afeSettings.objOT)
        config = afeSettings.objOT.config;
    elseif isfield(afeSettings,'OTB400Config')
        config = afeSettings.OTB400Config;
    else
        config = struct('NumChannels',afeSettings.channels);
        if strcmp(char(afeSettings.name),'OTB400_HD')
            config.NumMatrices = afeSettings.channels/64;
        else
            config.NumBipolar = afeSettings.channels;
        end
    end
    layout = OTB400_ChannelLayout(config);
    setappdata(mainFig,'OTBChannelLabels',layout.Labels);
    setappdata(mainFig,'OTBChannelLayout',layout);
end

% Reset previous state
OTB400_ChannelMap('remove', mainFig);
delete(findall(mainFig, 'Tag', 'OTBRecordingPanel'));
delete(findall(0, 'Tag', 'SQHeatFig'));
if isappdata(mainFig, 'SQHeatmapUpdate')
    rmappdata(mainFig, 'SQHeatmapUpdate');
end

if isappdata(mainFig, 'OTBRecordingRefresh')
    rmappdata(mainFig, 'OTBRecordingRefresh');
end

% Decide whether the HD map is used:
%  - OTB400_HD: always
%  - SQ+ matrix (64 ch): only when "Session + map" was chosen
isSQmatrix = isSQplus(afeSettings.name) && afeSettings.channels == 64;
if isSQmatrix
    if ~isfield(afeSettings,'SQDisplay') || ~strcmp(afeSettings.SQDisplay,'session_map')
        return
    end
elseif isempty(layout)
    return
end

if ~isfield(h, 'a_t0') || ~isscalar(h.a_t0) || ...
        ~isgraphics(h.a_t0, 'axes')
    error('OTB400:InvalidGUI', ...
        'Il grafico della registrazione HD non è valido.');
end

hasHD = isempty(layout) || ~isempty(layout.HDColumns);
if hasHD && ~isfield(afeSettings, 'OTB400Electrodes')
    error('Seleziona prima gli elettrodi HD.');
end

% Panel below the status message in the existing window.
panel = uipanel( ...
    'Parent', mainFig, ...
    'Tag', 'OTBRecordingPanel', ...
    'Units', 'normalized', ...
    'Position', [0.005 0.02 0.25 0.34], ...
    'BackgroundColor', [1 1 1], ...
    'Title', '');

if isempty(layout)
    layout = OTB400_ChannelLayout(struct('NumChannels',64,'NumMatrices',1));
end
groupPanel=OTB400_ChannelGroups(panel,layout,@highlightTrace);
groupPosition=get(groupPanel,'Position');
groupBottom=groupPosition(2);

filterButton = uicontrol( ...
    'Parent',groupPanel, ...
    'Style','togglebutton', ...
    'Units','normalized', ...
    'Position',[.05 .02 .90 .43], ...
    'String','Show selected', ...
    'Tag','OTBShowSelected', ...
    'Value',0, ...
    'Callback',@onFilter);

mapAx = [];
mapMotion = [];
if hasHD
mapAx = axes( ...
    'Parent', panel, ...
    'Units', 'normalized', ...
    'Position', [0.03 0.03 0.94 max(.15,groupBottom-.09)]);

setappdata(mapAx, 'OTB400_UniformBackground', true);

electrodes = afeSettings.OTB400Electrodes;
% Use the electrode types belonging to the actual acquisition configuration.
if isOTB400(afeSettings.name) && isfield(config,'Electrodes')
    electrodes = config.Electrodes;
end
if ~isempty(layout)
    electrodes.HDColumns = layout.HDColumns;
    electrodes.HDInputNumbers = layout.HDInputNumbers;
    electrodes.ChannelLabels = layout.Labels;
    electrodes.LocalNumbers = layout.LocalNumbers;
end
OTB400_ChannelMap('install', mainFig, mapAx, ...
    afeSettings.channels, electrodes);

st = getappdata(mainFig, 'OTB400_ChannelMapState');
set(st.panel, 'Visible', 'off');
set(st.toggle, 'Visible', 'off');

setappdata(panel, 'RecordingMapAxes', mapAx);

OTB400_ChannelMap('preview', mapAx, ...
    zeros(1, afeSettings.channels));

mapMotion = get(mainFig, 'WindowButtonMotionFcn');
set(mainFig, 'WindowButtonMotionFcn', @onMotion);
else
    set(filterButton,'Visible','off');
    set(panel,'Title','');
end

setappdata(mainFig, 'OTBRecordingRefresh', @highlightTrace);
% Keep the compact controls at a fixed pixel height when the panel resizes.
set(panel,'SizeChangedFcn',@resizePanel);
resizePanel();

% Live amplitude heatmap in its own window (drawn on the installed map)
try
    OTB400_LiveHeatmap('open', mainFig);
catch heatErr
    warning('Live heatmap unavailable: %s', heatErr.message);
end

    function resizePanel(~,~)
        pixels=getpixelposition(panel);
        rows=getappdata(groupPanel,'OTBGroupRows');
        height=min(.75,(24*(rows+1)+4)/max(1,pixels(4)));
        bottom=.99-height;
        set(groupPanel,'Position',[.02 bottom .96 height]);
        if isgraphics(mapAx,'axes')
            set(mapAx,'Position',[.03 .03 .94 max(.15,bottom-.09)]);
        end
    end
    function onFilter(src,~)
        if get(src,'Value')
            set(src,'String','Show all');
        else
            set(src,'String','Show selected');
        end
        highlightTrace();
    end

    function onMotion(src, evt)
        if ~isgraphics(panel)
            return
        end
        if isa(mapMotion,'function_handle'), mapMotion(src, evt); end
        highlightTrace();
    end

    function highlightTrace()
        if ~isgraphics(panel) || ~isgraphics(h.a_t0)
            return
        end

        state = struct('map',[],'hovered',0,'channelLabels',{layout.Labels});
        if hasHD, state = getappdata(mainFig,'OTB400_ChannelMapState'); end

        marked = false(1,afeSettings.channels);
        if isfield(state,'marked')
            marked = state.marked;
        end

        onlySelected = logical(get(filterButton,'Value'));

        active = marked;
        if state.hovered >= 1 && state.hovered <= numel(active)
            active(state.hovered) = true;
        end

        traces = flipud(findobj(h.a_t0, 'Type', 'line'));

        channels = 1:afeSettings.channels;
        if isappdata(h.a_t0,'OTBTraceColumns')
            channels = getappdata(h.a_t0,'OTBTraceColumns');
        end
        if numel(traces) ~= numel(channels), return; end
        hdChannels = state.map(isfinite(state.map));
        visible = getappdata(mainFig,'OTBGroupMask');
        if onlySelected
            visible(hdChannels) = visible(hdChannels) & marked(hdChannels);
        end
        displayColumns = channels(visible(channels));
        spacing = 5;
        if isappdata(h.a_t0,'OTBTraceSpacing'), spacing=getappdata(h.a_t0,'OTBTraceSpacing'); end
        ticks = (0:numel(displayColumns)-1)*spacing;
        setappdata(h.a_t0,'OTBDisplayColumns',displayColumns);
        setappdata(h.a_t0,'OTBDisplayTicks',ticks);
        set(h.a_t0,'YTick',ticks,'YTickLabel',state.channelLabels(displayColumns), ...
            'YLim',[-.6*spacing max(.6*spacing,(numel(ticks)-.4)*spacing)]);
        nativeOffsets = true;
        if isappdata(h.a_t0,'OTBOffsetsAreNative')
            nativeOffsets = getappdata(h.a_t0,'OTBOffsetsAreNative');
        end

        for k = 1:numel(traces)
            lineHandle = traces(k);
            ch = channels(k);
            if nativeOffsets, setappdata(lineHandle,'OTBCurrentOffset',(ch-1)*spacing); end

            if ~visible(ch)
                set(lineHandle,'Visible','off');
            else
                set(lineHandle,'Visible','on');
                moveTrace(lineHandle,ch,displayColumns,spacing,nativeOffsets);
            end

            if ~isappdata(lineHandle, 'OTBOriginalStyle')
                style = struct( ...
                    'Color', get(lineHandle, 'Color'), ...
                    'LineWidth', get(lineHandle, 'LineWidth'));
                setappdata(lineHandle, 'OTBOriginalStyle', style);
            end

            style = getappdata(lineHandle, 'OTBOriginalStyle');

            if active(ch)
                set(lineHandle, 'Color', [0.90 0.10 0.10], 'LineWidth', 2);
            else
                set(lineHandle, 'Color', style.Color, 'LineWidth', style.LineWidth);
            end
        end

        frequencyLines = [];
        if isfield(h,'a_f0') && isgraphics(h.a_f0,'axes')
            frequencyLines = flipud(findobj(h.a_f0,'Type','line'));
        end

        if numel(frequencyLines) == numel(marked)
            for k = 1:numel(frequencyLines)
                if nativeOffsets, setappdata(frequencyLines(k),'OTBCurrentOffset',(k-1)*spacing); end
                if ~visible(k)
                    set(frequencyLines(k),'Visible','off');
                else
                    set(frequencyLines(k),'Visible','on');
                    moveTrace(frequencyLines(k),k,displayColumns,spacing,nativeOffsets);
                end
            end
            set(h.a_f0,'YTick',ticks,'YTickLabel',state.channelLabels(displayColumns), ...
                'YLim',[-.6*spacing max(.6*spacing,(numel(ticks)-.4)*spacing)]);
        end
        setappdata(h.a_t0,'OTBOffsetsAreNative',false);

        if numel(get(h.a_t0,'YTick')) == numel(displayColumns)
            set(h.a_t0, 'YTickLabel', state.channelLabels(displayColumns));
        end

    end

    function moveTrace(lineHandle,ch,columns,spacing,nativeOffsets)
        oldOffset = (ch-1)*spacing;
        if ~nativeOffsets && isappdata(lineHandle,'OTBCurrentOffset')
            oldOffset = getappdata(lineHandle,'OTBCurrentOffset');
        end
        newOffset = (find(columns==ch,1)-1)*spacing;
        set(lineHandle,'YData',get(lineHandle,'YData')-oldOffset+newOffset);
        setappdata(lineHandle,'OTBCurrentOffset',newOffset);
    end
end

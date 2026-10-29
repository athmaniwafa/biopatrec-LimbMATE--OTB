function panel = OTB400_OpenRecordingMap(afeSettings, h)

panel = [];

if ~isfield(h, 'output') || ~isscalar(h.output) || ...
        ~isgraphics(h.output, 'figure')
    error('OTB400:InvalidGUI', ...
        'La finestra di registrazione non è valida.');
end

mainFig = h.output;

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
elseif ~strcmp(char(afeSettings.name), 'OTB400_HD')
    return
end

if ~isfield(h, 'a_t0') || ~isscalar(h.a_t0) || ...
        ~isgraphics(h.a_t0, 'axes')
    error('OTB400:InvalidGUI', ...
        'Il grafico della registrazione HD non è valido.');
end

if ~isfield(afeSettings, 'OTB400Electrodes')
    error('Seleziona prima gli elettrodi HD.');
end

% Panel below the status message in the existing window.
panel = uipanel( ...
    'Parent', mainFig, ...
    'Tag', 'OTBRecordingPanel', ...
    'Units', 'normalized', ...
    'Position', [0.005 0.02 0.25 0.34], ...
    'BackgroundColor', [1 1 1], ...
    'Title', 'Elettrodi HD');

filterButton = uicontrol( ...
    'Parent',panel, ...
    'Style','togglebutton', ...
    'Units','normalized', ...
    'Position',[0.05 0.86 0.90 0.10], ...
    'String','Solo selezionati', ...
    'Value',0, ...
    'Callback',@onFilter);

mapAx = axes( ...
    'Parent', panel, ...
    'Units', 'normalized', ...
    'Position', [0.05 0.06 0.90 0.72]);

setappdata(mapAx, 'OTB400_UniformBackground', true);

OTB400_ChannelMap('install', mainFig, mapAx, ...
    afeSettings.channels, afeSettings.OTB400Electrodes);

st = getappdata(mainFig, 'OTB400_ChannelMapState');
set(st.panel, 'Visible', 'off');
set(st.toggle, 'Visible', 'off');

setappdata(panel, 'RecordingMapAxes', mapAx);

OTB400_ChannelMap('preview', mapAx, ...
    zeros(1, afeSettings.channels));

mapMotion = get(mainFig, 'WindowButtonMotionFcn');
set(mainFig, 'WindowButtonMotionFcn', @onMotion);

setappdata(mainFig, 'OTBRecordingRefresh', @highlightTrace);

% --- SQ+ matrix: separate window with the live amplitude heatmap ---
heatLimit = 0.01;
if isSQmatrix
    gmap    = state0Map(mainFig);
    present = isfinite(gmap);
    hf = figure('Name','SQ+ live heatmap','NumberTitle','off', ...
        'Tag','SQHeatFig','Units','normalized', ...
        'Position',[0.62 0.08 0.30 0.50]);
    hax = axes('Parent',hf);
    hImg = imagesc(hax, nan(size(gmap)));
    set(hImg,'AlphaData',present);
    set(hax,'Color',[.85 .85 .85],'XTick',[],'YTick',[]);
    axis(hax,'image');
    colormap(hax,'jet');
    cb = colorbar(hax);
    ylabel(cb,'mean |x| (mV)');
    hold(hax,'on');
    for rr = 1:size(gmap,1)
        for cc = 1:size(gmap,2)
            if present(rr,cc)
                text(hax,cc,rr,num2str(mod(gmap(rr,cc)-1,64)+1), ...
                    'HorizontalAlignment','center','FontSize',7, ...
                    'Color',[1 1 1],'HitTest','off');
            end
        end
    end
    hold(hax,'off');
    title(hax,'Live amplitude');
    setappdata(mainFig,'SQHeatmapUpdate',@updateHeat);
    figure(mainFig);
end

    function m = state0Map(fig)
        stt = getappdata(fig, 'OTB400_ChannelMapState');
        m = stt.map;
    end

    function updateHeat(cData)
        if ~isgraphics(hImg), return; end
        v = mean(abs(double(cData)),1);
        img = nan(size(gmap));
        img(present) = v(gmap(present));
        set(hImg,'CData',img);
        heatLimit = max(heatLimit*0.97, max(img(:),[],'omitnan'));
        heatLimit = max(heatLimit, 1e-3);
        set(hax,'CLim',[0 heatLimit]);
        drawnow limitrate;
    end

    function onFilter(src,~)
        if get(src,'Value')
            set(src,'String','Mostra tutti');
        else
            set(src,'String','Solo selezionati');
        end
        highlightTrace();
    end

    function onMotion(src, evt)
        if ~isgraphics(panel)
            return
        end
        mapMotion(src, evt);
        highlightTrace();
    end

    function highlightTrace()
        if ~isgraphics(panel) || ~isgraphics(h.a_t0)
            return
        end

        state = getappdata(mainFig, 'OTB400_ChannelMapState');

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

        if numel(traces) ~= afeSettings.channels
            return
        end

        for k = 1:numel(traces)
            lineHandle = traces(k);

            if onlySelected && ~marked(k)
                set(lineHandle,'Visible','off');
            else
                set(lineHandle,'Visible','on');
            end

            if ~isappdata(lineHandle, 'OTBOriginalStyle')
                style = struct( ...
                    'Color', get(lineHandle, 'Color'), ...
                    'LineWidth', get(lineHandle, 'LineWidth'));
                setappdata(lineHandle, 'OTBOriginalStyle', style);
            end

            style = getappdata(lineHandle, 'OTBOriginalStyle');

            if active(k)
                set(lineHandle, 'Color', [0.90 0.10 0.10], 'LineWidth', 2);
            else
                set(lineHandle, 'Color', style.Color, 'LineWidth', style.LineWidth);
            end
        end

        frequencyLines = flipud(findobj(h.a_f0,'Type','line'));

        if numel(frequencyLines) == numel(marked)
            for k = 1:numel(frequencyLines)
                if onlySelected && ~marked(k)
                    set(frequencyLines(k),'Visible','off');
                else
                    set(frequencyLines(k),'Visible','on');
                end
            end
        end

        channels = 1:numel(traces);

        labels = arrayfun(@(k) sprintf('IN%d/%d', ...
            ceil(k/64), mod(k-1,64)+1), ...
            channels, 'UniformOutput', false);

        set(h.a_t0, 'YTickLabel', labels);

        set(panel, 'Title', sprintf('Elettrodi HD - %d canali selezionati', nnz(marked)));
    end
end
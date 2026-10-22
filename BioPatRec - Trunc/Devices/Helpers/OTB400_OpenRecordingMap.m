function panel = OTB400_OpenRecordingMap(afeSettings, h)

panel = [];

% Usa il riferimento alla figura, indipendentemente dalla mappa HD.
if ~isfield(h, 'output') || ~isscalar(h.output) || ...
        ~isgraphics(h.output, 'figure')
    error('OTB400:InvalidGUI', ...
        'La finestra di registrazione non è valida.');
end

mainFig = h.output;

% Reset previous state
OTB400_ChannelMap('remove', mainFig);
delete(findall(mainFig, 'Tag', 'OTBRecordingPanel'));

if isappdata(mainFig, 'OTBRecordingRefresh')
    rmappdata(mainFig, 'OTBRecordingRefresh');
end

% Delete HD map if we are not using OTB400HD
if ~strcmp(char(afeSettings.name), 'OTB400_HD')
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

% This grid selects channels; its background is independent of EMG amplitude.
setappdata(mapAx, 'OTB400_UniformBackground', true);

OTB400_ChannelMap('install', mainFig, mapAx, ...
    afeSettings.channels, afeSettings.OTB400Electrodes);

% Use the numbered grid in the newly created panel.
% Hide the side controls used by the old HD GUI.
st = getappdata(mainFig, 'OTB400_ChannelMapState');
set(st.panel, 'Visible', 'off');
set(st.toggle, 'Visible', 'off');

setappdata(panel, 'RecordingMapAxes', mapAx);

OTB400_ChannelMap('preview', mapAx, ...
    zeros(1, afeSettings.channels));

% Preserve the callback that identifies the electrode under the mouse.
mapMotion = get(mainFig, 'WindowButtonMotionFcn');
set(mainFig, 'WindowButtonMotionFcn', @onMotion);

% Allow lines to be reconnected when DataShow recreates them.
setappdata(mainFig, 'OTBRecordingRefresh', @highlightTrace);

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

        % Selections pinned by clicking.
        marked = false(1,afeSettings.channels);
        if isfield(state,'marked')
            marked = state.marked;
        end

        onlySelected = logical(get(filterButton,'Value'));
        
        % Add a preview of the channel under the mouse.
        active = marked;
        if state.hovered >= 1 && state.hovered <= numel(active)
            active(state.hovered) = true;
        end

        % plot creates lines in channel order;
        % Children/findobj returns them in reverse order.
        traces = flipud(findobj(h.a_t0, 'Type', 'line'));

        % Avoid incorrect mappings in views displaying a subset of channels.
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

        % Physical numbering: IN1/1...64, IN2/1...64.
        channels = 1:numel(traces);

        labels = arrayfun(@(k) sprintf('IN%d/%d', ...
            ceil(k/64), mod(k-1,64)+1), ...
            channels, 'UniformOutput', false);
        
        set(h.a_t0, 'YTickLabel', labels);

        set(panel, 'Title', sprintf('Elettrodi HD - %d canali selezionati', nnz(marked)));
    end
end

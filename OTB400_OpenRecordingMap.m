function panel = OTB400_OpenRecordingMap(afeSettings, h)

panel = [];
if ~isfield(h,'a_t0') || ~isscalar(h.a_t0) || ...
        ~isgraphics(h.a_t0,'axes')
    error('OTB400:InvalidGUI', ...
        'Chiudi e riapri la finestra di registrazione.');
end
mainFig = ancestor(h.a_t0, 'figure');

% Rimuove il pannello della registrazione precedente.
OTB400_ChannelMap('remove', mainFig);
delete(findall(mainFig, 'Tag', 'OTBRecordingPanel'));

if isappdata(mainFig, 'OTBRecordingRefresh')
    rmappdata(mainFig, 'OTBRecordingRefresh');
end

if ~contains(char(afeSettings.name), 'HD')
    return
end

if ~isfield(afeSettings, 'OTB400Electrodes')
    error('Seleziona prima gli elettrodi HD.');
end

% Pannello sotto il messaggio di stato, nella finestra esistente.
panel = uipanel( ...
    'Parent', mainFig, ...
    'Tag', 'OTBRecordingPanel', ...
    'Units', 'normalized', ...
    'Position', [0.005 0.02 0.25 0.34], ...
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

OTB400_ChannelMap('install', mainFig, mapAx, ...
    afeSettings.channels, afeSettings.OTB400Electrodes);

% Usa la matrice numerata nel pannello appena creato.
% Nasconde i controlli laterali previsti dalla vecchia GUI HD.
st = getappdata(mainFig, 'OTB400_ChannelMapState');
set(st.panel, 'Visible', 'off');
set(st.toggle, 'Visible', 'off');

setappdata(panel, 'RecordingMapAxes', mapAx);

OTB400_ChannelMap('preview', mapAx, ...
    zeros(1, afeSettings.channels));

% Conserva il callback che individua l'elettrodo sotto il mouse.
mapMotion = get(mainFig, 'WindowButtonMotionFcn');
set(mainFig, 'WindowButtonMotionFcn', @onMotion);

% Permette di ricollegare le linee quando DataShow le ricrea.
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

        % Selezioni fissate con il clic.
        marked = false(1,afeSettings.channels);
        if isfield(state,'marked')
            marked = state.marked;
        end

        onlySelected = logical(get(filterButton,'Value'));
        
        % Aggiunge l'anteprima del canale sotto il mouse.
        active = marked;
        if state.hovered >= 1 && state.hovered <= numel(active)
            active(state.hovered) = true;
        end

        % plot crea le linee nell'ordine dei canali;
        % Children/findobj le restituisce in ordine inverso.
        traces = flipud(findobj(h.a_t0, 'Type', 'line'));

        % Evita associazioni sbagliate nelle viste con un sottoinsieme.
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

        % Numerazione fisica: IN1/1...64, IN2/1...64.
        channels = 1:numel(traces);

        labels = arrayfun(@(k) sprintf('IN%d/%d', ...
            ceil(k/64), mod(k-1,64)+1), ...
            channels, 'UniformOutput', false);
        
        set(h.a_t0, 'YTickLabel', labels);

        set(panel, 'Title', sprintf('Elettrodi HD - %d canali selezionati', nnz(marked)));
    end
end
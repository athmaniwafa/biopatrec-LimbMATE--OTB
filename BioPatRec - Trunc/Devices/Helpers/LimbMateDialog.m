function result = LimbMateDialog()
    % LIMMBATEDIALOG  Modal popup that scans for LimbMATE devices,
    % lets the user pick one, and connects to it.
    %
    % Returns a struct:
    %   result.connected - true if a device was successfully connected
    %   result.objLM     - the connected LimbMATE_BioPatRec handle
    %   result.lmName    - name of the connected device, e.g. 'LM 14'
    %   result.port      - COM port the dongle was found on, e.g. 'COM4'

    result = struct('connected', false, 'objLM', [], 'lmName', '', 'port', '');

    dlgWidth  = 380;
    dlgHeight = 260;
    scr = get(0, 'ScreenSize');
    xPos = round((scr(3) - dlgWidth) / 2);
    yPos = round((scr(4) - dlgHeight) / 2);

    hFig = figure( ...
        'Name', 'LimbMATE Devices', ...
        'NumberTitle', 'off', ...
        'MenuBar', 'none', ...
        'ToolBar', 'none', ...
        'Resize', 'off', ...
        'WindowStyle', 'modal', ...
        'Position', [xPos, yPos, dlgWidth, dlgHeight], ...
        'Color', [0.94, 0.94, 0.94]);

    hStatus = uicontrol(hFig, 'Style', 'text', ...
        'String', 'Scanning for LimbMATE devices...', ...
        'Position', [20, dlgHeight-40, dlgWidth-40, 25], ...
        'HorizontalAlignment', 'left', ...
        'BackgroundColor', get(hFig, 'Color'), ...
        'FontSize', 10);

    hList = uicontrol(hFig, 'Style', 'listbox', ...
        'String', {'(scanning...)'}, ...
        'Position', [20, 80, dlgWidth-40, dlgHeight-130], ...
        'FontSize', 11, ...
        'Callback', @onListSelect);

    hRefresh = uicontrol(hFig, 'Style', 'pushbutton', ...
        'String', 'Refresh', ...
        'Position', [20, 30, 90, 30], ...
        'Callback', @onRefresh);

    hConnect = uicontrol(hFig, 'Style', 'pushbutton', ...
        'String', 'Connect', ...
        'Position', [120, 30, 90, 30], ...
        'Enable', 'off', ...
        'Callback', @onConnect);

    hCancel = uicontrol(hFig, 'Style', 'pushbutton', ...
        'String', 'Cancel', ...
        'Position', [220, 30, 90, 30], ...
        'Callback', @onCancel);

    setappdata(hFig, 'hStatus',  hStatus);
    setappdata(hFig, 'hList',    hList);
    setappdata(hFig, 'hConnect', hConnect);
    setappdata(hFig, 'result',   result);
    setappdata(hFig, 'lmNames',  {});
    setappdata(hFig, 'portFound','');
    setappdata(hFig, 'scanning', false);

    drawnow;

    tScan = timer( ...
        'StartDelay', 0.3, ...
        'TimerFcn',   @(~,~) doScan(), ...
        'StopFcn',    @(s,~) delete(s));
    start(tScan);

    uiwait(hFig);

    if ishandle(hFig)
        result = getappdata(hFig, 'result');
        delete(hFig);
    end

    % ---------- Nested functions ----------

    function doScan()
        if ~ishandle(hFig) || ~isvalid(hFig), return; end
        if isappdata(hFig, 'scanning') && getappdata(hFig, 'scanning'), return; end
        setappdata(hFig, 'scanning', true);

        set(hStatus, 'String', 'Scanning for LimbMATE devices... (~10s, please wait)');
        set(hList,   'String', {'(scanning...)'}, 'Value', 1);
        set(hConnect, 'Enable', 'off');
        drawnow;

        try
            [lmNames, portFound] = scanForLimbMATEs();
        catch ME
            set(hStatus, 'String', sprintf('Scan failed: %s', ME.message));
            set(hList, 'String', {'(no devices)'}, 'Value', 1);
            setappdata(hFig, 'scanning', false);
            return;
        end

        if isempty(lmNames)
            set(hStatus, 'String', 'No LimbMATE devices found. Click Refresh.');
            set(hList, 'String', {'(no devices)'}, 'Value', 1);
            setappdata(hFig, 'scanning', false);
            return;
        end

        if ~iscell(lmNames), lmNames = cellstr(lmNames); end
        lmNames = lmNames(:);

        setappdata(hFig, 'lmNames',   lmNames);
        setappdata(hFig, 'portFound', portFound);
        set(hList, 'String', lmNames, 'Value', 1);
        drawnow;

        set(hConnect, 'Enable', 'on');
        set(hStatus, 'String', sprintf('Found %d device(s) on %s', ...
            numel(lmNames), char(portFound)));

        setappdata(hFig, 'scanning', false);
    end

    function onRefresh(~, ~)
        doScan();
    end

    function onListSelect(~, ~)
        if ~isempty(get(hList, 'String'))
            set(hConnect, 'Enable', 'on');
        end
    end

    function onConnect(~, ~)
        lmNames   = getappdata(hFig, 'lmNames');
        portFound = getappdata(hFig, 'portFound');

        if isempty(lmNames)
            errordlg('No device available.', 'LimbMate');
            return;
        end

        val = get(hList, 'Value');
        if val < 1 || val > numel(lmNames)
            errordlg('Select a device first.', 'LimbMate');
            return;
        end

        selLM   = lmNames{val};
        portStr = char(portFound);

        set(hStatus, 'String', sprintf('Connecting to %s...', selLM));
        set(hConnect, 'Enable', 'off');
        drawnow;

        try
            objLM = LimbMATE_BioPatRec();
            objLM.connectBTdongle(portStr);
            objLM.connectBTdevice(selLM, "2");

            result.connected = true;
            result.objLM     = objLM;
            result.lmName    = selLM;
            result.port      = portStr;    % NEW
            setappdata(hFig, 'result', result);

            set(hStatus, 'String', sprintf('Connected to %s', selLM));
            drawnow;
            pause(0.3);
            uiresume(hFig);
        catch ME
            errordlg(sprintf('Connection failed: %s', ME.message), 'LimbMate');
            set(hStatus, 'String', 'Connection failed. Try again or Refresh.');
            set(hConnect, 'Enable', 'on');
        end
    end

    function onCancel(~, ~)
        uiresume(hFig);
    end
end
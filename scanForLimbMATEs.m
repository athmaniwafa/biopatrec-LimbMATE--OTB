function [lmNames, portFound] = scanForLimbMATEs()
    % SCANFORLIMBMATES
    % Auto-detects the Bluetooth dongle on any available COM port,
    % then scans for nearby LimbMATE devices.

    lmNames   = {};
    portFound = '';

    pause(0.3);

    ports = serialportlist("available");
    if isempty(ports)
        fprintf('[scan] No COM ports available.\n');
        return;
    end
    fprintf('[scan] Available ports: %s\n', strjoin(cellstr(ports), ', '));

    lm = LimbMATE();

    for k = 1:numel(ports)
        p = string(ports(k));
        try
            lm.connectBTdongle(p);
            portFound = p;
            fprintf('[scan] Dongle found on %s\n', p);
            break;
        catch ME
            fprintf('[scan] %s: %s\n', p, ME.message);
            portFound = '';
        end
    end

    if isempty(portFound)
        fprintf('[scan] No dongle found on any port.\n');
        try delete(lm); catch, end
        pause(0.5);
        return;
    end

    try
        lm.scanDevicesStart();
        pause(3);
        lm.scanDevicesStop();
        lm.getDevicesInfo();
    catch ME
        warning('scanForLimbMATEs: BT scan failed: %s', ME.message);
        try delete(lm); catch, end
        pause(0.3);
        return;
    end

    for k = 1:numel(lm.BTdevices)
        name = string(char(lm.BTdevices(k).DeviceName));
        if startsWith(name, "LM ", "IgnoreCase", true) || ...
           startsWith(name, "LMATE", "IgnoreCase", true)
            lmNames{end+1} = char(name); %#ok<AGROW>
        end
    end
    fprintf('[scan] Found %d LM device(s).\n', numel(lmNames));

    % ----- 5. Cleanup -----
    try
        sObj = lm.serialObj;
        if ~isempty(sObj) && isvalid(sObj)
            delete(sObj);
            pause(0.3);
        end
    catch
    end
    try delete(lm); catch, end
    clear lm;
end
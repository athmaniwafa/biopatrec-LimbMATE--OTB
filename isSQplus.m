function tf = isSQplus(deviceName)
    % ISSQPLUS  Returns true if deviceName refers to the Sessantaquattro+.
    if iscell(deviceName)
        if isempty(deviceName)
            tf = false;
            return;
        end
        deviceName = deviceName{1};
    end
    tf = contains(string(deviceName), "SQ+");
end
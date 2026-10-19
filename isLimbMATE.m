function tf = isLimbMATE(deviceName)
    % ISLIMBMATE  Returns true if deviceName refers to a LimbMATE device.
    % Works whether deviceName is a char, string, or 1-element cell array.
    if iscell(deviceName)
        if isempty(deviceName)
            tf = false;
            return;
        end
        deviceName = deviceName{1};
    end
    tf = startsWith(string(deviceName), "LM ");
end

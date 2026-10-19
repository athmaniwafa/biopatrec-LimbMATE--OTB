function tf = isOTB400(deviceName)
    % ISOTB400  Returns true if deviceName refers to the OTB400.
    if iscell(deviceName)
        if isempty(deviceName)
            tf = false;
            return;
        end
        deviceName = deviceName{1};
    end
    tf = contains(string(deviceName), "OTB400");
end

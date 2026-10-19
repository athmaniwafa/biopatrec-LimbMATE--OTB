function tf = isLimbMATE(deviceName)
    % Returns true if deviceName refers to a LimbMATE device.
    if iscell(deviceName)
        if isempty(deviceName)
            tf = false;
            return;
        end
        deviceName = deviceName{1};
    end
    dn = lower(char(deviceName));
    tf = contains(dn, 'lm') || contains(dn, 'limb');
end

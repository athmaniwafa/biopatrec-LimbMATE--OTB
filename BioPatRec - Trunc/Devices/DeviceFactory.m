function adapter = DeviceFactory(deviceName, nCh, sF, handles, afeSettings)
    dn = char(deviceName);
    if iscell(dn), dn = dn{1}; end
    
    if isLimbMATE(dn)
        % Pass handles directly. The adapter will handle it safely.
        [adapter, ~, ~] = LimbMateAdapter.configure(handles);
        
    elseif isOTB400(dn)
        adapter = OTB400Adapter(afeSettings.objOT, nCh);
        
    elseif isSQplus(dn)
        adapter = SQPlusAdapter(afeSettings.objSQ, nCh);
        
    else
        adapter = LegacyAdapter(afeSettings);
    end
end
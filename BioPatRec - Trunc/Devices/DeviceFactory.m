function adapter = DeviceFactory(deviceName, nCh, sF, handles, afeSettings)
    dn = char(deviceName);
    if iscell(dn), dn = dn{1}; end
    
    % Force LM routing if the object is present in afeSettings
    if (isfield(afeSettings, 'objLM') && ~isempty(afeSettings.objLM)) || isLimbMATE(dn)
        adapter = LimbMateAdapter(afeSettings.objLM, nCh, sF);
        
    elseif isOTB400(dn)
        adapter = OTB400Adapter(afeSettings.objOT, nCh);
        
    elseif isSQplus(dn)
        adapter = SQPlusAdapter(afeSettings.objSQ, nCh);
        
    else
        adapter = LegacyAdapter(afeSettings);
    end
end
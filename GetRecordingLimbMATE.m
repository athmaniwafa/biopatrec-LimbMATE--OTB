function objLM = GetRecordingLimbMATE(afeSettings, comPort)
% Reuse the dialog connection while retaining recording-integrity support.
objLM = [];
if isfield(afeSettings,'objLM') && isa(afeSettings.objLM,'LimbMATE_BioPatRec')
    candidate = afeSettings.objLM;
    if isscalar(candidate) && isvalid(candidate) && ~isempty(candidate.serialObj) ...
            && isvalid(candidate.serialObj)
        objLM = candidate;
    end
end

if isempty(objLM)
    objLM = LimbMATE_BioPatRec();
    try
        objLM.connectBTdongle(comPort);
        name = afeSettings.name;
        if iscell(name), name = name{1}; end
        objLM.connectBTdevice(char(name), "2");
    catch ME
        objLM.closeRecording();
        rethrow(ME);
    end
end

objLM.recoveryDirectory = fullfile(pwd,'LimbMATE_Recovery');
objLM.graphical_information.enable_graph = 0;
objLM.graphical_information_session.enable_graph = 0;
end

function config = OTB400_InputPlan(selection)
% Validate explicit physical connections without opening hardware.
    models = {'EMG_USB2p_64','EMG_USB2p_128','EMG_USB2p_256'};
    multipleCounts = [0 1 3];
    model = find(strcmp(selection.Model,models),1);
    assert(~isempty(model),'OTB400:Inputs','Modello EMG-USB2+ non valido.');
    counts = selection.BipolarCounts(:)';
    validateattributes(counts,{'numeric'},{'numel',4,'integer','>=',0,'<=',16});
    types = selection.HDTypes(:)';
    assert(numel(types)==4,'OTB400:Inputs','Specificare quattro ingressi MULTIPLE.');
    active = find(~cellfun(@isempty,types));
    assert(all(active<=multipleCounts(model)),'OTB400:Inputs', ...
        'Ingresso MULTIPLE non disponibile sul modello selezionato.');
    assert(all(ismember(types(active),{'BIG','SMALL'})),'OTB400:Inputs','Tipo di griglia non valido.');
    ids = []; electrodes = struct();
    for k=1:4, ids=[ids (k-1)*16+(0:counts(k)-1)]; end %#ok<AGROW>
    for k=active
        ids=[ids 64+(k-1)*64+(0:63)]; %#ok<AGROW>
        electrodes.(sprintf('MULTIPLE_IN%d',k))=types{k};
    end
    assert(~isempty(ids),'OTB400:Inputs','Selezionare almeno un ingresso.');
    config = struct('NumChannels',numel(ids),'NumBipolar',sum(counts), ...
        'NumMatrices',numel(active),'HDInputNumbers',active,'Model',models{model}, ...
        'Type','Inputs','InputSelection',selection,'ExpectedChannels',ids, ...
        'Electrodes',electrodes);
end

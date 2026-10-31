function layout = OTB400_ChannelLayout(config)
% Map OTComm zero-based connector channel IDs to local device labels.
% IN1 occupies IDs 0:15; MULTIPLE IN1 starts at 64, IN2 at 128.
    nB = 0; nHD = 0;
    if isfield(config,'NumBipolar'), nB = config.NumBipolar; end
    if isfield(config,'NumMatrices'), nHD = config.NumMatrices; end
    ids = [0:nB-1, 64:64+64*nHD-1];
    if isfield(config,'ExpectedChannels'), ids=config.ExpectedChannels; end
    assert(numel(ids) == config.NumChannels, 'OTB400:ChannelLayout', ...
        'Channel configuration does not match bipolar/HD counts.');
    if isfield(config,'AcquiredChannels')
        acquired = double(config.AcquiredChannels(:)');
        assert(numel(acquired)==numel(ids) && all(acquired>=0) && ...
            all(acquired==fix(acquired)) && all(acquired<320) && ...
            nnz(acquired<64)==nB && numel(unique(acquired))==numel(ids), ...
            'OTB400:ChannelLayout', ...
            'OTComm channel IDs do not match configured IN1/MULTIPLE inputs.');
        ids = acquired;
    end
    if isfield(config,'ExpectedChannels')
        assert(isequal(sort(ids),sort(config.ExpectedChannels)), ...
            'OTB400:ChannelLayout','OTComm channels differ from the selected physical inputs.');
    end
    labels = cell(1,numel(ids));
    local = zeros(1,numel(ids));
    layout.GroupNames = {};
    layout.GroupColumns = {};
    for input=1:4
        columns = find(ids >= (input-1)*16 & ids < input*16);
        if isempty(columns), continue; end
        local(columns) = mod(ids(columns),16)+1;
        for c=columns, labels{c}=sprintf('B - %d',local(c)); end
        layout.GroupNames{end+1} = sprintf('Bipolari IN%d',input);
        layout.GroupColumns{end+1} = columns;
    end
    layout.HDColumns = cell(1,nHD);
    layout.HDInputNumbers = unique(floor((ids(ids>=64)-64)/64)+1);
    assert(numel(layout.HDInputNumbers)==nHD,'OTB400:ChannelLayout','Unexpected HD input count.');
    for index=1:nHD
        m=layout.HDInputNumbers(index);
        [present, columns] = ismember(64+(m-1)*64+(0:63),ids);
        assert(all(present),'OTB400:ChannelLayout','Incomplete HD input.');
        local(columns)=1:64;
        for k=1:64, labels{columns(k)}=sprintf('HD%d - %d',m,k); end
        layout.HDColumns{index} = columns;
        layout.GroupNames{end+1} = sprintf('HD%d',m);
        layout.GroupColumns{end+1} = columns;
    end
    layout.Labels = labels;
    layout.LocalNumbers = local;
    layout.BipolarColumns = find(ids<64);
end

function imagePath = OTB400_ElectrodeImagePath(sensorType)
% Resolve reference images in the current layout, then in legacy checkouts.

    sensorType = lower(char(sensorType));
    if ~ismember(sensorType, {'big','small'})
        error('OTB400:InvalidElectrodeType', 'Unknown electrode type: %s', sensorType);
    end

    projectRoot = fileparts(mfilename('fullpath'));
    filename = sprintf('OTB400_HD_%s.png', sensorType);
    candidates = { ...
        fullfile(projectRoot, 'BioPatRec - Trunc', 'Img', filename), ...
        fullfile(projectRoot, 'Img', filename)};

    imagePath = '';
    for k = 1:numel(candidates)
        if exist(candidates{k}, 'file') == 2
            imagePath = candidates{k};
            return
        end
    end
end

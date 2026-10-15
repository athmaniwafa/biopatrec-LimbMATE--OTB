function [electrodes, ok] = OTB400_SelectElectrodes(nCh)

    electrodes = struct('MULTIPLE_IN1', '', ...
                        'MULTIPLE_IN2', '');
    ok = false;

    % Determine active inputs
    if nCh == 64
        inputs = {'MULTIPLE_IN1'};
    elseif nCh == 128
        inputs = {'MULTIPLE_IN1', 'MULTIPLE_IN2'};
    else
        error('Invalid channel count. Choose 64 or 128.');
    end

    % Resolve images without depending on MATLAB's current folder.
    imgBig = OTB400_ElectrodeImagePath('BIG');
    imgSmall = OTB400_ElectrodeImagePath('SMALL');

    nInputs = numel(inputs);

    % Dialog dimensions
    dlgW = 660;
    dlgH = 100 + 225*nInputs;

    d = dialog( ...
        'Name', 'OTB400 HD - Electrode selection', ...
        'Position', [300 180 dlgW dlgH], ...
        'WindowStyle', 'modal', ...
        'Resize', 'off', ...
        'CloseRequestFcn', @onCancel);

    groups = cell(1, nInputs);

    for k = 1:nInputs

        y = dlgH - 30 - 225*k;

        % Panel for each MULTIPLE input
        p = uipanel( ...
            'Parent', d, ...
            'Title', strrep(inputs{k}, '_', ' '), ...
            'Units', 'pixels', ...
            'Position', [20 y 620 210], ...
            'FontWeight', 'bold');

        % BIG electrode image
        ax1 = axes('Parent', p, ...
            'Units', 'pixels', ...
            'Position', [25 65 250 120]);

        showElectrodeImage(ax1, imgBig, 'BIG', '8 x 8');

        % SMALL electrode image
        ax2 = axes('Parent', p, ...
            'Units', 'pixels', ...
            'Position', [345 65 250 120]);

        showElectrodeImage(ax2, imgSmall, 'SMALL', '13 x 5');

        % Exclusive selection group
        bg = uibuttongroup( ...
            'Parent', p, ...
            'Units', 'pixels', ...
            'Position', [20 10 580 43], ...
            'BorderType', 'none');

        rbBig = uicontrol( ...
            'Parent', bg, ...
            'Style', 'radiobutton', ...
            'String', 'BIG', ...
            'Position', [110 8 120 25]);

        uicontrol( ...
            'Parent', bg, ...
            'Style', 'radiobutton', ...
            'String', 'SMALL', ...
            'Position', [420 8 120 25]);

        % Default selection
        set(bg, 'SelectedObject', rbBig);

        groups{k} = bg;

    end

    % Confirm button
    uicontrol( ...
        'Parent', d, ...
        'Style', 'pushbutton', ...
        'String', 'OK', ...
        'Position', [440 15 90 32], ...
        'Callback', @onConfirm);

    % Cancel button
    uicontrol( ...
        'Parent', d, ...
        'Style', 'pushbutton', ...
        'String', 'Cancel', ...
        'Position', [540 15 90 32], ...
        'Callback', @onCancel);

    uiwait(d);

    % Retrieve selected values
    if ishandle(d)

        if isappdata(d, 'SelectedElectrodes')
            electrodes = getappdata(d, 'SelectedElectrodes');
            ok = true;
        end

        delete(d);
    end

    % Callback: Confirm selections
    function onConfirm(~, ~)

        for j = 1:nInputs

            selected = get(groups{j}, 'SelectedObject');

            electrodes.(inputs{j}) = get(selected, 'String');

        end

        setappdata(d, 'SelectedElectrodes', electrodes);
        uiresume(d);

    end

    % Callback: Cancel
    function onCancel(~, ~)
        uiresume(d);
    end

end

function showElectrodeImage(ax, imagePath, sensorType, geometry)
    if ~isempty(imagePath)
        image(ax, imread(imagePath));
        axis(ax, 'image');
    else
        % The electrode choice remains available if reference images are absent.
        text(ax, 0.5, 0.5, {sensorType, geometry, '64 elettrodi'}, ...
            'Units', 'normalized', ...
            'HorizontalAlignment', 'center', 'FontSize', 12);
    end
    axis(ax, 'off');
end

function GUI_PreviewFeatures(sigFeatures, featureNames)
% Preview selected training features, averaged over channels.
% Each column of trFeatures corresponds to a movement.

if ~isfield(sigFeatures,'trFeatures') || isempty(sigFeatures.trFeatures)
    error('No training features available.');
end

features = sigFeatures.trFeatures;
nWindows = size(features,1);
nMovements = size(features,2);
nFeatures = numel(featureNames);

values = zeros(nWindows*nMovements,nFeatures);

for f = 1:nFeatures
    name = featureNames{f};

    if ~isfield(features,name)
        error('Feature "%s" is not available.',name);
    end

    for m = 1:nMovements
        for w = 1:nWindows
            channelValues = features(w,m).(name);

            if ~isnumeric(channelValues) || ~isvector(channelValues) ...
                    || isempty(channelValues) ...
                    || any(~isfinite(channelValues(:)))
                error('Feature "%s" contains invalid values.',name);
            end

            row = (m-1)*nWindows+w;
            values(row,f) = mean(channelValues(:));
        end
    end
end

% Statistics on the original channel-averaged values.
stats = [mean(values,1); std(values,0,1); ...
         min(values,[],1); max(values,[],1)]';

fig = figure( ...
    'Name','Selected features - MATLAB', ...
    'NumberTitle','off', ...
    'Units','normalized', ...
    'Position',[0.15 0.15 0.70 0.70]);

ax = axes('Parent',fig,'Position',[0.10 0.45 0.85 0.47]);
hold(ax,'on');

offsets = 0:nFeatures-1;

for f = 1:nFeatures
    % Scale for display only; preserve original values in the table.
    scale = max(abs(values(:,f)));
    if scale == 0
        scale = 1;
    end

    % Plot movements separately to avoid connecting unrelated windows.
    for m = 1:nMovements
        rows = (m-1)*nWindows+(1:nWindows);
        plot(ax,rows,offsets(f)+0.35*values(rows,f)/scale, ...
            'b.-','MarkerSize',4);
    end
end

for m = 1:nMovements-1
    xline(ax,m*nWindows+0.5,'-k', 'LineWidth', 2);
end

set(ax,'YTick',offsets,'YTickLabel',featureNames, ...
    'TickLabelInterpreter','none');

ylim(ax,[-0.5 nFeatures-0.5]);
xlim(ax,[0.5 size(values,1)+0.5]);

movementNames = sigFeatures.mov;
if ischar(movementNames)
    movementNames = cellstr(movementNames);
end

centers = (0:nMovements-1)*nWindows + (nWindows+1)/2;

set(ax, ...
    'XTick',centers, ...
    'XTickLabel',movementNames, ...
    'TickLabelInterpreter','none');

xlabel(ax, {'Movement'; 'Each block contains its training windows'});
title(ax,{'Selected features: mean over channels', ...
          'Curves scaled for display; lines separate movements'});
grid(ax,'on');
hold(ax,'off');

headers = {'Feature','Mean','Standard deviation','Minimum','Maximum'};
nRows = size(stats,1) + 1;

panel = uipanel( ...
    'Parent',fig, ...
    'Units','normalized', ...
    'Position',[0.10 0.07 0.85 0.28], ...
    'BorderType','none');

% Larghezze relative: la somma deve essere 1.
widths = [0.12 0.22 0.22 0.22 0.22];
lefts = [0 cumsum(widths(1:end-1))];

for r = 1:nRows
    for c = 1:5
        if r == 1
            label = headers{c};
            background = [0.90 0.90 0.90];
            weight = 'bold';
        else
            if c == 1
                label = featureNames{r-1};
            else
                label = sprintf('%.4g',stats(r-1,c-1));
            end

            background = [1 1 1];
            if mod(r,2) == 1
                background = [0.95 0.95 0.95];
            end
            weight = 'normal';
        end

        annotation(panel,'textbox', ...
                    'Units','normalized', ...
                    'Position',[lefts(c), 1-r/nRows, widths(c), 1/nRows], ...
                    'String',label, ...
                    'Interpreter','none', ...
                    'HorizontalAlignment','center', ...
                    'VerticalAlignment','middle', ...
                    'FontUnits','points', ...
                    'FontSize',12, ...
                    'FontWeight',weight, ...
                    'BackgroundColor',background, ...
                    'EdgeColor','none', ...
                    'Margin',0);
    end
end

end
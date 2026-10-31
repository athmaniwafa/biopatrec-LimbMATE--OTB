function fig = SQ_OpenHeatmap(handles, adapter)
% Live amplitude map for the SQ+. One panel per matrix, shared colour scale.
L  = adapter.layout();
nG = numel(L.grids);

delete(findall(0, 'Tag', 'SQHeatFig'));
fig = figure('Tag', 'SQHeatFig', 'Name', 'SQ+ live map', 'NumberTitle', 'off', ...
             'Color', 'w', 'ToolBar', 'none', 'MenuBar', 'none');
if nG > 1
    fig.Position(3) = max(fig.Position(3), 900);   % wider window for two matrices
end

tl = tiledlayout(fig, 1, nG, 'TileSpacing', 'loose', 'Padding', 'compact');
hImg = gobjects(1, nG);
axs  = gobjects(1, nG);
for k = 1:nG
    g  = L.grids(k);
    ax = nexttile(tl);
    axs(k) = ax;
    hImg(k) = imagesc(ax, nan(g.rows, g.cols));
    set(hImg(k), 'AlphaData', ~isnan(g.map));
    axis(ax, 'image'); colormap(ax, 'jet');
    title(ax, g.title);
    set(ax, 'XTick', 1:g.cols, 'YTick', 1:g.rows, 'Box', 'on');
    % channel number in each cell (1-based, as in the software)
    for r = 1:g.rows
        for c = 1:g.cols
            if ~isnan(g.map(r,c))
                text(ax, c, r, num2str(g.map(r,c)), 'HorizontalAlignment', 'center', ...
                     'FontSize', 8, 'Color', [0.2 0.2 0.2]);
            end
        end
    end
end
cb = colorbar(axs(end));
cb.Layout.Tile = 'east';
ylabel(cb, 'RMS (mV)');

state.peak = 1e-3;
setappdata(handles.output, 'SQHeatmapUpdate', @updateMap);

    function updateMap(cData)
        if ~isgraphics(fig), return; end
        amp = sqrt(mean((cData - mean(cData,1)).^2, 1));    % RMS, DC removed
        state.peak = max(0.98*state.peak, max(amp));
        for kk = 1:nG
            gg  = L.grids(kk);
            img = nan(gg.rows, gg.cols);
            ok  = ~isnan(gg.map);
            img(ok) = amp(gg.map(ok));
            set(hImg(kk), 'CData', img);
            caxis(axs(kk), [0 state.peak]);                 % same scale on both matrices
        end
        drawnow limitrate;
    end
end
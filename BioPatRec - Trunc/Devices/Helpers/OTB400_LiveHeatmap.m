function OTB400_LiveHeatmap(action, fig)
% Live amplitude heatmap in its own window, drawn on whatever HD map is
% already installed in the recording figure (OTB400_ChannelMap state).
% Does not change the map, the acquisition or the traces.
%   OTB400_LiveHeatmap('open', fig)   - call right after the map is installed
% RecordingSession already feeds it each window through the appdata
% 'SQHeatmapUpdate' (set below) and deletes the 'SQHeatFig' window at the end.

    if ~strcmpi(action,'open'), return; end
    if ~isappdata(fig,'OTB400_ChannelMapState'), return; end

    st      = getappdata(fig,'OTB400_ChannelMapState');
    gmap    = st.map;                       % values = data column indices
    present = isfinite(gmap);
    if isfield(st,'localNumbers')
        loc = st.localNumbers;
    else
        loc = mod((1:st.nCh)-1,64)+1;
    end

    delete(findall(0,'Tag','SQHeatFig'));
    hf  = figure('Name','Live HD heatmap','NumberTitle','off', ...
        'Tag','SQHeatFig','Units','normalized','Position',[0.62 0.08 0.30 0.50]);
    hax = axes('Parent',hf);
    hImg = imagesc(hax, nan(size(gmap)));
    set(hImg,'AlphaData',present);
    set(hax,'Color',[.85 .85 .85],'XTick',[],'YTick',[]);
    axis(hax,'image');
    colormap(hax,'jet');
    cb = colorbar(hax);  ylabel(cb,'mean |x|');
    hold(hax,'on');
    for rr = 1:size(gmap,1)
        for cc = 1:size(gmap,2)
            if present(rr,cc)
                text(hax,cc,rr,num2str(loc(gmap(rr,cc))), ...
                    'HorizontalAlignment','center','FontSize',7, ...
                    'Color',[1 1 1],'HitTest','off');
            end
        end
    end
    offset=0;
    for k=1:numel(st.contactMaps)
        grid=st.contactMaps{k};
        first=grid(find(isfinite(grid),1));
        label=regexp(st.channelLabels{first},'^HD\d+','match','once');
        [rows,cols]=size(grid);
        for x=0:cols
            line(hax,[offset+x+.5 offset+x+.5],[.5 rows+.5], ...
                'Color',[.7 .7 .7],'HitTest','off');
        end
        for y=0:rows
            line(hax,[offset+.5 offset+cols+.5],[y+.5 y+.5], ...
                'Color',[.7 .7 .7],'HitTest','off');
        end
        text(hax,offset+(cols+1)/2,.2, ...
            label, ...
            'HorizontalAlignment','center','VerticalAlignment','bottom', ...
            'FontSize',8,'Clipping','off','Tag','OTBMatrixTitle');
        offset=offset+cols+1;
    end
    hold(hax,'off');
    title(hax,'');

    d = struct('hImg',hImg,'hax',hax,'gmap',gmap,'present',present,'limit',0.01);
    setappdata(hf,'heat',d);
    setappdata(fig,'SQHeatmapUpdate',@(cData) updateHeat(hf,cData));
    figure(fig);
end

function updateHeat(hf, cData)
    if ~isgraphics(hf), return; end
    d = getappdata(hf,'heat');
    v = mean(abs(double(cData)),1);
    img = nan(size(d.gmap));
    img(d.present) = v(d.gmap(d.present));
    set(d.hImg,'CData',img);
    d.limit = max(d.limit*0.97, max(img(:),[],'omitnan'));
    d.limit = max(d.limit, 1e-3);
    set(d.hax,'CLim',[0 d.limit]);
    setappdata(hf,'heat',d);
    drawnow limitrate;
end

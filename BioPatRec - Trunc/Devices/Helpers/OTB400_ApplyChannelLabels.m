function OTB400_ApplyChannelLabels(h, plotType)
% Keep device labels when legacy plotting code resets ticks.
    fig = ancestor(h.a_t0,'figure');
    if ~isappdata(fig,'OTBChannelLabels'), return; end
    labels = getappdata(fig,'OTBChannelLabels');
    columns = 1:numel(labels);
    if isappdata(h.a_t0,'OTBDisplayColumns')
        columns = getappdata(h.a_t0,'OTBDisplayColumns');
    end
    ticks = (columns-1)*5;
    if isappdata(h.a_t0,'OTBDisplayTicks'), ticks=getappdata(h.a_t0,'OTBDisplayTicks'); end
    if strcmp(plotType,'Raw Signal')
        set(h.a_t0,'YTick',ticks,'YTickLabel',labels(columns));
    elseif strcmp(plotType,'Bar Chart')
        set(h.a_t0,'XTick',1:numel(labels),'XTickLabel',labels);
    end
    if isfield(h,'a_f0') && isgraphics(h.a_f0,'axes')
        set(h.a_f0,'YTick',ticks,'YTickLabel',labels(columns));
    end
end

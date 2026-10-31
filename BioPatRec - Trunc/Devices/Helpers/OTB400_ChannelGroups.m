function groupPanel = OTB400_ChannelGroups(parent, layout, refresh)
% Checkboxes reflect acquired connector groups, never unconfigured inputs.
    fig = ancestor(parent,'figure');
    parentSize=getpixelposition(parent);
    rows=1;
    names=strrep(layout.GroupNames,'Bipolari','Bipolar');
    weights=cellfun(@numel,[{'All'},names])+3;
    widths=.96*weights/sum(weights);
    left=.02+[0 cumsum(widths(1:end-1))];
    panelHeight=min(.75,(24*(rows+1)+4)/max(1,parentSize(4)));
    groupPanel = uipanel('Parent',parent,'Units','normalized', ...
        'Position',[.02 .99-panelHeight .96 panelHeight],'BorderType','none');
    setappdata(groupPanel,'OTBGroupRows',rows);
    setappdata(fig,'OTBGroupMask',true(1,numel(layout.Labels)));
    allBox = uicontrol('Parent',groupPanel,'Style','checkbox', ...
        'Units','normalized','Position',[left(1) .5 widths(1) .5], ...
        'String','All','Value',1,'Tag','OTBGroupAll','Callback',@toggleAll);
    boxes = gobjects(1,numel(layout.GroupNames));
    for k=1:numel(boxes)
        boxes(k) = uicontrol('Parent',groupPanel,'Style','checkbox', ...
            'Units','normalized','Position',[left(k+1) .5 widths(k+1) .5], ...
            'String',names{k},'Value',1, ...
            'Tag',sprintf('OTBGroup%d',k),'Callback',@toggleGroup);
    end
    function toggleAll(src,~)
        set(boxes,'Value',get(src,'Value'));
        update();
    end
    function toggleGroup(~,~)
        values = arrayfun(@(b)logical(get(b,'Value')),boxes);
        set(allBox,'Value',all(values));
        update();
    end
    function update()
        mask = false(1,numel(layout.Labels));
        for j=1:numel(boxes)
            if get(boxes(j),'Value'), mask(layout.GroupColumns{j})=true; end
        end
        setappdata(fig,'OTBGroupMask',mask);
        refresh();
    end
end

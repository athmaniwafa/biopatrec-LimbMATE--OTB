function groupPanel = OTB400_ChannelGroups(parent, layout, refresh)
% Checkboxes reflect acquired connector groups, never unconfigured inputs.
    fig = ancestor(parent,'figure');
    parentSize=getpixelposition(parent);
    rows=ceil(numel(layout.GroupNames)/2);
    panelHeight=max(.26,min(.60,(37+18*rows)/max(1,parentSize(4))));
    groupPanel = uipanel('Parent',parent,'Units','normalized', ...
        'Position',[.02 .99-panelHeight .96 panelHeight],'Title','Mostra ingressi');
    setappdata(fig,'OTBGroupMask',true(1,numel(layout.Labels)));
    allBox = uicontrol('Parent',groupPanel,'Style','checkbox', ...
        'Units','normalized','Position',[.03 .70 .94 .26], ...
        'String','Tutto','Value',1,'Tag','OTBGroupAll','Callback',@toggleAll);
    boxes = gobjects(1,numel(layout.GroupNames));
    rows = ceil(numel(boxes)/2);
    height = .65/max(1,rows);
    for k=1:numel(boxes)
        row = floor((k-1)/2); column = mod(k-1,2);
        boxes(k) = uicontrol('Parent',groupPanel,'Style','checkbox', ...
            'Units','normalized','Position',[.03+.49*column .68-(row+1)*height .48 height], ...
            'String',layout.GroupNames{k},'Value',1, ...
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

function fig = RecordingSession_Summary(data,sF,cT,rT,nR,mov,received,varargin)
% Inspect sample counts and all recorded channels after a complete session.
% Counts exclude padding; vertical offsets affect only the displayed traces.
    expected=round(sF*(cT+rT)*nR);
    names=cellstr(string(mov(:)));
    received=received(:);
    nMov=numel(names);
    session=struct('sF',sF,'sT',(cT+rT)*nR,'cT',cT,'rT',rT,'nR',nR, ...
        'nM',nMov,'nCh',size(data,2),'mov',{names},'tdata',data, ...
        'receivedSamples',received,'expectedSamples',expected);
    if ~isempty(varargin) && isstruct(varargin{1})
        session=varargin{1};
        varargin(1)=[];
    end
    assert(numel(received)==nMov && all(received>=0) && ...
        all(received<=size(data,1)), 'BioPatRec:SummaryCounts', ...
        'Sample counts must match the movements and available data.');
    fig=figure('Name','Recording session summary','NumberTitle','off', ...
        'Tag','RecordingSessionSummary','Position',[100 80 1400 900],varargin{:});
    nCh=size(data,2);
    colours=get(groot,'defaultAxesColorOrder');
    colours=colours(mod(0:nCh-1,size(colours,1))+1,:);
    labels=cellstr(compose('Channel %d',1:nCh));
    layout=[];
    if isfield(session,'OTB400Config')
        layout=OTB400_ChannelLayout(session.OTB400Config);
        labels=layout.Labels;
    end
    if isfield(session,'ChannelLabels'), labels=session.ChannelLabels; end
    if isfield(session,'ChannelColors'), colours=session.ChannelColors; end
    details=gobjects(0); detailMovements=[];
    counts=[names,num2cell(received),repmat({expected},nMov,1), ...
        num2cell(received-expected),num2cell(received/sF)];
    countTable=uitable(fig,'Units','normalized','Position',[.02 .79 .96 .19], ...
        'Tag','SessionSampleCounts','Data',counts, ...
        'ColumnName',{'Movement','Received / channel','Expected / channel', ...
        'Difference','Recorded seconds'},'RowName',[]);
    setappdata(fig,'RecordingSession',session);
    uicontrol(fig,'Style','pushbutton','Units','normalized', ...
        'Position',[.80 .739 .18 .04],'String','Salva sessione', ...
        'Tag','SaveSession','Callback',@(~,~)RecordingSession_SaveSummary(fig));
    sidebar=uipanel(fig,'Units','normalized','Position',[.01 .01 .23 .72], ...
        'Title','Channels (Ctrl/Shift to select)');
    selector=uicontrol(sidebar,'Style','listbox','Units','normalized', ...
        'Position',[.03 .59 .94 .38],'String',labels,'Min',0,'Max',max(2,nCh), ...
        'Value',1:nCh,'Tag','SummaryChannels','Callback',@refreshSelection);
    groupBoxes=gobjects(0);
    if ~isempty(layout)
        set(selector,'Position',[.03 .59 .94 .32]);
        groupNames=[{'All'},strrep(layout.GroupNames,'Bipolari','Bipolar')];
        weights=cellfun(@numel,groupNames)+3;
        widths=.94*weights/sum(weights);
        left=.03+[0 cumsum(widths(1:end-1))];
        for group=1:numel(groupNames)
            groupBoxes(group)=uicontrol(sidebar,'Style','checkbox','Units','normalized', ...
                'Position',[left(group) .925 widths(group) .045], ...
                'String',groupNames{group},'Value',1, ...
                'Tag',sprintf('SummaryGroup%d',group), ...
                'Callback',@(src,~)toggleGroup(src,group));
        end
    end
    uicontrol(sidebar,'Style','pushbutton','Units','normalized', ...
        'Position',[.03 .53 .45 .045],'String','All','Tag','SummaryAll', ...
        'Callback',@(~,~)selectChannels(1:nCh));
    uicontrol(sidebar,'Style','pushbutton','Units','normalized', ...
        'Position',[.52 .53 .45 .045],'String','None','Tag','SummaryNone', ...
        'Callback',@(~,~)selectChannels([]));
    panel=uipanel(fig,'Units','normalized','Position',[.25 .01 .74 .72], ...
        'BorderType','none');
    columns=ceil(sqrt(nMov)); rows=ceil(nMov/columns);
    axesList=gobjects(nMov,1);
    for k=1:nMov
        column=mod(k-1,columns); row=floor((k-1)/columns);
        tile=uipanel(panel,'Units','normalized', ...
            'Position',[column/columns 1-(row+1)/rows 1/columns 1/rows]);
        ax=axes('Parent',tile,'Units','normalized','Position',[.13 .25 .82 .56]);
        axesList(k)=ax;
        drawMovement(ax,k);
        uicontrol(tile,'Style','pushbutton','Units','normalized', ...
            'Position',[.58 .01 .39 .1],'String','Open separately', ...
            'Tag',sprintf('OpenMovement%d',k),'Callback',@(~,~)openMovement(k));
    end
    setappdata(fig,'MovementAxes',axesList);
    if ~isempty(layout) && ~isempty(layout.HDColumns) && isfield(session,'OTB400Electrodes')
        mapAx=axes('Parent',sidebar,'Units','normalized','Position',[.03 .03 .94 .44]);
        setappdata(mapAx,'OTB400_UniformBackground',true);
        electrodes=session.OTB400Electrodes;
        electrodes.HDColumns=layout.HDColumns;
        electrodes.HDInputNumbers=layout.HDInputNumbers;
        electrodes.ChannelLabels=layout.Labels;
        electrodes.LocalNumbers=layout.LocalNumbers;
        OTB400_ChannelMap('install',fig,mapAx,nCh,electrodes);
        state=getappdata(fig,'OTB400_ChannelMapState');
        set(state.panel,'Visible','off'); set(state.toggle,'Visible','off');
        OTB400_ChannelMap('preview',mapAx,zeros(1,nCh));
        setappdata(fig,'OTB400_ChannelSelectionChanged',@selectMask);
    else
        set(selector,'Position',[.03 .12 .94 .85]);
        set(findobj(sidebar,'Tag','SummaryAll'),'Position',[.03 .03 .45 .06]);
        set(findobj(sidebar,'Tag','SummaryNone'),'Position',[.52 .03 .45 .06]);
    end
    set(fig,'SizeChangedFcn',@resizeTable);
    resizeTable();
    refreshSelection();
    function toggleGroup(src,group)
        mask=false(1,nCh); mask(get(selector,'Value'))=true;
        if group==1
            mask(:)=logical(get(src,'Value'));
        else
            mask(layout.GroupColumns{group-1})=logical(get(src,'Value'));
        end
        selectMask(mask);
    end
    function selectMask(mask)
        selectChannels(find(mask));
    end
    function selectChannels(channels)
        set(selector,'Value',channels);
        refreshSelection();
    end
    function refreshSelection(~,~)
        selected=get(selector,'Value');
        mask=false(1,nCh); mask(selected)=true;
        if ~isempty(groupBoxes)
            set(groupBoxes(1),'Value',all(mask));
            for group=1:numel(layout.GroupColumns)
                set(groupBoxes(group+1),'Value',all(mask(layout.GroupColumns{group})));
            end
        end
        if isappdata(fig,'OTB400_ChannelMapState')
            OTB400_ChannelMap('setmask',fig,mask);
        end
        for j=1:nMov, drawMovement(axesList(j),j); end
        for j=1:numel(details)
            if isgraphics(details(j)), drawMovement(details(j),detailMovements(j)); end
        end
    end
    function resizeTable(~,~)
        pixels=getpixelposition(countTable);
        available=max(5,floor(pixels(3))-20);
        widths=floor(available*[.28 .20 .20 .14 .18]);
        widths(end)=available-sum(widths(1:end-1));
        set(countTable,'ColumnWidth',num2cell(widths));
        % Classic uitable uses HTML cells to center movement names.
        rows=get(countTable,'Data');
        for j=1:nMov
            label=strrep(strrep(strrep(names{j},'&','&amp;'),'<','&lt;'),'>','&gt;');
            rows{j,1}=sprintf(['<html><table width="%d"><tr><td align="center">' ...
                '%s</td></tr></table></html>'],max(1,widths(1)-12),label);
        end
        set(countTable,'Data',rows);
    end
    function drawMovement(ax,k)
        cla(ax);
        selected=get(selector,'Value');
        block=double(data(1:received(k),:,k));
        t=(0:received(k)-1)'/sF;
        spacing=1;
        if ~isempty(block)
            block=block-mean(block,1);
            spacing=max(max(block,[],1)-min(block,[],1));
            if ~isfinite(spacing) || spacing<=0, spacing=1; end
        end
        spacing=spacing*1.2;
        for index=1:numel(selected)
            ch=selected(index);
            line('Parent',ax,'XData',t,'YData',block(:,ch)+(index-1)*spacing, ...
                'Color',colours(ch,:),'Tag','SummaryTrace','UserData',ch);
        end
        RecordingSession_PhaseLines(ax,cT,rT,nR);
        ticks=unique(round(linspace(1,numel(selected),min(numel(selected),12))));
        set(ax,'YTick',(ticks-1)*spacing,'YTickLabel',labels(selected(ticks)));
        ylim(ax,[-spacing max(1,numel(selected))*spacing]);
        title(ax,names{k},'Interpreter','none');
        xlabel(ax,'Time (s)'); ylabel(ax,'Channel'); grid(ax,'on');
        xlim(ax,[0 max((cT+rT)*nR,received(k)/sF)]);
        axtoolbar(ax,{'zoomin','zoomout','pan','restoreview'});
    end
    function openMovement(k)
        detail=figure('Name',names{k},'NumberTitle','off', ...
            'Tag','RecordingMovementDetail');
        ax=axes('Parent',detail);
        details(end+1)=ax; detailMovements(end+1)=k;
        drawMovement(ax,k);
    end
end

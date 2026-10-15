function varargout = OTB400_ChannelMap(action, varargin)
% OTB400_ChannelMap - Mappe HD interattive per GUI_Recordings_Image (GUIDE).
%
% API:
%   OTB400_ChannelMap('install', figureHandle, axesHandle, nCh, electrodes)
%   OTB400_ChannelMap('preview', axesHandle, windowData)
%   img = OTB400_ChannelMap('features', figureHandle, windowData, Fs, featureId)
%   OTB400_ChannelMap('render', axesHandle, img [, colourLimits])
%   mask = OTB400_ChannelMap('mask', figureHandle)
%   OTB400_ChannelMap('setmask', figureHandle, mask)
%   OTB400_ChannelMap('numbers', figureHandle)  % labels already managed
%   sizeRC = OTB400_ChannelMap('size', figureHandle)
%   OTB400_ChannelMap('remove', figureHandle)
%
% All acquisition channels are kept unchanged; only visualisation is masked.
% BIG: 8x8 geometry; SMALL: 13x5 with one vacant position.
% The contact order is copied from user-provided numbered electrode photos.
% IN2 uses local physical labels 1..64, but BioPatRec channels 65..128.
% Verify OTComm channel ordering experimentally before interpreting data.
%
% BioPatRec source compatibility: this is a standalone helper; do not
% remove or change any original BioPatRec copyright notice in other files.

    switch lower(char(action))
        case 'install'
            cmInstall(varargin{:});
        case 'preview'
            cmPreview(varargin{:});
        case 'features'
            varargout{1} = cmFeatures(varargin{:});
        case 'render'
            cmRender(varargin{:});
        case 'mask'
            st=cmGet(varargin{1});
            varargout{1}=st.enabled;
        case 'setmask'
            cmSetMask(varargin{:});
        case 'size'
            st=cmGet(varargin{1});
            varargout{1}=size(st.map);
        case 'numbers'
            % Plot numbers are created and updated by cmRender.
        case 'remove'
            cmRemove(varargin{:});
        otherwise
            error('OTB400_ChannelMap: invalid action %s', char(action));
    end
end

function [channelMap, contactMaps] = cmPhysicalMap(nCh, electrodes)
    % Map values are global BioPatRec channel indices (1..nCh).
    % NaN means there is no electrode at that row/column.
    mapBIG = [ ...
        64 63 62 61 60 59 58 57; ...
        56 55 54 53 52 51 50 49; ...
        48 47 46 45 44 43 42 41; ...
        40 39 38 37 36 35 34 33; ...
        32 31 30 29 28 27 26 25; ...
        24 23 22 21 20 19 18 17; ...
        16 15 14 13 12 11 10  9; ...
         8  7  6  5  4  3  2  1];

    % Exactly as in the user's SMALL image: 13 rows, up to 5 contacts.
    % The bottom row has no fifth electrode.
    mapSMALL = [ ...
        61 60 59 58 57; ...
        62 63 64 56 55; ...
        50 51 52 53 54; ...
        49 41 42 43 44; ...
        40 48 47 46 45; ...
        39 38 37 36 35; ...
        34 33 27 26 25; ...
        32 31 30 29 28; ...
        24 23 22 21 20; ...
        10  9 17 18 19; ...
        11 12 13 14 15; ...
         5  6  7  8 16; ...
         4  3  2  1 NaN];

    if ~ismember(nCh,[64 128])
        error('OTB400_ChannelMap: only 64 or 128 channels are supported.');
    end
    nMatrices=nCh/64;
    contactMaps=cell(1,nMatrices);
    for k=1:nMatrices
        fld=sprintf('MULTIPLE_IN%d',k);
        if ~isfield(electrodes,fld)
            error('OTB400_ChannelMap: missing electrode type for %s.',fld);
        end
        switch upper(strtrim(char(electrodes.(fld))))
            case 'BIG'
                local=mapBIG;
            case 'SMALL'
                local=mapSMALL;
            otherwise
                error('OTB400_ChannelMap: unknown type for %s.',fld);
        end
        present=isfinite(local);
        local(present)=local(present)+64*(k-1);
        contactMaps{k}=local;
    end

    maxRows=max(cellfun(@(m)size(m,1),contactMaps));
    for k=1:nMatrices
        m=contactMaps{k};
        pad=nan(maxRows,size(m,2));
        pad(1:size(m,1),:)=m;
        if k==1
            channelMap=pad;
        else
            % One empty column visually separates the matrices.
            channelMap=[channelMap nan(maxRows,1) pad];
        end
    end
end

function cmInstall(fig, ax, nCh, electrodes)
    if ~ishghandle(fig) || ~ishghandle(ax)
        error('OTB400_ChannelMap: invalid figure or axes handle.');
    end
    if ~isstruct(electrodes) || ~isfield(electrodes,'MULTIPLE_IN1') || ...
            (nCh == 128 && ~isfield(electrodes,'MULTIPLE_IN2'))
        error('OTB400_ChannelMap: missing MULTIPLE IN electrode choice.');
    end
    [channelMap, contactMaps] = cmPhysicalMap(nCh, electrodes);
    cmRemove(fig);

    figPos = getpixelposition(fig);
    axesPos = getpixelposition(ax, true);
    % Fits the available blank area left of the original HD plot.
    width = min(300, max(190, axesPos(1)-15));
    x = max(5, axesPos(1)-width-6);
    height = min(figPos(4)-65, 150+floor(nCh/64)*245);
    height = max(230,height);
    y = max(5, min(axesPos(2),figPos(4)-height-44));
    btnY = min(figPos(4)-31, y+height+5);

    toggle = uicontrol('Parent',fig,'Style','togglebutton','Units','pixels', ...
        'Position',[x btnY width 27],'String','Mostra elettrodi HD', ...
        'Value',0,'Callback',@(src,evt)cmToggle(fig,src));
    panel = uipanel('Parent',fig,'Units','pixels','Position',[x y width height], ...
        'Title','Elettrodi HD / Canali visibili','Visible','off');

    st = struct();
    st.map = channelMap;
    st.contactMaps = contactMaps;
    st.nCh = nCh;
    st.fig = fig;
    st.axes = ax;
    st.enabled = true(1,nCh);
    st.selected = 1;
    st.hovered = 0;
    st.toggle = toggle;
    st.panel = panel;
    st.hotspots = cell(1,nCh);
    st.plotImage = [];
    st.plotHighlight = [];
    st.plotLabels = [];
    st.rawImage = [];
    st.previousMotion = get(fig,'WindowButtonMotionFcn');
    st.previousDown = get(fig,'WindowButtonDownFcn');

    st.info = uicontrol('Parent',panel,'Style','text','Units','pixels', ...
        'Position',[8 58 width-16 30], ...
        'String','IN1: elettrodo 1 = canale 1', ...
        'HorizontalAlignment','left');
    st.checkbox = uicontrol('Parent',panel,'Style','checkbox', ...
        'Units','pixels','Position',[8 37 width-16 23], ...
        'String','Visualizza canale 1','Value',1, ...
        'Callback',@(src,evt)cmCheckbox(fig,src));
    uicontrol('Parent',panel,'Style','pushbutton','Units','pixels', ...
        'Position',[8 7 (width-25)/2 26], 'String','Tutti ON', ...
        'Callback',@(src,evt)cmAll(fig,true));
    uicontrol('Parent',panel,'Style','pushbutton','Units','pixels', ...
        'Position',[17+(width-25)/2 7 (width-25)/2 26], ...
        'String','Tutti OFF', 'Callback',@(src,evt)cmAll(fig,false));

    nMatrices = nCh/64;
    areaBottom = 94;
    usableHeight = height-areaBottom-8;
    areaH = usableHeight/nMatrices;
    imagesFolder = fullfile(fileparts(mfilename('fullpath')),'Img');

    % Reference pixel locations for the numbered images provided by user.
    % BIG image: 376x401; SMALL image: 299x418.
    xBig   = [32 61 91 120 149 178 207 236];
    yBig   = [46 90 134 178 222 266 310 353];
    xSmall = [41 62 83 104 125];
    ySmall = [36 65 94 123 152 181 210 239 269 298 327 356 385];
    for k=1:nMatrices
        if k==1
            sensorType = upper(strtrim(char(electrodes.MULTIPLE_IN1)));
        else
            sensorType = upper(strtrim(char(electrodes.MULTIPLE_IN2)));
        end
        if ~ismember(sensorType,{'BIG','SMALL'})
            error('OTB400_ChannelMap: unknown electrode type %s.',sensorType);
        end
        if strcmp(sensorType,'BIG')
            xContacts=xBig; yContacts=yBig;
            referenceWidth=376; referenceHeight=401;
        else
            xContacts=xSmall; yContacts=ySmall;
            referenceWidth=299; referenceHeight=418;
        end
        localMap=contactMaps{k};
        subY = areaBottom + (nMatrices-k)*areaH;
        uicontrol('Parent',panel,'Style','text','Units','pixels', ...
            'Position',[8 subY+areaH-21 width-16 19], ...
            'String',sprintf('MULTIPLE IN%d - %s',k,sensorType), ...
            'FontWeight','bold');

        imgAxes = axes('Parent',panel,'Units','pixels', ...
            'Position',[10 subY+2 width-20 max(70,areaH-26)], ...
            'XTick',[],'YTick',[],'Visible','off');
        imgFile = fullfile(imagesFolder,sprintf('OTB400_HD_%s.png',lower(sensorType)));
        if exist(imgFile,'file')
            source = imread(imgFile);
        else
            % Fallback retains clickable contact cells without a PNG.
            source = uint8(245*ones(referenceHeight,referenceWidth,3));
            warning('OTB400_ChannelMap: missing image %s',imgFile);
        end
        imgH = size(source,1);
        imgW = size(source,2);
        image('Parent',imgAxes,'CData',source, ...
              'XData',[1 imgW], 'YData',[1 imgH], 'HitTest','off');
        set(imgAxes,'XLim',[1 imgW],'YLim',[1 imgH],'YDir','reverse');
        axis(imgAxes,'image');
        axis(imgAxes,'off');
        hold(imgAxes,'on');

        for r=1:size(localMap,1)
            for c=1:size(localMap,2)
                globalCh=localMap(r,c);
                if ~isfinite(globalCh), continue; end
                px = xContacts(c)*imgW/referenceWidth;
                py = yContacts(r)*imgH/referenceHeight;
                if strcmp(sensorType,'BIG')
                    dx = 12*imgW/referenceWidth;
                    dy = 11*imgH/referenceHeight;
                else
                    dx = 10*imgW/referenceWidth;
                    dy = 9*imgH/referenceHeight;
                end
                patchHandle = patch('Parent',imgAxes, ...
                    'XData',px+[-dx dx dx -dx], ...
                    'YData',py+[-dy -dy dy dy], ...
                    'FaceColor','none','EdgeColor','none', ...
                    'HitTest','on','PickableParts','all', ...
                    'ButtonDownFcn',@(src,evt)cmClicked(fig,globalCh));
                setappdata(patchHandle,'OTB400_GlobalChannel',globalCh);
                st.hotspots{globalCh}=patchHandle;
                % The image already contains the local numbering.
                % Fallback numbering when the file is absent:
                if ~exist(imgFile,'file')
                    text(imgAxes,px,py,num2str(mod(globalCh-1,64)+1), ...
                        'HorizontalAlignment','center', ...
                        'VerticalAlignment','middle','FontSize',7, ...
                        'HitTest','off');
                end
            end
        end
    end
    setappdata(fig,'OTB400_ChannelMapState',st);
    set(fig,'WindowButtonMotionFcn',@(src,evt)cmMotion(src,evt));
    cmRefresh(fig);
end

function cmToggle(fig,button)
    st = cmGet(fig);
    show = logical(get(button,'Value'));
    if show
        set(st.panel,'Visible','on');
        set(button,'String','Nascondi elettrodi HD');
    else
        set(st.panel,'Visible','off');
        set(button,'String','Mostra elettrodi HD');
        cmHover(fig,0);
    end
end

function st = cmGet(fig)
    if ~isappdata(fig,'OTB400_ChannelMapState')
        error('OTB400_ChannelMap: first call install.');
    end
    st = getappdata(fig,'OTB400_ChannelMapState');
end

function cmMotion(fig,evt)
    if ~isappdata(fig,'OTB400_ChannelMapState'), return; end
    st=cmGet(fig);
    hover=0;
    hit=hittest(fig);
    if ishghandle(hit) && isappdata(hit,'OTB400_GlobalChannel')
        hover=getappdata(hit,'OTB400_GlobalChannel');
    elseif ishghandle(hit) && (~isempty(st.plotImage)) && ...
            (isequal(hit,st.plotImage) || isequal(hit,st.axes))
        hover=cmPlotPointChannel(st);
    end
    if hover~=st.hovered, cmHover(fig,hover); end

    % Keep existing GUIDE motion callback, if provided as a function handle.
    old=st.previousMotion;
    if isa(old,'function_handle')
        old(fig,evt);
    elseif iscell(old) && ~isempty(old)
        feval(old{1},fig,evt,old{2:end});
    end
end

function ch=cmPlotPointChannel(st)
    ch=0;
    pt=get(st.axes,'CurrentPoint');
    c=round(pt(1,1)); r=round(pt(1,2));
    if r>=1 && r<=size(st.map,1) && c>=1 && c<=size(st.map,2)
        candidate=st.map(r,c);
        if isfinite(candidate) && candidate>=1 && candidate<=st.nCh
            ch=candidate;
        end
    end
end

function cmHover(fig,ch)
    st=cmGet(fig);
    
    old=st.hovered;
    st.hovered=ch;
    setappdata(fig,'OTB400_ChannelMapState',st);
    cmPaintHotspot(fig,old);
    cmPaintHotspot(fig,ch);
    cmHighlight(fig);
end

function cmClicked(fig,ch)
    if ~isappdata(fig,'OTB400_ChannelMapState')
        return
    end

    st = cmGet(fig);
    recordingMap = isappdata(fig,'OTBRecordingRefresh');

    if recordingMap
        if ~isfield(st,'marked')
            st.marked = false(1,st.nCh);
        end

        % Ogni clic inverte solo la selezione di questo canale.
        st.marked(ch) = ~st.marked(ch);
    else
        st.enabled(ch) = ~st.enabled(ch);
    end

    st.selected = ch;
    st.hovered = ch;
    setappdata(fig,'OTB400_ChannelMapState',st);
    cmRefresh(fig);

    if recordingMap
        refreshTrace = getappdata(fig,'OTBRecordingRefresh');
        refreshTrace();
    end
end

function cmCheckbox(fig,src)
    st=cmGet(fig);
    st.enabled(st.selected)=logical(get(src,'Value'));
    setappdata(fig,'OTB400_ChannelMapState',st);
    cmRefresh(fig);
end

function cmSetMask(fig,mask)
    st=cmGet(fig);
    if ~islogical(mask) || numel(mask)~=st.nCh
        error('OTB400_ChannelMap: visibility mask must be logical 1 x nCh.');
    end
    st.enabled=reshape(mask,1,[]);
    setappdata(fig,'OTB400_ChannelMapState',st);
    cmRefresh(fig);
end

function cmAll(fig,value)
    st=cmGet(fig);
    st.enabled(:)=logical(value);
    setappdata(fig,'OTB400_ChannelMapState',st);
    cmRefresh(fig);
end

function cmRefresh(fig)
    st=cmGet(fig);
    for ch=1:st.nCh, cmPaintHotspot(fig,ch); end
    k=floor((st.selected-1)/64)+1;
    local=mod(st.selected-1,64)+1;
    set(st.info,'String',sprintf('IN%d: elettrodo %d = canale BioPatRec %d', ...
        k,local,st.selected));
    set(st.checkbox,'String',sprintf('Visualizza IN%d / %d',k,local), ...
        'Value',double(st.enabled(st.selected)));
    cmPaint(fig);
end

function cmPaintHotspot(fig,ch)
    st=cmGet(fig);
    if ch<1 || ch>st.nCh,return;end
    h=st.hotspots{ch};
    if ~ishghandle(h),return;end
    if ch==st.hovered
        set(h,'FaceColor',[1 0.85 0.15],'FaceAlpha',0.5, ...
            'EdgeColor',[0.85 0.55 0],'LineWidth',2);
    elseif ~st.enabled(ch)
        set(h,'FaceColor',[.5 .5 .5],'FaceAlpha',0.55, ...
            'EdgeColor',[.25 .25 .25],'LineWidth',1);
    elseif ch==st.selected
        set(h,'FaceColor',[.35 .8 1],'FaceAlpha',0.35, ...
            'EdgeColor',[0 .45 .85],'LineWidth',2);
    else
        set(h,'FaceColor','none','EdgeColor','none');
    end
end

function cmPreview(ax,twData)
    fig=ancestor(ax,'figure');
    st=cmGet(fig);
    if size(twData,2)<st.nCh
        error('OTB400_ChannelMap: data have %d columns; expected %d.', ...
            size(twData,2),st.nCh);
    end
    values=mean(abs(double(twData(:,1:st.nCh))),1);
    raw=nan(size(st.map));
    present=isfinite(st.map);
    raw(present)=values(st.map(present));
    cmRender(ax,raw);
end

function raw=cmFeatures(fig,twData,Fs,featureId)
    st=cmGet(fig);
    if size(twData,2)<st.nCh
        error('OTB400_ChannelMap: data have %d columns; expected %d.', ...
            size(twData,2),st.nCh);
    end
    values=zeros(1,st.nCh);
    for ch=1:st.nCh
        result=GetSigFeatures(twData(:,ch),Fs,{featureId});
        values(ch)=result.(featureId);
    end
    raw=nan(size(st.map));
    present=isfinite(st.map);
    raw(present)=values(st.map(present));
end

function cmRender(ax,raw,varargin)
    fig=ancestor(ax,'figure');
    st=cmGet(fig);
    if ~isequal(size(raw),size(st.map))
        error('OTB400_ChannelMap: image size does not match channel map.');
    end
    st.rawImage=raw;
    setappdata(fig,'OTB400_ChannelMapState',st);
    cmPaint(fig);
    if nargin>=3 && numel(varargin{1})==2 && all(isfinite(varargin{1})) && ...
            varargin{1}(2)>varargin{1}(1)
        caxis(ax,varargin{1});
    end
    drawnow limitrate;
end

function cmPaint(fig)
    st=cmGet(fig);
    if isempty(st.rawImage),return;end
    present=isfinite(st.map);
    alpha=zeros(size(st.map));
    alpha(present)=double(st.enabled(st.map(present)));
    img=double(st.rawImage);
    img(alpha==0)=NaN;
    if isempty(st.plotImage) || ~ishghandle(st.plotImage)
        cla(st.axes);
        st.plotImage=imagesc(st.axes,img);
        set(st.plotImage,'ButtonDownFcn',@(src,evt)cmClickedPlot(fig), ...
            'HitTest','on','PickableParts','all');
        set(st.axes,'YDir','reverse','Color',[.86 .86 .86], ...
            'XLim',[.5 size(st.map,2)+.5], ...
            'YLim',[.5 size(st.map,1)+.5], ...
            'XTick',[],'YTick',[]);
        hold(st.axes,'on');
        st.plotHighlight=rectangle('Parent',st.axes, ...
            'Position',[.5 .5 1 1], 'EdgeColor',[1 .7 0], ...
            'LineWidth',3,'Visible','off','HitTest','off');
        st.plotLabels=cell(size(st.map));
        for rr=1:size(st.map,1)
            for cc=1:size(st.map,2)
                if ~isfinite(st.map(rr,cc)), continue; end
                globalCh = st.map(rr,cc);
                local = mod(globalCh-1,64)+1;
                
                label = text(st.axes,cc,rr,num2str(local), ...
                    'HorizontalAlignment','center', ...
                    'VerticalAlignment','middle', ...
                    'FontSize',7, ...
                    'Color',[0 0 0], ...
                    'HitTest','on', ...
                    'PickableParts','all', ...
                    'ButtonDownFcn',@(src,evt)cmClicked(fig,globalCh));
                
                st.plotLabels{rr,cc} = label;
                setappdata(label,'OTB400_GlobalChannel',globalCh);
            end
        end
        if st.nCh==128
            gapX=size(st.contactMaps{1},2)+1;
            line(st.axes,[gapX gapX],[.5 size(st.map,1)+.5], ...
                'Color',[1 1 1],'LineWidth',3,'HitTest','off');
            title(st.axes,'IN1 (sinistra)  /  IN2 (destra)');
        else
            title(st.axes,'MULTIPLE IN1');
        end
        hold(st.axes,'off');
    else
        set(st.plotImage,'CData',img);
    end
    set(st.plotImage,'AlphaData',alpha);
    setappdata(fig,'OTB400_ChannelMapState',st);
    cmHighlight(fig);
end

function cmClickedPlot(fig)
    st=cmGet(fig);
    ch=cmPlotPointChannel(st);
    if ch>0,cmClicked(fig,ch);end
end

function cmHighlight(fig)
    st = cmGet(fig);

    if isempty(st.plotHighlight) || ~isgraphics(st.plotHighlight)
        return
    end

    % I bordi non devono intercettare i clic.
    set(st.plotHighlight,'PickableParts','none');

    if isappdata(fig,'OTBRecordingRefresh')
        marked = false(1,st.nCh);
        if isfield(st,'marked')
            marked = st.marked;
        end

        % Posizioni dei canali fissati.
        cells = false(size(st.map));
        valid = isfinite(st.map);
        cells(valid) = marked(st.map(valid));
        [rr,cc] = find(cells);

        % Un unico oggetto disegna tutti i quadrati fissi.
        outline = findobj(st.axes, ...
            'Type','line','Tag','OTBPinnedOutlines');

        if isempty(outline)
            outline = line( ...
                'Parent',st.axes, ...
                'Tag','OTBPinnedOutlines', ...
                'XData',NaN,'YData',NaN, ...
                'Color',[1 .7 0], ...
                'LineWidth',2.5, ...
                'HitTest','off', ...
                'PickableParts','none');
        end

        xx = [cc-.5 cc+.5 cc+.5 cc-.5 cc-.5 NaN(size(cc))].';
        yy = [rr-.5 rr-.5 rr+.5 rr+.5 rr-.5 NaN(size(rr))].';

        set(outline,'XData',xx(:),'YData',yy(:));

        % Il quadrato mobile segue soltanto il mouse.
        ch = st.hovered;
    else
        ch = st.hovered;
        if ch == 0
            ch = st.selected;
        end
    end

    if ch < 1 || ch > st.nCh
        set(st.plotHighlight,'Visible','off');
        return
    end

    [r,c] = find(st.map == ch,1);

    if isempty(r)
        set(st.plotHighlight,'Visible','off');
        return
    end

    set(st.plotHighlight, ...
        'Position',[c-.5 r-.5 1 1], ...
        'Visible','on');
end


function cmRemove(fig)
    if ~isscalar(fig) || ~isgraphics(fig,'figure') || ~isappdata(fig,'OTB400_ChannelMapState')
        return;
    end
    st=getappdata(fig,'OTB400_ChannelMapState');
    set(fig,'WindowButtonMotionFcn',st.previousMotion);
    if ishghandle(st.panel),delete(st.panel);end
    if ishghandle(st.toggle),delete(st.toggle);end
    % Leave previously acquired plot data; subsequent GUI drawing may replace it.
    rmappdata(fig,'OTB400_ChannelMapState');
end

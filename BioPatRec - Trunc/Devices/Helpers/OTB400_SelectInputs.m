function [selection,ok] = OTB400_SelectInputs(deviceName) %#ok<INUSD>
    selection=[]; ok=false;
    d=dialog('Name','OTB400 - Input configuration','Position',[250 170 650 520], ...
        'WindowStyle','modal','CloseRequestFcn',@cancel);
    uicontrol(d,'Style','text','Position',[20 472 180 22],'String','Hardware model (automatic):');
    models={'EMG_USB2p_64','EMG_USB2p_128','EMG_USB2p_256'};
    model=uicontrol(d,'Style','text','Position',[210 470 280 26], ...
        'String',models{1},'Tag','OTBInputModel');
    uicontrol(d,'Style','text','Position',[20 431 610 26], ...
        'String','Select connected inputs. IN: bipolar channels (1-16). MULTIPLE: HD grid (64).');
    checks=gobjects(1,8); controls=gobjects(1,8);
    for k=1:4
        y=391-(k-1)*43;
        checks(k)=uicontrol(d,'Style','checkbox','Position',[25 y 145 26], ...
            'String',sprintf('IN%d - bipolar',k),'Value',0,'Callback',@updateEnabled, ...
            'Tag',sprintf('OTBInputIN%d',k));
        controls(k)=uicontrol(d,'Style','edit','Position',[180 y 70 26],'String','8');
        checks(k+4)=uicontrol(d,'Style','checkbox','Position',[300 y 160 26], ...
            'String',sprintf('MULTIPLE IN%d',k),'Value',0,'Callback',@updateEnabled, ...
            'Tag',sprintf('OTBInputMultiple%d',k));
        controls(k+4)=uicontrol(d,'Style','popupmenu','Position',[470 y 150 26], ...
            'String',{'BIG (8x8)','SMALL (13x5)'},'Value',1);
    end
    % MULTIPLE IN4 is not supported by the installed OTComm library.
    set(checks(8),'Enable','off');
    set(checks(1),'Value',1);
    uicontrol(d,'Style','pushbutton','Position',[390 45 110 34], ...
        'String','Cancel','Callback',@cancel,'Tag','OTBInputCancel');
    uicontrol(d,'Style','pushbutton','Position',[510 45 110 34], ...
        'String','Confirm','Callback',@confirm,'Tag','OTBInputConfirm');
    updateEnabled();
    try
        uiwait(d);
    catch ME
        deleteDialog(d);
        rethrow(ME);
    end
    deleteDialog(d);
    function updateEnabled(~,~)
        % Select the smallest model supporting the selected physical ports.
        active=find(arrayfun(@(h)get(h,'Value'),checks(5:7)));
        modelIndex=1;
        if ~isempty(active)
            if max(active)==1, modelIndex=2; else, modelIndex=3; end
        end
        set(model,'String',models{modelIndex});
        for j=1:8
            if get(checks(j),'Value'), set(controls(j),'Enable','on');
            else, set(controls(j),'Enable','off'); end
        end
    end
    function confirm(~,~)
        updateEnabled();
        s=struct('Model',get(model,'String'), ...
            'BipolarCounts',zeros(1,4),'HDTypes',{{'','','',''}});
        for j=1:4
            if get(checks(j),'Value'), s.BipolarCounts(j)=str2double(get(controls(j),'String')); end
            if get(checks(j+4),'Value')
                types={'BIG','SMALL'}; s.HDTypes{j}=types{get(controls(j+4),'Value')};
            end
        end
        try, OTB400_InputPlan(s);
        catch ME, errordlg(ME.message,'OTB inputs','modal'); return; end
        selection=s; ok=true;
        deleteDialog(d); % Deleting the dialog also releases uiwait.
        drawnow;
    end
    function cancel(~,~)
        selection=[]; ok=false;
        deleteDialog(d);
    end
end
function deleteDialog(d)
    if isgraphics(d), delete(d); end
end

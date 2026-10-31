function [selection,ok] = OTB400_SelectInputs(deviceName)
    selection=[]; ok=false;
    d=dialog('Name','OTB400 - Collegamento elettrodi','Position',[250 170 650 520], ...
        'WindowStyle','modal','CloseRequestFcn',@cancel);
    uicontrol(d,'Style','text','Position',[20 472 180 22],'String','Modello hardware:');
    models={'EMG_USB2p_64','EMG_USB2p_128','EMG_USB2p_256'};
    model=uicontrol(d,'Style','popupmenu','Position',[210 470 280 26], ...
        'String',models,'Value',2,'Callback',@updateModel,'Tag','OTBInputModel');
    uicontrol(d,'Style','text','Position',[20 431 610 26], ...
        'String','Spunta gli ingressi collegati. IN: numero bipolari (1-16). MULTIPLE: griglia HD (64).');
    checks=gobjects(1,8); controls=gobjects(1,8);
    for k=1:4
        y=391-(k-1)*43;
        checks(k)=uicontrol(d,'Style','checkbox','Position',[25 y 145 26], ...
            'String',sprintf('IN%d - bipolari',k),'Value',0,'Callback',@updateEnabled, ...
            'Tag',sprintf('OTBInputIN%d',k));
        controls(k)=uicontrol(d,'Style','edit','Position',[180 y 70 26],'String','8');
        checks(k+4)=uicontrol(d,'Style','checkbox','Position',[300 y 160 26], ...
            'String',sprintf('MULTIPLE IN%d',k),'Value',0,'Callback',@updateEnabled, ...
            'Tag',sprintf('OTBInputMultiple%d',k));
        controls(k+4)=uicontrol(d,'Style','popupmenu','Position',[470 y 150 26], ...
            'String',{'BIG (8x8)','SMALL (13x5)'},'Value',1);
    end
    if strcmp(deviceName,'OTB400_bipolar')
        set(checks(1),'Value',1);
    elseif strcmp(deviceName,'OTB400_HD')
        set(checks(5),'Value',1);
    else
        set(checks([1 5]),'Value',1);
    end
    uicontrol(d,'Style','text','Position',[25 120 600 74], ...
        'String',['Il modello deve corrispondere al dispositivo. ' ...
        'EMG-USB2+ 64: nessun MULTIPLE; 128: MULTIPLE IN1; 256: MULTIPLE IN1-3. ' ...
        'MULTIPLE IN4 non disponibile nella libreria OTComm installata.']);
    uicontrol(d,'Style','pushbutton','Position',[390 45 110 34], ...
        'String','Annulla','Callback',@cancel,'Tag','OTBInputCancel');
    uicontrol(d,'Style','pushbutton','Position',[510 45 110 34], ...
        'String','Conferma','Callback',@confirm,'Tag','OTBInputConfirm');
    updateModel();
    try
        uiwait(d);
    catch ME
        deleteDialog(d);
        rethrow(ME);
    end
    deleteDialog(d);
    function updateModel(~,~)
        available=[0 1 3]; n=available(get(model,'Value'));
        for j=1:4
            if j<=n, set(checks(j+4),'Enable','on');
            else, set(checks(j+4),'Value',0,'Enable','off'); end
        end
        updateEnabled();
    end
    function updateEnabled(~,~)
        for j=1:8
            if get(checks(j),'Value'), set(controls(j),'Enable','on');
            else, set(controls(j),'Enable','off'); end
        end
    end
    function confirm(~,~)
        s=struct('Model',models{get(model,'Value')}, ...
            'BipolarCounts',zeros(1,4),'HDTypes',{{'','','',''}});
        for j=1:4
            if get(checks(j),'Value'), s.BipolarCounts(j)=str2double(get(controls(j),'String')); end
            if get(checks(j+4),'Value')
                types={'BIG','SMALL'}; s.HDTypes{j}=types{get(controls(j+4),'Value')};
            end
        end
        try, OTB400_InputPlan(s);
        catch ME, errordlg(ME.message,'Ingressi OTB','modal'); return; end
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

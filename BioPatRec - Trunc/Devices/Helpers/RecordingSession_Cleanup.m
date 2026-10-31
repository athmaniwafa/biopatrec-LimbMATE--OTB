function cleanup = RecordingSession_Cleanup(kind,target)
% Scope guards for recording UI and hardware, including exceptions.
    switch kind
        case 'ui'
            assert(isgraphics(target,'figure'),'BioPatRec:RecordingClosed', ...
                'La finestra di registrazione e stata chiusa.');
            if isappdata(target,'RecordingInProgress') && getappdata(target,'RecordingInProgress')
                error('BioPatRec:AlreadyRecording','Una registrazione e gia in corso.');
            end
            buttons=findall(target,'Tag','pb_Start');
            enabled=get(buttons,'Enable');
            setappdata(target,'RecordingInProgress',true);
            setappdata(target,'RecordingStopRequested',false);
            % Reset offline axis controls on every acquisition, including reruns.
            axisControls={'txt_it','txt_ft','et_it','et_ft','txt_if','txt_ff','et_if','et_ff'};
            for control=axisControls
                set(findall(target,'Tag',control{1}),'Visible','off');
            end
            set(buttons,'Enable','off');
            set(findall(target,'Tag','pb_StopSession'),'Enable','on');
            cleanup=onCleanup(@()releaseUI(target,buttons,enabled));
        case 'device'
            cleanup=onCleanup(@()stopDevice(target));
        otherwise
            error('BioPatRec:Cleanup','Unknown recording guard.');
    end
end
function releaseUI(fig,buttons,enabled)
    if ~isgraphics(fig), return; end
    setappdata(fig,'RecordingInProgress',false);
    set(findall(fig,'Tag','pb_StopSession'),'Enable','off');
    if getappdata(fig,'DisconnectAfterRecording')
        setappdata(fig,'DisconnectAfterRecording',false);
        GUI_Recordings('pb_disconnect_Callback',fig,[],guidata(fig));
    end
    if isscalar(buttons) && isgraphics(buttons)
        if isappdata(fig,'SessionResumeState')
            set(buttons,'Enable','on');
        elseif isappdata(fig,'FastRecordingMode') && ~getappdata(fig,'FastRecordingMode')
            set(buttons,'Enable','off');
        else
            set(buttons,'Enable',enabled);
        end
    end
    if getappdata(fig,'CloseAfterRecording'), delete(fig); end
end
function stopDevice(adapter)
    try, adapter.stop();
    catch ME, warning('BioPatRec:StopFailed','%s',ME.message); end
end

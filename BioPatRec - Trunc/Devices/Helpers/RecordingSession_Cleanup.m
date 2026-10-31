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
            set(buttons,'Enable','off');
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
    if isscalar(buttons) && isgraphics(buttons), set(buttons,'Enable',enabled); end
end
function stopDevice(adapter)
    try, adapter.stop();
    catch ME, warning('BioPatRec:StopFailed','%s',ME.message); end
end

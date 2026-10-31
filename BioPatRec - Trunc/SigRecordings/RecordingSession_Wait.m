function RecordingSession_Wait(fig,seconds)
% Service UI callbacks and interrupt timed phases promptly.
started = tic;
while true
    drawnow;
    if ~isgraphics(fig) || getappdata(fig,'RecordingStopRequested')
        error('BioPatRec:RecordingCancelled','Registrazione arrestata.');
    end
    remaining = seconds-toc(started);
    if remaining <= 0, return; end
    pause(min(0.05,remaining));
end
end

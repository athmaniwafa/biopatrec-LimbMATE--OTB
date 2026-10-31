function RecordingSession_PhaseLines(ax,cT,rT,nR)
% Mark contraction/rest transitions consistently in session review plots.
    delete(findobj(ax,'Tag','RestStart'));
    delete(findobj(ax,'Tag','ContractionStart'));
    if cT<=0 || rT<=0, return; end
    for rep=1:nR
        xline(ax,(rep-1)*(cT+rT)+cT,'--','Color',[.8 .25 .15], ...
            'LineWidth',1.1,'Tag','RestStart');
        if rep<nR
            xline(ax,rep*(cT+rT),':','Color',[.2 .2 .2], ...
                'LineWidth',1.1,'Tag','ContractionStart');
        end
    end
end

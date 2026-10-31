function [data,t,duration] = RecordingSession_PhaseData(allData,sF,cT,rT)
% Return the current phase for display without altering recorded samples.
    contractionSamples=round(cT*sF);
    restSamples=round(rT*sF);
    cycleSamples=contractionSamples+restSamples;
    lastSample=size(allData,1)-1;
    cycleStart=floor(lastSample/cycleSamples)*cycleSamples;
    if lastSample-cycleStart < contractionSamples
        phaseStart=cycleStart;
        duration=cT;
    else
        phaseStart=cycleStart+contractionSamples;
        duration=rT;
    end
    data=allData(phaseStart+1:end,:);
    t=(0:size(data,1)-1)'/sF;
end

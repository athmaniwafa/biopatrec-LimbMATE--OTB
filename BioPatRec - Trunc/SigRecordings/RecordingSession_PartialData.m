function partialSession = RecordingSession_PartialData(completed,current,index,sF,cT,rT,nR,mov,device)
% Preserve raw samples without padding an unfinished movement to full length.
partialSession.partial = true;
partialSession.sF = sF;
partialSession.cT = cT;
partialSession.rT = rT;
partialSession.nR = nR;
partialSession.plannedMovements = mov;
partialSession.dev = device;
partialSession.date = fix(clock);
partialSession.completedData = completed(:,:,1:index-1);
partialSession.currentMovement = index;
partialSession.currentData = current;
partialSession.currentDuration = size(current,1)/sF;
end

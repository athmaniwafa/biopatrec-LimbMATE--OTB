% ---------------------------- Copyright Notice ---------------------------
% This file is part of BioPatRec ?? which is open and free software under 
% the GNU Lesser General Public License (LGPL). See the file "LICENSE" for 
% the full license governing this code and copyrights.
%
% BioPatRec was initially developed by Max J. Ortiz C. at Integrum AB and 
% Chalmers University of Technology. All authors??? contributions must be kept
% acknowledged below in the section "Updates % Contributors". 
%
% Would you like to contribute to science and sum efforts to improve 
% amputees??? quality of life? Join this project! or, send your comments to:
% maxo@chalmers.se.
%
% The entire copyright notice must be kept in this or any source file 
% linked to BioPatRec. This will ensure communication with all authors and
% acknowledge contributions here and in the project web page (optional).
%
% -------------------------- Function Description -------------------------
% This function adds semi-artificial Artifacts into the realtime data stream.
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2016-04-07 / Julian Maier  / Creation
% 20xx-xx-xx / Author  / Comment on update

function tempdata = AddArtifactRealtime(tempdata, timeLength)

    global patRec
    
    lDebug = true;
    nW = patRec.sF * patRec.tW;
    posTW = size(tempdata,1)/nW;
    numTW = floor(posTW);
    numArtW = timeLength/patRec.tW;
    lengthArtSig = numArtW * nW;

    if mod(numTW,numArtW)==1 || ~isfield(patRec.addArtifact,'sigArtifact')
        % Initialize input params
        sF = patRec.sF;
        sigArtifact = zeros(lengthArtSig,numel(patRec.nCh));
        selTypes   = patRec.addArtifact.selTypes;
        artDB      = patRec.addArtifact.data(selTypes);
        timeGap    = patRec.addArtifact.timeGap(1);
        nMaxCh     = patRec.addArtifact.nMaxCh;
        scaleMax   = patRec.addArtifact.scaleMax;
        
        % Find longest artefact to make sure that it is not cutted.
        maxLengthArt = zeros(numel(artDB),1);
        for i = 1:numel(artDB)
            maxLengthArt(i) = max(cellfun('length',artDB{i}))+1;
        end
        maxLengthArt = max(maxLengthArt);
        tEnd = lengthArtSig - maxLengthArt;
        
        % Create new sigArtifact
        numArt = round(lengthArtSig / (timeGap * sF));
        posArt = sort(randi(tEnd,numArt,1));
        numCh = randi(nMaxCh,numArt,1);
        
        for i = 1:numArt
            % Choose artifact
            typeArt = randi(numel(artDB));
            currArt = cell2mat(artDB{typeArt}(randi(numel(artDB{typeArt}))));
            % Choose channel
            currCh = randperm(numel(patRec.nCh),numCh(i));
            % Insert artifact
            l = length(currArt);
            % Scale artifact
            scaleVec = rand(1,numel(currCh)) * randi([1,scaleMax]); %.* (median(abs(tempdata(:,currCh))));
            currArt = currArt * scaleVec;
            % Add artifact
            sigArtifact(posArt(i):posArt(i)+l-1,currCh) = currArt;
        end
        % Save current artifact signal in patRec
        patRec.addArtifact.sigArtifact = sigArtifact;   
        
        if lDebug
            % Plot artifact signal
            if isempty(findall(0,'type','figure','name','Artifical disturbance signal'))
                s1 = figure('name','Artifical disturbance signal','color',[1 1 1]);
            end
            s1 = findall(0,'type','figure','name','Artifical disturbance signal');
            distCh = max(max(sigArtifact)) * 1.2;
            figure(s1)
            hold off
            for i = 1:numel(patRec.nCh)
                plot([1:lengthArtSig]/sF,sigArtifact(:,i)+distCh*(i-1)*ones(lengthArtSig,1));
                hold on
            end
            title('Artifical disturbance signal')
            set(gca,'YTick',distCh*(patRec.nCh-1),...
                'yTickLabel',strtrim(cellstr(num2str(patRec.nCh'))'));
            xlabel('time [s]')
            ylabel('Channel')
            yLimits = get(gca,'YLim');
            hLine = line([0,0],yLimits,'color','r','linewidth', 2);
        end

    else
        
        % Load artifact signal
        sigArtifact = patRec.addArtifact.sigArtifact;
        
    end

    % Add artifact signal to tempdata
    startAddingArt = floor((numTW-1)/numArtW)*nW*numArtW+1;
    endAddingArt = mod(numTW,numArtW)*nW;
    if endAddingArt == 0, endAddingArt = numArtW*nW; end
    tempdata(startAddingArt:end,:) = tempdata(startAddingArt:end,:) ...
        + sigArtifact(1:endAddingArt,:);
    
    % Plot currPos
    if lDebug
        h = get(gca,'Children');
        currPos = endAddingArt/patRec.sF;
        set(h(1),'XData',[currPos,currPos])
    end
end
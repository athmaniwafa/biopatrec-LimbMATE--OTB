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
% This function adds semi-artificial Artifacts into trimmed trData.
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2016-04-07 / Julian Maier  / Creation
% 20xx-xx-xx / Author  / Comment on update

function sigTreated = AddArtifactOffline(sigTreated)

% Initialization
lDebug = false;
trData = sigTreated.trData;
sF = sigTreated.sF;
selTypes   = sigTreated.addArtifact.selTypes;
artDB      = sigTreated.addArtifact.data;
             artDB(cellfun(@isempty,artDB))=[]; % clean empty colums
artDB       = artDB(selTypes);
timeGap    = sigTreated.addArtifact.timeGap;
nMaxCh     = sigTreated.addArtifact.nMaxCh;
scaleMax   = sigTreated.addArtifact.scaleMax;
sigArtifact = zeros(size(trData));
[nSample,~,nMov] = size(trData);

% Quasi random numbers
load(['SigTreatment' filesep 'Motion Filters' filesep 'databases' filesep 'randGen.mat'])
rng(randGen{1});

% Copy raw data in addArtifact struct
sigTreated.addArtifact.trData = sigTreated.trData;

% Find longest artifact
maxLengthArt = zeros(numel(artDB),1);
for i = 1:numel(artDB)
    maxLengthArt(i) = max(cellfun('length',artDB{i}))+1;
end
maxLengthArt = max(maxLengthArt);

% Number of artifacts per set
tStart = [1,0.4*nSample+1,0.6*nSample+1];
tEnd = [0.4,0.6,1]*nSample - maxLengthArt;
numArt = ceil((tEnd-tStart)./(timeGap * sF));

% Loop over Movements
for iMov = 1:nMov
    % Determine time points and channels
    posArt = cell(1,3);
    for iSet = 1:3
        posArt{iSet} = sort(randi([tStart(iSet),tEnd(iSet)],numArt(iSet),1));
    end
    posArt = cell2mat(posArt');
    numArtTot = numel(posArt);
    numCh = randi(nMaxCh,numArtTot,1);
    
    % Create new sigArtifact
    for i = 1:numArtTot
        % Choose artifact
        typeArt = randi(numel(artDB));
        currArt = cell2mat(artDB{typeArt}(randi(numel(artDB{typeArt}))));
        % Choose channel
        currCh = randperm(numel(sigTreated.nCh),numCh(i));
        % Insert artifact
        l = length(currArt);
        % Scale artifact
        scaleVec = rand(1,numel(currCh)) * randi([1,scaleMax]) .* (median(abs(trData(:,currCh))));
        currArt = currArt * scaleVec;
        % Add artifact
        sigArtifact(posArt(i):posArt(i)+l-1,currCh,iMov) = currArt;
    end
end

% Save current artifact signal in sigTreated
sigTreated.addArtifact.sigArtifact = sigArtifact;

% Add artifacts to signal
sigTreated.trData = sigTreated.trData + sigArtifact;

% Plot artifact signal
if lDebug
    figure('color',[1 1 1],'name','Artifact signal in first movement')
    hold off
    for i = 1:numel(sigTreated.nCh)
        plot([1:nSample]/sF,sigArtifact(:,i,1)+scaleMax*(i-1)*ones(nSample,1));
        hold on
    end
    title('Artifical disturbance signal')
    set(gca,'YTick',scaleMax*([1:numel(sigTreated.nCh)]-1),...
        'yTickLabel',strtrim(cellstr(num2str(sigTreated.nCh'))'));
    xlabel('time [s]')
    xlim([0 nSample/sF])
    ylabel('Channel')
    
    figure('color',[1 1 1],'name','EMG signal plus artifacts')
    hold off
    for i = 1:numel(sigTreated.nCh)
        plot([1:nSample]/sF,sigTreated.trData(:,i,1)+scaleMax*(i-1)*ones(nSample,1));
        hold on
    end
    title('EMG signal plus artifacts')
    set(gca,'YTick',scaleMax*([1:numel(sigTreated.nCh)]-1),...
        'yTickLabel',strtrim(cellstr(num2str(sigTreated.nCh'))'));
    xlabel('time [s]')
    xlim([0 nSample/sF])
    ylabel('Channel')
end

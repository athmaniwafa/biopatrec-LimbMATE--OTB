function addArtifact = ChoiceArtifact(struct)
addArtifact = [];
% Params
maxChInput = 	 numel(struct.nCh);
inputPrompt =   {'Mean time gap [s]',...
    ['Max. number of channels per artifact (' char(8804) ' ' num2str(maxChInput) ')'],...
    'Max amplitude (Realtime: [mV], Offline: Times MAV of EMG)'};
defaultans =    {'2',num2str(maxChInput),'5'};
paramsArtifact = inputdlg(inputPrompt,'Artifact Insertation',1,defaultans);
if isempty(paramsArtifact)
    return;
end

% Load Artifact Data
[fileArtifact,pathArtifact] = uigetfile('*_artDB.mat','Select the Artifact Data file');
if fileArtifact == 0,
    load('.\SigTreatment\Motion Filters\databases\default_artDB.mat');
    disp('Using default artifact DB!')
else
    load([pathArtifact fileArtifact]);
end
% Select artifact types
strTypes = artDB.typeNames;
lEmpty = false(numel(strTypes),1);
for i = 1:numel(strTypes)
    lEmpty(i) = isempty(artDB.data{i});
end
strTypes(lEmpty)=[];
[selTypes,ok] = listdlg('PromptString','Select artifact type:','SelectionMode','multi',...
    'ListSize',[160 80],'ListString',strTypes);
if ~ok,
    return;
end

% Save addArtifact struct
addArtifact.data = artDB.data;
addArtifact.typeNames = artDB.typeNames;
addArtifact.selTypes = selTypes;
addArtifact.timeGap = str2double(strsplit(paramsArtifact{1},{' ',','}));
addArtifact.timeGap(addArtifact.timeGap == 0) = Inf;
addArtifact.nMaxCh = str2double(paramsArtifact{2});
addArtifact.scaleMax = str2double(paramsArtifact{3});
    
end
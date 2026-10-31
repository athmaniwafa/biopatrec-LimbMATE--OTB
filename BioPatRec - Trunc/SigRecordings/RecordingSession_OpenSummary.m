function fig = RecordingSession_OpenSummary(filename,varargin)
% Open a saved recording in the same viewer used after acquisition.
    fig=[];
    if nargin<1
        [file,folder]=uigetfile({'*.mat','Recording sessions (*.mat)'}, ...
            'Visualize session data',fullfile(pwd,'*.mat'));
        if isequal(file,0) || isequal(folder,0), return; end
        filename=fullfile(folder,file);
    end
    variables=whos('-file',filename);
    if ismember('recSession',{variables.name})
        stored=load(filename,'recSession');
        session=stored.recSession;
    elseif ismember('ss',{variables.name})
        stored=load(filename,'ss');
        session=Compatibility_recSession(stored.ss);
    else
        error('BioPatRec:InvalidSession','The selected file does not contain a recording session (recSession).');
    end
    required={'tdata','sF','cT','rT','nR','mov'};
    assert(isstruct(session) && isscalar(session) && all(isfield(session,required)), ...
        'BioPatRec:InvalidSession','The recording session is missing data or timing parameters.');
    validateattributes(session.tdata,{'numeric'},{'real','nonempty'},mfilename,'tdata');
    validateattributes(session.sF,{'numeric'},{'scalar','finite','positive'},mfilename,'sF');
    validateattributes(session.cT,{'numeric'},{'scalar','finite','nonnegative'},mfilename,'cT');
    validateattributes(session.rT,{'numeric'},{'scalar','finite','nonnegative'},mfilename,'rT');
    validateattributes(session.nR,{'numeric'},{'scalar','finite','positive','integer'},mfilename,'nR');
    if ischar(session.mov), movements=cellstr(session.mov);
    else, movements=cellstr(string(session.mov(:))); end
    nMov=size(session.tdata,3);
    assert(ndims(session.tdata)<=3 && numel(movements)==nMov && session.cT+session.rT>0, ...
        'BioPatRec:InvalidSession','Movement names or timing parameters do not match the recording.');
    hasCounters=isfield(session,'receivedSamples');
    if hasCounters
        received=session.receivedSamples;
        validateattributes(received,{'numeric'}, ...
            {'vector','numel',nMov,'integer','nonnegative','<=',size(session.tdata,1)});
    else
        % Historical files lack acquisition counters; count stored rows only.
        received=repmat(size(session.tdata,1),1,nMov);
    end
    fig=RecordingSession_Summary(session.tdata,session.sF,session.cT,session.rT, ...
        session.nR,movements,received,session,varargin{:});
    setappdata(fig,'LastSavedFile',filename);
    set(findobj(fig,'Tag','SaveSession'),'Enable','off');
    [~,name,extension]=fileparts(filename);
    set(fig,'Name',['Recording session summary - ' name extension]);
    if ~hasCounters
        table=findobj(fig,'Tag','SessionSampleCounts');
        columns=get(table,'ColumnName'); columns{2}='Stored / channel';
        set(table,'ColumnName',columns,'TooltipString', ...
            'This file has no acquisition counters. Counts refer to stored sample rows.');
    end
end

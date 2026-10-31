function saved = RecordingSession_SaveSummary(fig,filename)
% Save the original session data and metadata, independent of acquisition UI.
    saved=false;
    if isappdata(fig,'LastSavedFile'), return; end
    if nargin<2
        [file,folder]=uiputfile({'*.mat','MAT-files (*.mat)'}, ...
            'Save as','Untitled.mat');
        if isequal(file,0) || isequal(folder,0), return; end
        filename=fullfile(folder,file);
    end
    recSession=getappdata(fig,'RecordingSession');
    save(filename,'recSession');
    setappdata(fig,'LastSavedFile',filename);
    set(findobj(fig,'Tag','SaveSession'),'Enable','off');
    saved=true;
end

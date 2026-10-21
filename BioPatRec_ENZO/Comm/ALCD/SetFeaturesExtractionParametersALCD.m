function error = SetFeaturesExtractionParametersALCD(handles, tWs, oWs, FeaturesEnables)
    
    error = 1;

    obj = handles.obj;
    if strcmp(obj.Status, 'closed')
        setMessage(handles,'Connection error'); 
        return
    end
    
    if(obj.BytesAvailable)
        fread(obj,obj.BytesAvailable,'char');
    end
    
    nFeatures = sum(FeaturesEnables(:));
    fwrite(obj,'f','char');
    replay = char(fread(obj,1,'char'));
    if ~strcmp(replay,'f')
        setMessage(handles,'Error Setting Features extraction parameters'); 
        fclose(obj);
        return
    end
    
    fwrite(obj,tWs,'float32');
    fwrite(obj,oWs,'float32');
    fwrite(obj,nFeatures,'char');
    for i = 1:size(FeaturesEnables,2)
        fwrite(obj,FeaturesEnables(i),'char');
    end
    
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'f')
        setMessage(handles,'Features extraction parameters set');
    else
        setMessage(handles,'Error Setting Features extraction parameters');
        fclose(obj);
        return
    end
    
    error = 0;

end

function setMessage(handles, message)
    if ishandle(handles) && isfield(handles.t_msg)
        set(handles.t_msg,'String',message);
    end
end

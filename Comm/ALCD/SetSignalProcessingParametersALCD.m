function error = SetSignalProcessingParametersALCD(handles, alcdParams)

    error = 1;
    
    obj = handles.obj;
    if strcmp(obj.Status, 'closed')
        setMessage('Connection error\n');
        return
    end
    
    if obj.BytesAvailable
        fread(obj,obj.BytesAvailable,'char');
    end
    
    % Set sample rate
    fwrite(obj,'r');
    replay = fread(obj,1,'char');
    if ~strcmp(char(replay),'r')
        setMessage('Error setting sample rate.');
        fclose(obj);
        return
    end
    fwrite(obj,handles.sF,'uint32');
    replay = fread(obj,1,'char');
    if ~strcmp(char(replay),'r') 
        setMessage('Error setting sample rate.');
        fclose(obj);
        return
    end
    
    % Set extraction parameters
    tmpHandle.obj = obj;
    if isfield(alcdParams,'featuresEnables')
        featuresEnables = alcdParams.featuresEnables;
    else
        featuresEnables = [1,1,1,1,0];
    end
    if SetFeaturesExtractionParametersALCD(tmpHandle,alcdParams.wLength,alcdParams.wOverlap,featuresEnables)
        setMessage('Error setting Feature Extraction parameters.');
        fclose(obj);
        return
    end
    
    % Set SWT processing
    fwrite(obj,'d');
    replay = fread(obj,1,'char');
    if ~strcmp(char(replay),'d')
        setMessage('Error setting SWT processing.');
        fclose(obj);
        return
    end
    fwrite(obj,alcdParams.swtType-1,'uint8');   % 1-indexed value
    replay = fread(obj,1,'char');
    if ~strcmp(char(replay),'d')
        setMessage('Error setting SWT processing.');
        fclose(obj);
        return
    end
    
    % Set DSP processing
    fwrite(obj,'H');
    replay = fread(obj,1,'char');
    if ~strcmp(char(replay),'H')
        setMessage('Error setting DSP processing.'); 
        fclose(obj);
        return
    end
    fwrite(obj,alcdParams.dspEnable,'uint8');
    replay = fread(obj,1,'char');
    if ~strcmp(char(replay),'H')
        setMessage('Error setting DSP processing.');
        fclose(obj);
        return
    end
    
    % Set lead-off handling
    if isfield(alcdParams,'loffEnable')
        fwrite(obj,'I');
        replay = fread(obj,1,'char');
        if ~strcmp(char(replay),'I') 
            setMessage('Error setting Lead-Off detection.');
            fclose(obj); 
            return
        end
        fwrite(obj,alcdParams.loffEnable,'uint8');
        replay = fread(obj,1,'char');
        if ~strcmp(char(replay),'I')
            setMessage(handles, 'Error setting Lead-Off detection.');
            fclose(obj);
            return
        end
    end
    
    error = 0;
end

function setMessage(handles, message)
    if isfield(handles,'t_msg')
        set(handles.t_msg,'String',message);
    end
    fprintf([message,'\n']);
end

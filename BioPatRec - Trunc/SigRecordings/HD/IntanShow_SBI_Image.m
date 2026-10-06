function iData = IntanShow_SBI_Image( handlesX )
%INTANSHOW_SBI_IMAGE Summary of this function goes here
%   Detailed explanation goes here
 % Global variable
    global handles;
    global allData;
    global timeStamps;

    % Variable to be sent globally
    handles     = handlesX;
    allData     = [];
    timeStamps  = [];
    
    % Init variables
    %ampPP   = str2double(get(handles.et_ampPP,'String'));
    sF      = str2double(get(handles.et_sF,'String'));
    sT      = str2double(get(handles.et_sT,'String'));
    tW      = str2double(get(handles.et_tw,'String'));
    allCh   = str2double(get(handles.lb_ch, 'String'));
    sCh     = get(handles.lb_ch,'Value');
    nCh     = size(sCh,2);
    ampPP   = 65535;
    
    r      = str2double(get(handles.et_rows,'String'));
    c      = str2double(get(handles.et_columns,'String'));
    allF   = get(handles.pm_features,'String');
    fID    = char(allF(get(handles.pm_features,'Value'))); 
        
    handles.imageRows       = r;
    handles.imageColumns    = c;
    handles.fID             = fID;
    handles.sF              = sF;
 
    % Setting for data timw window
    tWs = sF*tW;
    
    %sTw= tW * sF;
   
    %%Init WIicom
    obj.io=instrfind('Status','open');
    if isempty(obj.io)
        obj = tcpip('192.168.100.10',65100,'NetworkRole','client');
        obj.InputBufferSize = tWs*2*nCh;
        fopen(obj);
    else
        %obj = instrfind('Status','open');
    end
    %fclose(obj);
    
    %obj.InputBufferSize = tWs*2*nCh;
    %fopen(obj);
    
   
    
    % Read available data and discard it
    if obj.BytesAvailable > 1
        fread(obj,obj.BytesAvailable,'uint16');    % Read the samples        
    end    
    disp(obj);
    vCh = allCh(get(handles.lb_ch,'Value'))

    % Setup the selected channels
    fwrite(obj,'C','char');
    fwrite(obj,nCh,'uint8');
    for i = 1 : nCh    
      fwrite(obj,vCh(i),'uint8');
    end     
    replay = char(fread(obj,1,'char'));
    if ~strcmp(replay,'O')
        set(handles.t_msg,'String','Error setting the vector of channels'); 
        fclose(obj);        
        return
    else    
        set(handles.t_msg,'String','Channel vector set'); 
    end    
    
    % Set up frequency in the microcontroller    
    fwrite(obj,'F','char');
%    rSF = sF * nCh;
%    fwrite(obj,rSF/100,'uint8');
%    fwrite(obj,rSF,'uint16');    % Sampling frequency considering all
%    channels
    fwrite(obj,sF,'uint16');    
    replay = char(fread(obj,1,'char'));
    if ~strcmp(replay,'O')
        set(handles.t_msg,'String','Error setting the frequency'); 
        fclose(obj);        
        return
    else    
        set(handles.t_msg,'String','Frequency set'); 
    end
    % Send sampling time
    fwrite(obj,sT,'uint8');
    replay = char(fread(obj,1,'char'));
    if ~strcmp(replay,'O')
        set(handles.t_msg,'String','Error setting sampling time'); 
        fclose(obj);        
        return
    else    
        set(handles.t_msg,'String','Sampling time set'); 
    end
    
    % Start the aquisition    
    allData = zeros(nCh,sT*sF);
    cData = zeros(nCh,tW*sF);
    printFlag = 1;
    sTw = tW*sF;
    
    
    fwrite(obj,'S','char');
    tic;
    
    % Run through all samples. Samples per channel are considered since all
    % channels samples are recieved at once in the code below
    for i = 1:sT*sF
        
        % Find the right sequence of characters
        if fread(obj,1,'uint8') == 83
                value16 = fread(obj,nCh,'uint16');    % Read the samples        
%            if fread(obj,1) == 69        
                centValue = value16 - 16384;       % Center the data
                cData(:,printFlag) = centValue;
                allData(:,i) = centValue;
                printFlag = printFlag +1;
        end
    end
                
    %tempData = event.Data;
    %allData = [allData; tempData];
    %timeStamps = [timeStamps; event.TimeStamps];

                % Compute for all the data
                c = 1;
                for i = 1 : handles.imageRows
                    for j = 1 : handles.imageColumns
                        if c <= nCh
                            feature = GetSigFeatures(allData(:,c), handles.sF, {handles.fID});
                            iData(i,j) = feature.(handles.fID);
                            c = c+1;
                        else
                            break;
                        end

                    end

                end
                imagesc(iData);
                drawnow;
                set(handles.t_msg,'String','Done')
                fclose(obj);
                %printFlag = printFlag +1;
        end
               
            % Compute for all data    
   

    %end
    
    
    %allData = allData';

%     toc
%     % Finish the aquisition    
%     fwrite(obj,'Q','char');   
%   
%   
%     
%     % Close connection
%     fclose(obj);
%    
%    
%    
%     
%     %% Finish session
%     set(handles.t_msg,'String','Done')      % Show message about acquisition    
%     
%     iData = allData;
%     
%     
%     %Delete listener SBI and clear variable
% 
%     clear allData;
%     clear timeStamps;
%     clear handles;
%     
% end




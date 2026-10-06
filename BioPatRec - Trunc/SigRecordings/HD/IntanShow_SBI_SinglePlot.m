function cData = IntanShow_SBI_SinglePlot( handlesX )
% Global variable
    global handles;
    global allData;
    global timeStamps;

    % Variable to be sent globally
    handles     = handlesX;
    allData     = [];
    timeStamps  = [];
%INTANSHOW_SBI_SINGLEPLOT Summary of this function goes here
%   Detailed explanation goes here
 % Init variables
    A = str2double(get(handles.et_ampPP,'String'));
    ampPP   =  65535/(2^A);
    %ampPP   = str2double(get(handles.et_ampPP,'String'));
    sF      = str2double(get(handles.et_sF,'String'));
    sT      = str2double(get(handles.et_sT,'String'));
    tW      = str2double(get(handles.et_tw,'String'));
    allCh   = str2double(get(handles.lb_ch,'String'));
    selCh     = allCh(get(handles.lb_ch,'Value'));
    %sCh(selCh)= 1;
    nCh     = size(selCh,1);
    
   
     %% Initial Plot
    % Setting for data time window
    tWs = sF*tW;
    tv = 0:1/sF:tW-1/sF;                % Create vector of time
    cData = zeros(length(tv),nCh);       % Current data

    % Offset the data
    offVector = 0:nCh-1;
    offVector = offVector .* ampPP;
    sData = cData;
    for i = 1 : nCh
        sData(:,i) = cData(:,i) + offVector(i);
    end    
    
     % Draw figure
    p_t0 = plot(handles.a_t0, tv, sData);
    handles.p_t0 = p_t0;
    xlim([0,tW]);
    ylim([-ampPP/2,(ampPP*nCh)-ampPP/2]);
    set(handles.a_t0,'YTick',offVector);
    set(handles.a_t0,'YTickLabel',1:nCh);
    
    %%Init Wiicom
    obj = tcpip('192.168.100.10',65100,'NetworkRole','client');
    fclose(obj);
    
%      if isfield(handles,'obj')
%         % obj = tcpip('192.168.100.10',65100,'NetworkRole','client');
%         obj = handles.obj;
%     else
%         set(handles.t_msg,'String','No connection obj found');   
%         return;
%      end
     obj.InputBufferSize = tWs*2*nCh;
     fopen(obj);
     
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
%            end
        end
                        
        if printFlag == sTw+1
            % Offset the data
            for j = 1 : nCh
                sData(:,j) = cData(j,:);
                set(p_t0(j),'YData',sData(:,j)+ offVector(j));
            end
            printFlag = 1;      
            drawnow;
        end


    end
    allData = allData';

    toc
    % Finish the aquisition    
    fwrite(obj,'Q','char');    
    
    % Close connection
    fclose(obj);
    
    % Print the data    
    tv = 0:1/sF:sT-1/sF;                % Create vector of time
    cData = allData;
    p_t0 = plot(handles.a_t0,tv,cData);
    sData = zeros(size(cData));
    for i = 1 : nCh
        sData(:,i) = cData(:,i) + offVector(i);
        set(p_t0(i),'YData',sData(:,i));
    end     
    % Update for all data
    xlim([0,sT]);
    ylim([-ampPP/2,(ampPP*nCh)-ampPP/2]);
    set(handles.a_t0,'YTick',offVector);
    set(handles.a_t0,'YTickLabel',vCh);
    
    set(handles.t_msg,'String','');
    
    disp(size(sData,1));
    disp(sData(end));
    
    save('sData.mat','sData');
     
end   

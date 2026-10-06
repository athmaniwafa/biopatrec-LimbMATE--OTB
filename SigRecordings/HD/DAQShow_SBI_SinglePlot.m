% ---------------------------- Copyright Notice ---------------------------
% This file is part of BioPatRec © which is open and free software under 
% the GNU Lesser General Public License (LGPL). See the file "LICENSE" for 
% the full license governing this code and copyrights.
%
% BioPatRec was initially developed by Max J. Ortiz C. at Integrum AB and 
% Chalmers University of Technology. All authors’ contributions must be kept
% acknowledged below in the section "Updates % Contributors". 
%
% Would you like to contribute to science and sum efforts to improve 
% amputees’ quality of life? Join this project! or, send your comments to:
% maxo@chalmers.se.
%
% The entire copyright notice must be kept in this or any source file 
% linked to BioPatRec. This will ensure communication with all authors and
% acknowledge contributions here and in the project web page (optional).
%
% -------------------------- Function Description -------------------------
% Function to show cData in a single plot
% 
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2012-11-25 / Max Ortiz  / Creation
% 20xx-xx-xx / Authors    / Comments


function cData = DAQShow_SBI_SinglePlot(handlesX) 

    % Global variable
    global handles;
    global allData;
    global timeStamps;

    % Variable to be sent globally
    handles     = handlesX;
    allData     = [];
    timeStamps  = [];
    
    % Init variables
    ampPP   = str2double(get(handles.et_ampPP,'String'));
    sF      = str2double(get(handles.et_sF,'String'));
    sT      = str2double(get(handles.et_sT,'String'));
    tW      = str2double(get(handles.et_tw,'String'));
    allCh   = str2double(get(handles.lb_ch,'String'));
    selCh     = allCh(get(handles.lb_ch,'Value'));
    sCh(selCh)= 1;
    nCh     = size(selCh,1);

    %% Initial Plot
    % Setting for data time window
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
 
    %% Init DAQ
    s = InitSBI_NI(sF,sT,sCh);
    % Change the interruption time
    s.NotifyWhenDataAvailableExceeds = sF*tW;  
    lh = s.addlistener('DataAvailable', @DataShow_SBI_SP_OneShot); 
    
    %% Run in the backgroud
    set(handles.t_msg,'String','Recording...')      % Show message about acquisition    
    s.startBackground();
    % Wait until it has finished done
    s.wait();
    
    %% Finish session
    set(handles.t_msg,'String','Done')      % Show message about acquisition    
    tv = timeStamps;
    cData = allData;       % Current data
    
    % Offset the data
    set(p_t0,'XData',tv);
    offVector = 0:nCh-1;
    offVector = offVector * ampPP;
    sData = zeros(size(cData));
    for i = 1 : nCh
        sData(:,i) = cData(:,i) + offVector(i);
        set(p_t0(i),'YData',sData(:,i));
    end    
    % Update for all data
    xlim([0,sT]);
    ylim([-ampPP/2,(ampPP*nCh)-ampPP/2]);
    set(handles.a_t0,'YTick',offVector);
    set(handles.a_t0,'YTickLabel',1:nCh);

    %Delete listener SBI and clear variable
    delete (lh)
    clear allData;
    clear timeStamps;
    clear handles;
    
end

function DataShow_SBI_SP_OneShot(src,event)

    global handles;
    global allData;
    global timeStamps;
    
    % Get info from handles
    ampPP   = str2double(get(handles.et_ampPP,'String'));
    sCh     = get(handles.lb_ch,'Value');
    nCh     = size(sCh,2);

    % Get data
    tempData = event.Data;
    allData = [allData; tempData];
    timeStamps = [timeStamps; event.TimeStamps];
   
    % Update for all data
    cData = tempData;       % Current data
    
    % Offset the data
    offVector = 0:nCh-1;
    offVector = offVector * ampPP;
    sData = zeros(size(cData));
    for i = 1 : nCh
        sData(:,i) = cData(:,i) + offVector(i);
        set(handles.p_t0(i),'YData',sData(:,i));
        hold on;
    end
    hold off;
    
    drawnow;
    
end    
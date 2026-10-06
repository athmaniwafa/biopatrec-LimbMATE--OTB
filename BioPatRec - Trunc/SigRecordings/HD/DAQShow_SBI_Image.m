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
% 2012-11-27 / Max Ortiz  / Creation
% 20xx-xx-xx / Authors    /  Comments


function iData = DAQShow_SBI_Image(handlesX) 

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
    sCh     = get(handles.lb_ch,'Value');
    nCh     = size(sCh,2);
    
    r      = str2double(get(handles.et_rows,'String'));
    c      = str2double(get(handles.et_columns,'String'));
    allF   = get(handles.pm_features,'String');
    fID    = char(allF(get(handles.pm_features,'Value'))); 
        
    handles.imageRows       = r;
    handles.imageColumns    = c;
    handles.fID             = fID;
    handles.sF              = sF;
 
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
    
    iData = allData;
    
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
    sCh     = get(handles.lb_ch,'Value');
    nCh     = size(sCh,2);

    % Get data
    tempData = event.Data;
    allData = [allData; tempData];
    timeStamps = [timeStamps; event.TimeStamps];
   
    % Compute for all data    
    c = 1;
    for i = 1 : handles.imageRows
        for j = 1 : handles.imageColumns
            if c <= nCh
                feature = GetSigFeatures(tempData(:,c), handles.sF, {handles.fID});
                iData(i,j) = feature.(handles.fID);
                c = c+1;
            else
                break;
            end
        end
    end

    imagesc(iData);    
    drawnow;
    
end    
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
% Function to activate the units in standard prosthetic devices using
% wiless communication
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2013-04-17 / Max Ortiz  / Creation 
% 20xx-xx-xx / Author  / Comment on update

function ActivateSP_FixedTime(obj,id,speed,time)

    % Open connection
    if strcmp(obj.status,'open')
        fclose(obj);        
        fopen(obj);
    else
        fopen(obj);
    end        
    
    % Set up duty cycle    
    fwrite(obj,'D','char');
%     replay = char(fread(obj,1,'char'));
%     if strcmp(replay,'D');
%         set(handles.t_msg,'String','Sending DutyCycle!');
%     else
%         set(handles.t_msg,'String','Error in DutyCycle');        
%     end    
    % Select motor and direction
    fwrite(obj,id,'char');
%     replay = char(fread(obj,1,'char'));
%     if strcmp(replay,id);
%         set(handles.t_msg,'String','Unit selected!');
%     else
%         set(handles.t_msg,'String','Error in selecting unit');        
%     end    

    % Write dutty cycle
    fwrite(obj,speed,'uint8');
%    replay = char(fread(obj,1,'char'));
%     if strcmp(replay,'O');
%         set(handles.t_msg,'String','DutyCycle Stablished!');
%     else
%         set(handles.t_msg,'String','Error setting DutyCycle');        
%     end        

    % Wait time
    pause(time);

    
    % Read available data and discard it
    if obj.BytesAvailable > 0
        fread(obj,obj.BytesAvailable,'uint8');    % Read the samples        
    end
    
    % Set up duty cycle    
    fwrite(obj,'D','char');
%     replay = char(fread(obj,1,'char'));
%     if strcmp(replay,'D');
%         set(handles.t_msg,'String','Sending DutyCycle!');
%     else
%         set(handles.t_msg,'String','Error in DutyCycle');        
%     end    
    % Select motor and direction
    fwrite(obj,id,'char');
%     replay = char(fread(obj,1,'char'));
%     if strcmp(replay,id);
%         set(handles.t_msg,'String','Unit selected!');
%     else
%         set(handles.t_msg,'String','Error in selecting unit');        
%     end    

    % Write dutty cycle
    fwrite(obj,1,'uint8');
%     replay = char(fread(obj,1,'char'));
%     if strcmp(replay,'O');
%         set(handles.t_msg,'String','DutyCycle Stablished!');
%     else
%         set(handles.t_msg,'String','Error setting DutyCycle');        
%     end      
    
    % Close connection
    fclose(obj); 

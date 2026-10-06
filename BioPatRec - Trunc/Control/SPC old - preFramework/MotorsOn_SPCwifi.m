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
% Function to activate standard prosthetic units using wireless
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2013-04-21 / Max Ortiz  / Creation (3 DoF)
% 20xx-xx-xx / Author  / Comment on update

function MotorsOn_SPCwifi(obj, movement, motors)

    motorPct = motors(movement.motor).pct;  
    
    % Decode PWM id by looking at the motor ID and its direction
    pwmID = cell2mat(motors(movement.motor).id);
    if pwmID == 'A' && movement.vreDir == 0
        pwmID = 'A';
    elseif pwmID == 'A' && movement.vreDir == 1
        pwmID = 'B';
    elseif pwmID == 'B' && movement.vreDir == 0
        pwmID = 'C';
    elseif pwmID == 'B' && movement.vreDir == 1
        pwmID = 'D';
    elseif pwmID == 'C' && movement.vreDir == 0
        pwmID = 'E';
    elseif pwmID == 'C' && movement.vreDir == 1
        pwmID = 'F';
    end    
    
    fwrite(obj,'D','char');    
    fwrite(obj,pwmID,'char');    
    fwrite(obj,motorPct,'uint8');    
    
end
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
% ------------------- Function Description ------------------
% A Sensory Motor Control (SMC) Test is performed using the VRE. It
% requires external hardware to deliver vibrotactile stimulation to the
% user stump.
%
% The function is written in such a way that it requires two rows of
% vibrators on the stump. One row is the main row (odd vibrators numbers),
% activated at each movement detection, the other row (even vibrators
% numbers) is activate at particular target points). Parameters "param" can
% be changed by changing the "handles.SMCparam" in the GUI_TacTest.m
% function
%
% INPUTS:   1. handles from the GUI_TacTest gui
%           2. ID of the target movement
%           3. VRE ID of the detected movement
%           4. VRE dir of the detected movement
%           5. Movement speed (i.e. step)
%           6. Green/grey hand movement flag. If this is empty, then the grey
%              hand is intended to be moving, and the position is calculated.
%              If this is not empty, the green hand is intended to bemoving,
%              and this parameter is taken as the position
%
% OUTPUTS:  1. current position (in case the last parameter is not empty,
%              the position returned is the same as the one given plus the
%              sign (depending on movement direction)
%
% --------------------------Updates--------------------------
% [Contributors are welcome to add their email]
% 2015-12-04 / Francesco Clemente   / Creation of SMCTest
%                            
% 20xx-xx-xx / Author     / Comment on update                          

function current_pos = SMCtestMapPosToVib(handles, TargetMovID, MovDof, MovDir, DegPerMov, GreenMov)

global distance % FIX


if isempty(GreenMov) % if the grey hand is moving
    %update position only if the right movement is detected, accounting for
    %movement direction
    if (MovDof == handles.movList(TargetMovID).idVRE)
        current_pos = handles.SMCposition + (2*MovDir-1)*DegPerMov;
    else
        current_pos = handles.SMCposition;
    end
else % if the green hand is moving, use the last parameter as the position
    current_pos = (2*MovDir-1)*GreenMov;
end

% initialize useful variables
target_step = handles.SMCTargetStep;
half_step   = target_step/2;
max_int     = handles.SMCMaxVibInt;
abs_pos     = abs(current_pos);

% map position to vibrator (and keep it within limits)
if current_pos > 0
    vib_idx1 = 2*round(abs_pos/target_step)-1;
else
    vib_idx1 = handles.SMCMaxVibIdx - 2*round(abs_pos/target_step)+2;
end
if (vib_idx1 < 0),  vib_idx1 = 0;  end
if (vib_idx1 > handles.SMCMaxVibIdx), vib_idx1 = handles.SMCMaxVibIdx; end
if (abs_pos < half_step), vib_idx1 = 0; end % initial lag

% map position to intensity
vib_int = abs(round((abs_pos+half_step)/target_step)*target_step-(abs_pos+half_step))*max_int/half_step;
disp(['tpos: ',   num2str(distance),...
      ' | pos: ', num2str(current_pos), ...
      ' | idx: ', num2str(vib_idx1), ...
      ' | int: ', num2str(vib_int)]);

% decide wether to activate the second row of vibrator
if mod(abs_pos, target_step)<2
    vib_idx2 = vib_idx1 + 1;
    if(vib_idx1==7), vib_idx2 = 10; end %vib 8 and 10 are swapped in the arm cuff
    if(vib_idx1==9), vib_idx2 = 8; end
else
    vib_idx2 = [];
end

% activate vibrators
if (vib_idx1==0)||(vib_int==0)
else
    byte1 = vib_idx1*16 + vib_int;
    byte2 = handles.SMCVibduration;
    fwrite(handles.SMCtestSerial, [byte1 byte2]);

    if ~isempty(vib_idx2)
        byte1 = vib_idx2*16 + vib_int;
        byte2 = handles.SMCVibduration;
        fwrite(handles.SMCtestSerial, [byte1 byte2]);
    end
end
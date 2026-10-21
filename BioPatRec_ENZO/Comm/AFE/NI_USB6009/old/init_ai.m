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
% Funtion to Initialize the NI-6009 Analog Inputs 
% Input = Handles
% Output = ai object 
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2009-03-31 / Max Ortiz / Creation
% 20xx-xx-xx / Author  / Comment on update

function [ai,chp] = init_ai(handles,Fs,Ts)

chp = zeros(4,1);

% Close possible daq objects running
%if (~isempty(daqfind))
%    stop(daqfind)
%end

% Use this command to determine Board IDs in system, if needed
hw = daqhwinfo('nidaq');
hw.InstalledBoardIds;
hw.BoardNames

% Create an analog input object using Board ID "Dev6".
ai = analoginput('nidaq','Dev1');

% Set the sample rate and samples per trigger
ai.SampleRate = Fs;
ai.SamplesPerTrigger = Fs*Ts;

% Set Inputy Type and Ranges
%set(ai,'InputType','Differential');
set(ai,'InputType','SingleEnde');

% Add all chanels
if get(handles.cb_ch0,'Value') == 1
    addchannel(ai, 0,'ch0');
    set(ai.ch0,'InputRange',[-10 10]);
    chp(1)=1;
end
if get(handles.cb_ch1,'Value') == 1
    addchannel(ai, 1,'ch1');
    set(ai.ch1,'InputRange',[-10 10]);
    chp(2)=1;
end
if get(handles.cb_ch2,'Value') == 1
    addchannel(ai, 2,'ch2');
    set(ai.ch2,'InputRange',[-10 10]);
    chp(3)=1;
end
if get(handles.cb_ch3,'Value') == 1
    addchannel(ai, 3,'ch3');
    set(ai.ch3,'InputRange',[-10 10]);
    chp(4)=1;
end



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
% Funtion to Show the aquire data on the GUI
% Input = ai object, chp channels pressences
% Output = data and time 
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2009-04-15 / Max Ortiz  / Creation
% 20xx-xx-xx / Author  / Comment on update

function cdata = daq_nonshow(ai, chp, Fs, Ts)

% Start DAQ
start(ai);
while ai.SamplesAcquired < Ts*Fs
end
wait(ai,Ts+1);                              %Wait until the daq is over or until Ts+1 is reached
data = getdata(ai);

% Save acquired data into cdata
% Settings for total data
chi=1;    
if chp(1) == 1        
    cdata(:,1) = data(:,chi);
    chi=chi+1;
end
if chp(2) == 1        
    cdata(:,2) = data(:,chi);
    chi=chi+1;
end
if chp(3) == 1        
    cdata(:,3) = data(:,chi);
    chi=chi+1;
end
if chp(4) == 1        
    cdata(:,4) = data(:,chi);
end


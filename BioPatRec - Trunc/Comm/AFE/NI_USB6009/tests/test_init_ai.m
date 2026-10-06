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
% Test Funtion
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 20xx-xx-xx / Max Ortiz  / Creation
% 20xx-xx-xx / Author  / Comment on update


Fs = 40000;
Ts = 0.1;
ai = init_ai(Fs,Ts);

ai.TriggerRepeat = inf;     % From example demoai_intro.html

% Start the acquisition
start(ai);
t = 0:1/Fs:(Ts)-1/Fs;
for x = 1 : 10
    % Acquire whatever data was avilable at the samplespertrigger required
    pause((1/ai.SampleRate)*ai.SamplesPerTrigger*10);
    data =peekdata(ai,ai.SamplesPerTrigger);

    % Graphically plot the results
    subplot(2,2,1);
    plot(t,data(:,1));
    subplot(2,2,2);
    plot(t,data(:,2));
    subplot(2,2,3);
    plot(t,data(:,3));
    subplot(2,2,4);
    plot(t,data(:,4));
end

% Clean up
stop(ai);
delete(ai);

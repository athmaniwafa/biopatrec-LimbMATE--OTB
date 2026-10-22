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
% Function to test the analog output, toggling it using timers
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2009-06-30 / Max Ortiz  / Creation
% 20xx-xx-xx / Author  / Comment on update

function test_ao

t  = 0.1;           % Frequency
prh = 0.001;          % Percentage of the time that the signal would be high
th = t*prh;         % Time of high signal
tte = 10;         % Task to execute
ao = init_ao();

%putdata(ao,y); % PUTDATA doesn't work with the USB-6009 because it's
%missing a internal clock

t1 = timer;     % Timer for high level
t2 = timer;     % Timer for low level

%t1.TimerFcn = 'disp(''ON!'')';
t1.StartFcn = 'disp(''Analog Output Toggling 0 to 5'')';
t1.TimerFcn = {'set_ao',ao,5};
t1.StopFcn = 'disp(''Analog Ouput Stop'')';
t1.Period = t;
t1.StartDelay = 0;
%t1.BusyMode = 'drop';
t1.BusyMode = 'queu';
t1.ExecutionMode = 'fixedRate';
%t1.ExecutionMode = 'fixedDelay';
t1.TasksToExecute = tte;

%t2.TimerFcn = 'disp(''OFF!'')';
t2.TimerFcn = {'set_ao',ao,0};
t2.Period = t;
t2.StartDelay = th;
%t2.BusyMode = 'drop';
t2.BusyMode = 'queu';
t2.ExecutionMode = 'fixedRate';
%t2.ExecutionMode = 'fixedDelay';
t2.TasksToExecute = tte;

start([t1 t2]);
tic
wait(t2);
toc

putsample(ao,0);

stop(timerfind);
delete(timerfind);
stop(ao);
delete(ao);


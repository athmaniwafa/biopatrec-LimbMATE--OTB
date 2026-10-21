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
% Funtion to Initialize the NI-6009 Analog Outputs 
% Input = Nothing since the highest frequency will be used
% Output = dio object 
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2009-07-02 / Max Ortiz  / Creation
% 20xx-xx-xx / Author  / Comment on update

function dio = init_dio()

% NOTE: The AI might be running at the same time so dont!
% Close possible daq objects running
%if (~isempty(daqfind))
%    stop(daqfind)
%end

% Use this command to determine Board IDs in system, if needed
%hw = daqhwinfo('nidaq');
%hw.InstalledBoardIds;
%hw.BoardNames

%% Create an analog input object using Board ID "Dev6".
dio = digitalio('nidaq', 'Dev1');

%% Add channels
addline(dio, 0:3, 1, 'Out'); % Port 1 as Output
addline(dio, 0:7, 0, 'In');  % Port 0 as Inputs

%% Security
putvalue(dio.Line([1 2]), [1 1]);   % Stop motor
putvalue(dio.Line(4), 0);           % Zero Exit

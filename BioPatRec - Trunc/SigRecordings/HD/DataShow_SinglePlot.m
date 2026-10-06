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
% 20xx-xx-xx / Authors    /  Comments

function  DataShow_SinglePlot(handles,cData,sF,sT)            

    set(handles.et_sT,'String',num2str(sT));
    set(handles.s_t0, 'Max', sT);

    ampPP = str2double(get(handles.et_ampPP,'String'));
    nCh = size(cData,2);    % Number of Channels
    tv  = 0:1/sF:sT-1/sF;   % Create vector of time

    % Offset the data
    offVector = 0:nCh-1;
    offVector = offVector * ampPP;
    sData = zeros(size(cData));
    for i = 1 : nCh
        sData(:,i) = cData(:,i) + offVector(i);
    end

    % Draw figure
    plot(handles.a_t0, tv, sData);

    % Static Limits
    xlim([0,sT]);
    ylim([-ampPP/2,(ampPP*nCh)-ampPP/2]);

    set(handles.a_t0,'YTick',offVector);
    set(handles.a_t0,'YTickLabel',1:nCh);
    
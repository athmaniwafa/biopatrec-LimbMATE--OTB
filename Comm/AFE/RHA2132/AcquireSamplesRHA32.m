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
% Function to read a time window of samples from the RHA2132 AFE
%
% ------------------------- Updates & Contributors ------------------------
% 20??-??-?? / Max Ortiz  / Creation
% 2017-09-25 / Simon Nilsson / Refactorization to allow calling directly from
%                            % Biofeedback GUI

function cData = AcquireSamplesRHA32(obj, nCh, tWs)
	cData = zeros(tWs,nCh);
	LSBweight = double(2.5/(65535));   
	for sampleNr = 1:tWs
	    value16 = fread(obj,nCh,'uint16');
	    for k = 1:nCh
	        cData(sampleNr,k) = value16(k)*LSBweight - 1.235;                  % Convert data into volt
	    end
	end
	% Receive confirmation
	reply = fread(obj,1,'char');
	if reply ~= 0
	    ME = MException('Acquire_tWs:bufferOverflow',...
	                    'Buffer of acquisition device full');
	    throw(ME);
	end
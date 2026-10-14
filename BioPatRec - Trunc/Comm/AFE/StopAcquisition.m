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
% ------------------- Function Description ------------------
% Function to Record Exc Sessions
%
% --------------------------Updates--------------------------
% 2015-1-12 / Enzo Mastinu / Divided the RecordingSession function into
                            % several functions: ConnectDevice(),
                            % SetDeviceStartAcquisition(),
                            % Acquire_tWs(), StopAcquisition(). This functions 
                            % has been moved to COMM/AFE folder, into this new script.
% 2017-02-28 / Simon Nilsson / Separated the acquisition modes for RHA2216
                            % and RHA2132. The RHA2132 now uses a higher
                            % baudrate and a buffered acquisition mode to
                            % handle the higher data flow of HD-EMG.

% 20xx-xx-xx / Author  / Comment



% it sends the stop acquisition command to the chosen device
function StopAcquisition(deviceName, obj)

    %%%%% INTAN RHA2216 %%%%%
    if strcmp(deviceName, 'RHA2216')
        fwrite(obj,'Q','char');                                        % Stop the aquisition  ´
        fclose(obj);                                                   % Close connection
    end
    %%%%% INTAN RHA2132 %%%%%
    if strcmp(deviceName, 'RHA2132')
        fwrite(obj,'Q','char');                                        % Stop the aquisition  ´
        fclose(obj);                                                   % Close connection
    end

    %%%%% ADS1299 %%%%%
    if strcmp(deviceName, 'ADS1299')
        fwrite(obj,'G','char');                                        % Stop the aquisition  ´
        fclose(obj);                                                   % Close connection
    end
    if strcmp(deviceName, 'ADS_BP') || strcmp(deviceName, 'ALC-16chs') || strcmp(deviceName, 'ALC-24chs')
        fwrite(obj,'T','char');                                        % Stop the aquisition  
        pause(0.5);
        if obj.BytesAvailable > 0
            fread(obj,obj.BytesAvailable,'uint8');       
        end
        fclose(obj);                                                   % Close connection
    end
    
    %%%%% ADS_BP4 %%%%%
    if strcmp(deviceName, 'ADS_BP4')
        % stop any ongoing streaming
        fwrite(obj,hex2dec('CC'),'char');
        pause(0.5);
        if obj.BytesAvailable > 0
            fread(obj,obj.BytesAvailable,'uint8');       
        end
        fclose(obj);
    end

    %%%%% Limb Mate 1 or 2 %%%%%
    if strcmp(deviceName, 'LM 1') || strcmp(deviceName, 'LM 2') || strcmp(deviceName, 'LM 3') || strcmp(deviceName, 'LM 14')
        % Start the acquisition
        obj.stopAcquisitionEMG();
        % Turn off the LED
        obj.setLED("G", 0)
    end

    %%%%% OTB (OT Bioelettronica EMG-USB2+) %%%%%
    if contains(deviceName, 'OTB400')
        obj.stopAcquisitionEMG();
    end
        
end
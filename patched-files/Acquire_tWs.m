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
% 2015-1-19 / Enzo Mastinu / The ADS1299 part has been modified in way to be 
                            % compatible with the new ADS1299 acquisition mode (DSP + FPU) 
% 2015-4-10 / Enzo Mastinu / The ADS1299_DSP acquisition has been optimized, only desired
                            % channels are transmitted to PC, not all as before
% 2016-7-08 / Enzo Mastinu / The ADS_DSP/Neuromotus acquisition has been
                            % optimized introducing the re-synchronization
                            % in case the signal got lost
% 2017-02-28 / Simon Nilsson / Separated the acquisition modes for RHA2216
                            % and RHA2132. The RHA2132 now uses a higher
                            % baudrate and a buffered acquisition mode to
                            % handle the higher data flow of HD-EMG.
                            
% 20xx-xx-xx / Author  / Comment



% It acquire tWs samples from the selected device
function [cData, error] = Acquire_tWs(deviceName, obj, nCh, tWs, compressionEnabled)
 
    error = 0;
    if nargin < 5
        compressionEnabled = 0;
    end
    cData = zeros(tWs,nCh);                                                % this is the data structure that the function must return
    
    % Set warnings to temporarily issue error (exceptions)
    s = warning('error', 'instrument:fread:unsuccessfulRead');
    try
        %%%%% ADS1299 %%%%%
        if strcmp(deviceName, 'ADS1299')
            LSBweight = double(4.5/(8388607));
            for sampleNr = 1:tWs
                byteData = fread(obj,27,'char');
                value = [65536 256 1]*reshape(byteData(4:end), 3, 8);
                for k = 1:nCh  
                    if value(k) > 8388607
                        value(k) = value(k) - 2^24;
                    end
                    cData(sampleNr,k) = value(k) * LSBweight;                  
                end 
            end
        end
        if strcmp(deviceName, 'ADS_BP')
            for sampleNr = 1:tWs
                go = 0;
                while go == 0
                    if compressionEnabled
                        rawData = fread(obj,nCh,'int16');
                        byteData = DecompressData(rawData);
                    else
                        byteData = fread(obj,nCh,'float32');
                    end
                    if byteData < 5
                        go = 1;
                    else
                        fwrite(obj,'T','char');
                        if obj.BytesAvailable > 0
                            fread(obj,obj.BytesAvailable,'uint8');        
                        end
                        fwrite(obj,'G','char');
                        fwrite(obj,nCh,'char');
                        fread(obj,1,'char');
                        disp('Communication issue: automatic resynchronization')
                        go = 0;
                    end
                end
                cData(sampleNr,:) = byteData(1:nCh,:)';
            end
        elseif strcmp(deviceName, 'ALC-16chs') || strcmp(deviceName, 'ALC-24chs')
            for sampleNr = 1:tWs
                go = 0;
                while go == 0
                    if compressionEnabled
                        rawData = fread(obj,nCh,'int16');
                        byteData = DecompressData(rawData);
                    else
                        byteData = fread(obj,nCh,'float32');
                    end
                    if byteData < 5
                        go = 1;
                    else
                        fwrite(obj,'T','char');
                        if obj.BytesAvailable > 0
                            fread(obj,obj.BytesAvailable,'uint8');        
                        end
                        vCh = handles.vCh;
                        chIdxDiff = bitshift(sum(bitset(0,vCh)),-16);
                        chIdxUpper = bitshift(sum(bitset(0,vCh)),-8);
                        chIdxUpper = bitand(chIdxUpper,255);
                        chIdxLower = bitand(sum(bitset(0,vCh)),255);
                        fwrite(obj,'G','uint8');
                        if strcmp(deviceName, 'ALC-24chs')
                            fwrite(obj,chIdxDiff,'uint8');
                        end
                        fwrite(obj,chIdxUpper,'uint8');
                        fwrite(obj,chIdxLower,'uint8');
                        fwrite(obj,nCh,'uint8');
                        fread(obj,1,'char');
                        disp('Communication issue: automatic resynchronization')
                        go = 0;
                    end
                end
                cData(sampleNr,:) = byteData(1:nCh,:)';
            end
        end
        
        %%%%% ADS_BP4 %%%%%
        if strcmp(deviceName, 'ADS_BP4')
            for sampleNr = 1:tWs
                go = 0;
                while go == 0
                    if compressionEnabled
                        rawData = fread(obj,nCh,'int16');
                        byteData = DecompressData(rawData);
                    else
                        byteData = fread(obj,nCh,'float32');
                    end
                    if byteData < 5
                        go = 1;
                    else
                        fwrite(obj,hex2dec('CC'),'char');
                        if obj.BytesAvailable > 0
                            fread(obj,obj.BytesAvailable,'uint8');
                        end
                        if compressionEnabled
                            fwrite(obj,hex2dec('C2'),'char');
                        else
                            fwrite(obj,hex2dec('C1'),'char');
                        end
                        fwrite(obj,nCh,'char');
                        fread(obj,1,'char');
                        disp('Communication issue: automatic resynchronization')
                        go = 0;
                    end
                end
                cData(sampleNr,:) = byteData(1:nCh,:)';
            end
        end

       %%%%% INTAN RHA2216 %%%%%
       if strcmp(deviceName, 'RHA2216')   
            LSBweight = double(2.5/(65535));
            for sampleNr = 1:tWs                  
                value16 = fread(obj,nCh,'uint16');
                for k = 1:nCh
                    cData(sampleNr,k) = value16(k)*LSBweight;
                end
            end 
       end
       
       %%%%% INTAN RHA2132 %%%%%
       if strcmp(deviceName, 'RHA2132')   
            RequestSamplesRHA32(obj, tWs);
            cData = AcquireSamplesRHA32(obj, nCh, tWs);
       end

       %%%%% Limb Mate 1 or 2 %%%%% - Transmit the entire Class Structure %%%%%
       if strcmp(deviceName, 'LM 1') || strcmp(deviceName, 'LM 2') || strcmp(deviceName, 'LM 3') || strcmp(deviceName, 'LM 14')

           % Get the Data    
           [EMG_data_TW] = obj.getEMG_data_TW_float(tWs);
           
           cData = EMG_data_TW';
       end

       %%%%% OTB (OT Bioelettronica EMG-USB2+) %%%%%
       if strcmp(deviceName, 'OTB')

           % Our wrapper already returns [tWs x nCh], no transpose needed
           cData = obj.getEMG_data_TW_float(tWs);
       end
   
    catch exception
       fprintf('ACQUIRE_TWS REAL ERROR: %s\n', exception.message);
       for k = 1:numel(exception.stack)
           fprintf('  at %s line %d\n', exception.stack(k).name, exception.stack(k).line);
       end
       error = 1;
    end
    %Set warning back to normal state
    warning(s);
   
end
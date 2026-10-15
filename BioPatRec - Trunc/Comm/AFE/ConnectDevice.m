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
% 2017-02-28 / Simon Nilsson / Separated the acquisition modes for RHA2216
                            % and RHA2132. The RHA2132 now uses a higher
                            % baudrate and a buffered acquisition mode to
                            % handle the higher data flow of HD-EMG.                            

% 20xx-xx-xx / Author  / Comment



% it creates IP object and sets the buffersize depending on the device that has been chose
function obj = ConnectDevice(handles)

    deviceName  = handles.deviceName;

    % OTB400 uses OTComm .NET, not MATLAB serial communication
    if contains(deviceName, 'OTB400')
    
        if ~isfield(handles, 'objOT') || isempty(handles.objOT)
            error('OTB400: device object not initialized.');
        end
    
        obj = handles.objOT;
        return;
    
    end

    % Sessantaquattro+ uses a TCP socket, not MATLAB serial communication
    if strcmp(deviceName, 'SQ+')
        if ~isfield(handles, 'objSQ') || isempty(handles.objSQ)
            error('SQ+: device object not initialized.');
        end
        obj = handles.objSQ;
        return;
    end

    ComPortType = handles.ComPortType;

    if strcmp(ComPortType, 'COM')
        ComPortName = handles.ComPortName;
    end
    sF          = handles.sF;
    sT          = handles.sT;
    nCh         = handles.nCh;
    sTall       = handles.sTall;

    %%%%% WiFi %%%%%
    if strcmp(ComPortType, 'WiFi')
        %%%%% TI ADS1299 %%%%%
        if strcmp(deviceName, 'ADS_BP') || strcmp(deviceName, 'ADS1299')
            obj = tcpip('192.168.100.10',65100,'NetworkRole','client');        % ADS1299
            obj.InputBufferSize = sTall*sF*nCh*4;  
        end
        %%%%% INTAN RHA2216 %%%%%
        if strcmp(deviceName, 'RHA2216')
            obj = tcpip('192.168.100.10',65100,'NetworkRole','client');        % WIICOM
            obj.InputBufferSize = sT*sF*nCh*2;  
        end
        %%%%% ADS_BP4 %%%%%
        if strcmp(deviceName, 'ADS_BP4')
            obj = tcpip('10.10.10.1',8000,'NetworkRole','client');
            obj.InputBufferSize = sTall*sF*nCh*4;  
            % test connection
            fclose(obj);
            fopen(obj);
            fwrite(obj,hex2dec('A1'),'char');
            fwrite(obj,hex2dec('A2'),'char');
            fread(obj,1,'char');  
            fclose(obj);
        end
    end

    %%%%% COM %%%%%
    if strcmp(ComPortType, 'COM')
        %%%%% TI ADS1299 %%%%%
        if strcmp(deviceName, 'ADS1299')
           obj = serial (ComPortName, 'baudrate', 2000000, 'databits', 8, 'byteorder', 'bigEndian');                       
           obj.InputBufferSize = sTall*sF*27;                                 % 27bytes data package
        end
        if strcmp(deviceName, 'ADS_BP') 
           obj = serial (ComPortName, 'baudrate', 921600, 'databits', 8, 'byteorder', 'bigEndian'); 
           obj.InputBufferSize = sTall*sF*nCh*4;  
        end
        if strcmp(deviceName, 'ALC-16chs') || strcmp(deviceName, 'ALC-24chs')
           obj = serial (ComPortName, 'baudrate', 460800, 'databits', 8, 'byteorder', 'bigEndian');
           obj.InputBufferSize = sTall*sF*nCh*4;  
        end
        %%%%% INTAN RHA2216 %%%%%
        if strcmp(deviceName, 'RHA2216')
            obj = serial (ComPortName, 'baudrate', 1250000, 'databits', 8, 'byteorder', 'bigEndian');
            obj.InputBufferSize = sTall*sF*nCh*2;
        end
        %%%%% INTAN RHA2132 %%%%%
        if strcmp(deviceName, 'RHA2132')
            obj = serial (ComPortName, 'baudrate', 1500000, 'databits', 8, 'byteorder', 'bigEndian');
            obj.InputBufferSize = sTall*sF*nCh*2;
        end
        %%%%% ADS_BP4 %%%%%
        if strcmp(deviceName, 'ADS_BP4') 
           obj = serial (ComPortName, 'baudrate', 921600, 'databits', 8, 'byteorder', 'bigEndian'); 
           obj.InputBufferSize = sTall*sF*nCh*4;  
        end

       %%%%% Limb Mate 1 or 2 %%%%% - Transmit the entire Class Structure %%%%%
        if (strcmp(deviceName, 'LM 1') || strcmp(deviceName, 'LM 2') || strcmp(deviceName, 'LM 3') || strcmp(deviceName, 'LM 14') )
            % Create object for device and connection
            obj = handles.objLM;

            pause(3)
        end
    end     

    % Open the connection if not Limb Mate, OTB400, or SQ+
    if (~(strcmp(deviceName, 'LM 1') || strcmp(deviceName, 'LM 2') || strcmp(deviceName, 'LM 3') || strcmp(deviceName, 'LM 14') || contains(deviceName, 'OTB400') || strcmp(deviceName, 'SQ+')) )
        % Open the connection
        fopen(obj);
    
        % Read available data and discard it
        if obj.BytesAvailable > 1
            fread(obj,obj.BytesAvailable,'uint8');       
        end    
    %     disp(obj);
    end
    
end
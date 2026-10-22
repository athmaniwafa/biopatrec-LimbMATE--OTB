classdef LegacyAdapter < DeviceInterface
    properties
        afeSettings
        obj
    end
    methods
        function obj = LegacyAdapter(afeSettings)
            obj.afeSettings = afeSettings;
        end
        
        function start(obj, cfg)
            % Rebuild the handles struct expected by the original ConnectDevice
            h.deviceName = char(obj.afeSettings.name);
            h.ComPortType = obj.afeSettings.ComPortType;
            if strcmp(h.ComPortType, 'COM'), h.ComPortName = obj.afeSettings.ComPortName; end
            h.nCh = obj.afeSettings.channels; 
            h.sF = obj.afeSettings.sampleRate;
            h.sT = 10; h.sTall = 10; 
            h.compressData = obj.afeSettings.compressData;
            
            obj.obj = ConnectDevice(h);
            SetDeviceStartAcquisition(h, obj.obj);
        end
        
        function data = read(obj, n)
            h.deviceName = char(obj.afeSettings.name);
            h.nCh = obj.afeSettings.channels;
            h.compressData = obj.afeSettings.compressData;
            
            [data, acqError] = Acquire_tWs(h.deviceName, obj.obj, h.nCh, n, h.compressData);
            if acqError == 1, error('Legacy acquisition error.'); end
        end
        
        function stop(obj)
            if ~isempty(obj.obj)
                StopAcquisition(char(obj.afeSettings.name), obj.obj);
            end
        end
        
        function disconnect(obj)
            % Handled in StopAcquisition
        end
    end
    methods (Static)
        function [adapter, nCh, vCh] = configure(handles, deviceName)
            % Handles UI setup for Legacy devices
            if strcmp(deviceName, 'ALC-16chs') || strcmp(deviceName, 'ALC-24chs')
                str = arrayfun(@num2str, 1:(16 + 8*strcmp(deviceName, 'ALC-24chs')), 'UniformOutput', false);
                vCh = listdlg('PromptString', 'Select recording channels:', 'SelectionMode', 'multiple', 'ListString', str);
                if isempty(vCh), error('User cancelled ALC selection.'); end
                nCh = size(vCh,2); 
                set(handles.et_chs,'String',num2str(nCh));
                set(handles.ComPortType,'Value',3); 
                set(handles.ComPortName,'Enable', 'on');
            elseif strcmp(deviceName, 'Thalmic MyoBand')
                nCh = 8; vCh = 1:8;
                set(handles.pm_sampleRate, 'Value', 9);
                set(handles.ComPortType, 'Value', 1);
                set(handles.et_chs, 'String', '8');
            else
                nCh = str2double(get(handles.et_chs,'String'));
                vCh = 1:nCh;
            end
            adapter = LegacyAdapter([]);
        end
    end
end
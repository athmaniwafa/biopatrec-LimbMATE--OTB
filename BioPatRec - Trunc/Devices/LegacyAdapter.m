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
            % Re-create the handles struct that the original ConnectDevice expects
            h.deviceName = char(obj.afeSettings.name);
            h.ComPortType = obj.afeSettings.ComPortType;
            if strcmp(h.ComPortType, 'COM')
                h.ComPortName = obj.afeSettings.ComPortName;
            end
            h.nCh = obj.afeSettings.channels;
            h.sF = obj.afeSettings.sampleRate;
            h.sT = 10; % Fallback for legacy devices
            h.sTall = 10;
            h.compressData = obj.afeSettings.compressData;
            
            % Connect using the original ConnectDevice
            obj.obj = ConnectDevice(h);
            
            if isprop(obj.obj, 'Status') && strcmp(get(obj.obj,'Status'),'closed')
                error('Legacy device failed to connect.');
            end
            
            SetDeviceStartAcquisition(h, obj.obj);
        end
        
        function data = read(obj, n)
            h.deviceName = char(obj.afeSettings.name);
            h.nCh = obj.afeSettings.channels;
            h.compressData = obj.afeSettings.compressData;
            
            [data, acqError] = Acquire_tWs(h.deviceName, obj.obj, ...
                h.nCh, n, h.compressData);
            
            if acqError == 1
                error('Acquisition error in legacy device.');
            end
        end
        
        function stop(obj)
            if ~isempty(obj.obj)
                StopAcquisition(char(obj.afeSettings.name), obj.obj);
            end
        end
        
        function disconnect(obj)
            % Legacy devices close their port in StopAcquisition
        end
    end
end
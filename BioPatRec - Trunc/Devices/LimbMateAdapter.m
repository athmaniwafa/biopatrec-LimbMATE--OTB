classdef LimbMateAdapter < DeviceInterface
    properties
        objLM
        nCh
        sF
    end
    methods
        function obj = LimbMateAdapter(objLM, nCh, sF)
            obj.objLM = objLM;
            obj.nCh = nCh;
            obj.sF = sF;
        end
        
        function start(obj, cfg)
            objLM = obj.objLM;
            objLM.enable_testmode = 0;
            objLM.setSampleFreqGain(obj.sF, 4);
            objLM.setElectrodesConfig("Differential");
            
            % Determine tWs (time window in samples)
            if isfield(cfg, 'tWs') && ~isempty(cfg.tWs)
                tWs = cfg.tWs;
            else
                % Fallback: use 100ms window, matching RecordingSession defaults
                tW = 100 / obj.sF;
                if tW < 0.1
                    tW = 0.1;
                end
                tWs = round(tW * obj.sF);
            end
            
            % Guard against uint8 saturation
            if tWs > 255
                tWs = 255;
            end
            
            objLM.startAcquisitionEMG(1, uint8(255), uint8(tWs), uint8(0));
            objLM.packages_per_TW           = tWs / 5;
            objLM.packages_per_TW_increment = tWs / 5;
        end
        
        function data = read(obj, n)
            data_raw = obj.objLM.getEMG_data_TW_float(n);
            if size(data_raw, 1) == obj.nCh && size(data_raw, 2) == n
                data = data_raw';
            else
                data = data_raw;
            end
        end
        
        function stop(obj)
            try
                obj.objLM.stopAcquisitionEMG();
            catch
            end
        end
        
        function disconnect(obj)
            try
                obj.objLM.disconnectBTdevice();
                delete(obj.objLM.serialObj);
            catch
            end
        end
    end
end
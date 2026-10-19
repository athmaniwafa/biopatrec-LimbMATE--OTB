classdef OTB400Adapter < DeviceInterface
    properties
        objOT
        nCh
    end
    methods
        function obj = OTB400Adapter(objOT, nCh)
            obj.objOT = objOT;
            obj.nCh = nCh;
        end
        function start(obj, cfg)
            % OTB starts streaming on construction
        end
        function data = read(obj, n)
            data_raw = obj.objOT.getEMG_data_TW_float(n);
            if size(data_raw, 1) == obj.nCh && size(data_raw, 2) == n
                data = data_raw';
            else
                data = data_raw;
            end
        end
        function stop(obj)
            try, obj.objOT.stopAcquisition(); catch, end
        end
        function disconnect(obj)
            try
                obj.objOT.disconnectBTdevice();
            catch
            end
        end
    end
end
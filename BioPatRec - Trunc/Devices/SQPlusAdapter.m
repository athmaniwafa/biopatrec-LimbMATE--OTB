classdef SQPlusAdapter < DeviceInterface
    properties
        objSQ
        nCh
    end
    methods
        function obj = SQPlusAdapter(objSQ, nCh)
            obj.objSQ = objSQ;
            obj.nCh = nCh;
        end
        function start(obj, cfg)
            % SQ+ starts streaming on construction
        end
        function data = read(obj, n)
            data_raw = obj.objSQ.getEMG_data_TW_float(n);
            if size(data_raw, 1) == obj.nCh && size(data_raw, 2) == n
                data = data_raw';
            else
                data = data_raw;
            end
        end
        function stop(obj)
            try, obj.objSQ.stopAcquisition(); catch, end
        end
        function disconnect(obj)
            try
                obj.objSQ.disconnectBTdevice();
            catch
            end
        end
    end
end
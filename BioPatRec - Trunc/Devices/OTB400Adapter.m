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
            obj.objOT.startAcquisitionEMG();
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
            obj.objOT.stopAcquisitionEMG();
        end
        function flush(obj)
            obj.objOT.flushInput();
        end
        function disconnect(obj)
            try, obj.objOT.disconnectBTdevice(); catch, end
        end
    end
    methods (Static)
        function [adapter, nCh, vCh] = configure(handles, deviceName)
            [selection,ok] = OTB400_SelectInputs(deviceName);
            if ~ok, error('User cancelled OTB selection.'); end
            objOT = OT_Acquire('inputs',selection,120);
            nCh = objOT.Nch;
            set(handles.et_chs,'String',num2str(nCh));
            vCh = 1:nCh;
            
            % Force sample rate
            srList = cellstr(get(handles.pm_sampleRate, 'String'));
            idxSR = find(strcmp(srList, '2048'), 1);
            if isempty(idxSR)
                srList{end+1} = '2048'; set(handles.pm_sampleRate, 'String', srList);
                idxSR = numel(srList);
            end
            set(handles.pm_sampleRate, 'Value', idxSR);
            
            % Force COM port
            comList = cellstr(get(handles.ComPortType, 'String'));
            idxCOM = find(strcmp(comList, 'COM'), 1);
            if ~isempty(idxCOM), set(handles.ComPortType, 'Value', idxCOM); end
            
            adapter = OTB400Adapter(objOT, nCh);
        end
    end
end

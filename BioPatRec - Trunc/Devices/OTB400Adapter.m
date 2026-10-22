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
            try, obj.objOT.disconnectBTdevice(); catch, end
        end
    end
    methods (Static)
        function [adapter, nCh, vCh] = configure(handles, deviceName)
            if strcmp(deviceName, 'OTB400_HD')
                choice = questdlg('Select number of channels:', 'OTB400 HD', '64', '128', '64');
                if isempty(choice), error('User cancelled OTB selection.'); end
                nCh = str2double(choice);
                [electrodes, ok] = OTB400_SelectElectrodes(nCh);
                if ~ok, error('User cancelled electrode selection.'); end
                set(handles.et_chs, 'String', choice);
                
                objOT = OT_Acquire('hd', nCh, 120, electrodes);
            else
                nCh = 8;
                set(handles.et_chs, 'String', '8');
                objOT = OT_Acquire('bipolar', nCh, 120);
            end
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
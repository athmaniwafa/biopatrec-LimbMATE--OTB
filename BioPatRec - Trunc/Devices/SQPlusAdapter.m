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
            global GLOBAL_SQ_OBJ;
            
            % If we don't have an active connection, ask the user how to configure it
            if isempty(GLOBAL_SQ_OBJ)
                choice = questdlg('Select SQ+ configuration:', 'SQ+ Mode', ...
                                  '8 Channels (Bipolar)', '64 Channels (Matrix)', '8 Channels (Bipolar)');
                if isempty(choice), choice = '8 Channels (Bipolar)'; end
                
                if strcmp(choice, '64 Channels (Matrix)')
                    fprintf('[SQ] Adapter creating 64-channel Matrix connection...\n');
                    GLOBAL_SQ_OBJ = Sessantaquattro_Acquire(64, 120, 45454);
                else
                    fprintf('[SQ] Adapter creating 8-channel Bipolar connection...\n');
                    GLOBAL_SQ_OBJ = Sessantaquattro_Acquire(8, 120, 45454);
                end
            else
                fprintf('[SQ] Adapter reusing existing hardware connection...\n');
            end
            
            obj.objSQ = GLOBAL_SQ_OBJ;
            obj.objSQ.startAcquisitionEMG();
        end
        
        function data = read(obj, n)
            if isempty(obj.objSQ), data = zeros(n, obj.nCh); return; end
            data_raw = obj.objSQ.getEMG_data_TW_float(n);
            
            if size(data_raw, 1) == obj.nCh && size(data_raw, 2) == n
                data = data_raw';
            else
                data = data_raw;
            end
        end
        
        function stop(obj)
            try, obj.objSQ.stopAcquisitionEMG(); catch, end
        end
        
        function disconnect(obj)
            global GLOBAL_SQ_OBJ;
            try, obj.objSQ.disconnectBTdevice(); catch, end
            GLOBAL_SQ_OBJ = [];
        end
    end
    methods (Static)
        function [adapter, nCh, vCh] = configure(handles)
            % Force sample rate to 1000 Hz
            srList = cellstr(get(handles.pm_sampleRate, 'String'));
            idxSR = find(strcmp(srList, '1000'), 1);
            if isempty(idxSR)
                srList{end+1} = '1000'; set(handles.pm_sampleRate, 'String', srList);
                idxSR = numel(srList);
            end
            set(handles.pm_sampleRate, 'Value', idxSR);
            
            % Force COM port
            comList = cellstr(get(handles.ComPortType, 'String'));
            idxCOM = find(strcmp(comList, 'COM'), 1);
            if ~isempty(idxCOM), set(handles.ComPortType, 'Value', idxCOM); end
            
            nCh = str2double(get(handles.et_chs, 'String'));
            vCh = 1:nCh;
            
            adapter = SQPlusAdapter([], nCh);
        end
    end
end
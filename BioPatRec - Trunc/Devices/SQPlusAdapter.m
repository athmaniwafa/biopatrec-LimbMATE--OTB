classdef SQPlusAdapter < DeviceInterface
    properties
        objSQ
        nCh
    end

    methods
        function obj = SQPlusAdapter(objSQ, nCh)
            obj.objSQ = objSQ;
            obj.nCh   = nCh;
        end

        function start(obj, cfg) %#ok<INUSD>
            global GLOBAL_SQ_OBJ;

            % Drop a stale connection or one configured for the other mode
            if ~isempty(GLOBAL_SQ_OBJ) && isvalid(GLOBAL_SQ_OBJ) ...
                    && GLOBAL_SQ_OBJ.nChUsed ~= obj.nCh
                try GLOBAL_SQ_OBJ.disconnectBTdevice(); catch, end
                GLOBAL_SQ_OBJ = [];
            end

            if isempty(GLOBAL_SQ_OBJ) || ~isvalid(GLOBAL_SQ_OBJ) || isempty(GLOBAL_SQ_OBJ.srv)
                if obj.nCh == 64
                    fprintf('[SQ] Adapter creating 64-channel Matrix connection...\n');
                else
                    fprintf('[SQ] Adapter creating 8-channel Bipolar connection...\n');
                end
                GLOBAL_SQ_OBJ = Sessantaquattro_Acquire(obj.nCh, 120, 45454);
            else
                fprintf('[SQ] Adapter reusing existing hardware connection...\n');
            end

            obj.objSQ = GLOBAL_SQ_OBJ;
            obj.objSQ.flushInput();
        end

        function data = read(obj, n)
            global GLOBAL_SQ_OBJ;
            data = zeros(n, obj.nCh);
            sq = GLOBAL_SQ_OBJ;
            if isempty(sq) || ~isvalid(sq)
                return;
            end
            try
                data_raw = sq.getEMG_data_TW_float(n);
            catch ME
                try GLOBAL_SQ_OBJ.disconnectBTdevice(); catch, end
                GLOBAL_SQ_OBJ = [];
                error('SQ connection lost (%s). Click Record again.', ME.message);
            end
            c = min(obj.nCh, size(data_raw, 2));
            data(:, 1:c) = data_raw(:, 1:c);
        end

        function stop(obj)
            obj.disconnect();
        end

        function disconnect(obj)
            global GLOBAL_SQ_OBJ;
            try GLOBAL_SQ_OBJ.disconnectBTdevice(); catch, end
            GLOBAL_SQ_OBJ = [];
            obj.objSQ = [];
        end
    end

    methods (Static)
        function [adapter, nCh, vCh] = configure(handles)
            choice = questdlg('Select Sessantaquattro+ Mode:', 'SQ+ Mode', ...
                '8 Channels (Bipolar)', '64 Channels (Matrix)', '8 Channels (Bipolar)');
            if isempty(choice), choice = '8 Channels (Bipolar)'; end

            if strcmp(choice, '64 Channels (Matrix)')
                set(handles.et_chs, 'String', '64');
                nCh = 64;
                srTarget = '2000';
            else
                set(handles.et_chs, 'String', '8');
                nCh = 8;
                srTarget = '1000';
            end

            % Sample rate must match the mode (1000 Hz bipolar / 2000 Hz matrix)
            srList = cellstr(get(handles.pm_sampleRate, 'String'));
            idxSR  = find(strcmp(srList, srTarget), 1);
            if isempty(idxSR)
                srList{end+1} = srTarget;
                set(handles.pm_sampleRate, 'String', srList);
                idxSR = numel(srList);
            end
            set(handles.pm_sampleRate, 'Value', idxSR);

            comList = cellstr(get(handles.ComPortType, 'String'));
            idxCOM  = find(strcmp(comList, 'COM'), 1);
            if ~isempty(idxCOM), set(handles.ComPortType, 'Value', idxCOM); end

            vCh = 1:nCh;
            adapter = SQPlusAdapter([], nCh);
        end
    end
end
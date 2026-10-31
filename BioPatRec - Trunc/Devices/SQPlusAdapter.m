classdef SQPlusAdapter < DeviceInterface
    properties
        objSQ
        nCh
        % electrodes.adapter = 'AD1x64SP' | 'AD2x32SP' | 'BIPOLAR'
        % electrodes.grid    = '8x8' | '13x5' | '4x8' | ''
        % electrodes.MULTIPLE_IN1 = legacy code ('BIG'|'SMALL'|'AD2x32SP'|'BIPOLAR')
        % Any struct assigned here is normalized (old format accepted).
        electrodes = struct()
        display    = 'image'       % 'image' | 'session_map' | 'session_plain'
    end
    methods
        function obj = SQPlusAdapter(objSQ, nCh)
            obj.objSQ = objSQ;
            obj.nCh   = nCh;
            obj.electrodes = struct();      % triggers the default for this nCh
        end

        function set.electrodes(obj, v)
            obj.electrodes = SQPlusAdapter.fixElectrodes(v, obj.nCh);
        end

        function L = layout(obj)
            el = SQPlusAdapter.fixElectrodes(obj.electrodes, obj.nCh);
            L = SQ_GridLayout(el.adapter, el.grid);
        end

        function s = electrodeLabel(obj)
            % Text saved in the recording, e.g. 'AD1x64SP 8x8'
            el = SQPlusAdapter.fixElectrodes(obj.electrodes, obj.nCh);
            if isempty(el.grid)
                s = el.adapter;
            else
                s = [el.adapter ' ' el.grid];
            end
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
                    fprintf('[SQ] Adapter creating 64-channel Matrix connection (%s)...\n', ...
                            obj.electrodeLabel());
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

        function flush(obj) %#ok<MANU>
            global GLOBAL_SQ_OBJ;
            if ~isempty(GLOBAL_SQ_OBJ) && isvalid(GLOBAL_SQ_OBJ) ...
                    && ~isempty(GLOBAL_SQ_OBJ.srv)
                GLOBAL_SQ_OBJ.flushInput();
            end
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
            % Adapter / grid are normally chosen in GUI_AFEselection via
            % SQ_SelectElectrodes. Here we read them; if missing, ask now.
            el = [];
            if isfield(handles,'SQElectrodes') && isstruct(handles.SQElectrodes) ...
                    && ~isempty(fieldnames(handles.SQElectrodes))
                nHint = 64;
                if isfield(handles,'nCh') && isequal(handles.nCh, 8), nHint = 8; end
                el = SQPlusAdapter.fixElectrodes(handles.SQElectrodes, nHint);
            elseif isfield(handles,'nCh') && isequal(handles.nCh, 8)
                el = SQPlusAdapter.fixElectrodes(struct(), 8);
            end

            if isempty(el)
                [el, ~, ok] = SQ_SelectElectrodes();
                if ~ok, el = SQPlusAdapter.fixElectrodes(struct(), 8); end
                el = SQPlusAdapter.fixElectrodes(el, 8);
            end

            if strcmp(el.adapter, 'BIPOLAR'), nCh = 8; else, nCh = 64; end

            if nCh == 64, srTarget = '2000'; else, srTarget = '1000'; end
            set(handles.et_chs, 'String', num2str(nCh));

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
            adapter.electrodes = el;
            if isfield(handles,'SQDisplay'), adapter.display = handles.SQDisplay; end
        end

        function el = fixElectrodes(v, nCh)
            % Accepts the new struct (adapter/grid), the legacy struct
            % (MULTIPLE_IN1 = BIG | SMALL | AD2x32SP | BIPOLAR) or empty.
            % Always returns a struct with adapter, grid, MULTIPLE_IN1.
            el = [];
            if isstruct(v) && ~isempty(v)
                if isfield(v,'adapter') && ~isempty(v.adapter)
                    el = struct('adapter', v.adapter, 'grid', '');
                    if isfield(v,'grid') && ~isempty(v.grid), el.grid = v.grid; end
                    if strcmp(el.adapter,'AD1x64SP') && isempty(el.grid), el.grid = '8x8'; end
                    if strcmp(el.adapter,'AD2x32SP'), el.grid = '4x8'; end
                    if strcmp(el.adapter,'BIPOLAR'),  el.grid = '';    end
                elseif isfield(v,'MULTIPLE_IN1') && ~isempty(v.MULTIPLE_IN1)
                    switch upper(v.MULTIPLE_IN1)
                        case 'BIG',      el = struct('adapter','AD1x64SP','grid','8x8');
                        case 'SMALL',    el = struct('adapter','AD1x64SP','grid','13x5');
                        case 'AD2X32SP', el = struct('adapter','AD2x32SP','grid','4x8');
                        case 'BIPOLAR',  el = struct('adapter','BIPOLAR','grid','');
                    end
                end
            end
            if isempty(el)                       % nothing usable: default per mode
                if nargin >= 2 && isequal(nCh, 8)
                    el = struct('adapter','BIPOLAR','grid','');
                else
                    el = struct('adapter','AD1x64SP','grid','8x8');
                end
            end
            el.MULTIPLE_IN1 = SQPlusAdapter.legacyCode(el.adapter, el.grid);
        end

        function c = legacyCode(adapter, grid)
            switch adapter
                case 'AD1x64SP', if strcmp(grid,'13x5'), c = 'SMALL'; else, c = 'BIG'; end
                case 'AD2x32SP', c = 'AD2x32SP';
                otherwise,       c = 'BIPOLAR';
            end
        end
    end
end
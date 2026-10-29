classdef LimbMateAdapter < DeviceInterface
    properties
        objLM
        nCh
        sF
        modeChoice = 'Differential (Bipolar)';
        tWs = 100;
    end
    methods
        function obj = LimbMateAdapter(objLM, nCh, sF)
            obj.objLM = objLM; obj.nCh = nCh; obj.sF = sF;
        end

        function start(obj, cfg)
            obj.objLM.enable_testmode = 0;
            obj.objLM.setSampleFreqGain(obj.sF, 2);
            choice = questdlg('Select LimbMATE hardware mode:', 'LimbMATE Mode', ...
                'Differential (Bipolar)', 'Pre-amplified ', 'Differential (Bipolar)');
            if isempty(choice), choice = 'Differential (Bipolar)'; end
            obj.modeChoice = choice;
            if isfield(cfg,'tWs') && ~isempty(cfg.tWs), obj.tWs = cfg.tWs; end
            obj.applyMode();
            obj.beginAcquisition();
        end

        function applyMode(obj)
            if strcmp(obj.modeChoice, 'Pre-amplified ')
                obj.objLM.setElectrodesConfig("Pre-amplified");
            else
                obj.objLM.setElectrodesConfig("Differential");
            end
        end

               function beginAcquisition(obj)
            % Firmware expects samples_tw_encoded = 1 (for 100 samples) or 2 (for 200).
            % uint8(obj.tWs) was sending 100, which the firmware rejects as invalid,
            % causing it to stream nothing and the recording loop to spin at max speed.
            obj.objLM.startAcquisitionEMG(1, uint8(255), uint8(1), uint8(0));
            obj.objLM.packages_per_TW           = obj.tWs / 5;
            obj.objLM.packages_per_TW_increment = obj.tWs / 5;
        end

        function data = read(obj, n)
            if ~obj.objLM.emg_acquisition
                fprintf('[LM] Acquisition was stopped, restarting...\n');
                try, flush(obj.objLM.serialObj); catch, end
                pause(0.3);
                obj.beginAcquisition();
            end
            data_raw = obj.objLM.getEMG_data_TW_float(n);
            if size(data_raw,1) == obj.nCh && size(data_raw,2) == n
                data = data_raw';
            else
                data = data_raw;
            end
        end

        function stop(obj)
            try, obj.objLM.stopAcquisitionEMG(); catch, end
        end

        function disconnect(obj)
            try, obj.objLM.disconnectBTdevice(); delete(obj.objLM.serialObj); catch, end
        end
    end
    methods (Static)
        function [adapter, nCh, vCh] = configure(handles)
            if ~isfield(handles,'objLM') || isempty(handles.objLM)
                error('LimbMate not connected. Please try again.');
            end
            nCh = 8; vCh = 1:8;
            adapter = LimbMateAdapter(handles.objLM, nCh, 1000);
        end
    end
end
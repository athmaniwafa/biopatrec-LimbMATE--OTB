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
            
            % --- GUI MODE SELECTION ---
            choice = questdlg('Select LimbMATE hardware mode:', 'LimbMATE Mode', ...
                              'Differential (Bipolar)', 'Pre-amplified ', 'Differential (Bipolar)');
            
            if isempty(choice)
                choice = 'Differential (Bipolar)';
            end
            
            if strcmp(choice, 'Pre-amplified ')
                objLM.setElectrodesConfig("Pre-amplified");
                fprintf('[LM] Hardware set to Pre-amplified mode.\n');
            else
                objLM.setElectrodesConfig("Differential");
                fprintf('[LM] Hardware set to Differential (Bipolar) mode.\n');
            end
            
            if isfield(cfg, 'tWs') && ~isempty(cfg.tWs), tWs = cfg.tWs;
            else, tWs = 100; end
            
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
            try, obj.objLM.stopAcquisitionEMG(); catch, end
        end
        
        function disconnect(obj)
            try, obj.objLM.disconnectBTdevice(); delete(obj.objLM.serialObj); catch, end
        end
    end
    methods (Static)
        function [adapter, nCh, vCh] = configure(handles)
            % The dialog has already been opened by GUI_AFEselection.
            if ~isfield(handles, 'objLM') || isempty(handles.objLM)
                error('LimbMate not connected. Please try again.');
            end
            
            % NO GUI PARSING. NO sF PARSING. 
            % Just return the adapter with default 8 channels.
            nCh = 8; vCh = 1:8;
            
            % sF will be overwritten by FastRecordingSession/RecordingSession anyway
            adapter = LimbMateAdapter(handles.objLM, nCh, 1000);
        end
    end
end
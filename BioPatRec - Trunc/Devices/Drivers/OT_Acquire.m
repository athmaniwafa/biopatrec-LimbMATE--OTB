classdef OT_Acquire < handle
    % OT_Acquire
    % Handle class wrapping the OT Bioelettronica EMG-USB2+ device so
    % BioPatRec can use it exactly like it uses LimbMATE_BioPatRec.
    % Interface mirrors LimbMATE_BioPatRec:
    %   obj.startAcquisitionEMG(...)       -- starts streaming
    %   obj.getEMG_data_TW_float(N)        -- returns [N x Nch] single
    %   obj.stopAcquisitionEMG()           -- stops
    %   obj.disconnectBTdevice()           -- stops + closes
    %
    % Usage:
    %   ot = OT_Acquire('bipolar', 4, 30);    % mode, nBipolar, DurationSec
    %   ot = OT_Acquire('hd1');               % one 64-ch matrix
    %   ot = OT_Acquire('hd2');               % two 64-ch matrices

    properties
        mode        % 'bipolar' | 'hd' | 'mixed' | 'inputs'
        dev         % OTComm device object
        config      % struct from config_* helper
        Nch         % number of channels
        Fs          % sampling rate (2048 for EMG-USB2+)
        buffer
        readIndex = 1;
        writeIndex = 1;
        samplesAvailable = 0;
        bufferOverflow = false;
        listener
        stopped = false;
        started = false;
        deviceOpen = false;
        receivedSamples = 0;
        callbackError = [];
    end

    methods
        function obj = OT_Acquire(mode, nBipolar, DurationSec, electrodes)
            if nargin < 1, mode = 'bipolar';   end
            if nargin < 2, nBipolar = 4;       end
            if nargin < 3 || isempty(DurationSec)
                DurationSec = 60;
            end
            
            validateattributes(DurationSec, {'numeric'}, ...
                {'scalar','real','finite','positive'}, ...
                mfilename, 'DurationSec');
            if nargin < 4, electrodes = struct(); end

            % Fail loudly if OTBioLab+ is running
            [~,out] = system('tasklist | findstr /I "OTBioLab"');
            if ~isempty(strtrim(out))
                error('OT_Acquire: close OTBioLab+ before acquiring.');
            end

            % Load .NET assembly (safe to call repeatedly)
            NET.addAssembly('C:\Program Files\OT BioLab+\OTComm.dll');

            % Configure device
            obj.mode = lower(char(mode));
            
            switch obj.mode
            
                case 'bipolar'
                    [obj.dev, obj.config] = config_bipolar(nBipolar);

                case 'mixed'
                    [obj.dev, obj.config] = config_mixed(nBipolar, electrodes);
                case 'inputs'
                    [obj.dev, obj.config] = OTB400_ConfigureInputs(nBipolar);
            
                case 'hd'
            
                    if nargin < 4
                        error('Electrode configuration is required for HD.');
                    end
            
                    [obj.dev, obj.config] = config_hd(nBipolar, electrodes);
            
                otherwise
                    error('Unknown mode: %s', mode);
            
            end


            obj.Nch = double(obj.config.NumChannels);
            obj.Fs  = 2048;

            % Open + initialise
            obj.dev.NewDataAvailableEventsPerSecond = 16;
            try
                obj.dev.OpenDevice();
                obj.deviceOpen = true;
                obj.dev.InitializeDevice();
            catch ME
                % Also release a partially opened USB connection.
                try, obj.dev.CloseDevice(); catch, end
                obj.deviceOpen = false;
                rethrow(ME);
            end

            acquired = double(obj.dev.GetAcquiredChannels());
            obj.config.AcquiredChannels = acquired(:)';
            if numel(acquired) ~= obj.Nch
                if ismember(obj.mode, {'mixed','inputs'})
                    obj.dev.CloseDevice();
                    obj.deviceOpen = false;
                    error('OT_Acquire:MixedChannels', ...
                        'Mixed configuration requires %d channels; OTComm reports %d.', ...
                        obj.Nch, numel(acquired));
                end
                warning('OT_Acquire: expected %d channels, device reported %d.', ...
                    obj.Nch, numel(acquired));
            end

            % Preallocate internal buffer
            if strcmp(obj.mode,'inputs')
                try, OTB400_ChannelLayout(obj.config);
                catch ME, obj.disconnectBTdevice(); rethrow(ME); end
            end
            capacity = max(1, round(DurationSec * obj.Fs));
            obj.buffer = zeros(capacity, obj.Nch, 'single');
            
            obj.readIndex = 1;
            obj.writeIndex = 1;
            obj.samplesAvailable = 0;
            obj.bufferOverflow = false;
        end

        function startAcquisitionEMG(obj, varargin)
            % varargin ignored -- BioPatRec passes LM-style arguments.
            if obj.started, return; end
            % Each movement starts a fresh acquisition on the same device.
            if obj.stopped || ~obj.deviceOpen
                if obj.deviceOpen
                    obj.dev.CloseDevice();
                    obj.deviceOpen = false;
                end
                if strcmp(obj.mode, 'bipolar')
                    [obj.dev, obj.config] = config_bipolar(obj.Nch);
                elseif strcmp(obj.mode, 'mixed')
                    [obj.dev, obj.config] = config_mixed(obj.config.NumBipolar, obj.config.Electrodes);
                elseif strcmp(obj.mode, 'inputs')
                    [obj.dev, obj.config] = OTB400_ConfigureInputs(obj.config.InputSelection);
                else
                    [obj.dev, obj.config] = config_hd(obj.Nch, obj.config.Electrodes);
                end
                obj.dev.NewDataAvailableEventsPerSecond = 16;
                try
                    obj.dev.OpenDevice();
                    obj.deviceOpen = true;
                    obj.dev.InitializeDevice();
                catch ME
                    try, obj.dev.CloseDevice(); catch, end
                    obj.deviceOpen = false;
                    rethrow(ME);
                end
                if ismember(obj.mode, {'mixed','inputs'})
                    acquired = double(obj.dev.GetAcquiredChannels());
                    obj.config.AcquiredChannels = acquired(:)';
                    if numel(acquired) ~= obj.Nch
                        obj.dev.CloseDevice();
                        obj.deviceOpen = false;
                        error('OT_Acquire:MixedChannels', 'Unexpected mixed channel count after restart.');
                    end
                end
                if strcmp(obj.mode,'inputs')
                    try, OTB400_ChannelLayout(obj.config);
                    catch ME, obj.disconnectBTdevice(); rethrow(ME); end
                end
            end
            obj.readIndex = 1;
            obj.writeIndex = 1;
            obj.samplesAvailable = 0;
            obj.bufferOverflow = false;
            obj.receivedSamples = 0;
            obj.callbackError = [];
            obj.listener = addlistener(obj.dev, 'OnNewDataAvailable', @obj.onData);
            
            obj.stopped = false;
            obj.started = true;
            
            try
                obj.dev.StartAcquisition();
            catch ME
                obj.started = false;
                obj.stopped = true;
            
                try
                    delete(obj.listener);
                catch
                end
            
                obj.listener = [];
                rethrow(ME);
            end
        end

        function block = getEMG_data_TW_float(obj, N)
    
        if nargin < 2
            N = 256;
        end
    
        validateattributes(N, {'numeric'}, ...
            {'scalar','integer','positive'});
    
        if ~obj.started || obj.stopped
            error('OT_Acquire:Stopped','OT_Acquire: acquisition is not running.');
        end
    
        capacity = size(obj.buffer, 1);
    
        if N > capacity
            error('OT_Acquire: requested samples exceed buffer capacity.');
        end
    
        % Wait until N samples are available
        deadline = tic;
    
        while obj.samplesAvailable < N
            if obj.stopped || ~obj.started
                error('OT_Acquire:Stopped','OT_Acquire: acquisition was stopped.');
            end
            if ~isempty(obj.callbackError)
                callbackFailure = obj.callbackError;
                obj.disconnectBTdevice();
                rethrow(callbackFailure);
            end
    
            if obj.bufferOverflow
                error('OT_Acquire: buffer overflow.');
            end
    
            pause(0.005);
            if obj.stopped || ~obj.started
                error('OT_Acquire:Stopped','OT_Acquire: acquisition was stopped.');
            end

            % pause dispatches .NET callbacks, so recheck before timeout.
            if ~isempty(obj.callbackError)
                callbackFailure = obj.callbackError;
                obj.disconnectBTdevice();
                rethrow(callbackFailure);
            end
            if obj.samplesAvailable >= N, break; end
    
            if toc(deadline) > 2
                available = obj.samplesAvailable;
                received = obj.receivedSamples;
                obj.disconnectBTdevice();
                error('OT_Acquire:DataTimeout', ...
                    ['OT_Acquire: timeout waiting for %d samples ' ...
                     '(available: %d, received since start: %d). Connection closed.'], ...
                    N, available, received);
            end
    
        end
    
        if obj.bufferOverflow
            error('OT_Acquire: buffer overflow.');
        end
    
        % Read N samples, handling wraparound
        first = min(N, capacity - obj.readIndex + 1);
    
        block = zeros(N, obj.Nch, 'single');
    
        block(1:first, :) = ...
            obj.buffer(obj.readIndex:obj.readIndex+first-1, :);
    
        if first < N
            block(first+1:N, :) = obj.buffer(1:N-first, :);
        end
    
        % Update reading position
        obj.readIndex = mod(obj.readIndex - 1 + N, capacity) + 1;
    
        obj.samplesAvailable = obj.samplesAvailable - N;

end

        function flushInput(obj)
            % Call only between movements, never discard an active trial.
            obj.readIndex=obj.writeIndex;
            obj.samplesAvailable=0;
            obj.bufferOverflow=false;
        end

        function stopAcquisitionEMG(obj)
            if ~obj.started || obj.stopped, return; end
            try obj.dev.StopAcquisition(); catch, end
            try delete(obj.listener); obj.listener = []; catch, end
            obj.stopped = true;
            obj.started = false;
        end

        function disconnectBTdevice(obj)
            % Name kept for BioPatRec compatibility
            try obj.stopAcquisitionEMG(); catch, end
            if obj.deviceOpen
                try
                    obj.dev.CloseDevice();
                    obj.deviceOpen = false;
                catch ME
                    warning('OT_Acquire:CloseFailed', '%s', ME.message);
                end
            end
            obj.stopped = true;
        end

        function delete(obj)
            try obj.disconnectBTdevice(); catch, end
        end

        % ---- Event callback ----
        function onData(obj, ~, eventData)
            if obj.stopped || ~obj.started, return; end
            if ~isempty(obj.callbackError), return; end
            try

            D = eventData.Data;
            if double(D.channels) ~= obj.Nch
                error('OT_Acquire:PacketChannels', ...
                    'OTComm packet reports %d channels; configuration expects %d.', ...
                    double(D.channels),obj.Nch);
            end
            u = uint16(D.data16);  u = u(:);
            s = typecast(u, 'int16');  s = s(:);

            if ismember(obj.mode, {'mixed','inputs'}) && mod(numel(s), obj.Nch) ~= 0
                error('OT_Acquire:MixedFrame', ...
                    'OTComm packet contains %d values for %d mixed channels.', numel(s), obj.Nch);
            end

            nFrames = floor(numel(s) / obj.Nch);
            if nFrames < 1, return; end
            obj.receivedSamples = obj.receivedSamples + nFrames;

            % Check buffer overflow
            if obj.bufferOverflow
                return;
            end
            
            capacity = size(obj.buffer, 1);
            
            freeSpace = capacity - obj.samplesAvailable;
            
            if nFrames > freeSpace
                obj.bufferOverflow = true;
                return;
            end
            
            % Convert acquired data to [samples x channels]
            s = s(1:nFrames * obj.Nch);
            
            block = single(reshape(s, obj.Nch, nFrames)');
            
            % Write data in circular buffer
            first = min(nFrames, capacity - obj.writeIndex + 1);
            
            obj.buffer( ...
                obj.writeIndex:obj.writeIndex+first-1, :) = block(1:first, :);
            
            % Continue from beginning if necessary
            if first < nFrames
                obj.buffer(1:nFrames-first, :) = block(first+1:nFrames, :);
            end
            
            % Update writing position
            obj.writeIndex = mod(obj.writeIndex - 1 + nFrames, capacity) + 1;
            
            obj.samplesAvailable = obj.samplesAvailable + nFrames;
            catch ME
                % Propagate callback failures through the synchronous reader.
                % Stop/close there, outside the .NET event callback.
                obj.callbackError = ME;
            end

        end
    end
end

function [dev, config] = config_mixed(nBipolar, electrodes)
    % Initial hardware trial: one 64-channel grid plus IN1 bipolar channels.
    validateattributes(nBipolar, {'numeric'}, ...
        {'scalar','integer','>=',1,'<=',16});
    [dev, config] = config_hd(64, electrodes);
    adapter = OTComm.EMGUSB.AdapterInAD8x2JD;
    for ch = 1:nBipolar
        adapter.SetChannel(uint32(ch-1), OTComm.Sensors.SensorCDE(uint32(ch)));
    end
    dev.ConnectIn(uint32(0), adapter);
    config.NumChannels = 64 + nBipolar;
    config.NumBipolar = nBipolar;
    config.Type = 'Mixed';
    config.Input = 0;
    config.Model = 'EMG_USB2p_128';
    config.ChannelOrder = 'Native OTComm order; see AcquiredChannels. Verify experimentally.';
end

function [dev, config] = config_hd(nCh, electrodes)

    % Number of matrices
    if nCh == 64

        model = OTComm.EMGUSB.Models.EMG_USB2p_128;
        nMatrices = 1;

    elseif nCh == 128

        model = OTComm.EMGUSB.Models.EMG_USB2p_256;
        nMatrices = 2;

    else
        error('HD mode supports only 64 or 128 channels.');
    end

    % Device initialization
    freq = OTComm.EMGUSB.Frequencies.EMGUSB_2048Hz;

    dev = OTComm.EMGUSB.DataGeneratorEMGUSB(model, freq);

    % Electrode types selected in the GUI
    sensorTypes = {electrodes.MULTIPLE_IN1};

    if nMatrices == 2
        sensorTypes{2} = electrodes.MULTIPLE_IN2;
    end

    sensorNames = cell(1, nMatrices);

    % Configure each MULTIPLE input
    for k = 1:nMatrices

        [sensor, sensorNames{k}] = make_hd_sensor(sensorTypes{k});

        if double(sensor.Channels) ~= 64
            error('Invalid sensor on MULTIPLE IN%d', k);
        end

        adapter = OTComm.EMGUSB.AdapterMultipleInAD64;

        adapter.SetChannels(uint32(0), uint32(63), sensor);

        dev.ConnectMultipleIn(uint32(k-1), adapter);

    end

    % Save configuration
    config.NumChannels = nCh;
    config.Type = 'HD';
    config.NumMatrices = nMatrices;
    config.Sensor1 = sensorNames{1};
    config.MultipleIn1 = 0;

    if nMatrices == 2
        config.Sensor2 = sensorNames{2};
        config.MultipleIn2 = 1;
    end

    config.Electrodes = electrodes;

end


function [sensor, sensorName] = make_hd_sensor(electrodeType)
    switch upper(char(electrodeType))

        case 'BIG'

            sensor = OTComm.Sensors.SensorELSCH064NM3;
            sensorName = 'SensorELSCH064NM3';

        case 'SMALL'

            sensor = OTComm.Sensors.SensorELSCH064NM2;
            sensorName = 'SensorELSCH064NM2';

        otherwise

            error('Unknown electrode type: %s', electrodeType);

    end

end

classdef Sessantaquattro_Acquire < handle
    % Sessantaquattro_Acquire
    % Wrapper for the OT Bioelettronica Sessantaquattro+ over TCP.
    % Interface mirrors LimbMATE_BioPatRec and OT_Acquire so BioPatRec
    % can call it uniformly:
    %   obj.startAcquisitionEMG()
    %   obj.getEMG_data_TW_float(N)   -> [N x nCh] single
    %   obj.stopAcquisitionEMG()
    %   obj.disconnectBTdevice()
    %
    % Protocol based on the colleague's verified MVC acquisition script.

    properties
        t                    % tcpserver object
        Fs = 1000            % sample rate: 500, 1000, 2000, 4000 Hz
        nCh = 12             % channels delivered by the device
        nChUsed = 8          % channels BioPatRec actually reads (EMG only)
        port = 45454

        buffer               % [nBuffered x nChUsed] single
        writeIndex = 0
        bufferSize = 0

        stopped = false
        started = false

        % Config bits
        FSAMP_code = 1       % 0=500  1=1000  2=2000  3=4000
        NCH_code   = 0       % 0=8ch  1=16ch  2=32ch  3=64ch
        MODE       = 1       % 0=Mono 1=Bipolar 2=Differential 3=Accel
        HRES       = 0       % 0=16bit 1=24bit
        HPF        = 1       % 0=DC   1=High-pass
        EXTEN      = 0       % 0=std  1=x2  2=x4  3=x8
        ConvFact   = 0.000286;   % ADC counts to mV (16-bit)
    end

    methods
        function obj = Sessantaquattro_Acquire(nCh, durationSec, port)
            if nargin < 1 || isempty(nCh),         nCh = 12;         end
            if nargin < 2 || isempty(durationSec), durationSec = 60; end
            if nargin < 3 || isempty(port),        port = 45454;     end

            obj.port = port;

            % How many channels the device will send (NumChan from protocol)
            obj.nCh = obj.computeNumChan();
            % How many of those BioPatRec will actually read
            if nCh > 0 && nCh <= obj.nCh
                obj.nChUsed = nCh;
            else
                obj.nChUsed = obj.nCh;
            end

            % Sample rate from FSAMP code
            obj.Fs = obj.computeFs();

            % Preallocate internal buffer
            obj.bufferSize = round(durationSec * obj.Fs);
            obj.buffer = zeros(obj.bufferSize, obj.nChUsed, 'single');
            obj.writeIndex = 0;

            % Build the 16-bit config word
            cmd = obj.buildCommand();
            fprintf('[SQ] Opening TCP server on port %d...\n', port);
            fprintf('[SQ] Config: %d Hz, %d channels sent, %d used, mode=%d\n', ...
                obj.Fs, obj.nCh, obj.nChUsed, obj.MODE);
            fprintf('[SQ] Command word: dec=%d bin=%s\n', cmd, dec2bin(cmd, 16));

            % Open server and wait for device
            obj.t = tcpserver(port, "ByteOrder", "big-endian");
            obj.t.InputBufferSize = 500000;   % ~250 ms at 1000 Hz × 12 ch × 2 bytes

            fprintf('[SQ] Waiting for Sessantaquattro+ to connect...\n');
            while obj.t.Connected < 1
                pause(0.1);
            end
            fprintf('[SQ] Device connected.\n');

            % Send command
            fwrite(obj.t, cmd, 'int16');
            fprintf('[SQ] Command sent.\n');
        end

        function startAcquisitionEMG(obj, varargin)
            % varargin ignored — BioPatRec passes LM-style arguments
            if obj.started, return; end
            obj.started = true;
            obj.stopped = false;
            fprintf('[SQ] Streaming started.\n');
        end

        function block = getEMG_data_TW_float(obj, N)
            % Return next N samples as [N x nChUsed] single.
            if nargin < 2, N = 100; end

            % Bytes expected for one read block (approximate)
            bytesPerSample = 2 * obj.nCh;   % 16-bit, all channels
            bytesNeeded = N * bytesPerSample;

            deadline = tic;
            while obj.t.BytesAvailable < bytesNeeded
                pause(0.005);
                if toc(deadline) > 3
                    warning('[SQ] Timeout waiting for %d bytes (have %d).', ...
                        bytesNeeded, obj.t.BytesAvailable);
                    break;
                end
            end

            % Read available complete frames
            nFramesAvailable = floor(obj.t.BytesAvailable / bytesPerSample);
            nRead = min(N, nFramesAvailable);

            if nRead < 1
                block = zeros(N, obj.nChUsed, 'single');
                return
            end

            raw = fread(obj.t, [obj.nCh, nRead], 'int16');   % [nCh x nRead]
            block = single(raw(1:obj.nChUsed, :)') * obj.ConvFact;  % [nRead x nChUsed]
            if nRead < N
                block = [block; zeros(N - nRead, obj.nChUsed, 'single')];
            end
        end

        function stopAcquisitionEMG(obj)
            if ~obj.started || obj.stopped, return; end
            try
                % Send stop command (GO=0, REC=0, all else same)
                stopCmd = obj.buildCommand(0, 0);
                fwrite(obj.t, stopCmd, 'int16');
            catch
            end
            pause(0.3);
            try
                clear obj.t
            catch
            end
            obj.stopped = true;
            obj.started = false;
            fprintf('[SQ] Streaming stopped.\n');
        end

        function disconnectBTdevice(obj)
            % Named for BioPatRec compatibility
            try obj.stopAcquisitionEMG(); catch, end
            fprintf('[SQ] Device disconnected.\n');
        end

        function delete(obj)
            try obj.disconnectBTdevice(); catch, end
        end
    end

    methods (Access = private)
        function cmd = buildCommand(obj, GO, REC)
            if nargin < 2 || isempty(GO),  GO = 1;  end
            if nargin < 3 || isempty(REC), REC = 0; end

            cmd = 0;
            cmd = cmd + GO;
            cmd = cmd + REC * 2;
            cmd = cmd + 0 * 4;                % TRIG
            cmd = cmd + obj.EXTEN * 16;
            cmd = cmd + obj.HPF * 64;
            cmd = cmd + obj.HRES * 128;
            cmd = cmd + obj.MODE * 256;
            cmd = cmd + obj.NCH_code * 2048;
            cmd = cmd + obj.FSAMP_code * 8192;
        end

        function n = computeNumChan(obj)
            % From colleague's lookup table
            if obj.MODE == 1   % Bipolar
                switch obj.NCH_code
                    case 0, n = 12;
                    case 1, n = 16;
                    case 2, n = 24;
                    case 3, n = 40;
                end
            else               % Monopolar / Differential / Accel
                switch obj.NCH_code
                    case 0, n = 16;
                    case 1, n = 24;
                    case 2, n = 40;
                    case 3, n = 72;
                end
            end
        end

        function f = computeFs(obj)
            switch obj.FSAMP_code
                case 0, f = 500;
                case 1, f = 1000;
                case 2, f = 2000;
                case 3, f = 4000;
                otherwise, f = 1000;
            end
        end
    end
end
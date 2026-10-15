classdef Sessantaquattro_Acquire < handle
    % Sessantaquattro_Acquire
    % Wrapper for the OT Bioelettronica Sessantaquattro+ over TCP.
    % Interface mirrors LimbMATE_BioPatRec and OT_Acquire so BioPatRec
    % can call it uniformly:
    %   obj.startAcquisitionEMG()
    %   obj.getEMG_data_TW_float(N)   -> [N x nCh] single
    %   obj.stopAcquisitionEMG()
    %   obj.disconnectBTdevice()

    properties
        serverSocket
        clientSocket
        in
        out

        Fs = 2000            % fixed per the Sessantaquattro+ config
        nCh = 16             % bio channels (CH1..CH16)
        port = 45454

        buffer               % [nBuffered x nCh] single
        writeIndex = 0
        bufferSize = 0

        timerObj
        stopped = false
        started = false
    end

    methods
        function obj = Sessantaquattro_Acquire(nCh, durationSec, port)
            if nargin < 1 || isempty(nCh),         nCh = 16;         end
            if nargin < 2 || isempty(durationSec), durationSec = 60; end
            if nargin < 3 || isempty(port),        port = 45454;     end

            obj.nCh = nCh;
            obj.port = port;

            % Preallocate an internal buffer
            obj.bufferSize = round(durationSec * obj.Fs);
            obj.buffer = zeros(obj.bufferSize, obj.nCh, 'single');
            obj.writeIndex = 0;

            % ----- Open TCP server -----
            import java.net.ServerSocket
            fprintf('[SQ] Opening TCP server on port %d...\n', port);
            try
                obj.serverSocket = java.net.ServerSocket(port);
                obj.serverSocket.setReuseAddress(true);
            catch ME
                error('Sessantaquattro: cannot bind port %d — %s', port, ME.message);
            end

            fprintf('[SQ] Waiting for Sessantaquattro+ to connect...\n');
            obj.clientSocket = obj.serverSocket.accept();
            fprintf('[SQ] Device connected.\n');

            obj.out = java.io.DataOutputStream(obj.clientSocket.getOutputStream());
            obj.in  = java.io.DataInputStream(obj.clientSocket.getInputStream());

            % Send config: 0x48 (SET, 2000 Hz, 16ch, Monopolar)
            %              0x01 (16-bit, no HPF, GO)
            obj.out.writeByte(0x48); obj.out.flush();
            pause(0.1);
            obj.out.writeByte(0x01); obj.out.flush();
            fprintf('[SQ] Config sent (0x48 0x01).\n');
        end

        function startAcquisitionEMG(obj, varargin)
            % varargin ignored — BioPatRec passes LM-style arguments
            if obj.started, return; end

            % Use a MATLAB timer to poll the socket every 20 ms
            obj.timerObj = timer( ...
                'ExecutionMode', 'fixedSpacing', ...
                'Period', 0.02, ...
                'TimerFcn', @(~,~) obj.pollSocket(), ...
                'ErrorFcn', @(~,~) fprintf('[SQ] Timer error\n'));
            start(obj.timerObj);

            obj.started = true;
            obj.stopped = false;
            fprintf('[SQ] Streaming started.\n');
        end

        function block = getEMG_data_TW_float(obj, N)
            % Return next N samples as [N x nCh] single.
            if nargin < 2, N = 100; end

            % Wait for enough samples
            deadline = tic;
            while obj.writeIndex < N
                pause(0.005);
                if toc(deadline) > 3
                    warning('[SQ] Timeout waiting for %d samples (have %d).', ...
                        N, obj.writeIndex);
                    break
                end
            end

            nTake = min(N, obj.writeIndex);
            block = zeros(N, obj.nCh, 'single');
            if nTake > 0
                block(1:nTake, :) = obj.buffer(1:nTake, :);
                remaining = obj.writeIndex - nTake;
                if remaining > 0
                    obj.buffer(1:remaining, :) = obj.buffer(nTake+1:obj.writeIndex, :);
                end
                obj.writeIndex = remaining;
            end
        end

        function stopAcquisitionEMG(obj)
            if ~obj.started || obj.stopped, return; end
            try stop(obj.timerObj);   catch, end
            try delete(obj.timerObj); catch, end
            try
                if obj.out, obj.out.writeByte(0x00); obj.out.flush(); end
            catch, end
            obj.stopped = true;
            obj.started = false;
            fprintf('[SQ] Streaming stopped.\n');
        end

        function disconnectBTdevice(obj)
            % Named for BioPatRec compatibility
            try obj.stopAcquisitionEMG(); catch, end
            try obj.in.close();             catch, end
            try obj.out.close();            catch, end
            try obj.clientSocket.close();   catch, end
            try obj.serverSocket.close();   catch, end
            fprintf('[SQ] Device disconnected.\n');
        end

        function delete(obj)
            try obj.disconnectBTdevice(); catch, end
        end
    end

    methods (Access = private)
        function pollSocket(obj)
            if obj.stopped, return; end
            try
                n = obj.in.available();
                if n < 48, return; end

                % Read available bytes
                raw = zeros(1, n, 'uint8');
                for i = 1:n
                    raw(i) = obj.in.readUnsignedByte();
                end

                % Parse into frames
                frameSize = 48;
                nFrames = floor(n / frameSize);
                if nFrames < 1, return; end
                raw = raw(1 : nFrames*frameSize);
                F = reshape(raw, frameSize, nFrames)';

                % Decode bio channels (bytes 0-31)
                block = zeros(nFrames, obj.nCh, 'single');
                for ch = 1:obj.nCh
                    idx = (ch-1)*2 + 1;
                    u = double(F(:, idx)) * 256 + double(F(:, idx+1));
                    s = u;
                    s(s > 32767) = s(s > 32767) - 65536;
                    block(:, ch) = single(s);
                end

                % Append to buffer
                spaceLeft = obj.bufferSize - obj.writeIndex;
                nTake = min(nFrames, spaceLeft);
                if nTake <= 0, return; end
                obj.buffer(obj.writeIndex+1 : obj.writeIndex+nTake, :) = block(1:nTake, :);
                obj.writeIndex = obj.writeIndex + nTake;
            catch ME
                fprintf('[SQ] pollSocket error: %s\n', ME.message);
            end
        end
    end
end

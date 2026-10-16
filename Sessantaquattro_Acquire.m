classdef Sessantaquattro_Acquire < handle
    % Sessantaquattro_Acquire
    % Wrapper for the Sessantaquattro+ over TCP.
    % Sends the 16-bit command word (matching colleague's working script).
    % Uses Java sockets (no Instrument Control Toolbox required).

    properties
        serverSocket
        clientSocket
        in
        out

        Fs = 1000
        nCh = 12             % total channels sent (8 EMG + 4 aux)
        nChUsed = 8          % channels BioPatRec reads
        port = 45454

        stopped = false
        started = false

        ConvFact = 0.000286;
    end

    methods
        function obj = Sessantaquattro_Acquire(nCh, durationSec, port)
            if nargin < 1 || isempty(nCh),         nCh = 8;         end
            if nargin < 2 || isempty(durationSec), durationSec = 60; end
            if nargin < 3 || isempty(port),        port = 45454;     end

            obj.port = port;
            obj.nChUsed = min(nCh, obj.nCh);

            % Build 16-bit command word = 8513
            %   GO=1, HPF=1, MODE=1 (bipolar), NCH=0 (8ch), FSAMP=1 (1000Hz)
            GO    = 1;
            REC   = 0;
            TRIG  = 0;
            EXTEN = 0;
            HPF   = 1;
            HRES  = 0;
            MODE  = 1;
            NCH   = 0;
            FSAMP = 1;

            cmd = GO + REC*2 + TRIG*4 + EXTEN*16 + HPF*64 + HRES*128 ...
                + MODE*256 + NCH*2048 + FSAMP*8192;

            fprintf('[SQ] Command word: %d (bin=%s)\n', cmd, dec2bin(cmd,16));

            import java.net.ServerSocket
            fprintf('[SQ] Opening TCP server on port %d...\n', port);
            try
                obj.serverSocket = java.net.ServerSocket(port);
                obj.serverSocket.setReuseAddress(true);
            catch ME
                error('SQ: cannot bind port %d — %s', port, ME.message);
            end

            fprintf('[SQ] Waiting for Sessantaquattro+...\n');
            obj.clientSocket = obj.serverSocket.accept();
            fprintf('[SQ] Device connected.\n');

            obj.out = java.io.DataOutputStream(obj.clientSocket.getOutputStream());
            obj.in  = java.io.DataInputStream(obj.clientSocket.getInputStream());

            % Send 16-bit big-endian command
            obj.out.writeShort(int16(cmd));
            obj.out.flush();
            fprintf('[SQ] Command sent.\n');
        end

        function startAcquisitionEMG(obj, varargin)
            if obj.started, return; end
            obj.started = true;
            obj.stopped = false;
            fprintf('[SQ] Streaming started.\n');
        end

        function block = getEMG_data_TW_float(obj, N)
            if nargin < 2, N = 100; end

            bytesPerSample = 2 * obj.nCh;   % 24 bytes for 12 ch
            bytesNeeded = N * bytesPerSample;

            deadline = tic;
            while obj.in.available() < bytesNeeded
                pause(0.02);
                if toc(deadline) > 3
                    break;
                end
            end

            availNow = obj.in.available();
            nFramesAvailable = floor(availNow / bytesPerSample);
            nRead = min(N, nFramesAvailable);

            block = zeros(N, obj.nChUsed, 'single');
            if nRead < 1, return; end

            for i = 1:nRead
                for ch = 1:obj.nCh
                    raw = obj.in.readShort();
                    if ch <= obj.nChUsed
                        block(i, ch) = single(raw) * obj.ConvFact;
                    end
                end
            end
        end

        function stopAcquisitionEMG(obj)
            if ~obj.started || obj.stopped, return; end
            try
                % Stop command = GO=0, rest same
                stopCmd = 0 + 1*64 + 1*256 + 0*2048 + 1*8192;
                obj.out.writeShort(int16(stopCmd));
                obj.out.flush();
            catch
            end
            pause(0.3);
            try obj.in.close();           catch, end
            try obj.out.close();          catch, end
            try obj.clientSocket.close(); catch, end
            try obj.serverSocket.close(); catch, end
            obj.stopped = true;
            obj.started = false;
            fprintf('[SQ] Streaming stopped.\n');
        end

        function disconnectBTdevice(obj)
            try obj.stopAcquisitionEMG(); catch, end
            fprintf('[SQ] Device disconnected.\n');
        end

        function delete(obj)
            try obj.disconnectBTdevice(); catch, end
        end
    end
end
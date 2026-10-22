classdef Sessantaquattro_Acquire < handle
    properties
        serverSocket
        clientSocket
        in
        out

        Fs = 1000
        nCh = 12             % 12 for 8ch, 72 for 64ch
        nChUsed = 8          % 8 or 64
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
            obj.nChUsed = nCh;
            
            % Configure hardware for 8ch or 64ch
            if nCh == 64
                obj.nCh = 72; 
                NCH = 3;      % 64 channels
                MODE = 0;     % Monopolar (Matrix)
            else
                obj.nCh = 12; 
                NCH = 0;      % 8 channels
                MODE = 1;     % Bipolar
            end

            % Build 16-bit command word
            GO    = 1;
            REC   = 0;
            TRIG  = 0;
            EXTEN = 0;
            HPF   = 1;
            HRES  = 0;
            FSAMP = 0;

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

            obj.out.writeShort(int16(cmd));
            obj.out.flush();
            fprintf('[SQ] Command sent.\n');
            
            obj.started = true;
            obj.stopped = false;
        end

        function startAcquisitionEMG(obj, varargin)
            if obj.started && ~obj.stopped
                try
                    if obj.nChUsed == 64, NCH = 3; MODE = 0; else, NCH = 0; MODE = 1; end
                    cmd = 1 + 64 + MODE*256 + NCH*2048 + 8192;
                    obj.out.writeShort(int16(cmd));
                    obj.out.flush();
                    fprintf('[SQ] Streaming started.\n');
                catch
                end
            end
        end

                        function block = getEMG_data_TW_float(obj, N)
            if nargin < 2, N = 100; end

            % For Matrix (64ch), the hardware sends 72 channels total.
            % We MUST read all 72 to keep the TCP buffer aligned.
            if obj.nChUsed == 64
                totalCh = 72;
            else
                totalCh = 12;
            end
            
            bytesPerSample = 2 * totalCh;
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
                for ch = 1:totalCh
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
                if obj.nChUsed == 64, NCH = 3; MODE = 0; else, NCH = 0; MODE = 1; end
                stopCmd = 0 + 64 + MODE*256 + NCH*2048 + 8192;
                obj.out.writeShort(int16(stopCmd));
                obj.out.flush();
                fprintf('[SQ] Stop command sent.\n');
            catch
            end
            obj.stopped = true;
        end

        function disconnectBTdevice(obj)
            if isempty(obj.serverSocket), return; end
            try obj.stopAcquisitionEMG(); catch, end
            try obj.in.close();           catch, end
            try obj.out.close();          catch, end
            try obj.clientSocket.close(); catch, end
            try obj.serverSocket.close(); catch, end
            try
                obj.serverSocket = [];
                obj.clientSocket = [];
                java.lang.System.gc(); 
            catch
            end
            obj.started = false;
            obj.stopped = false;
            fprintf('[SQ] Device disconnected.\n');
        end
    end
end
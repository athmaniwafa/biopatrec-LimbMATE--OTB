classdef Sessantaquattro_Acquire < handle
    % Sessantaquattro+ acquisition over TCP (PC = server, device = client).
    % Uses tcpserver (R2020b+).
    %
    %   nCh = 8  : Bipolar (16 electrodes -> 8 channels), 1000 Hz, 16 words
    %              1-8 EMG | 9-10 AUX | 11-14 IMU | 15 accessory | 16 counter
    %              (NCH = 1; counter position must be verified: it must
    %               increase by 1 per sample, see the debug print)
    %   nCh = 64 : Matrix (monopolar), 2000 Hz, 72 words
    %              1-64 bio | 65-66 AUX | 67-70 IMU | 71 accessory | 72 counter
    %
    % Samples are 16 bit big endian. Command word:
    %   GO + REC*2 + TRIG*4 + EXTEN*16 + HPF*64 + HRES*128 + MODE*256
    %      + NCH*2048 + FSAMP*8192
    properties
        srv
        Fs      = 1000
        nChHW   = 16
        nChUsed = 8
        port    = 45454

        stopped = false
        started = false

        ConvFact = 0.0002861        % mV per LSB (286.1 nV)

        startBytes = uint8([0 0])
        stopBytes  = uint8([0 0])
        checkCounter = true

        leftover    = zeros(0,1,"uint8")
        sampleBuf   = zeros(0,8,"single")
        lastCnt     = []
        lostSamples = 0
        dbgCalls    = 0
        dbgLast     = []
        restartCount = 0
    end

    methods
        function obj = Sessantaquattro_Acquire(nCh, durationSec, port, connectTimeoutSec)
            if nargin < 1 || isempty(nCh),                nCh = 8;                end
            if nargin < 2 || isempty(durationSec),        durationSec = 60;       end %#ok<NASGU>
            if nargin < 3 || isempty(port),               port = 45454;           end
            if nargin < 4 || isempty(connectTimeoutSec),  connectTimeoutSec = 60; end

            if ~ismember(nCh, [8 64])
                error('SQ: nCh must be 8 (bipolar) or 64 (matrix), got %d.', nCh);
            end

            obj.port      = port;
            obj.nChUsed   = nCh;
            obj.sampleBuf = zeros(0, nCh, "single");

            if nCh == 64
                obj.nChHW = 72;  obj.Fs = 2000;
                MODE = 0;  NCH = 3;  FSAMP = 2;
                modeName = 'Matrix 64ch, 2000 Hz';
            else
                obj.nChHW = 16;  obj.Fs = 1000;
                MODE = 1;  NCH = 1;  FSAMP = 1;     % NCH=1 -> 8 bipolar channels
                modeName = 'Bipolar 8ch (16 electrodes), 1000 Hz';
            end
            obj.checkCounter = true;
            obj.startBytes = Sessantaquattro_Acquire.cmdBytes(1, MODE, NCH, FSAMP);
            obj.stopBytes  = Sessantaquattro_Acquire.cmdBytes(0, MODE, NCH, FSAMP);

            fprintf('[SQ] Mode: %s | start = [%d %d] (hex %02X %02X)\n', modeName, ...
                    obj.startBytes(1), obj.startBytes(2), obj.startBytes(1), obj.startBytes(2));

            fprintf('[SQ] Opening TCP server on port %d...\n', port);
            try
                obj.srv = tcpserver("0.0.0.0", port, "Timeout", 10);
            catch ME
                error('SQ: cannot open port %d - %s', port, ME.message);
            end

            fprintf('[SQ] Waiting for Sessantaquattro+ (max %d s)...\n', connectTimeoutSec);
            t0 = tic;
            while ~obj.srv.Connected
                pause(0.1);
                if toc(t0) > connectTimeoutSec
                    obj.srv = [];
                    error('SQ: device did not connect within %d s. Check Wi-Fi and server IP.', connectTimeoutSec);
                end
            end
            fprintf('[SQ] Device connected.\n');

            write(obj.srv, obj.startBytes, "uint8");
            fprintf('[SQ] Start command sent.\n');
            obj.started = true;
            obj.stopped = false;
        end

        function startAcquisitionEMG(obj, varargin) %#ok<INUSD>
            % Constructor already sent the start command.
        end

        function flushInput(obj)
            % Drop whole frames only, keep the incomplete tail (alignment).
            fb = 2*obj.nChHW;
            n  = obj.srv.NumBytesAvailable;
            if n > 0
                data = [obj.leftover; obj.readBytes(n)];
                nFr  = floor(numel(data)/fb);
                obj.leftover = data(nFr*fb+1:end);
            end
            obj.sampleBuf = zeros(0, obj.nChUsed, "single");
            obj.lastCnt   = [];
        end

        function block = getEMG_data_TW_float(obj, N)
            % Exactly N consecutive samples [N x nChUsed] in mV.
            if nargin < 2, N = 100; end

            t0 = tic;
            while size(obj.sampleBuf,1) < N
                obj.pullFrames();
                if size(obj.sampleBuf,1) >= N, break; end
                pause(0.002);
                if toc(t0) > N/obj.Fs + 3
                    if obj.restartCount < 2
                        warning('SQ:stall', ['Stream stalled (%d/%d samples). ' ...
                                'Restarting acquisition: a gap will be in the data.'], ...
                                size(obj.sampleBuf,1), N);
                        obj.restartStream();
                        t0 = tic;
                    else
                        error('SQ: timeout, only %d/%d samples received.', ...
                              size(obj.sampleBuf,1), N);
                    end
                end
            end

            block = obj.sampleBuf(1:N, :);
            obj.sampleBuf(1:N, :) = [];

            if obj.dbgCalls < 3
                obj.dbgCalls = obj.dbgCalls + 1;
                m = mean(abs(block), 1);
                fprintf(['[SQ] block %d: %d x %d | mean|x| min/med/max = ' ...
                         '%.5f / %.5f / %.5f mV | last counter word(%d) = %d\n'], ...
                        obj.dbgCalls, size(block,1), size(block,2), ...
                        min(m), median(m), max(m), obj.nChHW, ...
                        obj.dbgLast(obj.nChHW));
            end

            if size(obj.sampleBuf,1) > 5*obj.Fs
                warning('SQ:latency', ['Processing is slower than acquisition: ' ...
                        '%.1f s of data waiting. Device buffer may overflow.'], ...
                        size(obj.sampleBuf,1)/obj.Fs);
            end
        end

        function stopAcquisitionEMG(obj)
            if ~obj.started || obj.stopped, return; end
            try
                write(obj.srv, obj.stopBytes, "uint8");
                fprintf('[SQ] Stop command sent.\n');
            catch
            end
            obj.stopped = true;
        end

        function disconnectBTdevice(obj)
            if isempty(obj.srv), return; end
            try obj.stopAcquisitionEMG(); catch, end
            pause(0.2);
            obj.srv       = [];
            obj.leftover  = zeros(0,1,"uint8");
            obj.sampleBuf = zeros(0, obj.nChUsed, "single");
            obj.started = false;
            obj.stopped = false;
            fprintf('[SQ] Device disconnected. Lost samples this session: %d\n', obj.lostSamples);
        end
    end

    methods (Access = private)
        function restartStream(obj)
            obj.restartCount = obj.restartCount + 1;
            try write(obj.srv, obj.stopBytes, "uint8"); catch, end
            pause(0.3);
            try
                n = obj.srv.NumBytesAvailable;
                if n > 0, read(obj.srv, n, "uint8"); end
            catch
            end
            obj.leftover  = zeros(0,1,"uint8");
            obj.lastCnt   = [];
            write(obj.srv, obj.startBytes, "uint8");
            fprintf('[SQ] Stream restarted (%d).\n', obj.restartCount);
        end

        function pullFrames(obj)
            fb = 2*obj.nChHW;
            n  = obj.srv.NumBytesAvailable;
            if n < 1, return; end

            data = [obj.leftover; obj.readBytes(n)];
            nFr  = floor(numel(data)/fb);
            obj.leftover = data(nFr*fb+1:end);
            if nFr < 1, return; end

            b = double(reshape(data(1:nFr*fb), fb, nFr));
            U = b(1:2:end,:)*256 + b(2:2:end,:);            % unsigned 16 bit
            S = U; S(S >= 32768) = S(S >= 32768) - 65536;   % two's complement
            obj.dbgLast = S(:,end);

            if obj.checkCounter
                cnt  = U(obj.nChHW, :);
                d    = mod(diff([obj.lastCnt cnt]), 65536);
                lost = sum(max(d-1, 0));
                if lost > 0
                    obj.lostSamples = obj.lostSamples + lost;
                    warning('SQ:lost', 'Lost %d samples (counter jump).', lost);
                end
                obj.lastCnt = cnt(end);
            end

            bio = single(S(1:obj.nChUsed, :)' * obj.ConvFact);
            obj.sampleBuf = [obj.sampleBuf; bio];
        end

        function raw = readBytes(obj, n)
            raw = read(obj.srv, n, "uint8");
            raw = raw(:);
        end
    end

    methods (Static, Access = private)
        function b = cmdBytes(GO, MODE, NCH, FSAMP)
            HPF = 1;
            cmd = GO + HPF*64 + MODE*256 + NCH*2048 + FSAMP*8192;
            b   = uint8([bitshift(cmd, -8), bitand(cmd, 255)]);
        end
    end
end
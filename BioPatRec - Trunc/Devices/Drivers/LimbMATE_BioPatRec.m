classdef LimbMATE_BioPatRec < LimbMATE
    % LimbMATE_BioPatRec
    % Strict recording adapter. Original GUI/feature streaming stays in LimbMATE.

    properties
        streamIntegrity = [];
        recoveryDirectory = '';
        recoveryPath = '';
        streamReadTimeout = 3;
    end
    properties (Access = private)
        recoveryFile = [];
        recoverySamples = 0;
    end

    methods
        function obj = LimbMATE_BioPatRec()
            obj@LimbMATE();
            obj.graphical_information = struct('enable_graph', 0);
        end

        function startAcquisitionEMG(self,varargin)
            self.prepareRecording();
            try
                startAcquisitionEMG@LimbMATE(self,varargin{:});
            catch ME
                try, self.streamIntegrity.fail(ME.identifier,ME.message); catch, end
                try, self.saveIntegrity(false); catch, end
                rethrow(ME);
            end
        end

        function prepareRecording(self)
            % Also usable with a replay source for hardware-independent tests.
            self.streamIntegrity = LMStreamIntegrity(self.EMG_NUM_CHANNELS,self.sampleF);
            self.recoverySamples = 0;
            self.recoveryPath = '';
            self.recoveryFile = [];
            if ~isempty(self.recoveryDirectory)
                if ~isfolder(self.recoveryDirectory), mkdir(self.recoveryDirectory); end
                self.recoveryPath = [tempname(self.recoveryDirectory), '.mat'];
                recordingComplete = false;
                committedSamples = 0;
                integrity = self.streamIntegrity.snapshot();
                data = zeros(self.EMG_NUM_CHANNELS,0,'single');
                save(self.recoveryPath,'data','integrity','recordingComplete','committedSamples','-v7.3');
                self.recoveryFile = matfile(self.recoveryPath,'Writable',true);
                fprintf('LimbMATE recovery file: %s\n',self.recoveryPath);
            end
        end

        function block = getEMG_data_TW_float(self,N)
            validateattributes(N,{'numeric'},{'scalar','integer','positive'});
            if ~self.emg_acquisition || isempty(self.streamIntegrity)
                error('LM:NotAcquiring','LimbMATE acquisition is not running.');
            end
            try
                deadline = tic;
                while size(self.streamIntegrity.pendingData,2) < N
                    header = self.readExact(4,deadline);
                    if header(1) ~= 2 || header(2) ~= hex2dec('84')
                        error('LM:FrameHeader','Unexpected frame during EMG streaming.');
                    end
                    count = double(header(3)) + 256*double(header(4));
                    if count < 8 || count > self.MAX_DATA_LENGTH
                        error('LM:FrameLength','Invalid Bluetooth frame length.');
                    end
                    body = self.readExact(count+1,deadline);
                    payload = LMStreamIntegrity.decodeFrame(header,body,self.MAX_DATA_LENGTH);
                    self.streamIntegrity.accept(payload);
                end
                block = self.streamIntegrity.take(N);
                % Compatibility with original diagnostics: these are packet IDs.
                self.packages_lost_index_total = double(self.streamIntegrity.lostPacketCounters(:)');
                self.checkpoint(block);
            catch ME
                try
                    self.streamIntegrity.fail(ME.identifier,ME.message);
                catch
                end
                try, self.saveIntegrity(false); catch, end
                rethrow(ME);
            end
        end

        function info = getRecordingIntegrity(self)
            if isempty(self.streamIntegrity)
                info = struct();
            else
                info = self.streamIntegrity.snapshot();
                info.recoveryPath = self.recoveryPath;
            end
        end

        function finishRecording(self,complete)
            self.saveIntegrity(complete);
            info = self.getRecordingIntegrity();
            if isfield(info,'replacedSamples') && info.replacedSamples > 0
                warning('LM:ReplacedSamples', ...
                    'LimbMATE: %d samples replaced (%d missing packets). See recordingIntegrity.', ...
                    info.replacedSamples,numel(info.lostPacketCounters));
            end
        end
    end

    methods
        function stopAcquisitionEMG(self)
            % Bounded shutdown; do not use the legacy unbounded retry loop.
            % Explicit calls also stop a board left streaming by an earlier process.
            if isempty(self.serialObj), return; end
            deadline = tic;
            command = uint8([2,4,2,0,hex2dec(self.STOP_ACQ_ADS1299),0]);
            checksum = uint8(0);
            for k = 1:numel(command), checksum = bitxor(checksum,command(k)); end
            self.emg_acquisition = false;
            try
                write(self.serialObj,[command,checksum],'uint8');
                while toc(deadline) < self.streamReadTimeout
                    header = self.readExact(4,deadline);
                    count = double(header(3)) + 256*double(header(4));
                    if header(1) ~= 2 || count > self.MAX_DATA_LENGTH
                        error('LM:StopFrame','Invalid frame while stopping acquisition.');
                    end
                    body = self.readExact(count+1,deadline);
                    if header(2) == hex2dec('84')
                        payload = LMStreamIntegrity.decodeFrame(header,body,self.MAX_DATA_LENGTH);
                        if numel(payload) >= 2 && payload(1) == hex2dec(self.STOP_ACQ_ADS1299) && payload(2) == 1
                            self.stop_acquisition_datetime = datetime('now');
                            return;
                        end
                    end
                end
            catch ME
                warning('LM:StopFailed','LimbMATE stop was not confirmed: %s',ME.message);
            end
        end

        function closeRecording(self)
            if self.emg_acquisition
                try, self.stopAcquisitionEMG(); catch, end
            end
            try, delete(self.serialObj); catch, end
            self.serialObj = [];
        end
    end

    methods (Access = private)
        function bytes = readExact(self,N,deadline)
            while self.serialObj.NumBytesAvailable < N
                if toc(deadline) > self.streamReadTimeout
                    error('LM:StreamTimeout','Timeout waiting for a complete EMG window.');
                end
                pause(0.001);
            end
            bytes = uint8(read(self.serialObj,N,'uint8'));
            if numel(bytes) ~= N
                error('LM:FrameLength','Incomplete serial read.');
            end
        end

        function checkpoint(self,block)
            if isempty(self.recoveryFile), return; end
            last = self.recoverySamples + size(block,2);
            self.recoveryFile.data(:,self.recoverySamples+1:last) = block;
            valid = self.streamIntegrity.validSamples(self.recoverySamples+1:last);
            counters = self.streamIntegrity.samplePacketCounters(self.recoverySamples+1:last);
            self.recoveryFile.validSamples(self.recoverySamples+1:last,1) = valid;
            self.recoveryFile.samplePacketCounters(self.recoverySamples+1:last,1) = counters;
            % Commit last, after data and provenance have both been written.
            self.recoveryFile.committedSamples = last;
            self.recoverySamples = last;
        end

        function saveIntegrity(self,complete)
            if isempty(self.recoveryFile), return; end
            integrity = self.getRecordingIntegrity();
            self.recoveryFile.integrity = integrity;
            self.recoveryFile.recordingComplete = logical(complete);
        end
    end
end

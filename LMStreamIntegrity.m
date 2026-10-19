classdef LMStreamIntegrity < handle
    % Packet continuity and sample provenance, independent of serial hardware.
    properties (SetAccess = private)
        nChannels
        sampleRate
        previousCounter = 0
        pendingData
        pendingValid = false(0,1)
        pendingCounter = zeros(0,1,'uint32')
        lastPacket
        receivedPacketCounters = zeros(0,1,'uint32')
        lostPacketCounters = zeros(0,1,'uint32')
        validSamples = false(0,1)
        samplePacketCounters = zeros(0,1,'uint32')
        errorIdentifier = ''
        errorMessage = ''
    end
    methods
        function self = LMStreamIntegrity(nChannels, sampleRate)
            self.nChannels = nChannels;
            self.sampleRate = sampleRate;
            self.pendingData = zeros(nChannels,0,'single');
            self.lastPacket = zeros(nChannels,5,'single');
        end

        function accept(self, payload)
            payload = uint8(payload(:)');
            minimumLength = 9 + 5 * self.nChannels * 4;
            if numel(payload) < minimumLength || payload(1) ~= hex2dec('AB')
                self.fail('LM:InvalidPayload', 'Invalid or incomplete EMG payload.');
            end
            counter = double(typecast(payload(5:-1:2), 'uint32'));
            % Counter starts at 1 in firmware. Modulo handles uint32 rollover.
            delta = LMStreamIntegrity.counterDistance(self.previousCounter,counter);
            if delta == 0 || delta >= 2^31
                self.fail('LM:CounterOrder', 'Duplicate or out-of-order EMG packet.');
            end
            missing = delta - 1;
            % Bound reconstruction and memory use; a longer gap needs a new take.
            if missing * 5 > self.sampleRate * 2
                self.fail('LM:StreamGap', 'More than two seconds of EMG data are missing.');
            end
            bytes = reshape(payload(10:minimumLength),4,[]);
            values = typecast(reshape(flipud(bytes),1,[]),'single');
            block = reshape(values,self.nChannels,5);
            if any(~isfinite(block(:)))
                self.fail('LM:InvalidSamples', 'Non-finite EMG samples received.');
            end
            if missing > 0
                lost = uint32(mod(self.previousCounter + (1:missing),2^32));
                self.lostPacketCounters = [self.lostPacketCounters; lost(:)];
                self.pendingData = [self.pendingData, repmat(self.lastPacket,1,missing)];
                self.pendingValid = [self.pendingValid; false(missing*5,1)];
                self.pendingCounter = [self.pendingCounter; reshape(repelem(lost(:),5),[],1)];
            end
            self.pendingData = [self.pendingData, block];
            self.pendingValid = [self.pendingValid; true(5,1)];
            self.pendingCounter = [self.pendingCounter; repmat(uint32(counter),5,1)];
            self.receivedPacketCounters(end+1,1) = uint32(counter);
            self.previousCounter = counter;
            self.lastPacket = block;
        end

        function block = take(self,N)
            if size(self.pendingData,2) < N
                self.fail('LM:IncompleteWindow', 'Not enough samples for the requested window.');
            end
            block = self.pendingData(:,1:N);
            self.validSamples = [self.validSamples; self.pendingValid(1:N)];
            self.samplePacketCounters = [self.samplePacketCounters; self.pendingCounter(1:N)];
            self.pendingData(:,1:N) = [];
            self.pendingValid(1:N) = [];
            self.pendingCounter(1:N) = [];
        end

        function info = snapshot(self)
            info.schemaVersion = 1;
            info.sampleRate = self.sampleRate;
            info.nChannels = self.nChannels;
            info.validSamples = self.validSamples;
            info.samplePacketCounters = self.samplePacketCounters;
            info.receivedPacketCounters = self.receivedPacketCounters;
            info.lostPacketCounters = self.lostPacketCounters;
            info.replacedSamples = nnz(~self.validSamples);
            info.replacementPolicy = 'Repeat previous five-sample packet; zeros before first packet';
            info.errorIdentifier = self.errorIdentifier;
            info.errorMessage = self.errorMessage;
            info.pendingData = self.pendingData;
            info.pendingValidSamples = self.pendingValid;
            info.pendingPacketCounters = self.pendingCounter;
            info.scope = 'Continuity from firmware packet generation to MATLAB; not ADC continuity';
            info.coordinates = 'Original acquisition samples; remap validity if samples are cropped or resampled';
        end

        function fail(self, identifier, message)
            self.errorIdentifier = identifier;
            self.errorMessage = message;
            error(identifier,'%s',message);
        end
    end
    methods (Static)
        function delta = counterDistance(previous,current)
            delta = mod(double(current)-double(previous),2^32);
        end

        function payload = decodeFrame(header, body, maxLength)
            % CMD_DATA_IND: 02 84 lengthLE(2) MAC(6) RSSI(1) payload checksum.
            header = uint8(header(:)');
            body = uint8(body(:)');
            if numel(header) ~= 4 || header(1) ~= 2 || header(2) ~= hex2dec('84')
                error('LM:FrameHeader','Invalid Bluetooth frame header.');
            end
            count = double(header(3)) + 256 * double(header(4));
            if count < 8 || count > maxLength || numel(body) ~= count+1
                error('LM:FrameLength','Invalid or incomplete Bluetooth frame length.');
            end
            frame = [header,body];
            checksum = uint8(0);
            for k = 1:numel(frame)-1
                checksum = bitxor(checksum,frame(k));
            end
            if checksum ~= frame(end)
                error('LM:FrameChecksum','Bluetooth frame checksum mismatch.');
            end
            payload = body(8:end-1);
        end
    end
end

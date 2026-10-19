function tests = testLMStreamIntegrity
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
testCase.TestData.oldPath = path;
addpath(root,fileparts(mfilename('fullpath')));
end

function teardownOnce(testCase)
path(testCase.TestData.oldPath);
end

function test_normalAndResiduals(testCase)
reader = LMStreamIntegrity(8,500);
a = reshape(single(1:40),8,5);
b = a+100;
reader.accept(packet(1,a));
verifyEqual(testCase,reader.take(3),a(:,1:3));
reader.accept(packet(2,b));
verifyEqual(testCase,reader.take(7),[a(:,4:5),b]);
verifyTrue(testCase,all(reader.validSamples));
verifyEqual(testCase,reader.samplePacketCounters,uint32([ones(5,1);2*ones(5,1)]));
end

function test_missingPacketAndWholeWindow(testCase)
reader = LMStreamIntegrity(8,500);
a = ones(8,5,'single');
reader.accept(packet(1,a));
% Ten packets = a whole increment at 500 Hz; old modulo check could miss it.
reader.accept(packet(12,2*a));
data = reader.take(60);
verifyEqual(testCase,data,[repmat(a,1,11),2*a]);
verifyEqual(testCase,reader.lostPacketCounters,uint32((2:11)'));
verifyEqual(testCase,find(~reader.validSamples),(6:55)');
end

function test_initialGap(testCase)
reader = LMStreamIntegrity(8,500);
reader.accept(packet(3,ones(8,5,'single')));
data = reader.take(15);
verifyEqual(testCase,data(:,1:10),zeros(8,10,'single'));
verifyEqual(testCase,reader.validSamples,[false(10,1);true(5,1)]);
end

function test_duplicateReverseAndLongGap(testCase)
reader = LMStreamIntegrity(8,500);
reader.accept(packet(1,ones(8,5,'single')));
verifyError(testCase,@() reader.accept(packet(1,ones(8,5,'single'))),'LM:CounterOrder');
verifyError(testCase,@() reader.accept(packet(0,ones(8,5,'single'))),'LM:CounterOrder');
verifyError(testCase,@() reader.accept(packet(1000,ones(8,5,'single'))),'LM:StreamGap');
end

function test_corruptAndTruncatedFrames(testCase)
frame = bluetoothFrame(packet(1,ones(8,5,'single')));
verifyEqual(testCase,LMStreamIntegrity.decodeFrame(frame(1:4),frame(5:end),255),packet(1,ones(8,5,'single')));
bad = frame; bad(30) = bitxor(bad(30),uint8(1));
verifyError(testCase,@() LMStreamIntegrity.decodeFrame(bad(1:4),bad(5:end),255),'LM:FrameChecksum');
verifyError(testCase,@() LMStreamIntegrity.decodeFrame(frame(1:4),frame(5:end-1),255),'LM:FrameLength');
bad = frame; bad(1) = 3;
verifyError(testCase,@() LMStreamIntegrity.decodeFrame(bad(1:4),bad(5:end),255),'LM:FrameHeader');
reader = LMStreamIntegrity(8,500);
verifyError(testCase,@() reader.accept(uint8([171,1])),'LM:InvalidPayload');
verifyError(testCase,@() reader.accept(packet(1,nan(8,5,'single'))),'LM:InvalidSamples');
end

function test_adapterReadsAndTimesOut(testCase)
obj = LimbMATE_BioPatRec();
obj.emg_acquisition = true;
obj.streamIntegrity = LMStreamIntegrity(8,500);
obj.serialObj = LMSerialMock(bluetoothFrame(packet(1,ones(8,5,'single'))));
verifyEqual(testCase,obj.getEMG_data_TW_float(5),ones(8,5,'single'));
obj.streamReadTimeout = 0.02;
verifyError(testCase,@() obj.getEMG_data_TW_float(5),'LM:StreamTimeout');
info = obj.getRecordingIntegrity();
verifyEqual(testCase,info.errorIdentifier,'LM:StreamTimeout');
verifyEqual(testCase,numel(info.validSamples),5);
end

function test_adapterRejectsCorruption(testCase)
obj = LimbMATE_BioPatRec();
obj.emg_acquisition = true;
obj.streamIntegrity = LMStreamIntegrity(8,500);
frame = bluetoothFrame(packet(1,ones(8,5,'single')));
frame(end) = bitxor(frame(end),uint8(1));
obj.serialObj = LMSerialMock(frame);
verifyError(testCase,@() obj.getEMG_data_TW_float(5),'LM:FrameChecksum');
verifyEmpty(testCase,obj.streamIntegrity.validSamples);
end

function test_boundedShutdown(testCase)
obj = LimbMATE_BioPatRec();
obj.emg_acquisition = true;
obj.streamReadTimeout = 0.02;
obj.serialObj = LMSerialMock(bluetoothFrame(uint8([19,1])));
obj.stopAcquisitionEMG();
verifyFalse(testCase,obj.emg_acquisition);
verifyEqual(testCase,obj.serialObj.writes{1},uint8([2,4,2,0,19,0,23]));
end

function test_rollover(testCase)
verifyEqual(testCase,LMStreamIntegrity.counterDistance(uint32(2^32-1),uint32(0)),1);
verifyEqual(testCase,LMStreamIntegrity.counterDistance(uint32(2^32-2),uint32(1)),3);
end

function test_shutdownWithoutReplyIsBounded(testCase)
obj = LimbMATE_BioPatRec();
obj.serialObj = LMSerialMock();
obj.emg_acquisition = true;
obj.streamReadTimeout = 0.02;
started = tic;
verifyWarning(testCase,@() obj.stopAcquisitionEMG(),'LM:StopFailed');
verifyLessThan(testCase,toc(started),1);
verifyFalse(testCase,obj.emg_acquisition);
end

function test_recoveryAndMetadata(testCase)
directory = tempname;
mkdir(directory);
cleanup = onCleanup(@() rmdir(directory,'s'));
obj = LimbMATE_BioPatRec();
obj.recoveryDirectory = directory;
obj.prepareRecording();
obj.emg_acquisition = true;
obj.serialObj = LMSerialMock([bluetoothFrame(packet(1,ones(8,5,'single'))), ...
    bluetoothFrame(packet(3,3*ones(8,5,'single')))]);
first = obj.getEMG_data_TW_float(7);
second = obj.getEMG_data_TW_float(8);
warningState = warning('off','LM:ReplacedSamples');
restoreWarning = onCleanup(@() warning(warningState));
obj.finishRecording(true);
saved = load(obj.recoveryPath);
verifyTrue(testCase,saved.recordingComplete);
verifyEqual(testCase,saved.committedSamples,15);
verifyEqual(testCase,saved.data,[first,second]);
verifyEqual(testCase,saved.validSamples,[true(5,1);false(5,1);true(5,1)]);
verifyEqual(testCase,saved.integrity.replacedSamples,5);
verifyEqual(testCase,saved.integrity.lostPacketCounters,uint32(2));
% A later timeout preserves the last committed data and marks it incomplete.
obj.streamReadTimeout = 0.02;
verifyError(testCase,@() obj.getEMG_data_TW_float(5),'LM:StreamTimeout');
saved = load(obj.recoveryPath);
verifyFalse(testCase,saved.recordingComplete);
verifyEqual(testCase,saved.committedSamples,15);
verifyEqual(testCase,saved.integrity.errorIdentifier,'LM:StreamTimeout');
obj.emg_acquisition = false;
end

function payload = packet(counter,values)
counterBytes = flip(typecast(uint32(counter),'uint8'));
bytes = reshape(typecast(single(values(:)),'uint8'),4,[]);
payload = [uint8(171),counterBytes,uint8([0,0,0,0]),reshape(flipud(bytes),1,[])];
end

function frame = bluetoothFrame(payload)
body = [zeros(1,7,'uint8'),payload];
frame = [uint8([2,132,mod(numel(body),256),floor(numel(body)/256)]),body];
checksum = uint8(0);
for k = 1:numel(frame), checksum = bitxor(checksum,frame(k)); end
frame(end+1) = checksum;
end

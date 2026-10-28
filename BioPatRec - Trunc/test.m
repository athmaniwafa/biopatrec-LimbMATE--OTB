%% test_SQ_class.m
% Tests Sessantaquattro_Acquire outside BioPatRec.
% Close OT BioLab+ and BioPatRec windows first.
close all force;                          % closes BioPatRec windows that hold the adapter
clear all; clear classes; clc; %#ok<CLALL>
rehash;                                   % make sure the NEW class files are used

fs = 2000;
sq = Sessantaquattro_Acquire(64, 10, 45454);   % waits for the device, sends 58 41
sq.flushInput();

d = sq.getEMG_data_TW_float(fs*6);        % 6 s, [12000 x 64] in mV

fprintf('\nSignal level per 0.5 s segment (median over channels of mean|x|, mV):\n');
seg = fs/2;
for k = 1:floor(size(d,1)/seg)
    x = d((k-1)*seg+1:k*seg, :);
    fprintf('  %4.1f - %4.1f s : %.5f   (flat channels: %d)\n', ...
            (k-1)*0.5, k*0.5, median(mean(abs(x),1)), sum(std(x,0,1) == 0));
end

s = std(d, 0, 1);
m = mean(abs(d), 1);
fprintf('\nsize of block         : %s\n', mat2str(size(d)));
fprintf('lost samples          : %d\n', sq.lostSamples);
fprintf('mean|x| (mV)  min/med/max : %.5f / %.5f / %.5f\n', min(m), median(m), max(m));
fprintf('std (mV)      min/med/max : %.5f / %.5f / %.5f\n', min(s), median(s), max(s));
fprintf('channels with zero std (flat) : %s\n', mat2str(find(s == 0)));
same = sum(all(abs(d - d(:,1)) < 1e-6, 1));
fprintf('channels identical to ch 1    : %d of 64  (64 = test-mode pattern)\n', same);
fprintf('max |x| (mV)          : %.4f (full-scale about +-9.4 mV when clipped)\n', max(abs(d(:))));

figure("Name","Mean |x| per electrode (mV)");
imagesc(reshape(m, 8, 8)); colorbar; axis image;
title("Same layout as the GUI (column-major)");

figure("Name","Channels 1-8");
t = (1:size(d,1))/fs;
plot(t, d(:,1:8) + (0:7)*max(1e-3, 4*median(s)));
xlabel("s"); title("Channels 1-8 (offset for display)");

fprintf('\nLast frame, ch 1-8 raw   : %s\n', mat2str(sq.dbgLast(1:8)'));
fprintf('Last frame, ch 65-72 raw : %s\n', mat2str(sq.dbgLast(65:72)'));
fprintf('  (ch 72 = counter, should be about %d; ch 67-70 = quaternions, non-zero if the IMU runs)\n', size(d,1));

sq.disconnectBTdevice();
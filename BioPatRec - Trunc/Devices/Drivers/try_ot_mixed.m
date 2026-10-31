function R = try_ot_mixed(durationSec, nBipolar, electrodeType, outputFile)
% TRY_OT_MIXED Acquire one HD grid (MULTIPLE IN1) and bipolar sensors (IN1).
% Example: R = try_ot_mixed(10, 8, 'BIG', 'mixed_trial.mat');
% Close OTBioLab+ first. Requires EMG-USB2+ 128 and suitable adapters.
% Columns retain native OTComm order: inspect R.config.AcquiredChannels
% and verify channel identity experimentally before interpreting signals.
% Values are raw ADC counts, following OT_Acquire's existing convention.
    if nargin < 1, durationSec = 10; end
    if nargin < 2, nBipolar = 8; end
    if nargin < 3, electrodeType = 'BIG'; end
    if nargin < 4, outputFile = ''; end
    validateattributes(durationSec, {'numeric'}, {'scalar','real','finite','positive'});
    electrodes = struct('MULTIPLE_IN1', electrodeType, 'MULTIPLE_IN2', '');
    ot = OT_Acquire('mixed', nBipolar, durationSec + 2, electrodes);
    cleanup = onCleanup(@() ot.disconnectBTdevice()); %#ok<NASGU>
    R.Fs = ot.Fs;
    R.config = ot.config;
    fprintf('Mixed acquisition: %d channels at %d Hz. Native channel IDs:\n', ot.Nch, ot.Fs);
    disp(R.config.AcquiredChannels);
    nSamples = max(1, round(durationSec * R.Fs));
    R.data = zeros(nSamples, ot.Nch, 'single');
    ot.startAcquisitionEMG();
    first = 1;
    while first <= nSamples
        count = min(256, nSamples - first + 1);
        R.data(first:first+count-1, :) = ot.getEMG_data_TW_float(count);
        first = first + count;
    end
    ot.stopAcquisitionEMG();
    R.units = 'ADC counts';
    if ~isempty(outputFile), save(outputFile, 'R'); end
    fprintf('Acquired %d samples x %d channels.\n', size(R.data,1), size(R.data,2));
end

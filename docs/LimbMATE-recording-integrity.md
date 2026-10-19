# LimbMATE acquisition in BioPatRec

Standard and fast recording sessions use `LimbMATE_BioPatRec`. This adapter reads
EMG samples independently of the legacy feature/hand-control plotting receiver.
It preserves the `[channels x samples]` driver interface. The external Limb-MATE
repository, its firmware and its original GUI have not been changed.

## Data quality

Each Bluetooth indication must have a valid header, bounded length and XOR
checksum. EMG packets carry five samples per channel and a uint32 counter.
Continuity uses the global counter, including rollover, rather than the position
inside a time window. The firmware resets the counter to zero before streaming,
so the first expected packet has counter 1.

A missing packet repeats the previous five-sample block (zeros before the first
received packet). These are replacements, not recovered measurements. Every
returned sample has a validity flag and packet counter. Gaps exceeding two seconds,
duplicates, reverse counters, invalid samples, malformed frames and timeouts stop
the take. There is no automatic resynchronization that silently discards bytes.
The two-second reconstruction ceiling is a bounded-memory policy, not a quality
threshold: even one replaced sample is reported, and the operator can repeat the
movement. A failed read is never appended as a zero-filled successful window.

The standard MAT file has `recSession.recordingIntegrity{movement}`; standard and
fast acquisition also return diagnostics in `sensorData.recordingIntegrity`
(`sdata.recordingIntegrity` in the existing `cdata.mat` workflow). Relevant fields:

- `validSamples`: one logical per time sample, shared across channels.
- `samplePacketCounters`: uint32 counter associated with each sample.
- `lostPacketCounters`, `receivedPacketCounters`, `replacedSamples`.
- `errorIdentifier`, `errorMessage`, and `recoveryPath`.
- `pendingData` and its provenance: read packets not yet returned in a full window.

The mask indexes the time dimension of `tdata`, not the channel dimension.
The regular GUI export preserves the `sdata` diagnostics. These refer to the
original acquisition: cropping or resampling signals later requires remapping
the validity mask and counters; the legacy offline processing GUI does not do that.
Training/analysis code must inspect this metadata before accepting affected data;
existing classifiers do not automatically exclude invalid samples.

## Recovery

One unique v7.3 MAT recovery file is retained per movement attempt in
`LimbMATE_Recovery` under the working directory, including repeated attempts.
Each returned window writes data and provenance before updating `committedSamples`.
The files are retained after a successful final save as well.

```matlab
r = load('LimbMATE_Recovery/<file>.mat');
n = r.committedSamples;
data = r.data(:,1:n)';                 % samples x all eight device channels
valid = r.validSamples(1:n);
```

For an empty checkpoint (`committedSamples == 0`), sample arrays may not exist yet.
After a process interruption use only the committed prefix. The top-level validity
and counter arrays are updated on every checkpoint; the `integrity` summary and
`recordingComplete` are updated on orderly completion/error. This is incremental
recovery, not a transactional guarantee against power loss or filesystem failure.

Recording storage is preallocated in RAM for LM. Graphics update at most ten times
per second; every window is still read, accumulated and checkpointed. Disk latency
and sustained Bluetooth throughput must be verified on the acquisition computer.
Shutdown waits for a validated stop acknowledgement with a deadline, then releases
the serial port during cleanup even if the board is unreachable.

## Validation and limits

Run `results = runtests('tests/testLMStreamIntegrity.m'); assertSuccess(results)`.
Tests use synthetic firmware-format packets and a serial mock, including complete
window loss, corrupt/truncated frames, duplicate/reversed counters, residuals,
rollover arithmetic, timeout, stop acknowledgement and recovery files.

Hardware validation is still required: record a known-duration signal, check sample
counts and quality metadata, interrupt Bluetooth and verify the error/recovery path,
and repeat with the normal GUI workload. These counters begin at firmware packet
generation; they cannot prove continuity at the ADC or in transfers between cores.

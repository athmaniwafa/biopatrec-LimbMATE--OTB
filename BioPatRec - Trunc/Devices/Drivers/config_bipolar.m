function [dev,config] = config_bipolar(nBipolar)

if nargin < 1
    nBipolar = 1;
end

if nBipolar < 1 || nBipolar > 16
    error('nBipolar deve essere tra 1 e 16.');
end

model = OTComm.EMGUSB.Models.EMG_USB2p_128;
freq = OTComm.EMGUSB.Frequencies.EMGUSB_2048Hz;
dev = OTComm.EMGUSB.DataGeneratorEMGUSB(model,freq);
adapter = OTComm.EMGUSB.AdapterInAD8x2JD;

for ch = 1:nBipolar

    sensor = OTComm.Sensors.SensorCDE(uint32(ch));

    adapter.SetChannel(uint32(ch-1),sensor);

end

dev.ConnectIn(uint32(0),adapter);

config.NumChannels = nBipolar;
config.Model = 'EMG_USB2p_128';
config.Type = 'Bipolar';
config.Adapter = 'AdapterInAD8x2JD';
config.Input = 0;
config.NumBipolar = nBipolar;

end
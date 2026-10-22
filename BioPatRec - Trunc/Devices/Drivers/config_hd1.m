function [dev,config] = config_hd1()

model = OTComm.EMGUSB.Models.EMG_USB2p_128;
freq = OTComm.EMGUSB.Frequencies.EMGUSB_2048Hz;
dev = OTComm.EMGUSB.DataGeneratorEMGUSB(model,freq);
adapter = OTComm.EMGUSB.AdapterMultipleInAD64;
sensor = OTComm.Sensors.SensorELSCH064NM3; 
% SensorELSCH064NM2 -> 8 mm
% SensorELSCH064NM3 -> 10 mm

if double(sensor.Channels) ~= 64
    error('Il sensore HD non dichiara 64 canali.');
end

adapter.SetChannels(uint32(0),uint32(63),sensor);

dev.ConnectMultipleIn(uint32(0),adapter);

config.NumChannels = 64;
config.Model = 'EMG_USB2p_128';
config.Type = 'HD';
config.NumMatrices = 1;
config.Sensor = 'SensorELSCH064NM3';
config.MultipleIn1 = 0;

end
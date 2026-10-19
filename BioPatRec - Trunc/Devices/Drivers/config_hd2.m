function [dev,config] = config_hd2()

model = OTComm.EMGUSB.Models.EMG_USB2p_256;
freq = OTComm.EMGUSB.Frequencies.EMGUSB_2048Hz;
dev = OTComm.EMGUSB.DataGeneratorEMGUSB(model,freq);

adapter1 = OTComm.EMGUSB.AdapterMultipleInAD64;
adapter2 = OTComm.EMGUSB.AdapterMultipleInAD64;

sensor1 = OTComm.Sensors.SensorELSCH064NM3; % 10 mm
sensor2 = OTComm.Sensors.SensorELSCH064NM2; % 8 mm
% SensorELSCH064NM2 -> 8 mm
% SensorELSCH064NM3 -> 10 mm

if double(sensor1.Channels) ~= 64
    error('Matrice 1 non valida.');
end

if double(sensor2.Channels) ~= 64
    error('Matrice 2 non valida.');
end

adapter1.SetChannels(uint32(0),uint32(63),sensor1);

adapter2.SetChannels(uint32(0),uint32(63),sensor2);

dev.ConnectMultipleIn(uint32(0),adapter1);

dev.ConnectMultipleIn(uint32(1),adapter2);

config.NumChannels = 128;
config.Model = 'EMG_USB2p_256';
config.Type = 'HD';
config.NumMatrices = 2;
config.Sensor1 = 'SensorELSCH064NM3';
config.Sensor2 = 'SensorELSCH064NM2';
config.MultipleIn1 = 0;
config.MultipleIn2 = 1;

end
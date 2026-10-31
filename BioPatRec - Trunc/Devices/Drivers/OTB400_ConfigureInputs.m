function [dev,config] = OTB400_ConfigureInputs(selection)
    config = OTB400_InputPlan(selection);
    switch config.Model
        case 'EMG_USB2p_64', model=OTComm.EMGUSB.Models.EMG_USB2p_64;
        case 'EMG_USB2p_128', model=OTComm.EMGUSB.Models.EMG_USB2p_128;
        case 'EMG_USB2p_256', model=OTComm.EMGUSB.Models.EMG_USB2p_256;
    end
    dev = OTComm.EMGUSB.DataGeneratorEMGUSB(model,OTComm.EMGUSB.Frequencies.EMGUSB_2048Hz);
    for k=1:4
        count=selection.BipolarCounts(k);
        if count==0, continue; end
        adapter=OTComm.EMGUSB.AdapterInAD8x2JD;
        for ch=1:count
            adapter.SetChannel(uint32(ch-1),OTComm.Sensors.SensorCDE(uint32(ch)));
        end
        dev.ConnectIn(uint32(k-1),adapter);
    end
    for k=config.HDInputNumbers
        adapter=OTComm.EMGUSB.AdapterMultipleInAD64;
        if strcmp(selection.HDTypes{k},'BIG')
            sensor=OTComm.Sensors.SensorELSCH064NM3;
        else
            sensor=OTComm.Sensors.SensorELSCH064NM2;
        end
        adapter.SetChannels(uint32(0),uint32(63),sensor);
        dev.ConnectMultipleIn(uint32(k-1),adapter);
    end
end

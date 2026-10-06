classdef LimbMATE < handle
    % Limb-MATE Summary of this class goes here
    % Detailed explanation goes here
    
    properties
        % Bluetooth %
        serialObj = [];
        USBstickMAC = []
        BTmoduleMACdec = [];
        BTdevices = [];
        BTindex = 0;
        devicesNumber = 0;
        portBaudrate = 1000000; 
        %portBaudrate = 115200; 
        portFlowControl = "hardware";
        current_position_BT = 1;

        % Acquisition Parameters - EMG %
        acquisitionParameters
        start_acquisition_datetime
        stop_acquisition_datetime

        emg_acquisition = false; 
        emg_data = [];
        temp_emg_data = [];
        temp_streamed_features = [];
        streamed_features = [];
        temp_streamed_control = [];
        streamed_control = [];
        hand_parameters = [];
        
        residual_emg_data = [];
        residual_timer = [];

        stopped_acquisition = 0;
        timer_TW = 0;
        full_timer_TW = []
        control_cycle_time = []
        packages_lost_index_total = [];
        num_incremental_TW = 0;
        num_TW = 0;
        packages_per_TW = 0;
        packages_per_TW_increment = 0;
        
        first_package_flag = true;
        first_package_number = 0;
        last_TW_emg_package;
        saved_TW_packages = [];
        first_TW_received = true;
        features_save_tw_package;
        features_save_tw_package_number = 1;
        raw_grasp_info_save_tw_package;

        extract_feature_flag = true;
        classify_flag = true;

        % Acquisition Parameters - MATLAB feature Extraction % 
        temp_features = [];
        MAV_max_v = []; MAV_min_v = [];

        % Acquisition Parameters - Control % 
        features_control = [];
        temp_control = [];
        MAV_max = 0; STD_max = 0; WL_max = 0; ZC_max = 0; SLP_max = 0;
        min_current = -1; max_current = 1;
        min_force = -1; max_force = 1;
        min_imu = -1; max_imu = 1;
        max_DAC = 0.1;
        Act_Lev_max = 0;
        plot_index_counter = 1;

        % ADS1299 Parameters 
        sampleF_encoded = uint8(1);
        gains_encoded = uint8([1,1,1,1,1,1,1,1]);
        config_encoded = uint8(0);
        sampleF = 500;
        gains = [1,1,1,1,1,1,1,1];
        config = "differential"
        enable_testmode = 0;
        enabled_filters = 0;
        enable_HP_filter = 0;    % compatibility alias used by BioPatRec integration
        channels_encoded = 0;
        tw_samples_encoded = 1;
        two_samples_encoded = 3;
        tw_samples = 100;
        two_samples = 75;

        % DAC %
        dac = [];
        class_DAC_params;

        % RTCC % 
        rtcc = [];

        % SD Card % 
        sd_text_ascii = "";
        sd_text = [];
        sd_text_datalog = [];
        sd_datalog = [];
        sd_EMGlog = [];
        sd_emg_flag = 1;

        % IMU %
        imu_direction = [];

        % Wrist PinMode %
        wrist_pinMode = 1;

        % Feedback Table %
        fb_table = [];

        % General Properties %
        battVoltage = 0;
        temperature = 0;
        deviceName = "";
        deviceFirmware = "";

        % MIA % 
        handInUse = "Generic_Hand"
        mia_reply_uint8_ASCII = 0;
        MIA_data_transmitted = [];
        MIA_EMG = []

        % Classifiers % 
        controlMode = 0;
        enableFloorNoise = 0;
        confidence_perc = 0;
        DC_params = [];
        DC_hands_params = [];
        LDA_params = [];
        SVM_params = [];
        MLP_params = [];
        Reg_params = [];
        Imu_params = [];

        % Post Process Control Algorithm %
        PP_control = []

        % Calibration Routine %
        CR_params = []

        % Plot Types %
        Streaming_plots = [];
        DC_plots = [];
        Control_plots = [];
        graphical = [];
        graphical_information = [];
        graphical_information_session = [];
        streaming_ymin = -0.01;
        streaming_ymax = +0.01;
        PLOT_EMG = 0;
        PLOT_MAV = 1;
        PLOT_CONTROL = 2;

        % NeuroStimulation
        ns_table
        ns_impulse

        % Connection Text %
        conn_text = "";
        module_names = "";
        warning_timeout = 0;

        % VRE %
        vre_comm
        vre_enabled = 0;
        desired_grasp = 0;
        max_degree_per_pred = 2;                    % With 50 ms Control Cicles, the max output is: max_degrees_per_mov*20°/sec. 


    end
    
    properties(Constant, Access = private)
        
        %BT communication protocol
        MAX_DATA_LENGTH = 255; % 243

        EMG_PACKAGE_SIZE    = 5;
        EMG_NUM_CHANNELS    = 8;
        DAC_CHANNELS        = 8;
        FB_NUM_CHANNELS     = 8;
        FEAT_NUM            = 5;
        NUM_MAX_FEAT_UNI    = 2;

        NUM_INERTIAL_COEFF = 3
        NUM_DOF = 4
        NUM_BYTES_CLASSES = 1
        
        %LM defines
        BATT_MAX_VOLTAGE            = 20;

        
        %LM COMMANDS
        ARE_YOU_ALIVE	  	 	  	= "0x01";
        GET_DEVICE_NAME           	= "0x02";
        GET_FIRMWARE_VERSION	  	= "0x03";
        TOGGLE_LED	  			  	= "0x04";
        SET_IMU_DIR                 = "0x05";
        GET_IMU_DIR                 = "0x06";
        GET_BATTERY_VOLTAGE       	= "0x07";
        SET_WRIST_PIN_MODE          = "0x08";
        GET_WRIST_PIN_MODE          = "0x09";
        SET_FREQ_GAIN_ADS1299	  	= "0x11";
        START_ACQ_ADS1299		  	= "0x12";
        STOP_ACQ_ADS1299		  	= "0x13";
        SET_ELECTRODES_CONFIG		= "0x14";
        NEW_SAMPLES_PACKAGE		  	= "0xA0";
        SET_RTCC_DATA				= "0x20";
        GET_RTCC_DATA				= "0x21";
        READ_SD_DATA				= "0x22";
        RESET_SD_DATA				= "0x23";
        GET_ADS_DATA                = "0x24";
        SET_DAC_CHANNELS			= "0x25";
        GET_DAC_CHANNELS			= "0x26";
        SEND_HAND_COMMAND           = "0x30";
        ENABLE_HAND_CONNECTION      = "0x31";
        SEND_MIA_COMMAND            = "0x32";
        GET_EMG_PARAMS              = "0x34";
        SET_DC_PARAMS               = "0x41";
        GET_DC_PARAMS               = "0x42";
        SET_LDA_PARAMS              = "0x45";
        GET_LDA_PARAMS              = "0x46";
        SET_PR_TABLE                = "0x47";
        GET_PR_TABLE                = "0x48";
        SET_SVM_PARAMS              = "0x49";
        GET_SVM_PARAMS              = "0x4A";
        SET_MLP_PARAMS              = "0x4B";
        GET_MLP_PARAMS              = "0x4C";
        SET_REG_PARAMS              = "0x4D";
        GET_REG_PARAMS              = "0x4E";
        SET_PP_PARAMS               = "0x50";
        GET_PP_PARAMS               = "0x51";
        SET_CLASS_DAC               = "0x52";
        GET_CLASS_DAC               = "0x53";
        SET_CONTROL_MODE            = "0x54";
        GET_CONTROL_MODE            = "0x55";
        GET_DATALOG				    = "0x56";
        RESET_SD_DATALOG			= "0x57";
        GET_ACQ_PARAMS				= "0x58";
        FORMAT_SD_CARD				= "0x59";
        GET_TEMPERATURE			    = "0x60";
        SET_FEEDBACK				= "0x61";
        GET_FEEDBACK				= "0x62";
        RESET_SD_EMGLOG				= "0x63";
        SET_SD_EMG_FLAG				= "0x64";
        GET_SD_EMG_FLAG				= "0x65";
        SET_IMU_PARAMS				= "0x70";
        GET_IMU_PARAMS			    = "0x71";
        SET_CR_PARAMS				= "0x72";
        GET_CR_PARAMS			    = "0x73";
        
        %BT COMMANDS
        CMD_BYTE_RESET_CNF          = "40";
        CMD_BYTE_GETSTATE_CNF       = "41";
        CMD_BYTE_SLEEP_CNF          = "42";
        CMD_BYTE_DATA_CNF           = "44";
        CMD_BYTE_CONNECT_CNF        = "46";
        CMD_BYTE_DISCONNECT_CNF     = "47";
        CMD_BYTE_SCANSTART_CNF      = "49";
        CMD_BYTE_SCANSTOP_CNF       = "4A";
        CMD_BYTE_GETDEVICES_CNF     = "4B";
        CMD_BYTE_GET_CNF            = "50";
        CMD_BYTE_SET_CNF            = "51";
        CMD_BYTE_PHYUPDATE_CNF      = "5A";

        CMD_BYTE_PHYUPDATE_IND      = "9A";
        CMD_BYTE_SLEEP_IND          = "82";
        CMD_BYTE_DATA_IND           = "84";
        CMD_BYTE_CONNECT_IND        = "86";
        CMD_BYTE_DISCONNECT_IND     = "87";

        CMD_BYTE_TXCOMPLETE_RSP     = "C4";
        CMD_BYTE_CHANNELOPEN_RSP    = "C6";

        % Classifiers classes % 
        NO_CONTROL				     = uint8(0)
        DIRECT_CONTROL			     = uint8(1)
        LDA_CONTROL				     = uint8(2)
        tSVM_CONTROL				 = uint8(3)
        MLP_CONTROL				     = uint8(4)
        tLDA_CONTROL				 = uint8(5)
        REG_CONTROL				     = uint8(6)
        tLDAR_CONTROL				 = uint8(7)
        IMU_CONTROL				     = uint8(8)
        tLDAiDC_CONTROL				 = uint8(9)
        tSVMR_CONTROL				 = uint8(10)

        % Hand Information % 
        RAW_GRASP_INFORMATION_SIZE   = 36

        % Calibration Routnine %
        CR_NUM_MOVEMENTS            = 4

        % ERRORS
        % ADS
        NO_ERR_CORECORE			    = hex2dec("0x00")

        ERR_CC_HEADER			    = hex2dec("0x11")
        ERR_CC_CHECKSUM			    = hex2dec("0x12")
        ERR_CC_PERIPHERAL			= hex2dec("0x13")
        ERR_CC_MODALITY			    = hex2dec("0x14")
        ERR_CC_DATA			        = hex2dec("0x15")
        ERR_CC_TARGET			    = hex2dec("0x16")
        ERR_SET_ADS			        = hex2dec("0x17")
        ERR_CC_WRONG_TRIGGER_C1	    = hex2dec("0x18")

        ERR_MODALITY_C0			    = hex2dec("0x21")

        % RTCC
        NO_ERR_RTCC			        = hex2dec("0x00")

        ERR_RTCC_SEC			    = hex2dec("0x11")
        ERR_RTCC_MIN			    = hex2dec("0x12")
        ERR_RTCC_HOUR			    = hex2dec("0x13")
        ERR_RTCC_WDAY			    = hex2dec("0x14")
        ERR_RTCC_DAY			    = hex2dec("0x15")
        ERR_RTCC_MONTH			    = hex2dec("0x16")
        ERR_RTCC_YEAR			    = hex2dec("0x17")

        % DAC
        NO_ERR_DAC			        = hex2dec("0x00")

        ERR_DAC_EXCEEDED_VALUE	    = hex2dec("0x11")
        ERR_DAC_EXCEEDED_CHAN		= hex2dec("0x12")

        % Movements
        REST_DONOTHING              = uint8(0)
        OPENHAND                    = uint8(1)
        CLOSEHAND                   = uint8(2)
        PRONATIONW                  = uint8(4)
        SUPINATIONW                 = uint8(8)
        FLEXIONW                    = uint8(16)
        EXTENSIONW                  = uint8(32)
        FLEXIONE                    = uint8(64)
        EXTENSIONE                  = uint8(128)
        LATERAL                     = bitor(bitshift(1, 0), bitshift(1, 1)) % Lateral
        PINCH                       = bitor(bitshift(1, 2), bitshift(1, 3)) % Pinch
        CYLIND                      = bitor(bitshift(1, 4), bitshift(1, 5)) % Cylindrical

        NUM_CHAR_VR = 5;
        HANDTYPE = 1;
        

        % SD Card % 
        MAX_PARAMS 				= (7) 	            % Max number of lines
        DATA_SEGM 				= (32)	            % Lenght of the useful information
        DATALOG_SIZE			= (256)	            % Num Bytes Datalog % First_Release: DATALOG_SIZE = 239 
        DATALOG_SIZE_MAX_BT		= (237)	            % Num Bytes Datalog trasmissibili tramite BT
        DATALOG_SIZE_BLOCK		= (256)	            % Num Bytes of each Datalog Block
        EMGLOG_SIZE             = (3200)            % Num Bytes EMGLog 

        % IMU % 
        GRAVITY                     = single(9.81)
        BMI160_ACCEL_RANGE_2G_SENS = single(16384)
        BMI160_ACCEL_RANGE_4G_SENS = single(8192)
        BMI160_ACCEL_RANGE_8G_SENS = single(4096)
        BMI160_ACCEL_RANGE_16G_SENS = single(2048)

        BMI160_GYRO_RANGE_2000_DPS_SENS = single(16.4)
        BMI160_GYRO_RANGE_1000_DPS_SENS = single(32.8)
        BMI160_GYRO_RANGE_500_DPS_SENS = single(65.6)
        BMI160_GYRO_RANGE_250_DPS_SENS = single(131.2)
        BMI160_GYRO_RANGE_125_DPS_SENS = single(262.4)

        BMI323_ACCEL_CONVERSION_4G_SENS = single(9.81) * single(4.0) / single(2^16 / 2);
        BMI323_GYRO_CONVERSION_250_DPS_SENS = single(250.0) / single(2^16 / 2);

        % Hand Types
        GENERIC_HAND        = 0
        OTTOBOCK_SENSORHAND = 1
        PRENSILIA_MIAHAND   = 2
        OTTOBOCK            = 3
        MICHELANGELO_HAND   = 4

        GENERIC_HAND_NAME           = "Generic_Hand"
        OTTOBOCK_SENSORHAND_NAME    = "Ottobock_Sensorised_Hand"
        MIA_HAND_NAME               = "MIA_Hand"
        OTTOBOCK_NAME               = "Ottobock_Hand"
        MICHELANGELO_HAND_NAME      = "Michelangelo_Hand"
        

    end
    
    methods
        
        %% Class constructor
        %------------------------------------------------------------------
        function objMC = LimbMATE()
            objMC.last_TW_emg_package = zeros(objMC.EMG_NUM_CHANNELS, objMC.EMG_PACKAGE_SIZE, 'single');
            objMC.features_save_tw_package = zeros(objMC.EMG_NUM_CHANNELS, objMC.FEAT_NUM, 'single');
            objMC.raw_grasp_info_save_tw_package = zeros(objMC.RAW_GRASP_INFORMATION_SIZE, 1, 'single');
            objMC.class_DAC_params = zeros(objMC.DAC_CHANNELS, 1, "uint8");
            objMC.handInUse = objMC.GENERIC_HAND_NAME;
            objMC.graphical_information = struct('enable_graph', 0);


        end

        %% Connect to Bluetooth Device
        % Routine to scan devices around, get the respective information, and connect to the BT device with the matching name given on the input.
        % @param[in] BTname corresponeds to the BT device name to be connected with
        % @param[in] BTspeed corresponeds to the BT wireless communication speed (1Mb/s or 2Mb/s)
        % @return none
        function connectBTdevice(self, BTname, BTspeed)
            self.scanDevicesStart();         
            self.scanDevicesStop();
            self.getDevicesInfo();
            self.findBTdevice(BTname);
            self.connectFoundBTmodule();
            pause(1.5) % This delay is necessary for the BT Dongle, since it happened to interfere with further commands
            self.setSpeedBT(BTspeed); %Communication speed can be 1Mb/s or 2Mb/s 
            self.getDeviceName();
            self.getDeviceFirmware();
        end
        
        %% Disconnect Bluetooth devices
        % Routine to end the connection between both BT devices.
        % @return none
        %------------------------------------------------------------------
        % *CMD_DISCONNECT_REQ (0x02 07 00 00 05) /\ CMD_DISCONNECT_CNF (0x02 47 01 00 00 44) /\ CMD_DISCONNECT_IND (0x02 87 01 00 16 92)*
        function disconnectBTdevice(self)
            self.stopAcquisitionEMG();  %Making sure that the device is really without EMG acquisition before disconnecting,
                                            % otherwise needs hardreset because pin DRDY is just toggling non-stop, not allowing
                                            % to receive bluetooth data because of constant interruptions
            %LED Green OFF indicating end of acquisition
            self.setLED('G', 0)
            fprintf('\n BT devices disconnected Successfully! \n')
            try
                flush(self.serialObj);
                %Send CMD_DISCONNECT_REQ
                command(1) = hex2dec('02');
                command(2) = hex2dec('07'); 
                command(3) = hex2dec('00');
                command(4) = hex2dec('00');
                command(5) = hex2dec('05');
                write(self.serialObj,command(1:5),"uint8");
                %Receive CMD_DISCONNECT_CNF
                inputLength1 = 6;
                receivedDataDec1 = read(self.serialObj,inputLength1,"uint8");
                CMD_DISCONNECT_CNF = dec2hex(receivedDataDec1,2); %CMD_DISCONNECT_CNF (0x02 47 01 00 00 44)*
                self.verifyInputData(inputLength1,receivedDataDec1,self.CMD_BYTE_DISCONNECT_CNF);
                %Receive CMD_DISCONNECT_IND
                inputLength2 = 6;
                receivedDataDec2 = read(self.serialObj,inputLength2,"uint8"); 
                CMD_DISCONNECT_IND = dec2hex(receivedDataDec2,2); %CMD_DISCONNECT_IND (0x02 87 01 00 16 92)*
                self.verifyInputData(inputLength2,receivedDataDec2,self.CMD_BYTE_DISCONNECT_IND);
                
            catch
                % error message and exit
                error('LM: Error disconnecting the device.');
            end
        end

        %%  Verify if Data length and Checksum of input packages matches
        % Routine to verify if the data length and checksum of the received commands matches the expected ones.
        % @param[in] length of the data to be verified.
        % @param[in] data corresponding to the full BT package
        % @param[in] BT_command_expected is the value of the BT command header to be expected of the received data.
        % @return none
        %------------------------------------------------------------------
        function verifyInputData(self, length, data, BT_command_expected)
                %If BT wurth commands are invalid, datalength is too big, or if checksum is incorrect it gives error
                checksum = 0;
                BT_start_signal = dec2hex(data(1));
                BT_command = dec2hex(data(2));
                if (BT_start_signal ~= "2" || BT_command_expected ~= BT_command) 
                    if (self.emg_acquisition == false) %In case we are trying to stop acquisition, 
                        % don't give error, because we are trying to empty the buffer
                        error('LM: BT received command is invalid')
                    end
                end
                dataLength=(data(3) + bitshift(data(4),4)); %Read Data length LSB and MSB
                if (dataLength > self.MAX_DATA_LENGTH)
                    if (self.emg_acquisition == false)
                        error('LM: Datalength of package is too big')
                    end
                end
                
                for (i = 1:(length-1))
                    checksum = bitxor(checksum,data(i));
                end
                if (data(length) ~= checksum)
                    if (self.emg_acquisition == false)
                        error('LM: Checksum did not match')
                    end
                end
            end
            
        %% Connect to self.serialObj port
        % Routine to connect the computer to the BT Dongle. Returns 1 or 2, in case the BT is connected successfully or if it is already connected, respectively.
        % @param[in] port refers to the serial port in which the BT Dongle is connected.
        % @return 1 if connected with success, 2 if already connected
        %------------------------------------------------------------------
        % *CMD_GETSTATE_REQ (0x02 01 00 00 03) /\ CMD_GETSTATE_CNF (0x02 41 02 00 01 01 41)*
               function BT_state = connectBTdongle(self, port)
            %%Run command to arrive here without the GUI:
                %objLM = LimbMATE();
                %objLM.connectBTdongle("COM__");

            % Send CMD_GETSTATE_REQ and read 7 bytes back at a given baud rate.
            % Returns the reply as a row of uint8, or empty if no valid reply.
            tryOtherSpeed = true;
            candidate_bauds = unique([self.portBaudrate, 115200, 1000000], 'stable');

            got_reply = uint8([]);
            inputLength = 7;

            for kB = 1:numel(candidate_bauds)
                baud = candidate_bauds(kB);
                try
                    % Close any previously opened object
                    if ~isempty(self.serialObj)
                        try
                            delete(self.serialObj);
                        catch
                        end
                        self.serialObj = [];
                    end

                    lastwarn('');   % clear any lingering warning
                    self.serialObj = serialport(port, baud, "FlowControl", self.portFlowControl);
                    pause(0.2);
                    flush(self.serialObj);

                    % Send CMD_GETSTATE_REQ
                    cmd = uint8([hex2dec('02'), hex2dec('01'), 0, 0, hex2dec('03')]);
                    write(self.serialObj, cmd, "uint8");

                    % Wait a moment for the reply to arrive
                    pause(0.3);
                    n = self.serialObj.NumBytesAvailable;
                    if n >= 7
                        reply = read(self.serialObj, 7, "uint8");
                    else
                        reply = uint8([]);
                    end

                    % A valid reply starts with 0x02 0x41
                    if numel(reply) == 7 && reply(1) == hex2dec('02') && reply(2) == hex2dec('41')
                        fprintf('connectBTdongle: dongle answered at %d bps\n', baud);
                        self.portBaudrate = baud;   % remember the working speed
                        got_reply = reply;
                        tryOtherSpeed = false;
                        break;
                    else
                        fprintf('connectBTdongle: no valid reply at %d bps, trying next\n', baud);
                    end
                catch ME
                    fprintf('connectBTdongle: open/IO failed at %d bps: %s\n', baud, ME.message);
                end
            end

            if ~tryOtherSpeed
                % got_reply is the CMD_GETSTATE_CNF
                receivedDataDec = got_reply;
                CMD_GETSTATE_CNF = dec2hex(receivedDataDec, 2);

                self.verifyInputData(inputLength, receivedDataDec, self.CMD_BYTE_GETSTATE_CNF);
                if (CMD_GETSTATE_CNF(6,:) == "01")
                    BT_state = 1;
                    disp('The device is connected via serialport.');
                elseif (CMD_GETSTATE_CNF(6,:) == "03")
                    BT_state = 2;
                    receivedDataDec = read(self.serialObj, 7, "uint8");
                    dec2hex(receivedDataDec);
                    disp('The device was already connected via serialport!');
                end
                return
            end

            % No speed worked
            error('Error setting Bluetooth Dongle baudrate');
        end

        %% Set BT communication speed (1Mb/s or 2Mb/s)
        % Routine to set the bluetooth wireless communication speed to either 1Mb/s or 2Mb/s
        % @param[in] speed of the bluetooth wireless communication
        % @return none
        %-----------------------------------------------------------------
        % CMD_PHYUPDATE_REQ (0x02 1A 01 00 + PHY(1) + CS(1)) / \ CMD_PHYUPDATE_CNF (0x02 5A 01 00 Status(1) CS(1)) \ CMD_PHYUPDATE_IND (0x02 9A 09 00 Status(1) PHY Rx(1) PHY Tx(1) BTMAC(6) CS(1))*
        function setSpeedBT(self, speed)
            try
            flush(self.serialObj);
            command(1) = hex2dec('02');
            command(2) = hex2dec('1A'); 
            command(3) = hex2dec('01');
            command(4) = hex2dec('00');
            command(5) = hex2dec(speed);
            packageLength = 5;
            checksum = 0;
            for (i = 1:packageLength)
                checksum = bitxor(checksum,command(i));
            end
            command(6) = checksum;
            write(self.serialObj,command(1:6),"uint8");
            inputLength1 = 6;
            receivedDataDec1 = read(self.serialObj,inputLength1,"uint8");
            CMD_PHYUPDATE_CNF = dec2hex(receivedDataDec1,2); 
            self.verifyInputData(inputLength1,receivedDataDec1,self.CMD_BYTE_PHYUPDATE_CNF);
            inputLength2 = 14;
            receivedDataDec2 = read(self.serialObj,inputLength2,"uint8");
            CMD_PHYUPDATE_IND = dec2hex(receivedDataDec2,2); 
            self.verifyInputData(inputLength2,receivedDataDec2,self.CMD_BYTE_PHYUPDATE_IND);

            self.conn_text = sprintf('BT communication speed set Successfully to %c Mb/s!\n',speed);
            disp(self.conn_text);
            catch
            % error message and exit
            error('LM: Error setting Bluetooth communication speed.');
            end
        end


        %% Set BT Dongle baudrate 
        % Routine to set the baudrate speed of the BT dongle.
        % After running this function, the program will update the USB baudrate, but then will give error because the Matlab
        %baudarte does not match, so then change the variable "portBaudrate" in properties to the wanted baudrate.
        %-----------------------------------------------------------------
        function setBaudRateBT(self, baudrate)

            switch baudrate
                case 115200
                    baudByte = 23;
                case 921600
                    baudByte = 31;
                case 1000000
                    baudByte = 33;
                otherwise
                    error('baudrate not supported by the device');
                return
            end

            try
            flush(self.serialObj);
            command(1) = hex2dec('02');
            command(2) = hex2dec('11'); 
            command(3) = hex2dec('02');
            command(4) = hex2dec('00');
            command(5) = hex2dec('0B');
            command(6) = baudByte; %Already decimal
            packageLength = 6;
            checksum = 0;
            for (i = 1:packageLength)
                checksum = bitxor(checksum,command(i));
            end
            command(7) = checksum;
            write(self.serialObj,command(1:7),"uint8");
            inputLength = 6;
            receivedDataDec = read(self.serialObj,inputLength,"uint8");
            CMD_SET_CNF = dec2hex(receivedDataDec,2); 
            self.verifyInputData(inputLength,receivedDataDec,self.CMD_BYTE_SET_CNF);
            fprintf('BT Dongle baudrate set Successfully to %d bps!\n',baudrate);
            catch
            % error message and exit
            error('LM: Error setting Bluetooth Dongle baudrate.');
            end
        end

        %% Get MAC Adress
        % Routine to acquire the BT dongle MAC adress.
        % @return none
        %------------------------------------------------------------------
        % *CMD_GET_REQ (0x02 10 01 00 04 17) /\ CMD_GET_CNF (0x02 50 07 00 00 + FS_BTMAC(6) + CS(1))*
        %   FS_BTMAC USB-PEN = 0xEA 7E 32 DA 18 00      EVALUATION BOARD = D0 8D 32 DA 18 00
        function getBTdongleMAC(self)
            flush(self.serialObj);
            %Send CMD_GET_REG
            command(1) = hex2dec('02');
            command(2) = hex2dec('10');
            command(3) = hex2dec('01');
            command(4) = hex2dec('00');
            command(5) = hex2dec('04');
            command(6) = hex2dec('17');
            write(self.serialObj,command(1:6),"uint8");
            %Receive CMD_GET_CNF
            inputLength = 12;
            receivedDataDec = read(self.serialObj,inputLength,"uint8");
            self.verifyInputData(inputLength,receivedDataDec,self.CMD_BYTE_GET_CNF);
            CMD_GET_CNF = dec2hex(receivedDataDec,2);
            self.USBstickMAC = CMD_GET_CNF(6:11,:);
            fprintf('USB-Stick MAC adress: %c%c %c%c %c%c %c%c %c%c %c%c\n',USBstickMAC(1,:),USBstickMAC(2,:),USBstickMAC(3,:),USBstickMAC(4,:),USBstickMAC(5,:),USBstickMAC(6,:))
        end

        %% Start Scanning Bluetooths in surroundings
        % Routine to scan for bluetooth devices in the surroundings (only Wurth-Proteus devices are detected)
        % @return none
        %------------------------------------------------------------------
        % CMD_SCANSTART_REQ (0x02 09 00 00 0B) /\ CMD_SCANSTART_CNF (0x02 49 01 00 + Status(1) + CS(1))
        function scanDevicesStart(self)
            self.conn_text = "Start scanning bluetooth devices...";
            disp(self.conn_text);

            % Reset Warnings
            lastwarn('') % Clear last warning message

            pause(0.1);
            flush(self.serialObj);
            %Send CMD_SCANSTART_REQ
            command=zeros(0);
            command(1) = hex2dec('02');
            command(2) = hex2dec('09');
            command(3) = hex2dec('00');
            command(4) = hex2dec('00');
            command(5) = hex2dec('0B');
            write(self.serialObj,command(1:5),"uint8");
            %Receive CMD_SCANSTART_CNF
            inputLength = 6;
            receivedDataDec = read(self.serialObj,inputLength,"uint8");
            self.verifyInputData(inputLength,receivedDataDec,self.CMD_BYTE_SCANSTART_CNF);
            CMD_SCANSTART_CNF = dec2hex(receivedDataDec,2); %Response  CMD_SCANSTART_CNF
            %Repeat CMD_SCANSTART_REQ in case operation failed
            while (CMD_SCANSTART_CNF(5,:) ~= "00")
                pause(1);
                flush(self.serialObj);
                write(self.serialObj,command(1:5),"uint8");
                receivedDataDec = read(self.serialObj,inputLength,"uint8");
                self.verifyInputData(inputLength,receivedDataDec,self.CMD_BYTE_SCANSTART_CNF);
                CMD_SCANSTART_CNF = dec2hex(receivedDataDec,2); %Response CMD_SCANSTART_CNF
            end

            % Check for a Timeout
            [warnMsg, warnId] = lastwarn;
            if ~isempty(warnMsg)
                error('A timeout has occurred on scanning BT Devices')
            end
        end

        %% Stop Scanning Bluetooths in surroundings
        % Routine to stop scanning for bluetooth devices in the surroundings
        % @return none
        %------------------------------------------------------------------
        % CMD_SCANSTOP_REQ (0x02 0A 00 00 08) /\ CMD_SCANSTOP_CNF (0x02 4A 01 00 + Status(1) + CS(1))
        function scanDevicesStop(self)
            self.conn_text = "Stop scanning bluetooth devices...";
            disp(self.conn_text);
            pause(0.1);
            flush(self.serialObj);
            %Send CMD_SCANSTOP_REQ
            command=zeros(0);
            command(1) = hex2dec('02');
            command(2) = hex2dec('0A');
            command(3) = hex2dec('00');
            command(4) = hex2dec('00');
            command(5) = hex2dec('08');
            write(self.serialObj,command(1:5),"uint8");
            %Receive CMD_SCANSTOP_CNF
            inputLength = 6;
            receivedDataDec = read(self.serialObj,inputLength,"uint8");
            self.verifyInputData(inputLength,receivedDataDec,self.CMD_BYTE_SCANSTOP_CNF);
            CMD_SCANSTOP_CNF = dec2hex(receivedDataDec,2); %Response  CMD_SCANSTOP_CNF
            %Repeat CMD_SCANSTOP_REQ in case operation failed
            while (CMD_SCANSTOP_CNF(5,:) ~= "00") 
                pause(1);
                flush(self.serialObj);
                write(self.serialObj,command(1:5),"uint8");
                receivedDataDec = read(self.serialObj,inputLength,"uint8");
                self.verifyInputData(inputLength,receivedDataDec,self.CMD_BYTE_SCANSTOP_CNF);
                CMD_SCANSTOP_CNF = dec2hex(receivedDataDec,2); %Response CMD_SCANSTOP_CNF
            end
        end

        %% Get Information from Devices in surroundings (Name of Device + MAC address) and save on structure "BTdevices"
        % Routine to get information from the discovered devices in the surroundings resulted from the scanning
        % @return none
        %------------------------------------------------------------------
        % CMD_GETDEVICES_REQ (0x02 0B 00 00 09) /\ CMD_GETDEVICES_CNF (0x02 4B + Length(2) + Status(1) + Devices + Payload + CS)
        function getDevicesInfo(self)
            self.conn_text = "Getting information from bluetooth devices...";
            disp(self.conn_text);
            pause(0.1);
            flush(self.serialObj);
            %Send CMD_GETDEVICES_REQ
            command=zeros(0);
            command(1) = hex2dec('02');
            command(2) = hex2dec('0B');
            command(3) = hex2dec('00');
            command(4) = hex2dec('00');
            command(5) = hex2dec('09');
            [line,length]=size(command);
            checksum = 0;
            for (i = 1:length)
                checksum = bitxor(checksum,command(i));
            end
            command(length+1) = checksum;
            write(self.serialObj,command(1:(length + 1)),"uint8");
            %Receive CMD_GETDEVICES_CNF first 4 bytes
            inputLength = 4;
            receivedDataDec = read(self.serialObj,inputLength,"uint8");
            dataLength=(receivedDataDec(3) + bitshift(receivedDataDec(4),8)); %Read Data length LSB and MSB
            inputLength = dataLength + 1;
            receivedDataDec (5:(4+inputLength)) = zeros();
            receivedDataDec (5:(4+inputLength)) = read(self.serialObj,inputLength,"uint8");
            self.verifyInputData((4+inputLength),receivedDataDec,self.CMD_BYTE_GETDEVICES_CNF);
            CMD_GETDEVICES_CNF = dec2hex(receivedDataDec,2); %Response CMD_GETDEVICES_CNF
            %Repeat CMD_GETDEVICES_REQ in case operation failed
            while (CMD_GETDEVICES_CNF(5,:) ~= "00") %In case command/connection not successfully achieved, try again
                pause(1);
                flush(self.serialObj);
                write(self.serialObj,command(1:(length + 1)),"uint8");
                %Receive CMD_GETDEVICES_CNF first 4 bytes
                inputLength = 4;
                receivedDataDec = read(self.serialObj,inputLength,"uint8");
                dataLength=(receivedDataDec(3) + bitshift(receivedDataDec(4),8)); %Read Data length LSB and MSB
                inputLength = dataLength + 1;
                %Status (1) + #Devices (1) + Payload [BTMAC(6) + RSSI(1) + TXPower(1) + NAMELENGTH(1) + NAME(1-5)] + checksum
                receivedDataDec (5:(inputLength)) = read(self.serialObj,inputLength,"uint8"); 
                self.verifyInputData((4+inputLength),receivedDataDec,self.CMD_BYTE_GETDEVICES_CNF);
                CMD_GETDEVICES_CNF = dec2hex(receivedDataDec,2); %Response CMD_GETDEVICES_CNF
            end
            %Number of devices detected on scan
            self.devicesNumber = receivedDataDec(6);
            %Acquire MAC adress and Device name from detected devices
            %See page (69/235) from ProteusIII Manual to understand better
            %Read Payload from CMD_GETDEVICES_REQ 
            %inputLength incldues (Status(1) + #Devices(1)) which are to be ignored
            receivedDataCopy = receivedDataDec(7:(4+inputLength));
            deviceName = zeros(self.devicesNumber,5);
            if (self.devicesNumber > 0)
                for (i = 1:self.devicesNumber)
                    temp_deviceMAC = receivedDataCopy(1:6);
                    temp_deviceNameLength = receivedDataCopy(9);
                    temp_deviceName = [];
                    temp_deviceName(1:temp_deviceNameLength) = receivedDataCopy(10:(9+temp_deviceNameLength));
                    nextIndex = 9 + temp_deviceNameLength + 1;
                    receivedDataCopy = receivedDataCopy(nextIndex:end);
                    %fprintf('Module Name(%d): %c %c %c %c %c\n',i, char(deviceName(i,1)),char(deviceName(i,2)),char(deviceName(i,3)),char(deviceName(i,4)),char(deviceName(i,5)))
                    fprintf('Module Name(%d): ',i);
                    for (j = 1:temp_deviceNameLength)
                        fprintf('%c',char(temp_deviceName(j)));
                    end
                    fprintf('\n');
                    BTdevices(i) = struct('DeviceName',uint8(temp_deviceName),'MACadress',uint8(temp_deviceMAC));
                end
            else
                error ('LM: No devices found');
            end
            self.BTdevices = BTdevices;
        end

        %% Find Bluetooth Device LMATE
        % Routine to verify is there is a specific BT device from the list of discovered BT devices in the surroundings
        % @param[in] BTname refers to the name of the BT device we want to connect with.
        % @return none
        %------------------------------------------------------------------
        function findBTdevice(self, BTname)
            findBT = 0;
            for (i = 1:self.devicesNumber)
                if (strcmp((char(self.BTdevices(i).DeviceName)),BTname)==1)
                 findBT = 1;
                 self.BTindex = i;
                end
            end

            if (findBT == 1)
                self.conn_text = sprintf('Bluetooth %s found\n',BTname);
                disp(self.conn_text);
            else
                error('LM: Bluetooth LMATE not found.');
            end
        end

        %% Test connection to the BT module
        % Routine to connect to the desired BT device found in the scanning list of devices
        % @return none
        %------------------------------------------------------------------
        % *CMD_CONNECT_REQ (0x02 06 06 00 + FS_BTMAC(EV.BOARD) (6) + CS(1)) /\ CMD_CONNECT_CNF (0x02 46 01 00 00 45) \ CMD_CONNECT_IND (0x02 86 07 00 00 BTMAC(6) CS(1)) \ CMD_CHANNELOPEN_RSP (0x02 C6 08 00 00 BTMAC(6) MaxPayload(1) CS(1)) *
        %  FS_BTMAC USB-PEN = 0xEA 7E 32 DA 18 00      EVALUATION BOARD = D0 8D 32 DA 18 00
        function connectFoundBTmodule(self)
            BTmoduleMACdec = self.BTdevices(self.BTindex).MACadress;
            disp('connecting...');
            pause(3);
            flush(self.serialObj);
            %Send CMD_CONNECT_REQ
            command=zeros(0);
            command(1) = hex2dec('02');
            command(2) = hex2dec('06');
            command(3) = hex2dec('06');
            command(4) = hex2dec('00');
            command(5) = BTmoduleMACdec(1);
            command(6) = BTmoduleMACdec(2);
            command(7) = BTmoduleMACdec(3);
            command(8) = BTmoduleMACdec(4);
            command(9) = BTmoduleMACdec(5);
            command(10) = BTmoduleMACdec(6);
            [line,length]=size(command);
            checksum = 0;
            for (i = 1:length)
                checksum = bitxor(checksum,command(i));
            end
            command(length+1) = checksum;         
            write(self.serialObj,command(1:11),"uint8");
            %Receive CMD_CONNECT_CNF
            inputLength1 = 6;
            receivedDataDec1 = read(self.serialObj,inputLength1,"uint8"); 
            self.verifyInputData(inputLength1,receivedDataDec1,self.CMD_BYTE_CONNECT_CNF);
            CMD_CONNECT_CNF = dec2hex(receivedDataDec1,2); %Response CMD_CONNECT_CNF
            %Repeat CMD_CONNECT_REQ in case operation failed
            while (CMD_CONNECT_CNF(5,:) ~= "00") 
                pause(1);
                flush(self.serialObj);
                write(s,command(1:11),"uint8");
                receivedDataDec1 = read(self.serialObj,6,"uint8")
                self.verifyInputData(inputLength1,receivedDataDec1,self.CMD_BYTE_CONNECT_CNF);
                CMD_CONNECT_CNF = dec2hex(receivedDataDec1,2); %Response CMD_CONNECT_CNF
            end
            %Receive CMD_CONNECT_IND
            inputLength2 = 12; % Only for successful connection --weak
            receivedDataDec2 = read(self.serialObj,inputLength2,"uint8"); ;
            self.verifyInputData(inputLength2,receivedDataDec2,self.CMD_BYTE_CONNECT_IND);
            CMD_CONNECT_IND = dec2hex(receivedDataDec2,2); %Indication CMD_CONNECT_IND
            %Check if connection was successfull by USB BT Stick response
            if (CMD_CONNECT_IND(5,:) == "00") 
                inputLength3 = 13;
                %Receive CMD_CHANNELOPEN_RSP
                receivedDataDec3 = read(self.serialObj,inputLength3,"uint8");
                self.verifyInputData(inputLength3,receivedDataDec3,self.CMD_BYTE_CHANNELOPEN_RSP);
                CMD_CHANNELOPEN_RSP = dec2hex(receivedDataDec3,2); %Indication CMD_CHANNELOPEN_RSP

                % self.conn_text = "Connected to Bluetooth Module LMATE with Success!!";
                disp(self.conn_text);
            else
                error('LM: Failed on Connecting to Bluetooth Module.')
            end
        end


        %% Send command
        % Routine to send a command via BT to the Limb-MATE. Returns if data was sent with success or not.
        % @param[in] LM_command refers to the task that is intended to send to Limb-MATE
        % @param[in] data is the payload to send with respet to the LM_command
        % @param[in] dataLength is the length of the message to send
        % @return 1 if error
        %------------------------------------------------------------------
        % *CMD_DATA_REQ (0x02 04 + dataLength(2) + opcode(1) + data(#) + checksum(1) / \ CMD_DATA_CNF (0x02 44 01 00 00 47) \ CMD_TXCOMPLETE_RSP (0x02 C4 01 00 00 C7)*          
        function result = sendCommand(self, LM_command, data, dataLength)
            %Payload Length(bytes) = opcode(1) + data(dataLength)
            dataLength = dataLength + 1; 
            if(dataLength > self.MAX_DATA_LENGTH)
                error('LM: message is too long!');
                return
            end
            % Set packagebyte 3 and 4 with LSB and MSB of datalength 
            % (apart from checksum)
            dataLengthHex=dec2hex(dataLength,4);
            dataLengthLSB= dataLengthHex(3:4);
            dataLengthMSB= dataLengthHex(1:2);
            
            pause(0.1);
            flush(self.serialObj);
            %Send CMD_DATA_REQ
            command=zeros(0);
            command(1) = hex2dec('02');
            command(2) = hex2dec('04');
            command(3) = hex2dec(dataLengthLSB);
            command(4) = hex2dec(dataLengthMSB);
            command(5) = hex2dec(LM_command);
            for (i = 1: (dataLength-1))
                command(i+5) = data(i);
            end
            packageLength = 4 + dataLength;
            checksum = 0;
            for (i = 1:packageLength)
                checksum = bitxor(checksum,command(i));
            end
            command(packageLength+1) = checksum;
            write(self.serialObj,command(1:(packageLength+1)),"uint8");
            %Receive CMD_DATA_CNF
            inputLength1 = 6;
            receivedDataDec1 = read(self.serialObj,inputLength1,"uint8");
            CMD_DATA_CNF = dec2hex(receivedDataDec1,2); %Response CMD_DATA_CNF
            self.verifyInputData(inputLength1,receivedDataDec1,self.CMD_BYTE_DATA_CNF);
            %Repeat CMD_DATA_REQ in case operation failed
            while (CMD_DATA_CNF(5,:) ~= "00") %In case data not successfully sent, try again
                pause(1);
                flush(self.serialObj);
                write(self.serialObj,command(1:(packageLength+1)),"uint8");
                receivedDataDec1 = read(self.serialObj,inputLength1,"uint8"); 
                self.verifyInputData(inputLength1,receivedDataDec1,self.CMD_BYTE_DATA_CNF);
                CMD_DATA_CNF = dec2hex(receivedDataDec1,2); %Response CMD_DATA_CNF
            end
            %Receive CMD_TXCOMPLETE_RSP
            inputLength2 = 6;
            receivedDataDec2 = read(self.serialObj,inputLength2,"uint8"); 
            self.verifyInputData(inputLength2,receivedDataDec2,self.CMD_BYTE_TXCOMPLETE_RSP);
            CMD_TXCOMPLETE_RSP = dec2hex(receivedDataDec2,2); %Indication CMD_TXCOMPLETE_RSP
            if (CMD_TXCOMPLETE_RSP(5,:) == "00")
                result = 0; %Sent command with success
            else 
                result = 1; %Sent commadn with no success
            end
        end

        %% Receive reply
        % Routine to receive a reply from the Limb-MATE, after a command is sent.
        % Lastly, it returns the data payload received.
        % @param[in] LM_command refers to the command that the reply should be associated with.
        % @return data received
        %------------------------------------------------------------------
        % *\ CMD_DATA_IND (0x02 84 dataLength(2) + BT Mac(6) + RSSI(1) + data(#) + checksum(1))*
        function [data] = receiveReply(self, LM_command)
            %Receive CMD_DATA_IND first 4 bytes
            inputLength1 = 4;
            receivedDataDec = read(self.serialObj,inputLength1,'uint8');
            copy_of_receivedDataDec1 = receivedDataDec;
            %In case it waits too long to receive data, or receives zeros when trying to stop acquisition, or it does not receive a CMD_DATA_IND command, flush and return
            if ((isempty(receivedDataDec) || sum(receivedDataDec) == 0) || (receivedDataDec(2) ~= hex2dec('84')) && self.emg_acquisition == true) 
            %if (isempty(receivedDataDec) && self.emg_acquisition == true) %In case it waits too long to receive data
                %but receives nothing, and it is the reply from MCU
                %noticing stop acuiqistion with sucess, then try again
                flush(self.serialObj);
                data = zeros(1,2);
                return
            end
            dataLength=(receivedDataDec(3) + bitshift(receivedDataDec(4),8)); %Read Data length LSB and MSB
            inputLength2 = dataLength + 1;
            receivedDataDec (5:(4+inputLength2)) = zeros();

            try
            receivedDataDec (5:(4+inputLength2)) = read(self.serialObj,inputLength2,"uint8");
            catch
                receivedDataDec
                error('Error "Unable to perform assignment because the left and right sides have a different number of elements." stop command')
            end
            self.verifyInputData((4+inputLength2),receivedDataDec,self.CMD_BYTE_DATA_IND);

            CMD_DATA_IND = dec2hex(receivedDataDec,2); %Response CMD_DATA_IND

            %Trying to understand error "Index exceeds the number of array elements. Index must not exceed 5."
            try
                    reply = receivedDataDec(12);           %first byte of Data sent by Limb-MATE (page 81/235 BT manual)
            catch
                copy_of_receivedDataDec1
                receivedDataDec
                error('Error "Index exceeds the number of array elements. Index must not exceed 5." stop command')
            end

            if (reply ~= hex2dec(LM_command) && self.emg_acquisition == false) %Check if the Sent CMD mathes with the reply CMD
                %Give error only in case not sending command to
                %stop.acquisition, because it might need multiple tries of
                %requests to stop
                error ('LM: LM_CMD does not match.')
            end
            if (self.emg_acquisition == true)
                data = receivedDataDec(12:(end-1));    %rest of Data sent by Limb-MATE (including LM_command)
            else
                data = dec2hex(receivedDataDec(13:(end-1)));    %rest of Data sent by Limb-MATE
            end
        end
        
        %% Test connection
        % Routine to test the BT connectiong between the bluetooth devices
        % @return none
        %------------------------------------------------------------------
        function testConnection(self)
            % send command!
            result = self.sendCommand(self.ARE_YOU_ALIVE, 0, 0);
            if (result == 0)
                fprintf('Connection tested Successfully!\n\n')
            else
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.ARE_YOU_ALIVE);
        end

        %% Turn LED ON or OFF
        % Routine to send command to turn ON or OFF the Limb-MATE onboard LED.
        % @param[in] colour:    Colour of the LED ["R", "G", "B"]
        % @param[in] state:     refers to the LED state we want to set.
        % @return none
        %-----------------------------------------------------------------
        function setLED(self, colour, state)
            colour_upper = upper(colour);
            switch colour_upper
                case 'R'
                    colour_encoded = 1;
                case 'G'
                    colour_encoded = 2;
                case 'B'
                    colour_encoded = 3;
                otherwise
                    colour_encoded = 1;
            end

            % send command!
            result = self.sendCommand(self.TOGGLE_LED, [colour_encoded, state], 2);
            if (result == 0)
                if (state == 0)
                    disp('LED set OFF with Success!!')
                else
                    disp('LED set ON with Success!!') 
                end
            else
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.TOGGLE_LED);
        end

        %% Write BT connection
        % Routine to Write BT data into a buffer
        % @return the appended buffer
        %------------------------------------------------------------------
        function appended_buffer = write_BT(self, buffer, new_data)
            % Oblise to be vertical vector
            [nRow, nCol] = size(new_data);
            new_data_v = zeros(max(nRow, nCol), min(nRow, nCol));
            new_data_v(:) = new_data;
            appended_buffer = vertcat(buffer, new_data_v);
            if length(appended_buffer) > self.MAX_DATA_LENGTH
                error('The Message cannot exeed a certain length')
            end
        end

        %% Read BT connection
        % Routine to reset the BT counter
        % @return none
        %------------------------------------------------------------------
        function reset_read_BT_counter(self)
            % Reset previous counter
            self.current_position_BT = 1;
        end

        %% Read BT connection
        % Routine to read BT data into a buffer
        % @return the appended buffer
        %------------------------------------------------------------------
        function [read_buffer] = read_BT(self, buffer, num_samples, type)
            % Retrive previous counter
            counter_in = self.current_position_BT;
            % Determine the number of bytes depending on the Type
            if strcmp(type, 'single') || strcmp(type, 'uint32') || strcmp(type, 'int32')
                num_bytes = 4 * num_samples;
            elseif strcmp(type, 'uint16') || strcmp(type, 'int16')
                num_bytes = 2 * num_samples;
            else
                num_bytes = num_samples;
            end
            buffer_u8 = uint8(buffer);
            read_buffer_portion = buffer_u8(counter_in:counter_in+num_bytes-1);
            read_buffer = typecast(read_buffer_portion, type);
            self.current_position_BT = counter_in + num_bytes;
        end

        %% Matrix to uint8
        % Given a [NxM] matrix, return a [num_bytes*M x N] matrix of uint8
        % @return matrix of uint8
        %------------------------------------------------------------------
        function matrix_u8 = matrix_to_u8(self, new_matrix)
            [numR, numC] = size(new_matrix);
            new_matrix_t = new_matrix';
            new_matrix_t_v = new_matrix_t(:);
            new_matrix_t_v8 = typecast(new_matrix_t_v, "uint8");
            new_matrix_t_m8 = reshape(new_matrix_t_v8, [], numR);
            matrix_u8 = new_matrix_t_m8;
        end

        %% Set Imu Direction 
        % Routine to send command to Set Imu Direction 
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function setIMUDir(self)
            % send command!
            state = uint8(self.imu_direction.direction); % state: 0: Pitch, 1: Roll
            offset= typecast(single(self.imu_direction.offset), "uint8");
            payload = [state, offset];
            result = self.sendCommand(self.SET_IMU_DIR, payload, length(payload));
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.SET_IMU_DIR);
            error_set_IMU_Dir_params = hex2dec(dataHex(1,:));
            % Check the Values of Imu Direction 
            if (error_set_IMU_Dir_params == 0)  
                disp('IMU Dir Params set successfully \n!')
            else
                disp('IMU Dir Params set NOT successfully \n!')
            end
        end

        %% Get Imu Direction 
        % Routine to send command to turn Imu Direction 
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function getIMUDir(self)
            self.imu_direction = [];
            % send command!
            result = self.sendCommand(self.GET_IMU_DIR, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_IMU_DIR);
            dataDec = hex2dec(dataHex);
            self.imu_direction.direction = dataDec(1);
            self.imu_direction.offset = typecast(uint8(dataDec(4-1 + 2:-1:2)), 'single');
            
        end

        %% Set Wrist PinMode
        % Routine to send command to Set wrist_pinMode
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function setWristPinMode(self)
            % send command!
            general_information = [];
            general_information = self.write_BT(general_information, uint8(self.wrist_pinMode) );
            result = self.sendCommand(self.SET_WRIST_PIN_MODE, general_information, length(general_information));
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.SET_WRIST_PIN_MODE);
            error_set_Wrist_PinMode_params = hex2dec(dataHex(1,:));
            % Check the Values of Imu Direction 
            if (error_set_Wrist_PinMode_params == 0)  
                disp('Wrist PinMode set successfully \n!')
            else
                disp('Wrist PinMode set NOT successfully \n!')
            end
        end

        %% Get Wrist PinMode
        % Routine to send command to Get Wrist PinMode
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function getWristPinMode(self)
            % send command!
            result = self.sendCommand(self.GET_WRIST_PIN_MODE, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_WRIST_PIN_MODE);
            dataDec = hex2dec(dataHex);
            dataDec = uint8(dataDec);
            self.reset_read_BT_counter();
            self.wrist_pinMode = self.read_BT(dataDec, 1, 'uint8');
        end

        %% Get Battery Voltage
        % Routine to send command to acquire the battery voltage in mV,
        % saved on the battVoltage properties of the class
        % @return none 
        %-----------------------------------------------------------------
        function getBatteryVoltage(self)
            % send command!
            result = self.sendCommand(self.GET_BATTERY_VOLTAGE, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_BATTERY_VOLTAGE);
            dataDec = hex2dec(dataHex);
            battVoltageADC = bitshift(dataDec(1),8) + dataDec(2); %Read Data length MSB first and LSB second
            self.battVoltage = battVoltageADC * self.BATT_MAX_VOLTAGE / 4095; %Voltage divider is set to output 3.3V (4095) when input is 20V
            disp(['Battery voltage: ', num2str(self.battVoltage) ' V']);
        end

        %% Get Temperature
        % Routine to get the temperature in °C saved on the temperature properties of the class
        % @return none 
        %-----------------------------------------------------------------
        function getTemperature(self)
            % send command!
            result = self.sendCommand(self.GET_TEMPERATURE, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_TEMPERATURE);
            dataDec = hex2dec(dataHex);
            self.temperature = double(typecast(uint8(dataDec(1:4)), "single"));
            disp(['Temperature: ', num2str(self.temperature) ' °C']);
        end
        
    
        %% Get Device Name
        % Routine to send command to get the device name to which we are connected with via bluetooth.
        % saved on the DeviceName properties of the class
        % @return none
        function getDeviceName(self)
            % Reset Warnings
            lastwarn('') % Clear last warning message

            % send command!
            result = self.sendCommand(self.GET_DEVICE_NAME, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_DEVICE_NAME);
            dataDec = hex2dec(dataHex);
            [sizeData, b] = size(dataDec);

            DeviceName = "";
            for i = 1:sizeData
                DeviceName = strcat(DeviceName, char(dataDec(i)));
            end
            self.deviceName = DeviceName;
            self.conn_text = strcat("Device name: ", DeviceName);
            disp(self.conn_text);
            fprintf("\n")

            % Check for a Timeout
            [warnMsg, warnId] = lastwarn;
            if ~isempty(warnMsg)
                error('A timeout has occurred on scanning BT Devices')
            end
        end

        %% Get Device Firmware
        % Routine to send command to get the firmware version of the device we are connected with.
        % saved on the FirmwareName properties of the class
        % @return none
        function  getDeviceFirmware(self)
            % send command!
            result = self.sendCommand(self.GET_FIRMWARE_VERSION, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_FIRMWARE_VERSION);
            dataDec = hex2dec(dataHex);
            [sizeData, b] = size(dataDec);
            FirmwareName = "";
            for i = 1:sizeData
                FirmwareName = strcat(FirmwareName, char(dataDec(i)));
            end
            self.deviceFirmware = FirmwareName;
            self.conn_text = strcat("Device Firmware: ", FirmwareName);
            disp(self.conn_text);
            fprintf("\n")
        end
    
        %% Start EMG Acquisition
        % Routine to send the command to start EMG acquisition.
        % Receives parameter to set if Limb-MATE should stream the data (streamFlag = 1) or not (streamFlag = 0).
        % @param[in] streamFlag:                    flag to indicate if it is also to stream the data to the PC.
        % @param[in] active_channels_encoded:		where every bit represents if the channel is selected or not
        % @param[in] samples_tw_encoded:			encoded number of samples of the TW (1:100; 2:200, ...)
        % @param[in] samples_tw_overlap_encoded:	encoded number of overlap samples of the TW (0:0; 1:25, 2:50, 3:75 ...)
        % @return none
        function startAcquisitionEMG(self, streamFlag, active_channels_encoded, samples_tw_encoded, samples_tw_overlap_encoded)    

            % Clear some General variables
            self.emg_data = [];
            self.temp_emg_data = [];
            self.residual_emg_data = [];
            self.streamed_features = [];
            self.features_save_tw_package = zeros(self.EMG_NUM_CHANNELS, self.FEAT_NUM, 'single');
            self.raw_grasp_info_save_tw_package = zeros(1 + self.NUM_DOF + self.RAW_GRASP_INFORMATION_SIZE , 1, 'single');
            self.temp_streamed_features = [];
            self.temp_streamed_control = [];
            self.streamed_control = [];
            self.temp_features = [];
            self.temp_control = [];
            self.features_control = [];
            self.plot_index_counter = 1;
            self.MAV_max_v = zeros(self.EMG_NUM_CHANNELS, 1);
            self.MAV_min_v = zeros(self.EMG_NUM_CHANNELS, 1);
            self.MAV_max = 0; self.STD_max = 0; self.WL_max = 0; self.ZC_max = 0; self.SLP_max = 0;
            self.min_current = -1; self.max_current = 1;
            self.min_force = -1; self.max_force = 1;
            self.min_imu = -1; self.max_imu = 1;
            self.Act_Lev_max = 0;
            self.stopped_acquisition = 0;
            self.timer_TW = 0;
            self.packages_lost_index_total = [];
            self.num_incremental_TW = 0;
            self.num_TW = 0;
            self.first_TW_received = true;            
            self.hand_parameters = [];
            self.start_acquisition_datetime = datetime("now");

            fprintf('samples_tw_encoded: %u; samples_tw_overlap_encoded: %u; TestMode: %u; Filters: %u; \n', samples_tw_encoded,samples_tw_overlap_encoded,  uint8(self.enable_testmode), uint8(self.enabled_filters));

            % send command!
            result = self.sendCommand(self.START_ACQ_ADS1299, [uint8(streamFlag), active_channels_encoded, samples_tw_encoded, samples_tw_overlap_encoded, uint8(self.enable_testmode), uint8(self.enabled_filters)], 6);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            self.receiveReply(self.START_ACQ_ADS1299);
            self.emg_acquisition = true;
            % disp('Started EMG Acquisition!')
        end

        %% Stop EMG Acquisition
        % Routine to send command to stop EMG acquisition. Waits for reply from Limb-MATE.
        % While it waits for the reply of the computer it discards all the data saved in the buffer.
        % @return none
        function stopAcquisitionEMG(self)
            flush(self.serialObj);
            % send command!
            data = zeros(1,2);
            %Waits for second byte from "receiveReply" == 1
            %In this case receiveReply returns two numbers because the
            %variable self_emg_acquisition = true.
            while (data(2) ~= 1)
                self.emg_acquisition = true;
                result = self.sendCommand(self.STOP_ACQ_ADS1299, 0, 0);
                while (result ~= 0)
                    pause(0.1);
                    result = self.sendCommand(self.STOP_ACQ_ADS1299, 0, 0);
                    disp('Received Stop Acquisition CNF')
                end
                data = self.receiveReply(self.STOP_ACQ_ADS1299);
                pause(0.1);
            end       
            self.stop_acquisition_datetime = datetime("now");
            disp('Received Stop Acquisition REPLY')
            disp('Stopped EMG Acquisition!')
            self.emg_acquisition = false;
        end

        %% Get raw EMG data
        % Routine to acquire EMG raw data from the Limb-MATE.
        %For the 8-channel ADS1299, the number of data outputs is [(24 status bits + 24 bits × 8 channels) = 216 bits].
        % The format of the 24 status bits is: (1100 + LOFF_STATP + LOFF_STATN + bits[4:7] of the GPIO register). The
        % data format for each channel data are twos complement and MSB first.
        % @param[in] sampleF refers to the desired sampling frequency of the ADS1299 acquisition of data
        % @param[in] gain is the desired ADS1299 acquired signals gain
        % @param[in] numsamples are the desired number of samples to acquire
        % @return raw_data
        %------------------------------------------------------------------
        %------------------------------------------------------------------
        % function raw_data = getEMG_raw(self, sampleF, gain, numsamples, active_channels)     
        %     % set sampling frequency and gain
        %     self.setSampleFreqGain(sampleF, gain);
        %     pause(0.2);
        %     tic
        %     % start sampling
        %     self.startAcquisitionEMG(1, active_channels);
        %     pause(0.2);
        %     package_size = 8;
        %     packages_counter = 0;
        %     raw_data = [];
        %     data_size = (27*package_size) + 12; %27bytes/package * numpackages + 12bytes for the BT communication protocol
        %     while packages_counter < numsamples
        %         new_data = read(self.serialObj,data_size,"uint8");
        %         raw_data = [raw_data new_data(12:(end-1))]; %ignores BT protocal data (header, BT_command, datalength, checksum)
        %         packages_counter = packages_counter + package_size;
        %     end
        %     toc
        %     % stop acquisition
        %     pause(0.2);
        %     self.stopAcquisitionEMG();
        %     return
        % end

        %% Get EMG data samples (for data in 24 bit / channel)
        % Routine to acquire EMG data samples in the format of 24bit complement2 for each channel.
        % For the 8-channel ADS1299, the number of data outputs is [(24 status bits + 24 bits × 8 channels) = 216 bits].
        % The format of the 24 status bits is: (1100 + LOFF_STATP + LOFF_STATN + bits[4:7] of the GPIO register). The
        % data format for each channel data are twos complement and MSB first.
        % @param[in] sampleF refers to the desired sampling frequency of the ADS1299 acquisition of data
        % @param[in] gain is the desired ADS1299 acquired signals gain
        % @param[in] numsamples are the desired number of samples to acquire
        % @return EMG_data
        %------------------------------------------------------------------
        % function EMG_data = getEMG_data_samples_24bit(self, sampleF, gain, numsamples, active_channels)   
        %     % set sampling frequency and gain
        %     self.setSampleFreqGain(sampleF, gain);
        %     pause(0.2);
        %     %LED Green ON indicating start of acquisition
        %     self.setLED('G', 1)
        %     % start sampling
        %     tic
        %     % Start Acuqisition
        %     self.startAcquisitionEMG(1, active_channels);    
        %     % Get data
        %     EMG_data = self.getEMG_data_TW_24bit(numsamples);
        % 
        %     % stop acquisition
        %     self.stopAcquisitionEMG();
        %     toc
        %     %LED Green OFF indicating end of acquisition
        %     self.setLED('G', 0)
        %     return
        % end

        %% Get EMG data time window sample (for data in 24 bit / channel)
        % Routine to acquire a time window equivalent of EMG data samples in the format of 24bit complement2 for each channel.
        % For the 8-channel ADS1299, the number of data outputs is [(24 status bits + 24 bits × 8 channels) = 216 bits].
        % The format of the 24 status bits is: (1100 + LOFF_STATP + LOFF_STATN + bits[4:7] of the GPIO register). The
        % data format for each channel data are twos complement and MSB first.
        % @param[in] TWnumsamples are the desired number of samples to acquire
        % @return EMG_data
        %------------------------------------------------------------------
        % function EMG_data = getEMG_data_TW_24bit(self, TWnumsamples)
        %     %Working with copy of variable, as it can be changed during the
        %     %running of this function on last if statement
        %     emg_package_size_copy = self.EMG_PACKAGE_SIZE;
        %     packages_counter = 0;
        %     samples_counter = 0;
        %     EMG_data = zeros(8,TWnumsamples);
        %     while packages_counter < TWnumsamples
        %         bt_data = self.receiveReply("0xC0"); % First byte from the Status bytes should be C0, indicating that it is indeed EMG data that we are acquiring
        %         if (dec2hex(bt_data(1)) == "C0")
        %             for (n = 1 : emg_package_size_copy) % Packages of x Samples
        %                 samples_counter = samples_counter + 1;
        %                 bt_data = bt_data(4:end); %Discard first 3 Status Bytes of ADAS299 data sample
        %                 for (i = 1 : self.EMG_NUM_CHANNELS) %Separate data into separate channel data
        %                     EMG_data(i,samples_counter) = self.int24c2_to_int32(bt_data(1:3)); %convert 24bits (3bytes) complement 2 into 32int
        %                     bt_data = bt_data(4:end); %Move onto next channel (next 24bits = 3bytes)
        %                 end
        %             end
        %             %Read next 8 samples
        %             packages_counter = packages_counter + emg_package_size_copy; %Stops at the exact number of nsamples, instead of multiples of 8x
        %             if(packages_counter + 8 > TWnumsamples)
        %                 emg_package_size_copy = mod(TWnumsamples,packages_counter);
        %             end
        %         end
        %     end
        %     %Set ADS1299 values to mV
        %     %Pre-amplified = [0 , 5000]mV
        %     if (self.self.config_encoded == 32)
        %         EMG_data = ((EMG_data * 4.5) /8388607) * 1000 * 2;
        %         EMG_data(EMG_data>5000) = 5000;
        %         EMG_data(EMG_data<0) = 0;
        %     %Differential = [-4500 , 4500]mV
        %     elseif (self.self.config_encoded == 0)
        %         EMG_data = ((EMG_data * 4.5) /8388607) * 1000;
        %         EMG_data(EMG_data>4500) = 4500;
        %         EMG_data(EMG_data<-4500) = -4500;
        %     end
        %     return
        % end

        %% Get EMG data samples (for data in int32 / channel)
        % Routine to acquire EMG data samples in the format of 32 int for each channel.
        % The data comes already formatted in int32, receiving a total of 33
        % number of bytes = 1 byte (Header indicating it is EMG data) + 4 bytes (1 channel) * 8 (channels) 
        % @param[in] sampleF refers to the desired sampling frequency of the ADS1299 acquisition of data
        % @param[in] gain is the desired ADS1299 acquired signals gain
        % @param[in] numsamples are the desired number of samples to acquire
        % @return EMG_data
        %------------------------------------------------------------------
        % function [counter, timer, EMG_data, elapsed] = getEMG_data_samples_int32(self, sampleF, gain, numsamples, active_channels)   
        %     % set sampling frequency and gain
        %     self.setSampleFreqGain(sampleF, gain);
        %     pause(0.2);
        %     %LED Green ON indicating start of acquisition
        %     self.setLED('G', 1)
        %     % start sampling
        %     self.startAcquisitionEMG(1, active_channels);
        %     tic
        %     [counter, timer, EMG_data, elapsed, ~] = self.getEMG_data_TW_int32(numsamples, sampleF, 0, 0);
        %     toc
        %     % stop acquisition
        %     self.stopAcquisitionEMG();
        %     %LED Green OFF indicating end of acquisition
        %     self.setLED('G', 0)
        %     return
        % end

        %% Get EMG data samples (for data in float / channel)
        % Routine to acquire EMG data samples in the format of float for each channel.
        % 1] Initialisation of the Parameters to be sent through BT to the ADS
        % 2] Initialise the Graphical Structures
        % 3] Start the Acuisition
        % 4] Acquire a Full Time Window + Update the Graphical Parameters + Check the Exiting Condition (Button or Max Num of Samples)
        % 5] Stop Acquisition
        % 6] Reconstruct the Data and Save them into the Class
        % @return none
        %------------------------------------------------------------------
        function getEMG_data_samples_float_plot(self, enable_dataTransmission, seconds_acquisition) 
            
            % Get Parameters from the internal struct
            % sampleF:               Sampling frequency of the ADS1299 acquisition of data
            % gain:                  Gain of the ADS1299
            % seconds_acquisition    Seconds of Acquisition
            % active_channels_v      Vector of the Active Channels
            % seconds_tw             Seconds of the TW
            % seconds_tw_overlap     Seconds of the TW Overlap
            % enable_testmode        1 to enable the testmode
            % eanbled_filters        1 to enable the HP filter, 2 The Notch, 3 both
            sampleF = self.acquisitionParameters.sampleF;
            gains = self.acquisitionParameters.gains;
            electrodes_config = self.acquisitionParameters.electrodes_config;
            active_channels_v = self.acquisitionParameters.active_channels_v;
            seconds_tw = self.acquisitionParameters.seconds_tw;
            seconds_tw_overlap = self.acquisitionParameters.seconds_tw_overlap;
            enable_testmode = self.acquisitionParameters.enable_testmode;
            enabled_filters = self.acquisitionParameters.enabled_filters;

            % 1] Initialisation of the Parameters to be sent through BT to the ADS
            % Transform Seconds on Samples
            seconds_increment = seconds_tw - seconds_tw_overlap;
            samples_tw  = sampleF * seconds_tw;
            samples_tw_overlap  = sampleF * seconds_tw_overlap;
            numsamples = sampleF * seconds_acquisition;

            samples_increment = samples_tw - samples_tw_overlap;

            self.packages_per_TW = samples_tw / 5;
            self.packages_per_TW_increment = samples_increment / 5;

            % Encode the parameters
            [active_channels_encoded, samples_tw_encoded, samples_tw_overlap_encoded] = self.encode_start_acq_param(active_channels_v, samples_tw, samples_tw_overlap);

            % set sampling frequency and gain --> Also saved into LimbMATE
            self.setSampleFreqGain(sampleF, gains);
            pause(7.5*0.001) % Wait 7.5 ms
            % set Electrode Configuration --> Also saved into LimbMATE
            self.setElectrodesConfig(electrodes_config)
            pause(7.5*0.001) % Wait 7.5 ms

            % Put the enable flags on the structure
            self.enable_testmode = enable_testmode;
            self.enabled_filters = enabled_filters;

            % 2] Initialise the Graphical Structures
            % Initialise some Graphical variables 
            self.graphical_information = [];
            self.graphical_information.enable_graph = self.graphical.enable_graph;
            if enable_dataTransmission
                if self.graphical.enable_graph
                    grafical_type = self.graphical.type;
                    switch grafical_type
                        case self.PLOT_EMG
                            self.initialise_graphical_parameters(active_channels_v);
                        case self.PLOT_MAV
                            self.initialise_graphical_parameters_MAV(active_channels_v);
                        case self.PLOT_CONTROL
                            self.initialise_graphical_parameters_feature_control(active_channels_v, seconds_acquisition, seconds_increment);
                        otherwise
                            self.initialise_graphical_parameters_MAV(active_channels_v);
                    end
                end
            else
                timer_TW = timer('TimerFcn', @self.increase_incremental_TW, 'ExecutionMode', 'fixedRate', 'Period', seconds_increment, UserData = self.num_incremental_TW);
                % timer_TW.ExecutionMode = 'fixedSpacing';
                % timer_TW.Period = seconds_increment;
                % timer_TW.UserData = self.num_incremental_TW;
                % timer_TW.TimerFcn = @increase_incremental_TW;
            end
            
            % 3] Start the Acquisition
            pause(0.2);
            % LED Green ON indicating start of acquisition
            self.setLED('G', 1)
            pause(7.5*0.001);

            % start sampling
            start_tic = tic;
            self.startAcquisitionEMG(enable_dataTransmission, active_channels_encoded, samples_tw_encoded, samples_tw_overlap_encoded);

            % Start the timer if no data tansmission
            if ~enable_dataTransmission
                start(timer_TW);
            end

            % DATA ACQUISITION
            try
                data_tic = tic;
                while (self.stopped_acquisition == 0)
                    if enable_dataTransmission
                        % 4] Acquire a Full Time Window + Update the Graphical Parameters + Check the Exiting Condition (Button or Max Num of Samples)
                        % Get a Full Time Window
                        
                        [EMG_data_TW] = self.getEMG_data_TW_float(samples_tw);
                        % Update the Graphical Parameters
                        if self.graphical.enable_graph
                            grafical_type = self.graphical.type;
                            switch grafical_type
                                case self.PLOT_EMG
                                    self.update_graphical_parameters(active_channels_v, samples_tw);
                                case self.PLOT_MAV
                                    self.update_graphical_parameters_MAV(active_channels_v, samples_tw);
                                case self.PLOT_CONTROL
                                    self.update_graphical_parameters_feature_control(active_channels_v, samples_tw);
                                otherwise
                                    self.update_graphical_parameters(active_channels_v, samples_tw);
                            end
                        end
                        drawnow
                    else
                        % Allow stop callback
                        drawnow 
                    end
    
                    % Check the Exiting Condition (Button or Max Num of Samples)
                    if (numsamples > 0 && self.num_incremental_TW >= (numsamples/(self.packages_per_TW_increment * 5)) )
                        self.stopped_acquisition = 1;
                    end    
                end
                data_toc = toc(data_tic)
                drawnow
                pause(0.5)
            catch ME
                disp(ME.message)
            end

            % 5] Stop Acquisition
            if self.warning_timeout == 0
                self.stopAcquisitionEMG();
                end_toc = toc(start_tic);
                % Set LED Green OFF indicating end of acquisition
                pause(7.5*0.001);
                self.setLED('G', 0)
                pause(7.5*0.001);
            else
                end_toc = toc(start_tic);
            end
            

            % 6] Reconstruct the Data and Save them into the Class
            if enable_dataTransmission
                num_TW_tot = length(self.temp_emg_data);
                n_packages_TW = self.packages_per_TW_increment;
                n_samples_TW = n_packages_TW * 5;
                counter = zeros(num_TW_tot * n_packages_TW, 1);
                elapsed = zeros(num_TW_tot * n_packages_TW, 1);
                
                timer_EMG = zeros(num_TW_tot * n_samples_TW, 1);
                % EMG
                emgdata = zeros(self.EMG_NUM_CHANNELS, num_TW_tot * n_samples_TW, 'single');
                % Streamed Features
                streamed_MAV = zeros(self.EMG_NUM_CHANNELS, num_TW_tot, 'single');
                streamed_WL = zeros(self.EMG_NUM_CHANNELS, num_TW_tot, 'single');
                streamed_SLP = zeros(self.EMG_NUM_CHANNELS, num_TW_tot, 'single');
                streamed_ZC = zeros(self.EMG_NUM_CHANNELS, num_TW_tot, 'single');
                streamed_STD = zeros(self.EMG_NUM_CHANNELS, num_TW_tot, 'single');
                % Streamed Control
                streamed_outIndex = zeros(1, num_TW_tot, "uint8");
                streamed_actLevels = zeros(self.NUM_DOF, num_TW_tot, "uint8");
                streamed_rawGraspInformation = zeros(self.RAW_GRASP_INFORMATION_SIZE, num_TW_tot, "uint8");
                % Calculated Features
                if self.extract_feature_flag == true
                    samples_increment_TW = self.packages_per_TW_increment * 5;
                    samples_TW = self.packages_per_TW * 5;
                    num_max_iteration = ceil(samples_TW / samples_increment_TW);
                    MAV = zeros(self.EMG_NUM_CHANNELS, num_TW_tot, 'single');
                    WL = zeros(self.EMG_NUM_CHANNELS, num_TW_tot, 'single');
                    SLP = zeros(self.EMG_NUM_CHANNELS, num_TW_tot, 'single');
                    ZC = zeros(self.EMG_NUM_CHANNELS, num_TW_tot, 'single');
                    STD = zeros(self.EMG_NUM_CHANNELS, num_TW_tot, 'single');
                    % Calculated Classification
                    outIndex = zeros(1, num_TW_tot, "uint8");
                end
                
    
                for iTW = 1:num_TW_tot
                    pos_package = n_packages_TW*(iTW-1)+1:n_packages_TW*iTW;
                    pos_samples = n_samples_TW*(iTW-1)+1:n_samples_TW*iTW;
    
                    counter(pos_package) = self.temp_emg_data(iTW).total_counter;
                    timer_EMG(pos_samples) = self.temp_emg_data(iTW).total_timer;
                    elapsed(pos_package) = self.temp_emg_data(iTW).total_elapsed;
    
                    % EMG Data
                    emgdata(:, pos_samples) = self.temp_emg_data(iTW).total_EMG_data;
                    % Streamed Features
                    streamed_MAV(:, iTW) = self.temp_streamed_features(iTW).MAV;
                    streamed_WL(:, iTW) = self.temp_streamed_features(iTW).WL;
                    streamed_SLP(:, iTW) = self.temp_streamed_features(iTW).SLP;
                    streamed_ZC(:, iTW) = self.temp_streamed_features(iTW).ZC;
                    streamed_STD(:, iTW) = self.temp_streamed_features(iTW).STD;
                    % Streamed Control 
                    streamed_outIndex(iTW) = self.temp_streamed_control(iTW).outIndex;
                    streamed_actLevels(:,iTW) = self.temp_streamed_control(iTW).actLevels;
                    streamed_rawGraspInformation(:, iTW) = self.temp_streamed_control(iTW).rawGraspInformation;
                    % Calculated Features
                    if self.extract_feature_flag == true
                        if (iTW + num_max_iteration - 1 <= num_TW_tot)
                            MAV(:, iTW) = self.temp_features(iTW + num_max_iteration - 1).MAV;
                            WL(:, iTW) = self.temp_features(iTW + num_max_iteration - 1).WL;
                            SLP(:, iTW) = self.temp_features(iTW + num_max_iteration - 1).SLP;
                            ZC(:, iTW) = self.temp_features(iTW + num_max_iteration - 1).ZC;
                            STD(:, iTW) = self.temp_features(iTW + num_max_iteration - 1).STD;
                            % Calculated Class
                            outIndex(iTW) = self.temp_control(iTW + num_max_iteration - 1).outIndex;
                        end
                    end
                end
    
                % MSE Streamed-calculated
                if self.extract_feature_flag == true
                    common_portion = 1:(num_TW_tot - num_max_iteration + 1);
                    eMAV = MAV(:, common_portion) - streamed_MAV(:, common_portion); eMAV = eMAV(:);
                    mseMAV = mean(eMAV.^2); 
                    eSTD = STD(:, common_portion) - streamed_STD(:, common_portion); eSTD = eSTD(:);
                    mseSTD = mean(eSTD.^2); 
                    eWL = WL(:, common_portion) - streamed_WL(:, common_portion); eWL = eWL(:);
                    mseWL = mean(eWL.^2); 
                    eZC = ZC(:, common_portion) - streamed_ZC(:, common_portion); eZC = eZC(:);
                    mseZC = mean(eZC.^2); 
                    eSLP = SLP(:, common_portion) - streamed_SLP(:, common_portion); eSLP = eSLP(:);
                    mseSLP = mean(eSLP.^2); 

                    % RMSE Streamed-Calculated
                    rmseMAV = sqrt(mseMAV);
                    rmseSTD = sqrt(mseSTD);
                    rmseWL = sqrt(mseWL);
                    rmseZC = sqrt(mseZC);
                    rmseSLP = sqrt(mseSLP);

                    % Mutual Accuracy
                    accuracy = sum(outIndex(common_portion) == streamed_outIndex(common_portion)) * 100 / length(common_portion)
                end
    
                % Save the values on a Structure
                emg = [];
                % Date and Time
                emg.date.start_acquisition_datetime = self.start_acquisition_datetime;
                emg.date.stop_acquisition_datetime = self.stop_acquisition_datetime;
                % General Acquisition Params
                emg.enable_dataTransmission = enable_dataTransmission;
                emg.sampleF = sampleF;
                emg.gains = gains;
                emg.seconds_acquisition = seconds_acquisition;
                emg.active_channels_v = active_channels_v;
                emg.seconds_tw = seconds_tw;
                emg.seconds_tw_overlap = seconds_tw_overlap;
                emg.enable_testmode = enable_testmode;
                emg.enabled_filters = enabled_filters;
                % Hand
                emg.handInUse = self.handInUse;
                % General Params
                emg.counter = counter;
                emg.timer = timer_EMG;
                emg.control_cycle_timer = timer_EMG(1:n_samples_TW:end);
                emg.emgdata = emgdata;
                emg.elapsed = elapsed;
                emg.packages_lost_index = self.packages_lost_index_total;
                % Streamed Features
                emg.streamed_features.MAV = streamed_MAV;
                emg.streamed_features.WL = streamed_WL;
                emg.streamed_features.SLP = streamed_SLP;
                emg.streamed_features.ZC = streamed_ZC;
                emg.streamed_features.STD = streamed_STD;
                % Streamed Control
                emg.streamed_control.outIndex = streamed_outIndex;
                emg.streamed_control.actLevels = streamed_actLevels;
                emg.streamed_control.rawGraspInformation = streamed_rawGraspInformation;
                emg.streamed_control.GraspInformation = self.decode_graspInformation(streamed_rawGraspInformation);
    
                % Calculated Features
                if self.extract_feature_flag == true
                    emg.features.MAV = MAV;
                    emg.features.WL = WL;
                    emg.features.SLP = SLP;
                    emg.features.ZC = ZC;
                    emg.features.STD = STD;
                    % Calculated Class
                    emg.control.outIndex = outIndex;
                    % Comparison Calclulated-Streamed
                    emg.comparison.mseMAV = mseMAV;
                    emg.comparison.mseSTD = mseSTD;
                    emg.comparison.mseWL = mseWL;
                    emg.comparison.mseZC = mseZC;
                    emg.comparison.mseSLP = mseSLP;
                    emg.comparison.rmseMAV = rmseMAV;
                    emg.comparison.rmseSTD = rmseSTD;
                    emg.comparison.rmseWL = rmseWL;
                    emg.comparison.rmseZC = rmseZC;
                    emg.comparison.rmseSLP = rmseSLP;
                    emg.comparison.accuracy = accuracy;
                end
                
                % Save the structure on the class
                self.emg_data = emg;
    
                % Clear the Temp Variables 
                self.temp_emg_data = [];
                self.temp_streamed_features = [];
                self.temp_streamed_control = [];
                self.temp_features = [];
                self.temp_control = [];
    
                packages_loss_idx = self.emg_data.packages_lost_index;
                packages_loss_number = length(packages_loss_idx);
                packages_loss_percentage = (length(packages_loss_idx) / self.emg_data.counter(end)) * 100;
                fprintf("Packages loss number: %d \nPackages loss percentage: %d %% \n",packages_loss_number, packages_loss_percentage);
            else
                % Stop the Timer and delete if
                stop(timer_TW);
                delete(timer_TW);
            end

            % Final plots in case of PLOT_CONTROL
             if enable_dataTransmission
                if self.graphical.enable_graph
                    grafical_type = self.graphical.type;
                    switch grafical_type
                        case self.PLOT_EMG
                        case self.PLOT_MAV
                        case self.PLOT_CONTROL
                            if self.graphical.enableFinalPlot
                                self.final_plots(active_channels_v, seconds_acquisition, seconds_increment, streamed_outIndex, streamed_rawGraspInformation);
                            end
                        otherwise
                    end
                end
                clear self.graphical;
             end


            return
        end

        %% Callback for increasing the Incremental TW counter
        % Necessary for data acquisition without streaming, and allowing the stop button in case it is desired to interrupt the acquisition before the time requested
        % @param[in] parameters referring to time passed since start of acquisition
        % @return none
        function increase_incremental_TW(self, mTimer, ~)
            self.num_incremental_TW = self.num_incremental_TW + 1;
        end

        %% Get EMG data samples of the Incremental TW (for data in float / channel)
        % Routine to acquire EMG data samples in the format of float for each channel.channels) 
        % @param[in] TWnumsamples_increment: Number of samples of the Incremental TW
        % @return increment_EMG_data
        %------------------------------------------------------------------
%         function [increment_EMG_data] = getEMG_data_increment_TW_float(self, TWnumsamples_increment)
%             % Update the counter
%             self.num_incremental_TW = self.num_incremental_TW + 1;
%             % Working with copy of variable, as it can be changed during the
%             % running of this function on last if statement
%             emg_package_size_copy = self.EMG_PACKAGE_SIZE;
%             start_time_TW = self.timer_TW(end);
% %             total_added_time = self.total_added_time;
%             % Initialise some variables
%             startIteration = zeros(TWnumsamples_increment/5, 1);
%             endIteration = zeros(TWnumsamples_increment/5, 1);
%             counter = zeros(TWnumsamples_increment/5, 1);
%             timer_samples_TW = zeros(TWnumsamples_increment, 1);
%             increment_EMG_data = zeros(self.EMG_NUM_CHANNELS, TWnumsamples_increment);
% 
%             packages_lost_index_TW = [];       %Index of the packages lost on the TW
%             packages_lost_index_samples = [];       %Index of the packages lost on the TW with the global samples counter value
%             samples_per_package = 5;
%             counter_packages_mcu = 0;       %Number of the package according to the value setted on the MCU
%             samples_counter = 0;            %Number of samples received from the TW
%             package_number = 1;     
%             previous_package_number = 0;    %Variable to save the number of the previous package received
%             packages_lost = false;      %Flag to notice if any packages lost in between packages
%             first_package_TW = true;    %Flag to notice first package of the TW
%             packages_lost_number = 0; %Packages lost inbetween two received packages
%             packages_lost_number_current_TW = 0; % Packages lost in current TW, in case receiving package from next TW
%             packages_lost_number_total = 0; %Total packages lost in the TW
%             next_TW_packages_flag = false;  %Flag to announce that we are receiving a package from the next TW due to packages loss
%             next_TW_EMG_data = zeros(self.EMG_NUM_CHANNELS, samples_per_package);  %Vector to save the package related to the next TW
% 
%             %Debug
% %             save_package_numbers = [];
% %             save_previous_package_numbers = [];
% %             lost = false;
% 
%             while package_number <= self.packages_per_TW_increment
%                 startIteration(package_number) = second(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSSSSS'));
%                 % Get the Header
%                 bt_data = self.receiveReply("0xAB"); % First byte from the Status bytes should be AB, indicating that it is indeed EMG data that we are acquiring
%                 % Get the Counter of packages from MCU, and set it to the counter of packages of TW in Matlab
%                 counter_packages_mcu = typecast(uint8(bt_data(5:-1:2)),'uint32');
%                 package_number = mod(counter_packages_mcu, self.packages_per_TW_increment);
%                 if (package_number == 0)
%                     package_number = uint32(self.packages_per_TW_increment);
% 
%                 end
% 
%                 %In case it jumps to another TW, do not save on the counter the current package, because package_number is not from the current TW
%                 if (package_number > previous_package_number)
%                     counter(package_number) = counter_packages_mcu;
%                 end
% 
% %                 save_package_numbers = [save_package_numbers package_number];
% %                 save_previous_package_numbers = [save_previous_package_numbers previous_package_number];
% 
%                 %Saves the index of the very first package received from streaming
%                 if (self.first_package_flag == true)
%                     self.first_package_flag = false;
%                     self.first_package_number = counter(package_number);
%                 end
% 
%                 % Get the Timer Elapsed since previous package in seconds
%                 elapsed_time_TW = typecast(uint8(bt_data(9:-1:6)),'uint32');
%                 elapsed_time_TW = single(elapsed_time_TW)/96000000;
% 
%                 %In case there is a skip in the packages received (package was lost) 
%                 if (package_number > previous_package_number + 1)
%                     disp('Sample loss A');
%                     packages_lost = true;
% %                     package_number
% %                     previous_package_number
% %                     counter(package_number)
%                     %lost = true;
%                     packages_lost_number = package_number - previous_package_number - 1;
%                     init_limit = previous_package_number + 1;
%                     finish_limit = package_number - 1;
%                     packages_lost_index_TW = [packages_lost_index_TW, init_limit:finish_limit]; %Index of the packages lost on the TW
%                     %Place on the counter positions the expected value, or we can decide to put a "0"
%                     m = 1;
%                     for i = init_limit:finish_limit
%                         counter(i) = counter_packages_mcu - packages_lost_number + m;
%                         m = m +1;
%                         %counter(i) = 0;                    
%                     end
%                 end
% 
%                 % Packages lost in case when previous_package_number = ...17,18,19,20 and package_number = 1,2,3,...
%                 if (package_number < previous_package_number)
%                     disp('Sample loss B');
%                     next_TW_packages_flag = true;
%                     packages_lost = true;
% %                     package_number
% %                     previous_package_number
% %                     counter(package_number)
%                     %lost = true;
%                     packages_lost_number = (self.packages_per_TW_increment - previous_package_number) + (package_number - 1);
%                     current_TW_packages_index = ((previous_package_number + 1) : self.packages_per_TW_increment);  %Values on the current TW
%                     packages_lost_number_current_TW = length(current_TW_packages_index);
%                     next_TW_packages_index = (1 : package_number - 1);            %Values on the next TW
%                     %packages_lost_index_TW = [packages_lost_index_TW, current_TW_packages_index, next_TW_packages_index]; 
%                     packages_lost_index_TW = [packages_lost_index_TW, current_TW_packages_index, next_TW_packages_index]; 
%                     %Place on the counter positions the expected value, or we can decide to put a "0"
%                     m = 1;
%                     for i = current_TW_packages_index
%                         counter(i) = counter_packages_mcu - packages_lost_number + m;
%                         m = m +1;
%                         %counter(i) = 0;
% 
%                     end
%                 end
% 
%                 %In case packages are lost, then place on their values the same values that are on the previous received packaged, saved on the EMG_data
%                 % Goes into this if statement in case we have only missed packages from the current TW
%                 if (packages_lost == true && next_TW_packages_flag == false)
%                     packages_lost = false;
%                     packages_lost_index_samples = [packages_lost_index_samples, (counter(package_number)-packages_lost_number) : (counter(package_number) - 1)];   %Index of the packages lost with the global counter   
%                     %Debug variables
%                     %packages_lost_number
%                     %samples_counter_init = samples_counter
%                     %In case it is the very first package and there are no samples before on EMG_data
%                     if (previous_package_number == 0 && self.first_package_number == counter(package_number))
%                         packages_lost_new_value = zeros(8,5);
%                     %In case it is the first package of the TW
%                     elseif (samples_counter == 0)
%                         packages_lost_new_value = self.last_TW_emg_package;
%                     else
%                         packages_lost_new_value = increment_EMG_data(:, samples_counter-4: samples_counter);
%                     end
%                     samples_counter = samples_counter + 1;
%                     for i = 1:packages_lost_number
%                         increment_EMG_data(:, samples_counter:(samples_counter + 4)) = packages_lost_new_value;
%                         samples_counter = samples_counter + 5;
%                     end
%                     samples_counter = samples_counter - 1;
%                     %samples_counter_finish_1 = samples_counter
%                 end
% 
%                 % Goes into this if statement in case we have missed packages of the current and the next TW
%                 if (packages_lost == true && next_TW_packages_flag == true)
%                     %When new TW package arrives, the package_number is not corret, therefore we should work with previous_package_number, to save the index of lost samples
%                     packages_lost_index_samples = [packages_lost_index_samples, (counter(previous_package_number) + 1) : (counter(previous_package_number) + packages_lost_number_current_TW)];   %Index of the packages lost with the global counter   
%                     if (samples_counter == 0)
%                         packages_lost_new_value = self.last_TW_emg_package;
%                     else
%                         packages_lost_new_value = increment_EMG_data(:, samples_counter-4: samples_counter);
%                     end
%                     samples_counter = samples_counter + 1;
%                     for i = (previous_package_number + 1):self.packages_per_TW_increment
%                         increment_EMG_data(:, samples_counter:(samples_counter + 4)) = packages_lost_new_value;
%                         samples_counter = samples_counter + 5;
%                     end
%                 end
% 
%                 % Get The Data of the current package (even if it belongs to another TW)
%                 if (dec2hex(bt_data(1)) == "AB")
%                     % Discard Header Byte indicating EMG data + Counter & Timer
%                     bt_data = bt_data(10:end); 
%                     for n = 1 : emg_package_size_copy % Packages of x Samples
%                         samples_counter = samples_counter + 1;
%                         % Read 1 sample for eache channel (32 bytes)
%                         for i = 1 : self.EMG_NUM_CHANNELS % Separate data into separate channel data
%                             %If the package received is related to the next TW (due to samples loss) then it saves on a vector for the next TW
%                             if (next_TW_packages_flag == true)
%                                 %Save the data of the package related to the next TW on a different vector
%                                 next_TW_EMG_data(i, n) = typecast(uint8(bt_data(4:-1:1)),'single');
%                             else
%                                 increment_EMG_data(i, samples_counter) = typecast(uint8(bt_data(4:-1:1)),'single');
%                             end
%                             bt_data = bt_data(5:end); % Move onto next channel (next 32bits = 4bytes)
%                         end
%                     end
%                 end
% 
%                 %In case we have received a package from the next TW, stop receiving data, in order to exit the function.
%                 if (next_TW_packages_flag == true)
%                     break
%                 end
% 
%                 endIteration(package_number) = second(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSSSSS')) -  startIteration(package_number);
%                 previous_package_number = package_number;
%                 package_number = package_number + 1;
%             end
% 
%             elapsed = endIteration;
%             %In case the package we received belongs to the next TW
%              if (next_TW_packages_flag == true)
%                 self.last_TW_emg_package = next_TW_EMG_data;
%              else
%                 self.last_TW_emg_package = increment_EMG_data(:, (samples_counter-4):samples_counter);
%              end
% 
%             %samples_counter_finish_2 = samples_counter
% 
% %             elapsed_time_TW
%             %In case it is the first TW received set time to be the expected time, because in reality core1 needs to acquire a full time-window at first (even with olerpapping timewindow)
%             if (self.first_TW_received == true)
%                 self.first_TW_received = false;
%                 elapsed_time_TW = (1 / self.sampleF) * (self.packages_per_TW_increment * 5);
%             end
% 
%             %Set the timing of each sample of the TW to return and plot the samples
%             for i= 1:(self.packages_per_TW_increment * 5)
%                 timer_samples_TW(i) = start_time_TW + ((elapsed_time_TW * i)/(self.packages_per_TW_increment * 5));
%             end
%             timer_samples_TW(self.packages_per_TW_increment * 5) = start_time_TW + (1 / self.sampleF) * (self.packages_per_TW_increment * 5);
% 
% 
%             % Store the data in the proper position
%             % Recursive Portion
%             self.timer_TW = timer_samples_TW;
% %             self.total_added_time = total_added_time;
%             % Global Portion
%             self.temp_emg_data(self.num_incremental_TW).total_counter = counter; 
%             self.temp_emg_data(self.num_incremental_TW).total_timer = self.timer_TW; 
%             self.temp_emg_data(self.num_incremental_TW).total_EMG_data = increment_EMG_data; 
%             self.temp_emg_data(self.num_incremental_TW).total_elapsed = elapsed; 
% 
%             %Store all the packagess lost index
%             self.packages_lost_index_total = [self.packages_lost_index_total packages_lost_index_samples];
% 
%             return
%         end

        %% Get EMG data samples and features of the Incremental TW (for data in float / channel)
        % Routine to acquire EMG data samples in the format of float for each channel, and the calculated features 
        % Includes mechanism to detect samples loss and try to solve it by filling the data of the lost samples with the last acquired data
        % @param[in] TWnumsamples_increment: Number of samples of the Incremental TW
        % @return increment_EMG_data
        %------------------------------------------------------------------
        function [increment_EMG_data] = getEMG_data_features_increment_TW_float(self, TWnumsamples_increment)
            % Update the counter
            self.num_incremental_TW = self.num_incremental_TW + 1;
            % Working with copy of variable, as it can be changed during the
            % running of this function on last if statement
            emg_package_size_copy = self.EMG_PACKAGE_SIZE;
            start_time_TW = self.timer_TW(end);
%             total_added_time = self.total_added_time;
            % Initialise some variables
            startIteration = zeros(TWnumsamples_increment/5, 1);
            endIteration = zeros(TWnumsamples_increment/5, 1);
            counter = zeros(TWnumsamples_increment/5, 1);
            timer_samples_TW = zeros(TWnumsamples_increment, 1);
            increment_EMG_data = zeros(self.EMG_NUM_CHANNELS, TWnumsamples_increment, 'single');

            outIndex = zeros(1, 1, "uint8");
            activationLevels = zeros(1, self.NUM_DOF, "uint8");
            rawGraspInformation = zeros(1, self.RAW_GRASP_INFORMATION_SIZE, "uint8");
            raw_grasp_info_save_tw_package = self.raw_grasp_info_save_tw_package;

            packages_lost_index_TW = [];       %Index of the packages lost on the TW
            packages_lost_index_samples = [];       %Index of the packages lost on the TW with the global samples counter value
            samples_per_package = 5;
            counter_packages_mcu = 0;       %Number of the package according to the value setted on the MCU
            samples_counter = 0;            %Number of samples received from the TW
            package_number = 1;     
            previous_package_number = 0;    %Variable to save the number of the previous package received
            packages_lost = false;      %Flag to notice if any packages lost in between packages
            first_package_TW = true;    %Flag to notice first package of the TW
            packages_lost_number = 0; %Packages lost inbetween two received packages
            packages_lost_number_current_TW = 0; % Packages lost in current TW, in case receiving package from next TW
            packages_lost_number_total = 0; %Total packages lost in the TW
            next_TW_packages_flag = false;  %Flag to announce that we are receiving a package from the next TW due to packages loss
            next_TW_EMG_data = zeros(self.EMG_NUM_CHANNELS, samples_per_package, 'single');  %Vector to save the package related to the next TW
            number_features = 5;
            features_tw_incremented = zeros(self.EMG_NUM_CHANNELS, number_features, 'single'); % Vector with features of acquired TW
            %Debug
%             save_package_numbers = [];
%             save_previous_package_numbers = [];
%             lost = false;
            
            while package_number <= self.packages_per_TW_increment
                startIteration(package_number) = second(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSSSSS'));
                % Reset Warnings
                lastwarn('') % Clear last warning message
                % Get the Header
                bt_data = self.receiveReply("0xAB"); % First byte from the Status bytes should be AB, indicating that it is indeed EMG data that we are acquiring
                % Check for a Timeout
                [warnMsg, warnId] = lastwarn;
                if ~isempty(warnMsg)
                    self.warning_timeout = 1;
                    error('A timeout has occurred')
                end
                % Get The Data of the current package (even if it belongs to another TW)
                if (dec2hex(bt_data(1)) == "AB")
                    % Get the Counter of packages from MCU, and set it to the counter of packages of TW in Matlab
                    counter_packages_mcu = typecast(uint8(bt_data(5:-1:2)),'uint32');
                    package_number = mod(counter_packages_mcu, self.packages_per_TW_increment);
                    if (package_number == 0)
                        package_number = uint32(self.packages_per_TW_increment);
                    end
    
                    %In case it jumps to another TW, do not save on the counter the current package, because package_number is not from the current TW
                    if (package_number > previous_package_number)
                        counter(package_number) = counter_packages_mcu;
                    end
    
    %                 save_package_numbers = [save_package_numbers package_number];
    %                 save_previous_package_numbers = [save_previous_package_numbers previous_package_number];
    
                    %Saves the index of the very first package received from streaming
                    if (self.first_package_flag == true)
                        self.first_package_flag = false;
                        self.first_package_number = counter(package_number);
                    end
    
                    % Get the Timer Elapsed since previous package in seconds
                    elapsed_time_TW = typecast(uint8(bt_data(9:-1:6)),'uint32');
                    elapsed_time_TW = single(elapsed_time_TW)/96000000;
    
                    %In case there is a skip in the packages received (package was lost) 
                    %In case packages are lost, then place on their values the same values that are on the previous received packaged, saved on the EMG_data
                    % Goes into this "if statement" in case we have only missed packages from the current TW
                    % If samples received were [18 x19x x20x x1x x2x 3], then it means that in that case we received the package number 3, but only saved the values
                    % on EMG_DATA of packages number 19 and 20. When afterwards this function enters again, it will receive package number 4 (or any other greater than 3, in case samples loss)
                    % and will enter this "if statement", because previous_package_number = 0
                    % Then it will save the packages number 1, 2 and 3 with the value of the "self.last_TW_emg_package"
                    if (package_number > previous_package_number + 1)
                        packages_lost_number = package_number - previous_package_number - 1;
                        init_limit = previous_package_number + 1;
                        finish_limit = package_number - 1;
                        packages_lost_index_TW = [packages_lost_index_TW, init_limit:finish_limit]; %Index of the packages lost on the TW
                        %Place on the counter positions the expected values of packages
                        m = 1;
                        for i = init_limit:finish_limit
                            counter(i) = counter_packages_mcu - packages_lost_number + m;
                            m = m +1;                   
                        end
                        new_packages_lost_index_samples = (counter(package_number)-packages_lost_number) : (counter(package_number) - 1); 
                        packages_lost_index_samples = [packages_lost_index_samples, new_packages_lost_index_samples];   %Index of the packages lost with the global counter   
                        
                        %In case it is the very first package and there are no samples before on EMG_data
                        if (previous_package_number == 0 && self.first_package_number == counter(package_number))
                            packages_lost_new_value = zeros(self.EMG_NUM_CHANNELS, samples_per_package, 'single');
                        
                        %In case it is the first package of the TW
                        elseif (samples_counter == 0)
                            packages_lost_new_value = self.last_TW_emg_package;
                        else
                            packages_lost_new_value = increment_EMG_data(:, samples_counter - 4: samples_counter);
                        end
                        % disp('d')
                        samples_counter = samples_counter + 1;
                        for i = 1:packages_lost_number
                            increment_EMG_data(:, samples_counter:(samples_counter + 4)) = packages_lost_new_value;
                            % disp('d2')
                            samples_counter = samples_counter + 5;
                        end
                        % disp('d3')
                        samples_counter = samples_counter - 1;
                        %samples_counter_finish_1 = samples_counter
                        
                        %Save first features of the current TW with the features from the last TW, and in case the other packages [-,5] are received, it overwrites them
                        if(previous_package_number < 5)
                            if (package_number > 6)
                                top_feature_index = 5;
                            else
                                top_feature_index = package_number-1;
                            end
                            for i = ((previous_package_number + 1) : top_feature_index)
                                features_tw_incremented(:,i) = self.features_save_tw_package(:,i);
                            end
                            

                        end

                        % \ disp(['Package loss A | Global Counter: ', num2str(new_packages_lost_index_samples), ' | TW package range: ', num2str(init_limit:finish_limit) ]);
                    end
    
                    % Packages lost in case when previous_package_number = ...17,18,19,20 and package_number = 1,2,3,...
                    % Goes into this "if statement" in case we have missed packages of the current and the next TW
                    if (package_number <= previous_package_number)
                        next_TW_packages_flag = true;
                        packages_lost_number = (self.packages_per_TW_increment - previous_package_number) + (package_number - 1);
                        current_TW_packages_index = ((previous_package_number + 1) : self.packages_per_TW_increment);  %Values on the current TW
                        packages_lost_number_current_TW = length(current_TW_packages_index);
                        next_TW_packages_index = (1 : package_number - 1);            %Values on the next TW
                        packages_lost_index_TW = [packages_lost_index_TW, current_TW_packages_index, next_TW_packages_index]; 
    
                        %Place on the counter positions the expected value, or we can decide to put a "0"
                        m = 1;
                        for i = current_TW_packages_index
                            counter(i) = counter_packages_mcu - packages_lost_number + m;
                            m = m +1;                        
                        end
    
                        %When new TW package arrives, the package_number is not corret, therefore we should work with previous_package_number, to save the index of lost samples
                        new_packages_lost_index_samples = (counter(previous_package_number) + 1) : (counter(previous_package_number) + packages_lost_number_current_TW); 
                        packages_lost_index_samples = [packages_lost_index_samples, new_packages_lost_index_samples];   %Index of the packages lost with the global counter   
                        if (samples_counter == 0)
                            packages_lost_new_value = self.last_TW_emg_package;
                        else
                            packages_lost_new_value = increment_EMG_data(:, samples_counter-4: samples_counter);
                        end
                        % disp('e')
                        samples_counter = samples_counter + 1;
                        for i = (previous_package_number + 1):self.packages_per_TW_increment
                            increment_EMG_data(:, samples_counter:(samples_counter + 4)) = packages_lost_new_value;
                            % disp('e2')
                            samples_counter = samples_counter + 5;
                        end

                        % disp(['Package loss B | Global Counter: ', num2str(new_packages_lost_index_samples), ' | TW package current: ', num2str(current_TW_packages_index), ' | TW package next: ', num2str(next_TW_packages_index) ]);

                    end
    
    
                    % Get The Data of the current package (even if it belongs to another TW)
                    % Discard Header Byte indicating EMG data + Counter & Timer
                    bt_data = bt_data(10:end); 
                    for n = 1 : emg_package_size_copy % Packages of x Samples
                        % disp('f')
                        samples_counter = samples_counter + 1;
                        % Read 1 sample for eache channel (32 bytes)
                        for i = 1 : self.EMG_NUM_CHANNELS % Separate data into separate channel data
                            %If the package received is related to the next TW (due to samples loss) then it saves on a vector for the next TW
                            if (next_TW_packages_flag == true)
                                %Save the data of the package related to the next TW on a different vector
                                next_TW_EMG_data(i, n) = typecast(uint8(bt_data(4:-1:1)),'single');
                            else
                                increment_EMG_data(i, samples_counter) = typecast(uint8(bt_data(4:-1:1)),'single');
                            end
                            bt_data = bt_data(5:end); % Move onto next channel (next 32bits = 4bytes)
                        end
                    end
    
                    % In case the package received is part of the first 5 packages then save the features that are placed on the last 32bytes of the bluetooth package
                    if (package_number <= 5 && next_TW_packages_flag == false)
                        for i = 1:self.EMG_NUM_CHANNELS
                            features_tw_incremented(i, package_number) = typecast(uint8(bt_data(4:-1:1)),'single');
                            bt_data = bt_data(5:end); % Move onto next channel (next 32bits = 4bytes)
                        end
                        %Save the features values of the packages in case it happens we receive packages: [...,18,19,3,4,5,...]
                        %Therefore we have already saved the features values for package [1,2] aswell
                        self.features_save_tw_package(:,package_number) = features_tw_incremented(:,package_number);
                    end
    
                    % Save Hand parameters, arriving in packages [3,4,...]
                    % Always overwriting just to prevent in case of samples loss 
                    if (package_number > 2 && next_TW_packages_flag == false)

                        raw_grasp_info_save_tw_package = bt_data;
                        self.raw_grasp_info_save_tw_package = raw_grasp_info_save_tw_package;
                    end
    
                    %In case we have received a package from the next TW, stop receiving data, in order to exit the function.
                    if (next_TW_packages_flag == true)
                        break
                    end
                    
                    endIteration(package_number) = second(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSSSSS')) -  startIteration(package_number);
                    previous_package_number = package_number;
                    package_number = package_number + 1;

                end
            end

            % Control Parameters
            outIndex  = uint8(raw_grasp_info_save_tw_package(end - self.RAW_GRASP_INFORMATION_SIZE + 1 - self.NUM_DOF - self.NUM_BYTES_CLASSES));
            activationLevels = uint8(raw_grasp_info_save_tw_package((end - self.RAW_GRASP_INFORMATION_SIZE + 1 - self.NUM_DOF):(end - self.RAW_GRASP_INFORMATION_SIZE))); % [1 x NUM_DOF]
            rawGraspInformation = uint8(raw_grasp_info_save_tw_package((end - self.RAW_GRASP_INFORMATION_SIZE + 1):end)); % [1 x RAW_GRASP_INFORMATION_SIZE]
            elapsed = endIteration;
            %In case the package we received belongs to the next TW
             if (next_TW_packages_flag == true)
                self.last_TW_emg_package = next_TW_EMG_data;
             else
                self.last_TW_emg_package = increment_EMG_data(:, (samples_counter-4):samples_counter);
                %Current package_number, before the last increment on "while" loop           
                package_number = package_number - 1;
             end
            
           
            %In case the package received is part of the first 5 packages, but its from the next TW, then save the features on a buffer to give on next TW function.
            %In case we receive packages: [...,18,19,3,4,5,...], we are saving the feature of package 3 for the next TW, 
            % and not overwriting the featue of package 3 of the current TW
            if (package_number <= 5 && next_TW_packages_flag == true)
                for i = 1:self.EMG_NUM_CHANNELS
                    self.features_save_tw_package(i,package_number) = typecast(uint8(bt_data(4:-1:1)),'single');
                    bt_data = bt_data(5:end); % Move onto next channel (next 32bits = 4bytes)
                end
                self.features_save_tw_package_number = package_number;

                % Save Hand parameters, arriving in packages [3,4,...]
                self.raw_grasp_info_save_tw_package = bt_data;
            end

%             elapsed_time_TW
            %In case it is the first TW received set time to be the expected time, because in reality core1 needs to acquire a full time-window at first (even with olerpapping timewindow)
            if (self.first_TW_received == true)
                self.first_TW_received = false;
                elapsed_time_TW = (1 / self.sampleF) * (self.packages_per_TW_increment * 5);
            end

            %Set the timing of each sample of the TW to return and plot the samples
            for i= 1:(self.packages_per_TW_increment * 5)
                timer_samples_TW(i) = start_time_TW + ((elapsed_time_TW * i)/(self.packages_per_TW_increment * 5));
            end
            timer_samples_TW(self.packages_per_TW_increment * 5) = start_time_TW + (1 / self.sampleF) * (self.packages_per_TW_increment * 5);
       

            % Store the data in the proper position
            % Recursive Portion
            self.timer_TW = timer_samples_TW;
%             self.total_added_time = total_added_time;
            % Global Portion
            self.temp_emg_data(self.num_incremental_TW).total_counter = counter; 
            self.temp_emg_data(self.num_incremental_TW).total_timer = self.timer_TW; 
            self.temp_emg_data(self.num_incremental_TW).total_EMG_data = increment_EMG_data; 
            if size(increment_EMG_data, 2) == 30
                disp('We got the error')
            end
            self.temp_emg_data(self.num_incremental_TW).total_elapsed = elapsed; 

            % Streamed Features
            self.temp_streamed_features(self.num_incremental_TW).MAV  = features_tw_incremented(:,1);
            self.temp_streamed_features(self.num_incremental_TW).STD  = features_tw_incremented(:,2);
            self.temp_streamed_features(self.num_incremental_TW).WL   = features_tw_incremented(:,3);
            self.temp_streamed_features(self.num_incremental_TW).ZC   = features_tw_incremented(:,4);
            self.temp_streamed_features(self.num_incremental_TW).SLP  = features_tw_incremented(:,5);
            % Streamed Control
            self.temp_streamed_control(self.num_incremental_TW).outIndex  = outIndex;
            self.temp_streamed_control(self.num_incremental_TW).actLevels  = activationLevels; % [1 x NUM_DOF]
            self.temp_streamed_control(self.num_incremental_TW).rawGraspInformation  = rawGraspInformation; % [1 x RAW_GRASP_INFORMATION_SIZE]
            % Update the Max and the min MAV
            MAV = features_tw_incremented(:,1);
            self.MAV_max_v(MAV > self.MAV_max_v) = MAV(MAV > self.MAV_max_v);
            self.MAV_min_v(MAV < self.MAV_min_v) = MAV(MAV < self.MAV_min_v);

            % Extract the Features computed on MATALB
            EMG_data_TW = zeros(self.EMG_NUM_CHANNELS, 5 * self.packages_per_TW, 'single');
            if self.extract_feature_flag == true
                samples_increment_TW = self.packages_per_TW_increment * 5;
                samples_TW = self.packages_per_TW * 5;
                num_max_iteration = ceil(samples_TW / samples_increment_TW);
                if self.num_incremental_TW >= num_max_iteration
                    % Reconstruct a full TW 
                    for iTW = 1:num_max_iteration
                        to_insert_position = fliplr(size(EMG_data_TW, 2) + 1 - [(iTW-1)*samples_increment_TW+1 : iTW*samples_increment_TW]);
                        if any(to_insert_position <= 0)
                            % Take the Incremental Part of the new one
                            initial_portion_current_EMG = 1:sum(to_insert_position > 0);
                            new_EMG_data_TW = self.temp_emg_data(self.num_incremental_TW - iTW + 2).total_EMG_data;
                            EMG_data_TW(:, initial_portion_current_EMG + samples_increment_TW) = new_EMG_data_TW(:, initial_portion_current_EMG);
                            % Recover the Full Previous TW
                            EMG_data_TW(:, 1:samples_increment_TW) = self.temp_emg_data(self.num_incremental_TW - iTW + 1).total_EMG_data;
                            
                        else
                            EMG_data_TW(:, to_insert_position) = self.temp_emg_data(self.num_incremental_TW - iTW + 1).total_EMG_data;
                        end
                    end
                    % Extract Features
                    feature_struct = self.features_extractions(EMG_data_TW);
                    self.temp_features(self.num_incremental_TW).MAV = feature_struct.MAV;
                    self.temp_features(self.num_incremental_TW).WL = feature_struct.WL;
                    self.temp_features(self.num_incremental_TW).SLP = feature_struct.SLP;
                    self.temp_features(self.num_incremental_TW).ZC = feature_struct.ZC;
                    self.temp_features(self.num_incremental_TW).STD = feature_struct.STD;
                    % Perform a classification with the computed features
                    if self.classify_flag == true
                        self.temp_control(self.num_incremental_TW).outIndex  = uint8(self.classify_movement());
                    end
                else
                    self.temp_features(self.num_incremental_TW).MAV = 0;
                    self.temp_features(self.num_incremental_TW).WL = 0;
                    self.temp_features(self.num_incremental_TW).SLP = 0;
                    self.temp_features(self.num_incremental_TW).ZC = 0;
                    self.temp_features(self.num_incremental_TW).STD = 0;
                    % Perform a classification with the computed features
                    if self.classify_flag == true
                        self.temp_control(self.num_incremental_TW).outIndex  = uint8(0);
                    end
                end
                
            end

            %Store all the packagess lost index
            self.packages_lost_index_total = [self.packages_lost_index_total packages_lost_index_samples];

            return
        end

        %% Classification on MATLAB
        % @return class_index
        function class_index = classify_movement(self)
            class_index = 0;
            controlMode = self.controlMode;
            switch controlMode
                case self.DIRECT_CONTROL
                    % class_index = self.classify_direct_control();
            end
        end

        %% Direct Control on MATLAB
        % Routine to classify the movement with direct control
        % @return none
        function class_index = classify_direct_control(self)
            MAVs = self.temp_features(self.num_incremental_TW).MAV;
            OH_flag = 0;
            CH_flag = 0;
            class_index = 0;

            ADS_chAcquireIndex_OH = self.DC_hands_params.openHand.ADS_chAcquireIndex;
            noise_OH = self.DC_hands_params.openHand.noise;
            MVC_OH = self.DC_hands_params.openHand.MVC;

            ADS_chAcquireIndex_CH = self.DC_hands_params.closeHand.ADS_chAcquireIndex;
            noise_CH = self.DC_hands_params.closeHand.noise;
            MVC_CH = self.DC_hands_params.closeHand.MVC;

            % Open Hand
            MAV_OH = MAVs(ADS_chAcquireIndex_OH);
            if MAV_OH > noise_OH
                OH_flag = 1;
                tempNormActivationLevel_OH = (MAV_OH - noise_OH) / (MVC_OH - noise_OH);
            end
            % Close Hand
            MAV_CH = MAVs(ADS_chAcquireIndex_CH);
            if MAV_CH > noise_CH
                CH_flag = 1;
                tempNormActivationLevel_CH = (MAV_CH - noise_CH) / (MVC_CH - noise_CH);
            end 
            % Both Above threshold
    		if (OH_flag && CH_flag)
			    if (tempNormActivationLevel_OH > tempNormActivationLevel_CH)
				    class_index = 1;
			    else 
				    class_index = 2; 
                end
            % Open Hand Above Threshold
            elseif OH_flag
			    class_index = 1; 
            % Close Hand Above Threshold
            elseif CH_flag
			    class_index = 2;
            end
        end

        %% Get EMG data samples of a Full TW (for data in float / channel)
        % Routine to acquire a Full Time Window (including calculated features) + Update the Graphical Parameters + Check the Exiting Condition (Button or Max Num of Samples)
        % @param[in] samples_tw: Number of samples of the Incremental TW
        % @return increment_EMG_data
        %------------------------------------------------------------------
        function [EMG_data_TW] = getEMG_data_TW_float(self, samples_tw)
            
            EMG_data_TW = zeros(self.EMG_NUM_CHANNELS, samples_tw, 'single');
            samples_increment = self.packages_per_TW_increment * 5;
            if samples_tw < samples_increment
                error("Are asked more samples than the TW")
            end
            num_min_iteration = floor(samples_tw / samples_increment);
            num_max_iteration = ceil(samples_tw / samples_increment);

            % Update num_iteration accordingly to Residual EMG
            size_residual_EMG = size(self.residual_emg_data, 2);
            if size_residual_EMG
                num_iteration = num_min_iteration;
            else
                num_iteration = num_max_iteration;
            end

            % Initialise the graphical info
            if self.graphical_information.enable_graph
                % Times 
                full_temp_timer_TW = zeros(samples_tw, 1);
                control_cycle_time = zeros(1, num_iteration);
                % MAV
                streamed_MAV = zeros(self.EMG_NUM_CHANNELS, num_iteration, 'single');
                streamed_WL = zeros(self.EMG_NUM_CHANNELS, num_iteration, 'single');
                streamed_SLP = zeros(self.EMG_NUM_CHANNELS, num_iteration, 'single');
                streamed_ZC = zeros(self.EMG_NUM_CHANNELS, num_iteration, 'single');
                streamed_STD = zeros(self.EMG_NUM_CHANNELS, num_iteration, 'single');
                % Control Params
                outIndexes = zeros(1, num_iteration, "uint8");
                actLevels = zeros(self.NUM_DOF, num_iteration, "uint8");
                rawGraspInformation = zeros(self.RAW_GRASP_INFORMATION_SIZE, num_iteration, "uint8");
            end

            % Retrieve Previous Residual EMG and full_temp_timer_TW
            if size_residual_EMG
                EMG_data_TW(:, 1:size_residual_EMG) = self.residual_emg_data;
                if self.graphical_information.enable_graph
                    % Times 
                    full_temp_timer_TW(1:size_residual_EMG) = self.residual_timer;
                end
            end

            for  iTW = 1:num_iteration
                % Get the Data
                [increment_EMG_data_TW] = self.getEMG_data_features_increment_TW_float(samples_increment);
                increment_timer_TW = self.timer_TW;

                to_insert_position = [(iTW-1)*samples_increment+1 : iTW*samples_increment]';
                % Update to_insert_position considering the residual_emg_data
                to_insert_position = to_insert_position + size_residual_EMG;
                % If there are more data than the required, to_insert_position is modified and they are saved for the next TW
                if ( to_insert_position(end) > samples_tw )
                    % Save Not used information
                    sample_residual = to_insert_position(end) - samples_tw;
                    residual_position = (length(increment_EMG_data_TW) - sample_residual + 1) : length(increment_EMG_data_TW);
                    self.residual_emg_data = increment_EMG_data_TW(:, residual_position);
                    self.residual_timer = self.timer_TW(residual_position);
                    % Update increment_EMG_data_TW and to_insert_position
                    increment_EMG_data_TW = increment_EMG_data_TW(:, 1:(samples_increment - sample_residual));
                    increment_timer_TW = increment_timer_TW(1:(samples_increment - sample_residual));
                    to_insert_position = to_insert_position(1):samples_tw;
                % Reset Residual EMG if no misallignment
                elseif ( to_insert_position(end) == samples_tw ) 
                    self.residual_emg_data = [];
                    self.residual_timer = [];
                end

                % Save the Data
                EMG_data_TW(:, to_insert_position) = increment_EMG_data_TW;

                % Save portion of Graphical Info
                if self.graphical_information.enable_graph
                    % Times 
                    full_temp_timer_TW(to_insert_position) = increment_timer_TW;
                    control_cycle_time(iTW) = increment_timer_TW(end);
                    % MAV
                    streamed_MAV(:, iTW) = self.temp_streamed_features(self.num_incremental_TW).MAV;
                    streamed_WL(:, iTW) = self.temp_streamed_features(self.num_incremental_TW).WL;
                    streamed_SLP(:, iTW) = self.temp_streamed_features(self.num_incremental_TW).SLP;
                    streamed_ZC(:, iTW) = self.temp_streamed_features(self.num_incremental_TW).ZC;
                    streamed_STD(:, iTW) = self.temp_streamed_features(self.num_incremental_TW).STD;
                    % Control Params
                    outIndexes(iTW) = self.temp_streamed_control(self.num_incremental_TW).outIndex;
                    actLevels(:, iTW) = self.temp_streamed_control(self.num_incremental_TW).actLevels;
                    rawGraspInformation(:, iTW) = self.temp_streamed_control(self.num_incremental_TW).rawGraspInformation;
                end
            end
                
            % Save the graphical info into the class
            if self.graphical_information.enable_graph
                self.graphical_information.full_timer_TW = full_temp_timer_TW;
                self.graphical_information.control_cycle_time = control_cycle_time;
                self.graphical_information.EMG_data_TW = EMG_data_TW;
                self.graphical_information.streamed_MAV = streamed_MAV;
                self.graphical_information.streamed_WL = streamed_WL;
                self.graphical_information.streamed_SLP = streamed_SLP;
                self.graphical_information.streamed_ZC = streamed_ZC;
                self.graphical_information.streamed_STD = streamed_STD;
                self.graphical_information.outIndexes = outIndexes;
                self.graphical_information.actLevels = actLevels;
                self.graphical_information.rawGraspInformation = rawGraspInformation;
            end
        end

        %% Decode Grasp information
        % Routine to Decode Grasp information from the bluetooth package, depending on the hand in use
        % @param[in] samples_tw: Number of samples of the Incremental TW
        % @return increment_EMG_data
        %------------------------------------------------------------------
        function GraspInformation = decode_graspInformation(self, rawGraspInformation)
            GraspInformation = zeros(size(rawGraspInformation));
            if self.handInUse == self.MIA_HAND_NAME
                %Position Motor Thumb
                GraspInformation(1, :) = double(rawGraspInformation(1, :));
                %Position Motor Middle/Ring/Little
                GraspInformation(2, :) = double(rawGraspInformation(2, :));

                %GraspPosition
                % GraspInformation(5, :) = double(rawGraspInformation(5, :));

                for i = 1:size(rawGraspInformation, 2)
                    %Position and Signal Motor Index
                    index_position = double(typecast([rawGraspInformation(4:-1:3, i)], 'int16'));
                    if index_position >= 0
                        GraspInformation(3, i) = index_position;
                        GraspInformation(4, i) = zeros(size(index_position));
                    elseif index_position < 0
                        GraspInformation(3, i) = zeros(size(index_position));
                        GraspInformation(4, i) = abs(index_position);
                    end
                
                    %Thumb Normal Force
                    GraspInformation(5,i) = double(typecast([rawGraspInformation(6:-1:5, i)], 'int16'));
                    %Middle/Ring/Little Normal Force
                    GraspInformation(6,i) = double(typecast([rawGraspInformation(8:-1:7, i)], 'int16'));
                    %Index Normal Force
                    GraspInformation(7,i) = double(typecast([rawGraspInformation(10:-1:9, i)], 'int16'));
                    
                    %Thumb Motor Electric Current
                    GraspInformation(8,i) = double(typecast([rawGraspInformation(12:-1:11, i)], 'int16'));
                    %Middle/Ring/Little Motor Electric Current
                    GraspInformation(9,i) = double(typecast([rawGraspInformation(14:-1:13, i)], 'int16'));
                    %Index Motor Electric Current
                    GraspInformation(10,i) = double(typecast([rawGraspInformation(16:-1:15, i)], 'int16'));

                end

            elseif self.handInUse == self.OTTOBOCK_SENSORHAND_NAME || self.handInUse == self.MICHELANGELO_HAND_NAME || self.handInUse == self.OTTOBOCK_NAME
                for i = 1:size(rawGraspInformation, 2)
                    uint_16_data_A = typecast([rawGraspInformation(2:-1:1, i)],'uint16');
                    GraspInformation(1, i) = round(double(uint_16_data_A)*5/4095, 2);
                    uint_16_data_B = typecast([rawGraspInformation(4:-1:3, i)],'uint16');
                    GraspInformation(2, i) = round(double(uint_16_data_B)*5/4095, 2);
                    uint_16_data_C = typecast([rawGraspInformation(6:-1:5, i)],'uint16');
                    GraspInformation(3, i) = round(double(uint_16_data_C)*5/4095, 2);
                    uint_16_data_D = typecast([rawGraspInformation(8:-1:7, i)],'uint16');
                    GraspInformation(4, i) = round(double(uint_16_data_D)*5/4095, 2);
                    uint_16_data_E = typecast([rawGraspInformation(10:-1:9, i)],'uint16');
                    GraspInformation(5, i) = round(double(uint_16_data_E)*5/4095, 2);
                    uint_16_data_F = typecast([rawGraspInformation(12:-1:11, i)],'uint16');
                    GraspInformation(6, i) = round(double(uint_16_data_F)*5/4095, 2);
                    uint_16_data_G = typecast([rawGraspInformation(14:-1:13, i)],'uint16');
                    GraspInformation(7, i) = round(double(uint_16_data_G)*5/4095, 2);
                    uint_16_data_H = typecast([rawGraspInformation(16:-1:15, i)],'uint16');
                    GraspInformation(8, i) = round(double(uint_16_data_H)*5/4095, 2);
                end
            else 
                GraspInformation(1, :) = double(rawGraspInformation(1, :));
            end

            % Other Parameters
            for i = 1:size(rawGraspInformation, 2)
                %Feedback Stimulation
                for m = 1:self.FB_NUM_CHANNELS
                    GraspInformation((10+m),i) = double(rawGraspInformation((16+m), i));
                end

                % Accelerometer X,Y,Z
                GraspInformation((10+self.FB_NUM_CHANNELS+1),i) = double(typecast([rawGraspInformation(16+self.FB_NUM_CHANNELS+2:-1:16+self.FB_NUM_CHANNELS+1, i)], 'int16'));
                GraspInformation((10+self.FB_NUM_CHANNELS+2),i) = double(typecast([rawGraspInformation(16+self.FB_NUM_CHANNELS+4:-1:16+self.FB_NUM_CHANNELS+3, i)], 'int16'));
                GraspInformation((10+self.FB_NUM_CHANNELS+3),i) = double(typecast([rawGraspInformation(16+self.FB_NUM_CHANNELS+6:-1:16+self.FB_NUM_CHANNELS+5, i)], 'int16'));
                % Gyroscope X,Y,Z
                GraspInformation((10+self.FB_NUM_CHANNELS+4),i) = double(typecast([rawGraspInformation(16+self.FB_NUM_CHANNELS+8:-1:16+self.FB_NUM_CHANNELS+7, i)], 'int16'));
                GraspInformation((10+self.FB_NUM_CHANNELS+5),i) = double(typecast([rawGraspInformation(16+self.FB_NUM_CHANNELS+10:-1:16+self.FB_NUM_CHANNELS+9, i)], 'int16'));
                GraspInformation((10+self.FB_NUM_CHANNELS+6),i) = double(typecast([rawGraspInformation(16+self.FB_NUM_CHANNELS+12:-1:16+self.FB_NUM_CHANNELS+11, i)], 'int16'));

            end
            
        end

        %% Get Feature + Class Index + activLevel
        % Routine to get the 5 Features + Class Index + activLevels in the Control Cycle
        % @param[in] none
        % @return feat:         5 Features
        % @return outIndex:     1 Output class
        % @return activLevel:   3 activLevels
        %------------------------------------------------------------------
        % function [feat, outIndex, activLevel] = getFeatControl(self)
        %     feat = zeros(8, 5);
        %     outIndex = 0;
        %     activLevel = zeros(3, 1);
        %     % Get the Header
        %     bt_data = self.receiveReply("0xAC"); % First byte from the Status bytes should be AC, indicating that it is indeed Feature + Class Index + activLevel
        %     % Get The Data 
        %     if (dec2hex(bt_data(1)) == "AC")
        %         % Discard Header Byte indicating Feature + Class Index + activLevel package
        %         bt_data = bt_data(2:end); 
        %         % Get the features
        %         feat_v = zeros(8*5, 1);
        %         for iFeat = 1:40
        %             positionInterval = 4*(iFeat):-1:4*(iFeat-1)+1;
        %             feat_v(iFeat) = typecast(uint8(bt_data(positionInterval)),'single');
        %         end
        %         feat = reshape(feat_v, 8, 5); % [Chan x Feat]
        %         % Get the OutIndex
        %         outIndex = bt_data(161);
        %         % Get the activLevels
        %         activLevel = bt_data(162:164);
        %     end
        % end

        %% Get EMG data time window sample (for data in int32 / channel)
        % Routine to acquire a time window equivalent of EMG data samples in the format of 32 int for each channel.
        % The data comes already formatted in int32, receiving a total of 33
        % number of bytes = 1 byte (Header indicating it is EMG data) + 4 bytes (1 channel) * 8 (channels) 
        % @param[in] TWnumsamples are the desired number of samples to acquire
        % @return EMG_data
        %------------------------------------------------------------------
        % function [counter, timer, EMG_data, elapsed, total_added_time] = getEMG_data_TW_int32(self, TWnumsamples, sampleF, final_time_TW, total_added_time)
        %     % Working with copy of variable, as it can be changed during the
        %     % running of this function on last if statement
        %     emg_package_size_copy = self.EMG_PACKAGE_SIZE;
        %     startIteration = zeros(TWnumsamples/5, 1);
        %     endIteration = zeros(TWnumsamples/5, 1);
        %     counter = zeros(TWnumsamples/5, 1);
        %     timer = zeros(TWnumsamples, 1);
        %     EMG_data = zeros(self.EMG_NUM_CHANNELS, TWnumsamples);
        %     start_time_TW = final_time_TW;
        % 
        %     packages_counter = 0;
        %     samples_counter = 0;
        %     package_number = 1;
        %     while packages_counter < TWnumsamples
        %         startIteration(package_number) = second(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSSSSS'));
        %         % Get the Header
        %         bt_data = self.receiveReply("0xAB"); % First byte from the Status bytes should be C0, indicating that it is indeed EMG data that we are acquiring
        %         % Get the Counter
        %         counter(package_number) = typecast(uint8(bt_data(5:-1:2)),'uint32');
        % 
        %         % Get the Timer
        %         elapsed_timer = typecast(uint8(bt_data(9:-1:6)),'uint32');
        %         % Reconstruct the time vector from the elapsed time of the
        %         % Timer and the Counter
        %         elapsed_timer = single(elapsed_timer)/96000000;
        %         % If not ask for a Tw              
        %         % Reconstruct the five samples of the Package
        %         t_package = zeros(5,1);
        %         % First Time, if it is 1, 21, 41... we want the real value;
        %         % Otherwise we reconstruct it
        %         if mod(counter(package_number), TWnumsamples/5) == 1
        %             if package_number == 1
        %                 start_time_TW =  start_time_TW + elapsed_timer; %-----------------------------------------CHECK, if "elapsed_timer" is required.
        %             else
        %                 start_time_TW =  start_time_TW + elapsed_timer  * (counter(package_number) - counter(package_number-TWnumsamples/5));
        %             end
        %         else
        %             %Value of time for the first sample of the package
        %             start_time_TW =  start_time_TW + 1/sampleF * (counter(package_number) - counter(package_number-1));  % Correction factor if we miss some samples
        %         end
        %         t_package(1) = start_time_TW;
        %         % Other 4 values of time
        %         for num_other_temp_values = 1:4
        %             start_time_TW = start_time_TW + 1/sampleF;
        %             t_package(num_other_temp_values+1) = start_time_TW;
        %         end
        % 
        %         %Time corresponding to each sample
        %         timer(5*(package_number-1) + 1 : 5*(package_number-1) + 5) = t_package;
        % 
        % 
        %         % Get The Data
        %         if (dec2hex(bt_data(1)) == "AB")
        %             % Discard Header Byte indicating EMG data + Counter & Timer
        %             bt_data = bt_data(10:end); 
        %             for n = 1 : emg_package_size_copy % Packages of x Samples
        %                 samples_counter = samples_counter + 1;
        %                 % Read 1 sample for eache channel (32 bytes)
        %                 for i = 1 : self.EMG_NUM_CHANNELS % Separate data into separate channel data
        %                     EMG_data(i, samples_counter) = typecast(uint8(bt_data(4:-1:1)),'single');
        %                     bt_data = bt_data(5:end); % Move onto next channel (next 32bits = 4bytes)
        %                 end
        %             end
        %             % Read next 8 * packages_size(5) samples
        %             packages_counter = packages_counter + emg_package_size_copy; %Stops at the exact number of nsamples, instead of multiples of 8x
        %             if(packages_counter + self.EMG_PACKAGE_SIZE > TWnumsamples)
        %                 emg_package_size_copy = mod(TWnumsamples, packages_counter);
        %             end
        %         end
        %         endIteration(package_number) = second(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSSSSS')) -  startIteration(package_number);
        %         package_number = package_number + 1;
        %     end
        % 
        %     elapsed = endIteration;
        % 
        %     return
        % end

        %% Convert from 24bit_complement2 to 32bit_single
        % Routine to convert the data acquired from the ADS1299 in 24bit complement 2 per channel, into int32 per channel.
        % @param[in] int24c2_data is the data in 24bit complement 2 for one channel
        % @return int32_data is the data in int32 for one channel
        %------------------------------------------------------------------
        % function int32_data = int24c2_to_int32(self, int24c2_data)
        %     msb_byte_a = uint8(0);
        %     msb_byte_b = uint8(int24c2_data(1));
        %     msb_byte_c = uint8(int24c2_data(2));
        %     msb_byte_d = uint8(int24c2_data(3));
        %     if bitand(uint8(msb_byte_b),uint8(128),'uint8')
        %         msb_byte_a = bitor(msb_byte_a,uint8(255),'uint8');
        %     end
        %     temp = double(msb_byte_d) + double(msb_byte_c)*256 + double(msb_byte_b)*65536;
        %     if temp > 8388607                                     
        %         temp = temp - 2^24;
        %     end
        %     int32_data = temp;
        % end

        %% Set sampling frequency and gain
        % Routine to set the desired sample frequency and sample gain of the ADS1299.
        % @param[in] sampleF refers to the desired sampling frequency of the ADS1299 acquisition of data
        % @param[in] gain is the desired ADS1299 acquired signals gain
        % @return none
        %------------------------------------------------------------------
        function setSampleFreqGain(self, sampleF, gains)
            % Encode
            switch sampleF
                case 16000
                    sampleF_encoded = 0;
                case 8000
                    sampleF_encoded = 1;
                case 4000
                    sampleF_encoded = 2;
                case 2000
                    sampleF_encoded = 3;
                case 1000
                    sampleF_encoded = 4;
                case 500
                    sampleF_encoded = 5;
                case 250
                    sampleF_encoded = 6;
                otherwise
                    error('sampling frequency not supported by the device');
            end

            % Compone
            general_information = [];
            general_information = self.write_BT(general_information, uint8(sampleF_encoded) );
            general_information = self.write_BT(general_information, uint8(gains) );
            % Send
            result = self.sendCommand(self.SET_FREQ_GAIN_ADS1299, general_information, length(general_information));
            if (result ~= 0)
                % error message and exit
                error('Failed at setting sampling frequency and gain.')
            end
            dataHex = self.receiveReply(self.SET_FREQ_GAIN_ADS1299);
            error_set_frequency = hex2dec(dataHex(1,:));
            error_set_gain = hex2dec(dataHex(2,:));
            % Check the Values of frequency
            if (error_set_frequency == self.NO_ERR_CORECORE)  
                fprintf('Sampling Frequency set to %d with Success! \n', sampleF)
                self.sampleF_encoded = sampleF_encoded;
                self.sampleF = sampleF;
            else
                disp('Sampling Frequency NOT set successfully!')
            end
            self.check_ads_set(error_set_frequency)
            % Check the Values of gain
            if (error_set_gain == self.NO_ERR_CORECORE)  
                fprintf('Gain set to %d with Success! \n', gains)
                self.gains_encoded = gains;
                self.gains = gains;
            else
                disp('Gain NOT set successfully!')
            end
            self.check_ads_set(error_set_gain)
            fprintf('\n');
        end

        %% Set Electrodes Configuration (Differential or Pre-amplified)
        % Routine to set the ADS1299 electrodes configuration "Differential" or "Pre-amplified".
        %(0x00) = (0) 0000 0000, Switch is open (Differential configuration / Pre-gel electrodes)
        %(0x20) = (32) 0010 0000, Switch closed (Pre-amplified configuration / Ottobock electrodes)
        % @param[in] configuration
        % @return none
        function setElectrodesConfig(self, configuration)
            % send command!
            if (configuration == "Differential")
                config = uint8(0);
            elseif (configuration == "Pre-amplified")
                config = uint8(32);
            else
                error('LM: wrong electrode configuration input')
            end

            general_information = [];
            general_information = self.write_BT(general_information, uint8(config) );
            result = self.sendCommand(self.SET_ELECTRODES_CONFIG, general_information, length(general_information));
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.SET_ELECTRODES_CONFIG);
            error_set_config = hex2dec(dataHex(1,:));
            % Check the Values of configuration
            if (error_set_config == self.NO_ERR_CORECORE)  
                fprintf('Electrodes configuration set to %s with Success! \n',configuration)
                self.config_encoded = config;
                self.config = configuration;
            else
                disp('Electrodes configuration NOT set successfully \n!')
            end
            self.check_ads_set(error_set_config)
            fprintf('\n');
        end
        
        %% Get RTCC Data
        % Routine to send command to read the values from the RTCC. (hour,minute,second,day,month,year)
        % saved in rtcc property of the class
        % @return none
        %-----------------------------------------------------------------
        function getRTCCData(self)
            % send command!
            result = self.sendCommand(self.GET_RTCC_DATA, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_RTCC_DATA);
            dataDec = hex2dec(dataHex);
            newRTCC.year = dataDec(1); newRTCC.month = dataDec(2); newRTCC.day = dataDec(3); newRTCC.weekday = dataDec(4); newRTCC.hour = dataDec(5); newRTCC.minute = dataDec(6); newRTCC.second = dataDec(7); 
            disp('RTCC Data: ');
            timeLabels = {'Year: ', 'Month: ', 'Day: ', 'Week Day: ','Hours: ','Minutes: ','Seconds: '};
            for i = 1:7
                fprintf('%s%d / ',timeLabels{i},dataDec(i))
            end
            self.rtcc = newRTCC;
            fprintf('\n');
        end

        %% SET RTCC Data
        % Routine to send command to set the values on the RTCC. (hour,minute,second,day,month,year).
        % @param[in] RTCC structure with the respective values to set on the RTCC.
        % @return none
        %-----------------------------------------------------------------
        function setRTCCData(self, RTCC)
            RTCC_vector = [RTCC.year, RTCC.month, RTCC.day, RTCC.weekday, RTCC.hour, RTCC.minute, RTCC.second];
            % send command!
            result = self.sendCommand(self.SET_RTCC_DATA, RTCC_vector, length(RTCC_vector));
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.SET_RTCC_DATA); % 'char', 'char';
            error_set_time = hex2dec(dataHex(1,:));
            error_set_date = hex2dec(dataHex(2,:));
            disp(' ')
            % Check the Values of Time
            if (error_set_time == self.NO_ERR_RTCC)  
                disp('Time set successfully')
            else
                disp('Time NOT set successfully!')
            end
            self.check_RTCC_set(error_set_time)
            % Check the Values of Date
            if (error_set_date == self.NO_ERR_RTCC)  
                disp('Date set successfully')
            else
                disp('Date NOT set successfully !')
            end
            self.check_RTCC_set(error_set_date)

            disp('RTCC Set Successfully')
            disp('RTCC Data: ');
            timeLabels = {'Year: ', 'Month: ', 'Day: ', 'Week Day: ','Hours: ','Minutes: ','Seconds: '};
            for i = 1:7
                fprintf('%s%d / ',timeLabels{i},RTCC_vector(i));
            end
            self.rtcc = RTCC;
            fprintf('\n');
        end

        %% Get ADS1299 Data
        % Routine to acquiree the ADS1299 setted parameters (gain, sample frequency, electrode configuration)
        % saved in the properties of the class
        % @return none
        %-----------------------------------------------------------------
       function getADSdata(self)
    result = self.sendCommand(self.GET_ADS_DATA, 0, 0);
    if (result ~= 0)
        error('LM: error connecting to device.')
    end
    dataHex = self.receiveReply(self.GET_ADS_DATA);

    % receiveReply returns either a hex char array or a raw uint8 vector,
    % depending on acquisition state. Normalise to uint8 before decoding.
    if ischar(dataHex) || isstring(dataHex)
        dataDec = uint8(hex2dec(dataHex));
    else
        dataDec = uint8(dataHex);
    end
    fprintf('DEBUG getADSdata: class=%s, size=%s, first16=%s\n', ...
    class(dataHex), mat2str(size(dataHex)), ...
    mat2str(double(dataHex(1:min(numel(dataHex),16)))));
            self.reset_read_BT_counter();
            self.sampleF_encoded = self.read_BT(dataDec, 1, 'uint8');
            self.gains_encoded = self.read_BT(dataDec, self.EMG_NUM_CHANNELS, 'uint8');
            self.config_encoded = self.read_BT(dataDec, 1, 'uint8');

            % Store the values on the ADS
            self.decodeADSdata();
            fprintf('\n');
        end

        

        %% Decode ADS Data
        % Routine to decode the ADS1299 setted parameters (gain, sample frequency, electrode configuration)
        % and save the the properties of the class
        % @return none
        %-----------------------------------------------------------------
        function decodeADSdata(self)
            sampleF_encoded = self.sampleF_encoded;
            switch sampleF_encoded
                case 0
                    sampleF = 16000;
                case 1
                    sampleF = 8000;
                case 2
                    sampleF = 4000;
                case 3
                    sampleF = 2000;
                case 4
                    sampleF = 1000;
                case 5
                    sampleF = 500;
                case 6
                    sampleF = 250;
                otherwise
                    error('sampling frequency not supported by the device');
            end
            self.sampleF = sampleF;

            % Check on the Gain 
            gain_encoded = self.gains_encoded;
            self.gains = gain_encoded;

            config_encoded = self.config_encoded;
            if (config_encoded == 0)
                configuration = "Differential";
            elseif (config_encoded == 32)
                configuration = "Pre-amplified";
            else
                error('LM: wrong electrode configuration input')
            end
            fprintf('Values Read from ADS Freq Sample: %d, Gain: %d %d %d %d %d %d %d %d, Configuration: %s \n',sampleF, gain_encoded, configuration)
            self.config = configuration;
        end

        %% Encode ADS Data
        % Routine to encode the ADS1299 setted parameters (gain, sample frequency, electrode configuration)
        % and save the the properties of the class
        % @return none
        %-----------------------------------------------------------------
        function encodeADSdata(self)
            sampleF = self.sampleF;
            switch sampleF
                case 16000
                    sampleF_encoded = 0;
                case 8000
                    sampleF_encoded = 1;
                case 4000
                    sampleF_encoded = 2;
                case 2000
                    sampleF_encoded = 3;
                case 1000
                    sampleF_encoded = 4;
                case 500
                    sampleF_encoded = 5;
                case 250
                    sampleF_encoded = 6;
                otherwise
                    error('sampling frequency not supported by the device');
            end
            self.sampleF_encoded = sampleF_encoded;

            self.gains_encoded = self.gains;

            configuration = self.config;
            if strcmp(configuration, "Differential")
                config_encoded = 0;
            elseif strcmp(configuration, "Pre-amplified")
                config_encoded = 32;
            else
                error('LM: wrong electrode configuration input')
            end
            self.config_encoded = config_encoded;

            fprintf('Values Read from ADS Freq Sample: %d, Gain: %d  %d  %d  %d  %d  %d  %d  %d, Configuration: %s \n',self.sampleF, self.gains_encoded(1), self.gains_encoded(2), self.gains_encoded(3), self.gains_encoded(4), self.gains_encoded(5), self.gains_encoded(6), self.gains_encoded(7), self.gains_encoded(8), self.config)
        end

        %% Get Acquisition Parameters
        % Routine to acquire the acquisition parameters (channels, tw samples, tw samples overlap, testmode, enabled_filters)
        % saved in the properties of the class
        % @return none
        %-----------------------------------------------------------------
        function getAcquisitionParams(self)
            % send command
            result = self.sendCommand(self.GET_ACQ_PARAMS, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_ACQ_PARAMS);
            dataDec = hex2dec(dataHex);
            % Store the values on the ADS
            self.channels_encoded = dataDec(1);
            self.tw_samples_encoded = dataDec(2);
            self.two_samples_encoded = dataDec(3);
            self.enable_testmode = dataDec(4);
            self.enabled_filters = dataDec(5);
            self.decodeAcquisitionParams();
            fprintf('\n');
        end

        %% Decode Acquisition Parameterss
        % Routine to decode the acquisition parameters
        % and save the the properties of the class
        % @return none
        %-----------------------------------------------------------------
        function decodeAcquisitionParams(self)
            tw_samples_encoded = self.tw_samples_encoded;
            switch tw_samples_encoded
                case 1
                    tw_samples = 100;
                case 2
                    tw_samples = 200;
                otherwise
                    error('Time Window Sample not supported by the device');
            end
            tw_samples
            self.tw_samples = tw_samples;

            two_samples_encoded = self.two_samples_encoded;
            switch two_samples_encoded
                case 0
                    two_samples = 0;
                case 1
                    two_samples = 25;
                case 2
                    two_samples = 50;
                case 3
                    two_samples = 75;
                case 4
                    two_samples = 100;
                otherwise
                    error('Time Window Sample Overlap not supported by the device');
            end
            two_samples
            self.two_samples = two_samples;

        end

        %% Encode Acquisition Parameterss
        % Routine to encode the acquisition parameters
        % and save the the properties of the class
        % @return none
        %-----------------------------------------------------------------
        function encodeAcquisitionParams(self)
            tw_samples = self.tw_samples;
            switch tw_samples
                case 100
                    tw_samples_encoded = 1;
                case 200
                    tw_samples_encoded = 2;
                otherwise
                    error('Time Window Sample not supported by the device');
            end
            self.tw_samples_encoded = tw_samples_encoded;

            two_samples = self.two_samples;
            switch two_samples
                case 0
                    two_samples_encoded = 0;
                case 25
                    two_samples_encoded = 1;
                case 50
                    two_samples_encoded = 2;
                case 75
                    two_samples_encoded = 3;
                case 100
                    two_samples_encoded = 4;
                otherwise
                    error('Time Window Sample Overlap not supported by the device');
            end
            self.two_samples_encoded = two_samples_encoded;

        end

        %% Decode OutIdx
        % Routine Decode From Grasp Indexes to Grasps names
        % @return decodedOutIdx: Name of the Grasp
        %-----------------------------------------------------------------
        function decodedOutIdx = decodeOutIdx(self, OutIdx)
            decodedOutIdx = "";
            for iOutIdx = 1:length(OutIdx)
                switch OutIdx(iOutIdx)
                    case 0
                        decodedOutIdx(iOutIdx) = "Rest";
                    case 1
                        decodedOutIdx(iOutIdx) = "Op H";
                    case 2
                        decodedOutIdx(iOutIdx) = "Cl H";
                    case 4
                        decodedOutIdx(iOutIdx) = "Pron";
                    case 8
                        decodedOutIdx(iOutIdx) = "Sup";
                    otherwise
                        error("Wrong OutIdx")
                end
            end
        end


        %% Get SD Data
        % Routine to acquiree the Limb-MATE setted parameters of all the peripherals saved on the SD card, 
        % saved on the sd_text property of the class
        % @return none
        %-----------------------------------------------------------------
        function getSDData(self)
            % First Package
            iPackage_to_send = typecast(uint32(0),"uint8");
            result = self.sendCommand(self.READ_SD_DATA, iPackage_to_send, 4);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.READ_SD_DATA);
            dataDec = hex2dec(dataHex);
            % Get the Size of the File and use this information to establish how many packages
            file_size = double(typecast(uint8(dataDec(1:4)), "uint32"));
            number_packages = floor(file_size / (self.DATA_SEGM) / (self.MAX_PARAMS));

            % Save the Data 
            uint8_data_m = zeros(self.MAX_PARAMS * number_packages, self.DATA_SEGM);
            uint8_data_m(1:self.MAX_PARAMS, :) = [reshape(dataDec(5:end), self.DATA_SEGM, [])]';
            % Wait the 7.5 msec if is not the last package
            pause(7.5/1000);

            % Other Packages
            for iPackage = 1 : number_packages - 1
                iPackage_to_send = typecast(uint32(iPackage),"uint8");
                result = self.sendCommand(self.READ_SD_DATA, iPackage_to_send, 1);
                if (result ~= 0)
                    % error message and exit
                    error('LM: error connecting to device.')
                end
                dataHex = self.receiveReply(self.READ_SD_DATA);
                dataDec = hex2dec(dataHex);

                % Save the Data 
                reshaped_data = [reshape(dataDec(5:end), self.DATA_SEGM, [])]';
                uint8_data_m((self.MAX_PARAMS) * iPackage + 1 : (self.MAX_PARAMS) * iPackage + size(reshaped_data, 1), :) = reshaped_data;
    
                if iPackage ~= (number_packages - 1)
                    % Wait the 7.5 msec if is not the last package
                    pause(7.5/1000);
                end
    
            end

            % Save the data into the class
            self.sd_text = uint8_data_m;
            self.sd_text_ascii = char(uint8_data_m);

            fprintf('\n');
        end

        %% Decode SD Information
        % Routine to decode the information present on the SD card general parameters
        % @return none
        %-----------------------------------------------------------------
        
        function desidered_value = decode_SD_info(self, row_ID, row, col)

            text_ascii = string(self.sd_text_ascii);
            row_ascii = string(row);
            if row < 100
                row_ascii = "00" + row_ascii;
            elseif row < 10
                row_ascii = "0" + row_ascii;
            end
            col_ascii = string(col);
            if col < 100
                col_ascii = "00" + col_ascii;
            elseif col < 10
                col_ascii = "0" + col_ascii;
            end
            % Extract all the rows with the ID
            row_number_ID = find(contains(text_ascii, row_ID))

            if isempty(row_number_ID)
                error('The ID is wrong')
            end

            % Extract all the rows with the specified row and column
            % Extract all the patterns of number
            pat_row =  ("(") + digitsPattern(3) + (","); 
            digits_extracted_row = extract(text_ascii(row_number_ID), pat_row);
            check_row = contains(digits_extracted_row(:,1), row_ascii)
            if isempty(find(check_row))
                error('The Row is wrong is wrong')
            end
            pat_col =  (",") + digitsPattern(3) + (")"); 
            digits_extracted_col = extract(text_ascii(row_number_ID), pat_col);
            check_col = contains(digits_extracted_col(:,1), col_ascii)
            if isempty(find(check_col))
                error('The Column is wrong is wrong')
            end
            % Final General Row
            specific_row = find(check_row .* check_col);   
            if isempty(specific_row)
                error('The Row-Column couple is wrong is wrong is wrong')
            end

            % Desired Row
            desired_row = row_number_ID(specific_row);
            % Desired Text 
            desired_text = text_ascii(desired_row, :)

            % DataType
            pat_data_type = ("f"|"u"|"i");
            data_type = extract(desired_text, pat_data_type);

            switch data_type
                case "u"
                    pat_number = digitsPattern(11);
                    desidered_value = str2double(extract(desired_text, pat_number))
                case "i"
                    pat_number = ("+"|"-") + digitsPattern(11);
                    desidered_value = str2double(extract(desired_text, pat_number))
                case "f" % +6.12345e+07
                    pat_number = ("+"|"-") + digitsPattern(1) + "." + digitsPattern(5) + "e" + ("+"|"-") + digitsPattern(2);
                    desidered_value = str2double(extract(desired_text, pat_number))
                otherwise
                    error ('The format is wrong')
            end
        end

        %% Reset SD card
        % Routine to reset the SD card data with the peripherals parameters
        % @return none
        %-----------------------------------------------------------------
        function resetSDData(self)
            % send command!
            result = self.sendCommand(self.RESET_SD_DATA, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            pause(35);
            self.receiveReply(self.RESET_SD_DATA);
            disp('Reset SD Data!')
            fprintf('\n');
            % Wait the 7.5 msec if is not the last package
            pause(7.5/1000);
            self.getSDData();
        end

        %% Get SD DataLog
        % Routine to acquiree the Limb-MATE setted datalogging and interpret it
        % saved on the sd_text_datalog property of the class
        % @return none
        %-----------------------------------------------------------------
        function getSDDatalog(self)
            % First Package
            iPackage_to_send = typecast(uint32(0),"uint8");
            result = self.sendCommand(self.GET_DATALOG, iPackage_to_send, 4);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_DATALOG);
            dataDec = hex2dec(dataHex);
            % Get the Size of the File and use this information to establish how many packages
            file_size = double(typecast(uint8(dataDec(1:4)), "uint32"));
            number_packages = floor(file_size / double(self.DATALOG_SIZE_MAX_BT));

            % Save the Data 
            uint8_data_m_BT = zeros(number_packages, self.DATALOG_SIZE_MAX_BT);
            uint8_data_m_BT(1, :) = [reshape(dataDec(5:end), self.DATALOG_SIZE_MAX_BT, [])]';

            % Wait the 7.5 msec if is not the last package
            pause(7.5/1000);

            % Other Packages
            for iPackage = 1: number_packages - 1
                iPackage_to_send = typecast(uint32(iPackage),"uint8");
                result = self.sendCommand(self.GET_DATALOG, iPackage_to_send, 4);
                if (result ~= 0)
                    % error message and exit
                    error('LM: error connecting to device.')
                end
                dataHex = self.receiveReply(self.GET_DATALOG);
                dataDec = hex2dec(dataHex);

                % Save the Data 
                uint8_data_m_BT(iPackage + 1, :) = [reshape(dataDec(5:end), self.DATALOG_SIZE_MAX_BT, [])]';
    
                if iPackage ~= (number_packages - 1)
                    % Wait the 7.5 msec if is not the last package
                    pause(7.5/1000);
                end
    
            end
            % Reshape Correctly
            uint8_data_m_BT = uint8_data_m_BT';
            uint8_data_v_BT = uint8_data_m_BT(:);
            uint8_data_v_BT = uint8_data_v_BT(1:self.DATALOG_SIZE_BLOCK*floor(length(uint8_data_v_BT) / self.DATALOG_SIZE_BLOCK));
            uint8_data_m = [reshape(uint8_data_v_BT, self.DATALOG_SIZE_BLOCK, [])]';
            uint8_data_m =  uint8_data_m(:, 1:self.DATALOG_SIZE);
            % Save the data into the class
            self.sd_text_datalog = uint8_data_m;
            % Interpret the Datalogging
            self.interpret_datalogging(uint8_data_m)

            fprintf('\n');

        end

        %% Interpret SD DataLog
        % Routine to Interpret the Limb-MATE Datalogging, 
        % saved on the sd_datalog property of the class
        % @return none
        %-----------------------------------------------------------------
        function interpret_datalogging(self, uint8_data_m)
            % Save compatibility even with older version
            if self.DATALOG_SIZE == 239 % First Release
                sd_datalog = self.interpret_datalogging_239(uint8_data_m);
            elseif self.DATALOG_SIZE == 242 % + 4 DoF (1 Act Level More for each step of the act levels)
                sd_datalog = self.interpret_datalogging_242(uint8_data_m);
            elseif self.DATALOG_SIZE == 254 % + 6 DoF IMU
                sd_datalog = self.interpret_datalogging_254(uint8_data_m);
            elseif self.DATALOG_SIZE == 256 % + Angle - 2 Bytes from conversion of the Temperature form float to int16
                sd_datalog = self.interpret_datalogging_256(uint8_data_m);
            end
            self.sd_datalog = sd_datalog;            
        end

        %% Interpret Datalog with 239 Parameters saved
        % Routine to Interpret the Limb-MATE Datalogging related to the
        % First Release
        % saved on the sd_datalog property of the class
        % @return none
        %-----------------------------------------------------------------
        function sd_datalog = interpret_datalogging_239(self, uint8_data_m)
            % creates an empty struct with fields
            sd_datalog = struct('header', {}, ...
                'counter', {}, 'RTCC_yy', {}, 'RTCC_MM', {}, 'RTCC_dd', {}, 'RTCC_ee', {}, 'RTCC_hh', {}, 'RTCC_mm', {}, 'RTCC_ss', {}, ...
                'battery', {}, 'temperature', {}, 'handInUse', {}, ...
                'MAV', {}, 'STD', {}, 'WL', {}, 'ZC', {}, 'SLP', {}, ...
                'class_raw', {}, 'class_pp', {}, 'actLevel_raw', {}, 'actLevel_pp', {}, 'actLevel_hand', {}, ...
                'graspType', {}, 'MIA', {}, 'Ottobock', {}, ...
                'stimulation', {}, 'tail', {} ...
                ); 

            for iRow = 1:size(uint8_data_m, 1)
                datalog = uint8_data_m(iRow, :);
                % Header
                header = datalog(1);
                % General
                counter = double(typecast(uint8(datalog(2:5)), "uint32"));
                RTCC_yy = datalog(6);
                RTCC_MM = datalog(7);
                RTCC_dd = datalog(8);
                RTCC_ee = datalog(9);
                RTCC_hh = datalog(10);
                RTCC_mm = datalog(11);
                RTCC_ss = datalog(12);
                battery = double(typecast(uint8(datalog(13:14)), "uint16")) * self.BATT_MAX_VOLTAGE / 4095; %Voltage divider is set to output 3.3V (4095) when input is 20V
                temperature = double(typecast(uint8(datalog(15:18)), "single"));
                handInUse = datalog(19);
                % Features
                % MAV
                for iCh = 1:self.EMG_NUM_CHANNELS
                    MAV(iCh) = double(typecast(uint8(datalog(20 + 4 * (iCh - 1) : 20 + 4 * (iCh - 1) + 3)), "single"));
                end
                % STD
                for iCh = 1:1:self.EMG_NUM_CHANNELS
                    STD(iCh) = double(typecast(uint8(datalog(52 + 4 * (iCh - 1) : 52 + 4 * (iCh - 1) + 3)), "single"));
                end
                % WL
                for iCh = 1:1:self.EMG_NUM_CHANNELS
                    WL(iCh) = double(typecast(uint8(datalog(84 + 4 * (iCh - 1) : 84 + 4 * (iCh - 1) + 3)), "single"));
                end
                % ZC
                for iCh = 1:1:self.EMG_NUM_CHANNELS
                    ZC(iCh) = double(typecast(uint8(datalog(116 + 4 * (iCh - 1) : 116 + 4 * (iCh - 1) + 3)), "single"));
                end
                % SLP
                for iCh = 1:1:self.EMG_NUM_CHANNELS
                    SLP(iCh) = double(typecast(uint8(datalog(148 + 4 * (iCh - 1) : 148 + 4 * (iCh - 1) + 3)), "single"));
                end
                % Control
                class_raw = datalog(180);
                class_pp = datalog(181);
                actLevel_raw(1:self.NUM_DOF) = datalog(182:184);
                actLevel_pp(1:self.NUM_DOF) = datalog(185:187);
                actLevel_hand(1:self.NUM_DOF) = datalog(188:190);
                % Grasp Type
                encoded_graspType = datalog(191);
                switch encoded_graspType
                    case 0
                        graspType = 'r';
                    case 1
                        graspType = 'O';
                    case 2
                        graspType = 'C';
                    case 3
                        graspType = 'P';
                    case 4
                        graspType = 'L';
                    case 5
                        graspType = 'S';
                    case 6
                        graspType = 'T';
                    case 7
                        graspType = 'U';
                    case 8
                        graspType = 'D';
                    case 9
                        graspType = 'R';
                    otherwise
                        graspType = '';
                end

                % Hand Parameters - MIA
                MIA.pos_thumb = datalog(192);
                MIA.pos_mrl = datalog(193);
                MIA.pos_index = double(typecast(uint8(datalog(194:195)), "int16"));
                MIA.cur_thumb = double(typecast(uint8(datalog(196:199)), "int32"));
                MIA.cur_mrl = double(typecast(uint8(datalog(200:203)), "int32"));
                MIA.cur_index = double(typecast(uint8(datalog(204:207)), "int32"));
                MIA.norm_force_thumb = double(typecast(uint8(datalog(208:211)), "int32"));
                MIA.norm_force_mrl = double(typecast(uint8(datalog(212:215)), "int32"));
                MIA.norm_force_index = double(typecast(uint8(datalog(216:219)), "int32"));
                MIA.handStatus = datalog(220);
                MIA.completeCalibration = datalog(221);
                % Hand Parameters - Ottobock
                for iCh = 1:self.DAC_CHANNELS
                    Ottobock.DAC(iCh) = double(typecast(uint8(datalog(222 + 2 * (iCh - 1) : 222 + 2 * (iCh - 1) + 1)), "uint16")) * 5 / 4095;
                end
                stimulation_encoded = uint8(datalog(238));
                stimulation = zeros(self.FB_NUM_CHANNELS, 1);
                stimulation_encoded_bin = dec2bin(stimulation_encoded, 8);
                for i = 1:self.FB_NUM_CHANNELS
                    if stimulation_encoded_bin(i) == '1'
                        stimulation(i) = 1;
                    end
                end
                stimulation = stimulation;
                % Tail
                tail = datalog(239);

                % Save into the struct
                sd_datalog(end+1) = cell2struct({header, ...
                    counter, RTCC_yy, RTCC_MM, RTCC_dd, RTCC_ee, RTCC_hh, RTCC_mm, RTCC_ss, ...
                    battery, temperature, handInUse, ...
                    MAV, STD, WL, ZC, SLP, ...
                    class_raw, class_pp, actLevel_raw, actLevel_pp, actLevel_hand, ...
                    graspType, MIA, Ottobock, ...
                    stimulation, tail ...
                    }, fieldnames(sd_datalog), 2);
            end
        end

        %% Interpret Datalog with 242 Parameters saved
        % Routine to Interpret the Limb-MATE Datalogging related to the
        % First Release after adding a 4th DoF (1 Act level more for each step)
        % saved on the sd_datalog property of the class
        % @return none
        %-----------------------------------------------------------------
        function sd_datalog = interpret_datalogging_242(self, uint8_data_m)
            % creates an empty struct with fields
            sd_datalog = struct('header', {}, ...
                'counter', {}, 'RTCC_yy', {}, 'RTCC_MM', {}, 'RTCC_dd', {}, 'RTCC_ee', {}, 'RTCC_hh', {}, 'RTCC_mm', {}, 'RTCC_ss', {}, ...
                'battery', {}, 'temperature', {}, 'handInUse', {}, ...
                'MAV', {}, 'STD', {}, 'WL', {}, 'ZC', {}, 'SLP', {}, ...
                'class_raw', {}, 'class_pp', {}, 'actLevel_raw', {}, 'actLevel_pp', {}, 'actLevel_hand', {}, ...
                'graspType', {}, 'MIA', {}, 'Ottobock', {}, ...
                'stimulation', {}, 'tail', {} ...
                ); 

            for iRow = 1:size(uint8_data_m, 1)
                datalog = uint8_data_m(iRow, :);
                % Header
                header = datalog(1);
                % General
                counter = double(typecast(uint8(datalog(2:5)), "uint32"));
                RTCC_yy = datalog(6);
                RTCC_MM = datalog(7);
                RTCC_dd = datalog(8);
                RTCC_ee = datalog(9);
                RTCC_hh = datalog(10);
                RTCC_mm = datalog(11);
                RTCC_ss = datalog(12);
                battery = double(typecast(uint8(datalog(13:14)), "uint16")) * self.BATT_MAX_VOLTAGE / 4095; %Voltage divider is set to output 3.3V (4095) when input is 20V
                temperature = double(typecast(uint8(datalog(15:18)), "single"));
                handInUse = datalog(19);
                % Features
                % MAV
                for iCh = 1:self.EMG_NUM_CHANNELS
                    MAV(iCh) = double(typecast(uint8(datalog(20 + 4 * (iCh - 1) : 20 + 4 * (iCh - 1) + 3)), "single"));
                end
                % STD
                for iCh = 1:1:self.EMG_NUM_CHANNELS
                    STD(iCh) = double(typecast(uint8(datalog(52 + 4 * (iCh - 1) : 52 + 4 * (iCh - 1) + 3)), "single"));
                end
                % WL
                for iCh = 1:1:self.EMG_NUM_CHANNELS
                    WL(iCh) = double(typecast(uint8(datalog(84 + 4 * (iCh - 1) : 84 + 4 * (iCh - 1) + 3)), "single"));
                end
                % ZC
                for iCh = 1:1:self.EMG_NUM_CHANNELS
                    ZC(iCh) = double(typecast(uint8(datalog(116 + 4 * (iCh - 1) : 116 + 4 * (iCh - 1) + 3)), "single"));
                end
                % SLP
                for iCh = 1:1:self.EMG_NUM_CHANNELS
                    SLP(iCh) = double(typecast(uint8(datalog(148 + 4 * (iCh - 1) : 148 + 4 * (iCh - 1) + 3)), "single"));
                end
                % Control
                class_raw = datalog(180);
                class_pp = datalog(181);
                actLevel_raw(1:self.NUM_DOF) = datalog(182:185);
                actLevel_pp(1:self.NUM_DOF) = datalog(186:189);
                actLevel_hand(1:self.NUM_DOF) = datalog(190:193);
                % Grasp Type
                num_new_parameters = 3;
                encoded_graspType = datalog(191 + num_new_parameters);
                switch encoded_graspType
                    case 0
                        graspType = 'r';
                    case 1
                        graspType = 'O';
                    case 2
                        graspType = 'C';
                    case 3
                        graspType = 'P';
                    case 4
                        graspType = 'L';
                    case 5
                        graspType = 'S';
                    case 6
                        graspType = 'T';
                    case 7
                        graspType = 'U';
                    case 8
                        graspType = 'D';
                    case 9
                        graspType = 'R';
                    otherwise
                        graspType = '';
                end

                % Hand Parameters - MIA
                MIA.pos_thumb = datalog(192 + num_new_parameters);
                MIA.pos_mrl = datalog(193 + num_new_parameters);
                MIA.pos_index = double(typecast(uint8(datalog(194 + num_new_parameters:195 + num_new_parameters)), "int16"));
                MIA.cur_thumb = double(typecast(uint8(datalog(196 + num_new_parameters:199 + num_new_parameters)), "int32"));
                MIA.cur_mrl = double(typecast(uint8(datalog(200 + num_new_parameters:203 + num_new_parameters)), "int32"));
                MIA.cur_index = double(typecast(uint8(datalog(204 + num_new_parameters:207 + num_new_parameters)), "int32"));
                MIA.norm_force_thumb = double(typecast(uint8(datalog(208 + num_new_parameters:211 + num_new_parameters)), "int32"));
                MIA.norm_force_mrl = double(typecast(uint8(datalog(212 + num_new_parameters:215 + num_new_parameters)), "int32"));
                MIA.norm_force_index = double(typecast(uint8(datalog(216 + num_new_parameters:219 + num_new_parameters)), "int32"));
                MIA.handStatus = datalog(220 + num_new_parameters);
                MIA.completeCalibration = datalog(221 + num_new_parameters);
                % Hand Parameters - Ottobock
                for iCh = 1:self.DAC_CHANNELS
                    Ottobock.DAC(iCh) = double(typecast(uint8(datalog(222 + 2 * (iCh - 1)  + num_new_parameters: 222 + 2 * (iCh - 1) + 1 + num_new_parameters)), "uint16")) * 5 / 4095;
                end
                stimulation_encoded = uint8(datalog(238 + num_new_parameters));
                stimulation = zeros(self.FB_NUM_CHANNELS, 1);
                stimulation_encoded_bin = dec2bin(stimulation_encoded, 8);
                for i = 1:self.FB_NUM_CHANNELS
                    if stimulation_encoded_bin(i) == '1'
                        stimulation(i) = 1;
                    end
                end
                stimulation = stimulation;
                % Tail
                tail = datalog(239 + num_new_parameters);

                % Save into the struct
                sd_datalog(end+1) = cell2struct({header, ...
                    counter, RTCC_yy, RTCC_MM, RTCC_dd, RTCC_ee, RTCC_hh, RTCC_mm, RTCC_ss, ...
                    battery, temperature, handInUse, ...
                    MAV, STD, WL, ZC, SLP, ...
                    class_raw, class_pp, actLevel_raw, actLevel_pp, actLevel_hand, ...
                    graspType, MIA, Ottobock, ...
                    stimulation, tail ...
                    }, fieldnames(sd_datalog), 2);
            end
        end
        %% Interpret Datalog with 254 Parameters saved
        % Routine to Interpret the Limb-MATE Datalogging related to the
        % First Release after adding a 4th DoF (1 Act level more for each
        % step) + 6 DoF IMU (int16)
        % saved on the sd_datalog property of the class
        % @return none
        %-----------------------------------------------------------------
        function sd_datalog = interpret_datalogging_254(self, uint8_data_m)
            % creates an empty struct with fields
            sd_datalog = struct('header', {}, ...
                'counter', {}, 'RTCC_yy', {}, 'RTCC_MM', {}, 'RTCC_dd', {}, 'RTCC_ee', {}, 'RTCC_hh', {}, 'RTCC_mm', {}, 'RTCC_ss', {}, ...
                'battery', {}, 'temperature', {}, 'handInUse', {}, ...
                'MAV', {}, 'STD', {}, 'WL', {}, 'ZC', {}, 'SLP', {}, ...
                'class_raw', {}, 'class_pp', {}, 'actLevel_raw', {}, 'actLevel_pp', {}, 'actLevel_hand', {}, ...
                'graspType', {}, 'MIA', {}, 'Ottobock', {}, ...
                'stimulation', {}, 'imu', {}, 'tail', {} ...
                ); 

            for iRow = 1:size(uint8_data_m, 1)
                datalog = uint8_data_m(iRow, :);
                % Header
                header = datalog(1);
                % General
                counter = double(typecast(uint8(datalog(2:5)), "uint32"));
                RTCC_yy = datalog(6);
                RTCC_MM = datalog(7);
                RTCC_dd = datalog(8);
                RTCC_ee = datalog(9);
                RTCC_hh = datalog(10);
                RTCC_mm = datalog(11);
                RTCC_ss = datalog(12);
                battery = double(typecast(uint8(datalog(13:14)), "uint16")) * self.BATT_MAX_VOLTAGE / 4095; %Voltage divider is set to output 3.3V (4095) when input is 20V
                temperature = double(typecast(uint8(datalog(15:18)), "single"));
                handInUse = datalog(19);
                % Features
                % MAV
                for iCh = 1:self.EMG_NUM_CHANNELS
                    MAV(iCh) = double(typecast(uint8(datalog(20 + 4 * (iCh - 1) : 20 + 4 * (iCh - 1) + 3)), "single"));
                end
                % STD
                for iCh = 1:1:self.EMG_NUM_CHANNELS
                    STD(iCh) = double(typecast(uint8(datalog(52 + 4 * (iCh - 1) : 52 + 4 * (iCh - 1) + 3)), "single"));
                end
                % WL
                for iCh = 1:1:self.EMG_NUM_CHANNELS
                    WL(iCh) = double(typecast(uint8(datalog(84 + 4 * (iCh - 1) : 84 + 4 * (iCh - 1) + 3)), "single"));
                end
                % ZC
                for iCh = 1:1:self.EMG_NUM_CHANNELS
                    ZC(iCh) = double(typecast(uint8(datalog(116 + 4 * (iCh - 1) : 116 + 4 * (iCh - 1) + 3)), "single"));
                end
                % SLP
                for iCh = 1:1:self.EMG_NUM_CHANNELS
                    SLP(iCh) = double(typecast(uint8(datalog(148 + 4 * (iCh - 1) : 148 + 4 * (iCh - 1) + 3)), "single"));
                end
                % Control
                class_raw = datalog(180);
                class_pp = datalog(181);
                actLevel_raw(1:self.NUM_DOF) = datalog(182:185);
                actLevel_pp(1:self.NUM_DOF) = datalog(186:189);
                actLevel_hand(1:self.NUM_DOF) = datalog(190:193);
                num_new_parameters = 3;
                % Grasp Type
                encoded_graspType = datalog(191 + num_new_parameters);
                switch encoded_graspType
                    case 0
                        graspType = 'r';
                    case 1
                        graspType = 'O';
                    case 2
                        graspType = 'C';
                    case 3
                        graspType = 'P';
                    case 4
                        graspType = 'L';
                    case 5
                        graspType = 'S';
                    case 6
                        graspType = 'T';
                    case 7
                        graspType = 'U';
                    case 8
                        graspType = 'D';
                    case 9
                        graspType = 'R';
                    otherwise
                        graspType = '';
                end

                % Hand Parameters - MIA
                MIA.pos_thumb = datalog(192 + num_new_parameters);
                MIA.pos_mrl = datalog(193 + num_new_parameters);
                MIA.pos_index = double(typecast(uint8(datalog(194 + num_new_parameters:195 + num_new_parameters)), "int16"));
                MIA.cur_thumb = double(typecast(uint8(datalog(196 + num_new_parameters:199 + num_new_parameters)), "int32"));
                MIA.cur_mrl = double(typecast(uint8(datalog(200 + num_new_parameters:203 + num_new_parameters)), "int32"));
                MIA.cur_index = double(typecast(uint8(datalog(204 + num_new_parameters:207 + num_new_parameters)), "int32"));
                MIA.norm_force_thumb = double(typecast(uint8(datalog(208 + num_new_parameters:211 + num_new_parameters)), "int32"));
                MIA.norm_force_mrl = double(typecast(uint8(datalog(212 + num_new_parameters:215 + num_new_parameters)), "int32"));
                MIA.norm_force_index = double(typecast(uint8(datalog(216 + num_new_parameters:219 + num_new_parameters)), "int32"));
                MIA.handStatus = datalog(220 + num_new_parameters);
                MIA.completeCalibration = datalog(221 + num_new_parameters);
                % Hand Parameters - Ottobock
                for iCh = 1:self.DAC_CHANNELS
                    Ottobock.DAC(iCh) = double(typecast(uint8(datalog(222 + 2 * (iCh - 1)  + num_new_parameters: 222 + 2 * (iCh - 1) + 1 + num_new_parameters)), "uint16")) * 5 / 4095;
                end
                stimulation_encoded = uint8(datalog(238 + num_new_parameters));
                stimulation = zeros(self.FB_NUM_CHANNELS, 1);
                stimulation_encoded_bin = dec2bin(stimulation_encoded, 8);
                for i = 1:self.FB_NUM_CHANNELS
                    if stimulation_encoded_bin(i) == '1'
                        stimulation(i) = 1;
                    end
                end
                stimulation = stimulation;
                % IMU      
                imu.acc_x = double(typecast(uint8(datalog(239 + num_new_parameters:240 + num_new_parameters)), "int16"));
                imu.acc_y = double(typecast(uint8(datalog(241 + num_new_parameters:242 + num_new_parameters)), "int16"));
                imu.acc_z = double(typecast(uint8(datalog(243 + num_new_parameters:244 + num_new_parameters)), "int16"));
                imu.gyr_x = double(typecast(uint8(datalog(245 + num_new_parameters:246 + num_new_parameters)), "int16"));
                imu.gyr_y = double(typecast(uint8(datalog(247 + num_new_parameters:248 + num_new_parameters)), "int16"));
                imu.gyr_z = double(typecast(uint8(datalog(249 + num_new_parameters:250 + num_new_parameters)), "int16"));
                num_new_parameters = num_new_parameters + 12;
                % Tail
                tail = datalog(239 + num_new_parameters);

                % Save into the struct
                sd_datalog(end+1) = cell2struct({header, ...
                    counter, RTCC_yy, RTCC_MM, RTCC_dd, RTCC_ee, RTCC_hh, RTCC_mm, RTCC_ss, ...
                    battery, temperature, handInUse, ...
                    MAV, STD, WL, ZC, SLP, ...
                    class_raw, class_pp, actLevel_raw, actLevel_pp, actLevel_hand, ...
                    graspType, MIA, Ottobock, ...
                    stimulation, imu, tail ...
                    }, fieldnames(sd_datalog), 2);
            end
        end

        %% Interpret Datalog with 256 Parameters saved
        % Routine to Interpret the Limb-MATE Datalogging related to the
        % First Release after adding a 4th DoF (1 Act level more for each
        % step) + 6 DoF IMU (int16) + Angle + Temp from float to int16
        % saved on the sd_datalog property of the class
        % @return none
        %-----------------------------------------------------------------
        function sd_datalog = interpret_datalogging_256(self, uint8_data_m)
            % creates an empty struct with fields
            sd_datalog = struct('header', {}, ...
                'counter', {}, 'RTCC_yy', {}, 'RTCC_MM', {}, 'RTCC_dd', {}, 'RTCC_ee', {}, 'RTCC_hh', {}, 'RTCC_mm', {}, 'RTCC_ss', {}, ...
                'battery', {}, 'temperature', {}, 'handInUse', {}, ...
                'MAV', {}, 'STD', {}, 'WL', {}, 'ZC', {}, 'SLP', {}, ...
                'class_raw', {}, 'class_pp', {}, 'actLevel_raw', {}, 'actLevel_pp', {}, 'actLevel_hand', {}, ...
                'graspType', {}, 'MIA', {}, 'Ottobock', {}, ...
                'stimulation', {}, 'imu', {}, 'angle', {}, 'tail', {} ...
                ); 

            for iRow = 1:size(uint8_data_m, 1)
                datalog = uint8_data_m(iRow, :);
                % Header
                header = datalog(1);
                % General
                counter = double(typecast(uint8(datalog(2:5)), "uint32"));
                RTCC_yy = datalog(6);
                RTCC_MM = datalog(7);
                RTCC_dd = datalog(8);
                RTCC_ee = datalog(9);
                RTCC_hh = datalog(10);
                RTCC_mm = datalog(11);
                RTCC_ss = datalog(12);
                battery = double(typecast(uint8(datalog(13:14)), "uint16")) * self.BATT_MAX_VOLTAGE / 4095; %Voltage divider is set to output 3.3V (4095) when input is 20V
                num_new_parameters = -2;
                temperature = double(typecast(uint8(datalog(15 : 18 + num_new_parameters)), "int16")) / 100;
                handInUse = datalog(19 + num_new_parameters);
                % Features
                % MAV
                for iCh = 1:self.EMG_NUM_CHANNELS
                    MAV(iCh) = double(typecast(uint8(datalog(20 + 4 * (iCh - 1) + num_new_parameters : 20 + 4 * (iCh - 1) + 3 + num_new_parameters) ), "single"));
                end
                % STD
                for iCh = 1:1:self.EMG_NUM_CHANNELS
                    STD(iCh) = double(typecast(uint8(datalog(52 + 4 * (iCh - 1) + num_new_parameters : 52 + 4 * (iCh - 1) + 3 + num_new_parameters) ), "single"));
                end
                % WL
                for iCh = 1:1:self.EMG_NUM_CHANNELS
                    WL(iCh) = double(typecast(uint8(datalog(84 + 4 * (iCh - 1) + num_new_parameters : 84 + 4 * (iCh - 1) + 3 + num_new_parameters) ), "single"));
                end
                % ZC
                for iCh = 1:1:self.EMG_NUM_CHANNELS
                    ZC(iCh) = double(typecast(uint8(datalog(116 + 4 * (iCh - 1) + num_new_parameters : 116 + 4 * (iCh - 1) + 3 + num_new_parameters) ), "single"));
                end
                % SLP
                for iCh = 1:1:self.EMG_NUM_CHANNELS
                    SLP(iCh) = double(typecast(uint8(datalog(148 + 4 * (iCh - 1) + num_new_parameters : 148 + 4 * (iCh - 1) + 3 + num_new_parameters) ), "single"));
                end
                % Control
                class_raw = datalog(180 + num_new_parameters );
                class_pp = datalog(181 + num_new_parameters );
                actLevel_raw(1:self.NUM_DOF) = datalog(182 + num_new_parameters : 185 + num_new_parameters );
                actLevel_pp(1:self.NUM_DOF) = datalog(186 + num_new_parameters : 189 + num_new_parameters );
                actLevel_hand(1:self.NUM_DOF) = datalog(190 + num_new_parameters : 193 + num_new_parameters);
                num_new_parameters = num_new_parameters + 3;
                % Grasp Type
                encoded_graspType = datalog(191 + num_new_parameters);
                switch encoded_graspType
                    case 0
                        graspType = 'r';
                    case 1
                        graspType = 'O';
                    case 2
                        graspType = 'C';
                    case 3
                        graspType = 'P';
                    case 4
                        graspType = 'L';
                    case 5
                        graspType = 'S';
                    case 6
                        graspType = 'T';
                    case 7
                        graspType = 'U';
                    case 8
                        graspType = 'D';
                    case 9
                        graspType = 'R';
                    otherwise
                        graspType = '';
                end

                % Hand Parameters - MIA
                MIA.pos_thumb = datalog(192 + num_new_parameters);
                MIA.pos_mrl = datalog(193 + num_new_parameters);
                MIA.pos_index = double(typecast(uint8(datalog(194 + num_new_parameters:195 + num_new_parameters)), "int16"));
                MIA.cur_thumb = double(typecast(uint8(datalog(196 + num_new_parameters:199 + num_new_parameters)), "int32"));
                MIA.cur_mrl = double(typecast(uint8(datalog(200 + num_new_parameters:203 + num_new_parameters)), "int32"));
                MIA.cur_index = double(typecast(uint8(datalog(204 + num_new_parameters:207 + num_new_parameters)), "int32"));
                MIA.norm_force_thumb = double(typecast(uint8(datalog(208 + num_new_parameters:211 + num_new_parameters)), "int32"));
                MIA.norm_force_mrl = double(typecast(uint8(datalog(212 + num_new_parameters:215 + num_new_parameters)), "int32"));
                MIA.norm_force_index = double(typecast(uint8(datalog(216 + num_new_parameters:219 + num_new_parameters)), "int32"));
                MIA.handStatus = datalog(220 + num_new_parameters);
                MIA.completeCalibration = datalog(221 + num_new_parameters);
                % Hand Parameters - Ottobock
                for iCh = 1:self.DAC_CHANNELS
                    Ottobock.DAC(iCh) = double(typecast(uint8(datalog(222 + 2 * (iCh - 1)  + num_new_parameters: 222 + 2 * (iCh - 1) + 1 + num_new_parameters)), "uint16")) * 5 / 4095;
                end
                stimulation_encoded = uint8(datalog(238 + num_new_parameters));
                stimulation = zeros(self.FB_NUM_CHANNELS, 1);
                stimulation_encoded_bin = dec2bin(stimulation_encoded, 8);
                for i = 1:self.FB_NUM_CHANNELS
                    if stimulation_encoded_bin(i) == '1'
                        stimulation(i) = 1;
                    end
                end
                % IMU      
                imu.acc_x = double(typecast(uint8(datalog(239 + num_new_parameters:240 + num_new_parameters)), "int16"));
                imu.acc_y = double(typecast(uint8(datalog(241 + num_new_parameters:242 + num_new_parameters)), "int16"));
                imu.acc_z = double(typecast(uint8(datalog(243 + num_new_parameters:244 + num_new_parameters)), "int16"));
                imu.gyr_x = double(typecast(uint8(datalog(245 + num_new_parameters:246 + num_new_parameters)), "int16"));
                imu.gyr_y = double(typecast(uint8(datalog(247 + num_new_parameters:248 + num_new_parameters)), "int16"));
                imu.gyr_z = double(typecast(uint8(datalog(249 + num_new_parameters:250 + num_new_parameters)), "int16"));
                % Angle
                angle = double(typecast(uint8(datalog(251 + num_new_parameters:254 + num_new_parameters)), "single"));
                num_new_parameters = num_new_parameters + 16;
                % Tail
                tail = datalog(239 + num_new_parameters);

                % Save into the struct
                sd_datalog(end+1) = cell2struct({header, ...
                    counter, RTCC_yy, RTCC_MM, RTCC_dd, RTCC_ee, RTCC_hh, RTCC_mm, RTCC_ss, ...
                    battery, temperature, handInUse, ...
                    MAV, STD, WL, ZC, SLP, ...
                    class_raw, class_pp, actLevel_raw, actLevel_pp, actLevel_hand, ...
                    graspType, MIA, Ottobock, ...
                    stimulation, imu, angle, tail ...
                    }, fieldnames(sd_datalog), 2);
            end
        end

        %% Interpret SD EMGLog
        % Routine to Interpret the Limb-MATE Datalogging, 
        % saved on the sd_datalog property of the class
        % @return none
        %-----------------------------------------------------------------
        function interpret_EMGlogging(self, uint8_EMG_m)
            % creates an empty struct with fields
            sd_EMGlog = struct('header', {}, 'counter', {}, 'EMG_SD', {}, 'tail', {} );
            for iRow = 1:size(uint8_EMG_m, 1)
                EMGlog = uint8_EMG_m(iRow, :);
                % Header
                header = EMGlog(1);
                % Counter
                counter = double(typecast(uint8(EMGlog(2:5)), "uint32"));
                % sd_EMG
                EMG_vector = double(typecast(uint8(EMGlog(6:end-1)), "single"));
                EMG_matrix = reshape(EMG_vector, (self.EMGLOG_SIZE/self.EMG_NUM_CHANNELS)/4, self.EMG_NUM_CHANNELS );
                % Tail
                tail = EMGlog(end);

                % Save into the struct
                sd_EMGlog(end+1) = cell2struct({header, counter, EMG_matrix, tail}, fieldnames(sd_EMGlog), 2);
            end
            self.sd_EMGlog = sd_EMGlog;
        end
        

        %% Read SD DataLog
        % Routine to Read a DATALOG.DAT file, 
        % @return uint8_data_m: Matrix of information that can be used by interpret_datalogging()
        %-----------------------------------------------------------------
        function [uint8_data_m] = read_datalog_file(self, filename)
            fileID = fopen(filename, 'r', 'n', 'ISO-8859-1'); % MAC
            % fileID = fopen(filename, 'r');
            character_v = fscanf(fileID,'%c');
            fclose(fileID);
            separator = char(19);
            line_endig = newline;
            % opts = delimitedTextImportOptions('whitespace',char(500),'delimiter',separator, 'LineEnding',separator,'TrailingDelimitersRule','keep','LeadingDelimitersRule','keep', ...
            %     'ConsecutiveDelimitersRule','split', 'EmptyLineRule','read', 'MissingRule', 'fill', ...
            %     'ImportErrorRule','fill', 'Encoding', 'Windows-1250');
            % % opts = setvaropts(opts,'FillValue',separator);
            % imported_data = readtable(filename, opts, 'ReadVariableNames', false);
            % imported_data_array = table2array(imported_data(2:end, :)); % Remove the first Empty Row
            % % Create a row String with all the data
            % character_v = "";
            % for iRow = 1:length(imported_data_array)
            %     if isempty(imported_data_array{iRow})
            %         character_v  = append(character_v, separator);
            % 
            %     else
            %         character_v  = append(character_v, separator, imported_data_array{iRow});
            %     end
            % 
            % end
            % a0 = char(character_v);
            % a = length(a0)
            % b = uint32(a0((33 - 1) * 237 + 2))
            
            % % Replace 'Windows-1250' encoding to UTF-8
            % list_Windows_1250   = ["€", "‚", "ƒ", "„", "…", ...
            %                         "†", "‡", "ˆ", "‰", "Š", ...
            %                         "‹", "Œ", "Ť", "Ž", "‘", "’", ...
            %                         "“", "”", "•", "–", "—", ...
            %                         "˜", "™", "š", "›", "œ", ...
            %                         "ž", "Ÿ", 
            % %                         "ˇ", "˘", "Ł", "Ą", ...
            % %                         "Ş", "Ż", "˛", "ł", ...
            % %                         "ą", "ş", "Ľ", "˝", ...
            % %                         "ľ", "ż", "Ŕ", "Ă", "Ĺ", "Ć", ...
            % %                         "Č", "Ę", "Ě", "Ď", "Đ", "Ń", ...
            % %                         "Ň", "Ő", "Ř", "Ů", "Ű", ...
            % %                         "Ţ", "ŕ", "ă", "ĺ", ...
            % %                         "ć", "č", "ę", "ě", "ď", ...
            % %                         "đ", "ń", "ň", "ő", "ř", "ů", ...
            % %                         "ű", "ţ", "˙"
            %                         ];
            % list_UTF_8          = [char(128), char(130), char(131), char(132), char(133), ...
            %                         char(134), char(135), char(136), char(137), char(138), ...
            %                         char(139), char(140), char(141), char(142), char(145), char(146), ...
            %                         char(147), char(148), char(149), char(150), char(151), ...
            %                         char(152), char(153), char(154), char(155), char(156), ...
            %                         char(158), char(159), 
            % %                         char(161), char(162), char(163), char(165), ...
            % %                         char(170), char(175), char(178), char(179), ...
            % %                         char(185), char(186), char(188), char(189), ...
            % %                         char(190), char(191), char(192), char(195), char(197), char(198), ...
            % %                         char(200), char(202), char(204), char(207), char(208), char(209), ...
            % %                         char(210), char(213), char(216), char(217), char(219), ...
            % %                         char(222), char(224), char(227), char(229), ...
            % %                         char(230), char(232), char(234), char(236), char(239), ...
            % %                         char(240), char(241), char(242), char(245), char(248), char(249), ...
            % %                         char(251), char(254), char(255)
            %                         ];
            % for iReplace = 1:length(list_Windows_1250)
            %     character_v = replace(character_v, list_Windows_1250(iReplace), list_UTF_8(iReplace));
            % end
            % Find the Desired Pattern 
            pat_row =  string(separator) + wildcardPattern(self.DATALOG_SIZE - 2) + line_endig; 
            digits_extracted_row = extract(character_v, pat_row);
            % Create the Matrix
            uint8_data_m = zeros(length(digits_extracted_row), self.DATALOG_SIZE, 'uint8');
            for iRow = 1:length(digits_extracted_row)
                % a = char(digits_extracted_row(iRow))
                % b = uint32(char(digits_extracted_row(iRow)));
                % b(2)
                % if b(2) > 255
                %     disp('')
                % end
                uint8_data_m(iRow,:) = uint8(char(digits_extracted_row(iRow)));
            end
            
            
        end
        

        %% Read SD Data/EMG-Log
        % Routine to Read a DATALOG.DAT file, 
        % @return uint8_data_m: Matrix of information that can be used by interpret_datalogging()
        %-----------------------------------------------------------------
         function [EMG] = read_EMG_file(self, filename)
            fileID = fopen(filename, 'r', 'n', 'ISO-8859-1'); % MAC
            % fileID = fopen(filename, 'r');
            character_v = fscanf(fileID,'%c');
            fclose(fileID);
            separator = char(20);
            line_endig = char(11);
            
            % % Replace 'Windows-1250' encoding to UTF-8
            % list_Windows_1250   = ["€", "‚", "ƒ", "„", "…", ...
            %                         "†", "‡", "ˆ", "‰", "Š", ...
            %                         "‹", "Œ", "Ť", "Ž", "‘", "’", ...
            %                         "“", "”", "•", "–", "—", ...
            %                         "˜", "™", "š", "›", "œ", ...
            %                         "ž", "Ÿ", 
            %                         ];
            % list_UTF_8          = [char(128), char(130), char(131), char(132), char(133), ...
            %                         char(134), char(135), char(136), char(137), char(138), ...
            %                         char(139), char(140), char(141), char(142), char(145), char(146), ...
            %                         char(147), char(148), char(149), char(150), char(151), ...
            %                         char(152), char(153), char(154), char(155), char(156), ...
            %                         char(158), char(159), 
            %                         ];
            % for iReplace = 1:length(list_Windows_1250)
            %     character_v = replace(character_v, list_Windows_1250(iReplace), list_UTF_8(iReplace));
            % end
            % Find the Desired Pattern for the 
            pat_row =  string(separator) + wildcardPattern(self.EMGLOG_SIZE + 4) + line_endig; 
            digits_extracted_row = extract(character_v, pat_row);
            % Create the Matrix
            uint8_data_m = zeros(length(digits_extracted_row), self.EMGLOG_SIZE + 4 + 2, 'uint8');
            for iRow = 1:length(digits_extracted_row)
                uint8_data_m(iRow,:) = uint8(char(digits_extracted_row(iRow)));
            end
            EMG = uint8_data_m;

         end

        %% Read SD Data/EMG-Log
        % Routine to Read a DATALOG.DAT file, 
        % Works under the Hypothesis of a predefined structure of the
        % datalog
        % @return uint8_data_m: Matrix of information that can be used by interpret_datalogging()
        %-----------------------------------------------------------------
         function [uint8_dataLog_m, uint8_EMGlog_m] = read_dataLog_EMGLog_file(self, filename)
            fileID = fopen(filename, 'r', 'n', 'ISO-8859-1');
            % fileID = fopen(filename, 'r');
            character_v = fscanf(fileID,'%c');
            fclose(fileID);
            separator_EMGLog = char(20);
            line_endig_EMGLog = char(11);
            separator_dataLog = char(19);
            line_endig_dataLog = newline;
            block_size = 512;
            whole_block = 8 * block_size;
            
            % Replace 'Windows-1250' encoding to UTF-8
            % list_Windows_1250   = ["€", "‚", "ƒ", "„", "…", ...
            %                         "†", "‡", "ˆ", "‰", "Š", ...
            %                         "‹", "Œ", "Ť", "Ž", "‘", "’", ...
            %                         "“", "”", "•", "–", "—", ...
            %                         "˜", "™", "š", "›", "œ", ...
            %                         "ž", "Ÿ", 
            %                         ];
            % list_UTF_8          = [char(128), char(130), char(131), char(132), char(133), ...
            %                         char(134), char(135), char(136), char(137), char(138), ...
            %                         char(139), char(140), char(141), char(142), char(145), char(146), ...
            %                         char(147), char(148), char(149), char(150), char(151), ...
            %                         char(152), char(153), char(154), char(155), char(156), ...
            %                         char(158), char(159), 
            %                         ];
            % for iReplace = 1:length(list_Windows_1250)
            %     character_v = replace(character_v, list_Windows_1250(iReplace), list_UTF_8(iReplace));
            % end
            character_m = reshape(character_v, whole_block, []);
            character_m = character_m';
            nRow = size(character_m, 1);
            % Find the Desired Pattern for EMGLog
            EMG_flag = zeros(nRow, 1);
            pat_row_EMGLog =  string(separator_EMGLog) + wildcardPattern(self.EMGLOG_SIZE + 4) + line_endig_EMGLog; 
            pat_row_dataLog =  string(separator_dataLog) + wildcardPattern(self.DATALOG_SIZE - 2) + line_endig_dataLog;             
            for i = 1:nRow
                row =  extract(character_m(i, block_size + 1 : block_size + 1 + self.EMGLOG_SIZE + 4 + 2 - 1), pat_row_EMGLog);
                if ~(isempty(row))
                    EMG_flag(i) = 1;
                end
            end
            num_row_EMGLog = sum(EMG_flag);
            num_row_dataLog = nRow - num_row_EMGLog;

            
            % Create the Matrix fot the EMG
            uint8_EMGlog_m = zeros(num_row_EMGLog, self.EMGLOG_SIZE + 4 + 2, 'uint8');
            uint8_dataLog_m = zeros(num_row_EMGLog + 8 * num_row_dataLog, self.DATALOG_SIZE, 'uint8');

            % Extract the information
            row_EMG = 1;
            row_dataLog = 1;
            for i = 1:nRow
                if EMG_flag(i) == 1
                    EMG_extracted = extract(character_m(i, block_size + 1 : block_size + 1 + self.EMGLOG_SIZE + 4 + 2 - 1), pat_row_EMGLog);
                    uint8_EMGlog_m(row_EMG, :) = uint8(char(EMG_extracted));
                    row_EMG = row_EMG + 1;
                    dataLog_extracted = extract(character_m(i, 1 : block_size), pat_row_dataLog);
                    uint8_dataLog_m(row_dataLog:row_dataLog + length(dataLog_extracted) - 1, :) = uint8(char(dataLog_extracted));
                    row_dataLog = row_dataLog + length(dataLog_extracted);
                else
                    dataLog_extracted = extract(character_m(i, 1 : end), pat_row_dataLog);
                    uint8_dataLog_m(row_dataLog:row_dataLog + length(dataLog_extracted) - 1, :) = uint8(char(dataLog_extracted));
                    row_dataLog = row_dataLog + length(dataLog_extracted);
                end
            end

            % Remove the empty Rows at the end
            uint8_dataLog_m(uint8_dataLog_m(:, 1) == 0, :) = [];

         end

        %% Reset SD Datalog
        % Routine to reset the SD card datalog
        % @return none
        %-----------------------------------------------------------------
        function resetSDDatalog(self)
            % send command!
            result = self.sendCommand(self.RESET_SD_DATALOG, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            self.receiveReply(self.RESET_SD_DATALOG);
            disp('Reset SD Datalog!')
            % Wait the 7.5 msec if is not the last package
            pause(7.5/1000);
            fprintf('\n');
        end

        %% Reset SD EMGlog
        % Routine to reset the SD card EMGlog
        % @return none
        %-----------------------------------------------------------------
        function resetSDEMGlog(self)
            % send command!
            result = self.sendCommand(self.RESET_SD_EMGLOG, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            self.receiveReply(self.RESET_SD_EMGLOG);
            disp('Reset SD Datalog!')
            % Wait the 7.5 msec if is not the last package
            pause(7.5/1000);
            fprintf('\n');
        end

        %% SET SD EMG flag Data
        % Routine to set the EMG dataflag, for EMG logging
        % @param[in] SD_EMG_FLAG.
        % @return none
        %-----------------------------------------------------------------
        function set_SD_EMG_Flag(self, SD_EMG_flag)
            % send command!
            result = self.sendCommand(self.SET_SD_EMG_FLAG, SD_EMG_flag, 1);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.SET_SD_EMG_FLAG);
            error_SD_EMG_FLAG_ = hex2dec(dataHex(1,:));
            % Check the Values of MIA connection            
            if (error_SD_EMG_FLAG_ == 1)  
                disp('SD EMG NOT sucessfully set \n!')
            else
                disp('SD EMG sucessfully set \n!')
            end
            fprintf('\n');
        end

        %% GET SD EMG flag Data
        % Routine to get the EMG dataflag, for EMG logging
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function get_SD_EMG_Flag(self)
            % send command!
            result = self.sendCommand(self.GET_SD_EMG_FLAG, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_SD_EMG_FLAG);
            dataDec = hex2dec(dataHex);
            self.sd_emg_flag = dataDec(1);
        end

        %% Format SD card
        % Routine to format the SD card 
        % @return none
        %-----------------------------------------------------------------
        function formatSDcard(self)
            % send command!
            result = self.sendCommand(self.FORMAT_SD_CARD, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            pause(75);
            self.receiveReply(self.FORMAT_SD_CARD);
            disp('Fromat SD card!')
            fprintf('\n');
            % Wait the 7.5 msec if is not the last package
            pause(7.5/1000);
            self.getSDData();
        end

        %% SET DAC Data
        % Routine to send command to set the values on the DAC. (8 channels).
        % @param[in] DAC structure with the respective values to set on the DAC.
        % @return none
        %-----------------------------------------------------------------
        function setDACdata(self, DAC)
            DAC_double_vector = [DAC.ch1, DAC.ch2, DAC.ch3, DAC.ch4, DAC.ch5, DAC.ch6, DAC.ch7, DAC.ch8];
            DAC_uint16_vector = zeros(2*length(DAC_double_vector), 1, 'uint8');
            for i = 1:length(DAC_double_vector)
                uint16_value = uint16(floor(abs(DAC_double_vector(i)) * 4095 / 5));
                uint8_values = typecast(uint16_value, 'uint8'); % uint8_values(1) = low significant, uint8_values(2) = high significant
                DAC_uint16_vector(2*i-1:2*i) = [bitand(uint8_values(2),0x0F,'uint8'), uint8_values(1)];
            end
            % send command!
            result = self.sendCommand(self.SET_DAC_CHANNELS, DAC_uint16_vector, length(DAC_uint16_vector));
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.SET_DAC_CHANNELS);
            error_set_DAC = hex2dec(dataHex(1,:));
            disp(' ')
            % Check the Values of Date
            if (error_set_DAC == self.NO_ERR_RTCC)  
                disp('Date set successfully')
                self.dac = DAC;
            else
                disp('Date NOT set successfully !')
            end
            self.check_DAC_set(error_set_DAC)

            disp('DAC Set Successfully')
            disp('DAC Data: ');
            chLabels = {'Ch1: ', 'Ch2: ', 'Ch3: ', 'Ch4: ','Ch5: ','Ch6: ','Ch7: ','Ch8: '};
            for i = 1:self.DAC_CHANNELS
                fprintf('%s%.2f / ',chLabels{i}, DAC_double_vector(i));
            end
            fprintf('\n');
        end

        %% GET DAC Data
        % Routine to send command to get the values on the DAC. (8 channels),
        % saved on the dac property of the class
        % @return DAC structure with the respective values set on the DAC.
        %-----------------------------------------------------------------
        function getDACdata(self)
            % send command
            result = self.sendCommand(self.GET_DAC_CHANNELS, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_DAC_CHANNELS);
            dataDec = hex2dec(dataHex);
            ch_values = zeros(self.DAC_CHANNELS,1);
            for n_ch = 1:self.DAC_CHANNELS
                uint_8_data = uint8(dataDec(2*(n_ch-1)+1:2*(n_ch-1)+2));
                uint_16_data = typecast([uint_8_data(2), uint_8_data(1)],'uint16');
                ch_values(n_ch) = round(double(uint_16_data)*5/4095, 2);
            end
            newDAC.ch1 = ch_values(1); newDAC.ch2 = ch_values(2); newDAC.ch3 = ch_values(3); newDAC.ch4 = ch_values(4);
            newDAC.ch5 = ch_values(5); newDAC.ch6 = ch_values(6); newDAC.ch7 = ch_values(7); newDAC.ch8 = ch_values(8);

            disp('Get DAC Successfully')
            disp('DAC Data: ');
            chLabels = {'Ch1: ', 'Ch2: ', 'Ch3: ', 'Ch4: ','Ch5: ','Ch6: ','Ch7: ','Ch8: '};
            for i = 1:self.DAC_CHANNELS
                fprintf('%s%.2f / ',chLabels{i}, ch_values(i));
            end
            fprintf('\n');
            self.dac = newDAC;
        
        end

        %% Send Hand command
        % Routine to send commands to a Generic Hand
        % @return none.
        %-----------------------------------------------------------------
        function send_hand_command(self, outIndex, ActivationLevels, repetitionNumber, enable_postProcess)
            payload = uint8([outIndex; ActivationLevels; repetitionNumber; enable_postProcess]);
            % send command!
            result = self.sendCommand(self.SEND_HAND_COMMAND, payload, length(payload));
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            % Wait the 500 msec for each 10 rep
            pause(500 / 1000 * floor(repetitionNumber/10))
            dataHex = self.receiveReply(self.SEND_HAND_COMMAND); 
            error_send_hand_command = hex2dec(dataHex(1,:));
            % Check the Values of configuration
            if (error_send_hand_command == 0)  
                % disp('Hand Command sent successfully \n!')
            else
                disp('Hand Command NOT sent successfully \n!')
            end
        end

        %% Enable Hand connection
        % Routine to enable the connection with MIA hand, in this case,
        % saves MIA_hand in the handInUse property of the class
        % @param[in] enable_MIA:    1 for enabling the connession with MIA,
        % @return none.
        %-----------------------------------------------------------------
        function enable_hand_connection(self, hand_number)
            % send command!
            result = self.sendCommand(self.ENABLE_HAND_CONNECTION, uint8(hand_number), 1);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.ENABLE_HAND_CONNECTION);
            error_enable_hand = hex2dec(dataHex(1,:));
            % Check the Values of MIA connection            
            if (error_enable_hand == 1)  
                self.handInUse = self.GENERIC_HAND_NAME;
                disp('Hand NOT connected \n!')
            else
                switch hand_number
                    case self.OTTOBOCK_SENSORHAND
                        self.handInUse = self.OTTOBOCK_SENSORHAND_NAME;
                        disp('Ottobock connected \n!')
                    case self.PRENSILIA_MIAHAND
                        self.handInUse = self.MIA_HAND_NAME;
                        disp('MIA connected \n!')
                    case self.OTTOBOCK
                        self.handInUse = self.OTTOBOCK_NAME;
                        disp('Ottobock connected \n!')
                    case self.MICHELANGELO_HAND
                        self.handInUse = self.MICHELANGELO_HAND_NAME;
                        disp('Michelangelo connected \n!')
                    otherwise
                        self.handInUse = self.GENERIC_HAND_NAME;
                end
            end                
            fprintf('\n');
        end

        %% MIA EMG params
        % Routine to get MIA EMG params
        % saves MIA_EMG in the handInUse property of the class
        % @return none.
        %-----------------------------------------------------------------
        function get_MIA_EMG(self)
            % send command!
            result = self.sendCommand(self.GET_EMG_PARAMS, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_EMG_PARAMS);
            detaDec = hex2dec(dataHex);
            MIA_EMG.enable = detaDec(1);
            MIA_EMG.enable_hand_relaxing = detaDec(2);
            MIA_EMG.change_grasp_mode = detaDec(3);
            MIA_EMG.threshold_open = double(typecast(uint8(detaDec(4:5)), "uint16"));
            MIA_EMG.threshold_close = double(typecast(uint8(detaDec(6:7)), "uint16"));
            MIA_EMG.time_change_grasp = double(typecast(uint8(detaDec(8:9)), "uint16"));
            MIA_EMG.max_perc_speed = double(typecast(uint8(detaDec(10:11)), "uint16"));
            MIA_EMG.grasp_cycle = detaDec(12:16);
            % Save into the stuct
            self.MIA_EMG = MIA_EMG;
        end

        %% Send MIA command
        % Routine to send MIA commands and saves the Reply in the
        % mia_reply_uint8_ASCII property of the class
        % @param[in] command:   ASCII Command to MIA (Without Header and Tail)
        % @return none.
        %-----------------------------------------------------------------
        function send_MIA_command(self, command)
            % send command!
            result = self.sendCommand(self.SEND_MIA_COMMAND, command, length(command));
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.SEND_MIA_COMMAND);
            dataDec = hex2dec(dataHex);
            self.mia_reply_uint8_ASCII = dataDec;     
        end

        %% Set ControlMode
        % Routine to set the controlModes, and EnableFloorNoise
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function set_controlMode_enableFloorNoise_confidence(self)
            % send command!
            [uint8(self.controlMode), uint8(self.enableFloorNoise), uint8(self.confidence_perc)]
            result = self.sendCommand(self.SET_CONTROL_MODE, [uint8(self.controlMode), uint8(self.enableFloorNoise), uint8(self.confidence_perc)], 3);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.SET_CONTROL_MODE);
            error_set_ControlMode = hex2dec(dataHex(1,:));
            disp(' ')
            % Check the Values of Date
            if (error_set_ControlMode == self.NO_ERR_RTCC)  
                disp('ControlMode set successfully')
            else
                disp('ControlMode NOT set successfully !')
            end
        end

        %% Get ControlMode
        % Routine to set the controlModes,
        % these parameters have to be previously stores in the DC_params property of the class
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function get_controlMode_enableFloorNoise_confidence(self)
            % send command
            result = self.sendCommand(self.GET_CONTROL_MODE, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_CONTROL_MODE);
            dataDec = hex2dec(dataHex);
            self.controlMode = dataDec(1);
            self.enableFloorNoise = dataDec(2);
            self.confidence_perc = dataDec(3);
        end

        %% Set DirectControl Parameters
        % Routine to set the DC parameters, 
        % these parameters have to be previously stores in the DC_params property of the class
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function set_DC_params(self)
            % Reset Local Struct
            self.DC_hands_params.openHand = [];
            self.DC_hands_params.closeHand = [];
            
            % Num Movements
            nMovements = self.EMG_NUM_CHANNELS;
            % Direct Control Params
            payload_DC = zeros(10*nMovements, 1, "uint8");
            for iMov = 1:nMovements
                ADS_chAcquireIndex = uint8(self.DC_params.params{iMov}.ADS_chIndex - 1); % From Matlab ADS Channels to MCU Positions
                movIndex = uint8(self.DC_params.params{iMov}.movIndex);
                noise = self.DC_params.params{iMov}.Noise;
                noise_uint8 = typecast(noise, "uint8");
                MVC = self.DC_params.params{iMov}.MVC;
                MVC_uint8 = typecast(MVC, "uint8");

                payload_DC(10*(iMov-1)+1:10*iMov) = [ADS_chAcquireIndex; movIndex; noise_uint8'; MVC_uint8'];
            end
            total_payload = [nMovements; payload_DC];
            result = self.sendCommand(self.SET_DC_PARAMS, total_payload, length(total_payload) );
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.SET_DC_PARAMS);
            error_set_DC_params = hex2dec(dataHex(1,:));
            % Check the Values of configuration
            if (error_set_DC_params == 0)  
                disp('DC parameters set successfully \n!')
                self.controlMode = self.DIRECT_CONTROL;
                % Save on MATLAB structs
                for iMov = 1:nMovements
                    ADS_chAcquireIndex = self.DC_params.params{iMov}.ADS_chIndex;
                    movIndex = self.DC_params.params{iMov}.movIndex;
                    noise = self.DC_params.params{iMov}.Noise;
                    MVC = self.DC_params.params{iMov}.MVC;
                    if movIndex == 1
                        self.DC_hands_params.openHand.ADS_chAcquireIndex = ADS_chAcquireIndex;
                        self.DC_hands_params.openHand.movIndex = movIndex;
                        self.DC_hands_params.openHand.noise = noise;
                        self.DC_hands_params.openHand.MVC = MVC;
                    elseif movIndex == 2
                        self.DC_hands_params.closeHand.ADS_chAcquireIndex = ADS_chAcquireIndex;
                        self.DC_hands_params.closeHand.movIndex = movIndex;
                        self.DC_hands_params.closeHand.noise = noise;
                        self.DC_hands_params.closeHand.MVC = MVC;
                    end
                end
            else
                disp('DC parameters set NOT successfully \n!')
            end
            % Clean the Struct
            self.DC_params = [];
        end

        %% Get DirectControl Parameters - LimbMATE_GUI >> DirectControl tab
        % Routine to get the DC parameters, 
        % such values are stored in the DC_params property of the class
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function get_DC_params(self)
            self.DC_params = [];
            % send command
            result = self.sendCommand(self.GET_DC_PARAMS, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_DC_PARAMS);
            dataDec = hex2dec(dataHex);

            self.controlMode = dataDec(1);
            Plot_counter = 1;
            % DC Params
            for iMov = 1:self.EMG_NUM_CHANNELS
                % Each Movement
                active_movement = dataDec(11*(iMov-1) + 2);
                ADS_channel_movement = dataDec(11*(iMov-1) + 3) + 1;
                mov_index_movement = dataDec(11*(iMov-1) + 4);
                noise_movement = typecast(uint8(dataDec(5+4-1 + 11*(iMov-1):-1:11*(iMov-1) + 5)), 'single');
                MVC_movement = typecast(uint8(dataDec(9+4-1 + 11*(iMov-1):-1:11*(iMov-1) + 9)), 'single');
                if active_movement
                    self.DC_params.params{Plot_counter}.ADS_chIndex = ADS_channel_movement;
                    self.DC_params.params{Plot_counter}.movIndex = mov_index_movement;
                    self.DC_params.params{Plot_counter}.Noise = noise_movement;
                    self.DC_params.params{Plot_counter}.MVC = MVC_movement;
                    Plot_counter = Plot_counter + 1;
                end
            end
            % If less, set them to 0
            while Plot_counter <= self.EMG_NUM_CHANNELS
                self.DC_params.params{Plot_counter}.ADS_chIndex = Plot_counter;
                self.DC_params.params{Plot_counter}.movIndex = 0;
                self.DC_params.params{Plot_counter}.Noise = 0.0;
                self.DC_params.params{Plot_counter}.MVC = 0.001;
                Plot_counter = Plot_counter + 1;
            end
        end

 

        %% Set LDA Params - GUI_PatRec --> Comm/ALCD/UpdateCOefficientsALCD.m
        % Routine to set the LDA parameters, 
        % these parameters have to be previously stores in the LDA_params property of the class.
        % More Packages of information are required because the required
        % amount of data is bigger than the Maximum dimension of a BT Package
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function set_LDA_params(self)
            nClasses = self.LDA_params.nClasses;
            nFeatures = self.LDA_params.nFeatures;
            nChannels = self.LDA_params.nChannels;
            FeaturesEnables = [self.LDA_params.FeaturesEnables];
            ChannelsEnables = [self.LDA_params.ChannelsEnables];
            floorNoise = self.LDA_params.floorNoise;
            % Transient
            thresh_Tr = self.LDA_params.thresh_Tr;
            ntFeatures = self.LDA_params.ntFeatures;
            % Other Features
            nFeatures_uni = self.LDA_params.nFeatures_uni;
            FeaturesEnables_uni = self.LDA_params.FeaturesEnables_uni;
            % Linear Dimention
            DimLinear = self.LDA_params.DimLinear;
            % Prosthetic Output - Classes
            prostheticOutputs = self.LDA_params.outputs;
            propTable = self.LDA_params.propTable;
            nClasses_transmitted = length(prostheticOutputs);

            if (nFeatures > self.FEAT_NUM || nChannels > self.EMG_NUM_CHANNELS || nFeatures_uni > self.NUM_MAX_FEAT_UNI)
                error(fprintf("Max Num Feat: %d, Max Num Channels: %d, Max Num Feat Uni: %d. Tou asked for %d Feat, %d Chann, %d Feat Uni ", self.FEAT_NUM, self.EMG_NUM_CHANNELS, self.NUM_MAX_FEAT_UNI, nFeatures, nChannels, nFeatures_uni))
            end

            if ntFeatures == 0 % No Transient
                self.controlMode = self.LDA_CONTROL;
            else
                self.controlMode = self.tLDA_CONTROL; % Transient
            end

            % Assemble the Data for LimbMATE
            general_information = [];
            general_information = self.write_BT(general_information, uint8(nClasses) );
            general_information = self.write_BT(general_information, uint8(nFeatures) );
            general_information = self.write_BT(general_information, uint8(nChannels) );
            general_information = self.write_BT(general_information, uint8(FeaturesEnables) );
            general_information = self.write_BT(general_information, uint8(ChannelsEnables) );
            general_information = self.write_BT(general_information, [typecast(single(floorNoise), "uint8")]' );
            general_information = self.write_BT(general_information, uint8(ntFeatures) );
            general_information = self.write_BT(general_information, [typecast(single(thresh_Tr), "uint8")]' );

            % Bias 
            bias = self.LDA_params.bias;
            general_information = self.write_BT(general_information, typecast(single(bias), "uint8") );
            % Other Features
            general_information = self.write_BT(general_information, uint8(nFeatures_uni) );
            general_information = self.write_BT(general_information, uint8(FeaturesEnables_uni) );
            general_information = self.write_BT(general_information, uint8(DimLinear) );

            % Prosthetic Output - Classes
            general_information = self.write_BT(general_information, uint8(prostheticOutputs) );
            propTable_uint8 = [self.matrix_to_u8(single(propTable'))];
          
            % Weigths
            fc_w = self.LDA_params.weights;
            weights = self.matrix_to_u8(single(fc_w));

            % Send the Initial Payload
            num_package_LDA = 1;
            result = self.sendCommand(self.SET_LDA_PARAMS, [num_package_LDA; general_information], length(general_information)+1);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.SET_LDA_PARAMS);
            % Wait the 7.5 msec
            pause(7.5/1000);

            % Send the Prop Table
            for iMov = 1:nClasses_transmitted
                num_package_LDA = num_package_LDA + 1;
                result = self.sendCommand(self.SET_LDA_PARAMS, [num_package_LDA; propTable_uint8(:,iMov)], size(propTable_uint8, 1)+1);
                if (result ~= 0)
                    % error message and exit
                    error('LM: error connecting to device.')
                end
                dataHex = self.receiveReply(self.SET_LDA_PARAMS);
                % Wait the 7.5 msec if is not the last package
                pause(7.5/1000);
            end

            % Send the Weights for each class
            for iWeight = 1:size(weights, 2)
                num_package_LDA = num_package_LDA + 1;
                result = self.sendCommand(self.SET_LDA_PARAMS, [num_package_LDA; weights(:,iWeight)], size(weights, 1)+1);
                if (result ~= 0)
                    % error message and exit
                    error('LM: error connecting to device.')
                end
                dataHex = self.receiveReply(self.SET_LDA_PARAMS);
                % Wait the 7.5 msec if is not the last package
                pause(7.5/1000);
            end

            % %%%%%%%%%%% Calibration Routine Params %%%%%%%%%
            % Number of Samples 
            nSamples = self.LDA_params.nSamples;
            % Mean
            mean_m = self.LDA_params.mean;
            % Pooled Covariance
            pooledCovariance_m = self.LDA_params.pooledCovariance;

            % Transform in uint8 Values
            general_information = [];
            % Number of Samples 
            general_information = self.write_BT(general_information, typecast(uint32(nSamples), "uint8") );
            % Mean
            mean_v_uint8 = self.matrix_to_u8(single(mean_m));
            % Pooled Covariance
            pooledCovariance_v_uint8 = self.matrix_to_u8(single(pooledCovariance_m));

            % Send the Number of Samples
            num_package_LDA = num_package_LDA + 1;
            result = self.sendCommand(self.SET_LDA_PARAMS, [num_package_LDA; general_information], length(general_information)+1);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.SET_LDA_PARAMS);
            % Wait the 7.5 msec
            pause(7.5/1000);

            % Send the Mean (UP to CR_NUM_MOVEMENTS would be stored)
            for iMov = 1:nClasses
                num_package_LDA = num_package_LDA + 1;
                result = self.sendCommand(self.SET_LDA_PARAMS, [num_package_LDA; mean_v_uint8(:,iMov)], size(mean_v_uint8, 1)+1);
                if (result ~= 0)
                    % error message and exit
                    error('LM: error connecting to device.')
                end
                dataHex = self.receiveReply(self.SET_LDA_PARAMS);
                % Wait the 7.5 msec if is not the last package
                pause(7.5/1000);
            end

            % Send the Covariance Metrix
            for iChannel = 1:nChannels
                num_package_LDA = num_package_LDA + 1;
                result = self.sendCommand(self.SET_LDA_PARAMS, [num_package_LDA; pooledCovariance_v_uint8(:,iChannel)], size(pooledCovariance_v_uint8, 1)+1);
                if (result ~= 0)
                    % error message and exit
                    error('LM: error connecting to device.')
                end
                dataHex = self.receiveReply(self.SET_LDA_PARAMS);
                % Wait the 7.5 msec if is not the last package
                pause(7.5/1000);
            end
            
            % Check Errors
            error_set_LDA_params = hex2dec(dataHex(1,:));
            % Check the Values of LDA params
            if (error_set_LDA_params == 0)  
                disp('LDA parameters set successfully \n!')
            else
                disp('LDA parameters set NOT successfully \n!')
            end
        end

        %% Get LDA Params
        % Routine to Get the LDA parameters, 
        % these parameters are stored in the LDA_params property of the class.
        % More Packages of information are required because the required
        % amount of data is bigger than the Maximum dimension of a BT Package
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function get_LDA_params(self)
            self.LDA_params = [];
            % send command to get the First Package
            result = self.sendCommand(self.GET_LDA_PARAMS, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_LDA_PARAMS);
            dataDec = hex2dec(dataHex);
            dataDec = uint8(dataDec);

            % General Information
            self.reset_read_BT_counter();
            self.controlMode = self.read_BT(dataDec, 1, 'uint8');
            package_counter = self.read_BT(dataDec, 1, 'uint8'); % Useful in case of missed packages
            nClasses = self.read_BT(dataDec, 1, 'uint8');
            nFeatures = self.read_BT(dataDec, 1, 'uint8');
            nChannels = self.read_BT(dataDec, 1, 'uint8');

            FeaturesEnables = self.read_BT(dataDec, self.FEAT_NUM, 'uint8');
            ChannelsEnables = self.read_BT(dataDec, self.EMG_NUM_CHANNELS, 'uint8');
            floorNoise = self.read_BT(dataDec, 1, 'single');
            ntFeatures = self.read_BT(dataDec, 1, 'uint8');
            thresh_Tr = self.read_BT(dataDec, 1, 'single');

            bias = self.read_BT(dataDec, nClasses, 'single');

            nFeatures_uni = self.read_BT(dataDec, 1, 'uint8');
            FeaturesEnables_uni = self.read_BT(dataDec, self.NUM_MAX_FEAT_UNI, 'uint8');
            DimLinear = self.read_BT(dataDec, 1, 'uint8'); 

            % Prosthetic Outputs
            if ntFeatures == 0 % No Transient
                nClasses_transmitted = nClasses;
            else
                nClasses_transmitted = nClasses + 1; % Rest Class
            end
            outputs = self.read_BT(dataDec, nClasses_transmitted, 'uint8');

            % Save on the LM class
            self.LDA_params.nClasses = nClasses;
            self.LDA_params.nFeatures = nFeatures;
            self.LDA_params.nChannels = nChannels;
            self.LDA_params.FeaturesEnables = FeaturesEnables;
            self.LDA_params.ChannelsEnables = ChannelsEnables;
            self.LDA_params.floorNoise = floorNoise;
            self.LDA_params.thresh_Tr = thresh_Tr;
            self.LDA_params.ntFeatures = ntFeatures;
            self.LDA_params.bias = bias;
            self.LDA_params.nFeatures_uni = nFeatures_uni;
            self.LDA_params.FeaturesEnables_uni = FeaturesEnables_uni;
            self.LDA_params.DimLinear = DimLinear;
            % Prosthetic Output - Classes
            self.LDA_params.outputs = outputs;
            self.LDA_params.propTable = [];

            % Wait the 7.5 msec
            pause(7.5/1000);

            packages_counters = zeros(nClasses + nClasses_transmitted + 1 + (nClasses + 1 + nChannels), 1);
            counter_package = 1;
            packages_counters(counter_package) = package_counter;

            % send command to get the LDA Weights
            for iPackage = 1:nClasses_transmitted
                result = self.sendCommand(self.GET_LDA_PARAMS, 0, 0);
                if (result ~= 0)
                    % error message and exit
                    error('LM: error connecting to device.')
                end
                dataHex = self.receiveReply(self.GET_LDA_PARAMS);
                dataDec = hex2dec(dataHex);
                dataDec = uint8(dataDec);
                counter_package = counter_package + 1;

                self.reset_read_BT_counter();
                self.controlMode = self.read_BT(dataDec, 1, 'uint8');
                packages_counters(counter_package) = self.read_BT(dataDec, 1, 'uint8');
                self.LDA_params.propTable(:, iPackage) = self.read_BT(dataDec, nChannels, 'single');

                % Wait the 7.5 msec if is not the last package
                pause(7.5/1000);
            end

            % Get the Weights
            for iPackage = 1:nClasses
                result = self.sendCommand(self.GET_LDA_PARAMS, 0, 0);
                if (result ~= 0)
                    % error message and exit
                    error('LM: error connecting to device.')
                end
                dataHex = self.receiveReply(self.GET_LDA_PARAMS);
                dataDec = hex2dec(dataHex);
                dataDec = uint8(dataDec);
                counter_package = counter_package + 1;

                self.reset_read_BT_counter();
                self.controlMode = self.read_BT(dataDec, 1, 'uint8');
                packages_counters(counter_package) = self.read_BT(dataDec, 1, 'uint8');
    
                self.LDA_params.weights(iPackage, :) = self.read_BT(dataDec, DimLinear, 'single');
            end

            % %%%%%%%%%%% Calibration Routine Params %%%%%%%%%
            nClasses_transmitted_CR = min(nClasses, self.CR_NUM_MOVEMENTS);
            % Send command to get the Number of Samples
            result = self.sendCommand(self.GET_LDA_PARAMS, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_LDA_PARAMS);
            dataDec = hex2dec(dataHex);
            dataDec = uint8(dataDec);
            counter_package = counter_package + 1;

            self.reset_read_BT_counter();
            self.controlMode = self.read_BT(dataDec, 1, 'uint8');
            packages_counters(counter_package) = self.read_BT(dataDec, 1, 'uint8');
            % Number of Samples 
            nSamples = self.read_BT(dataDec, nClasses_transmitted_CR, 'uint32');
            self.LDA_params.nSamples = nSamples;

            % Get the Mean (UP to CR_NUM_MOVEMENTS)
            for iPackage = 1:nClasses
                result = self.sendCommand(self.GET_LDA_PARAMS, 0, 0);
                if (result ~= 0)
                    % error message and exit
                    error('LM: error connecting to device.')
                end
                dataHex = self.receiveReply(self.GET_LDA_PARAMS);
                dataDec = hex2dec(dataHex);
                dataDec = uint8(dataDec);
                counter_package = counter_package + 1;

                self.reset_read_BT_counter();
                self.controlMode = self.read_BT(dataDec, 1, 'uint8');
               % Get the Counter
                package_counter = self.read_BT(dataDec, 1, 'uint8'); % Useful in case of missed packages
                packages_counters(counter_package) = package_counter;

                % Mean
                if iPackage <= nClasses_transmitted_CR
                    self.LDA_params.mean(iPackage, :) = self.read_BT(dataDec, nChannels, 'single');
                end

                % Wait the 7.5 msec if is not the last package
                pause(7.5/1000);
            end

            % Get the Pooled Covariance
            for iPackage = 1:nChannels
                result = self.sendCommand(self.GET_LDA_PARAMS, 0, 0);
                if (result ~= 0)
                    % error message and exit
                    error('LM: error connecting to device.')
                end
                dataHex = self.receiveReply(self.GET_LDA_PARAMS);
                dataDec = hex2dec(dataHex);
                dataDec = uint8(dataDec);
                counter_package = counter_package + 1;

                self.reset_read_BT_counter();
                self.controlMode = self.read_BT(dataDec, 1, 'uint8');
                % Get the Counter
                package_counter = self.read_BT(dataDec, 1, 'uint8'); % Useful in case of missed packages
                packages_counters(counter_package) = package_counter;

                % Pooled Covariance
                self.LDA_params.pooledCovariance(iPackage, :) = self.read_BT(dataDec, nChannels, 'single');

                if iPackage ~= nChannels
                    % Wait the 7.5 msec if is not the last package
                    pause(7.5/1000);
                end
            end

            % Save the Counters
            self.LDA_params.counters = packages_counters;
        end

        %% Set tSVM Params
        % Routine to set the SVM parameters, 
        % these parameters have to be previously stored in the SVM_params property of the class.
        % More Packages of information are required because the required
        % amount of data is bigger than the Maximum dimension of a BT Package
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function set_SVM_params(self)
            self.controlMode = self.tSVM_CONTROL;
            nClasses = self.SVM_params.nClasses;
            nFeatures = self.SVM_params.nFeatures;
            nChannels = self.SVM_params.nChannels;
            FeaturesEnables = [self.SVM_params.FeaturesEnables];
            ChannelsEnables = [self.SVM_params.ChannelsEnables];
            floorNoise = self.SVM_params.floorNoise;

            % Transient
            ntFeatures = self.SVM_params.ntFeatures;
            thresh_Tr = self.SVM_params.thresh_Tr;
            % Other Features
            nFeatures_uni = self.SVM_params.nFeatures_uni;
            FeaturesEnables_uni = self.SVM_params.FeaturesEnables_uni;
            % Linear Dimention
            DimLinear = self.SVM_params.DimLinear;

            % Prosthetic Output - Classes
            prostheticOutputs = self.SVM_params.outputs;
            propTable = self.SVM_params.propTable;
            nClasses_transmitted = length(prostheticOutputs);

            if (ntFeatures * nFeatures > 6 || nChannels > self.EMG_NUM_CHANNELS || nFeatures_uni > self.NUM_MAX_FEAT_UNI)
                error(fprintf("Max Num Feat: %d, Max Num Channels: %d, Max Num Feat Uni: %d. Tou asked for %d Feat, %d Chann, %d Feat Uni ", 6, self.EMG_NUM_CHANNELS, self.NUM_MAX_FEAT_UNI, ntFeatures * nFeatures, nChannels, nFeatures_uni))
            end

            % Assemble the Data for LimbMATE
            general_information = [];
            general_information = self.write_BT(general_information, uint8(nClasses) );
            general_information = self.write_BT(general_information, uint8(nFeatures) );
            general_information = self.write_BT(general_information, uint8(nChannels) );
            general_information = self.write_BT(general_information, uint8(FeaturesEnables) );
            general_information = self.write_BT(general_information, uint8(ChannelsEnables) );
            general_information = self.write_BT(general_information, [typecast(single(floorNoise), "uint8")]' );
            general_information = self.write_BT(general_information, uint8(ntFeatures) );
            general_information = self.write_BT(general_information, [typecast(single(thresh_Tr), "uint8")]' );
            % Bias 
            fc_b = self.SVM_params.bias;
            general_information = self.write_BT(general_information, typecast(single(fc_b), "uint8") );
            % Other Features
            general_information = self.write_BT(general_information, uint8(nFeatures_uni) );
            general_information = self.write_BT(general_information, uint8(FeaturesEnables_uni) );
            general_information = self.write_BT(general_information, uint8(DimLinear) );

            % Prosthetic Output - Classes
            general_information = self.write_BT(general_information, uint8(prostheticOutputs) );
            propTable_uint8 = [self.matrix_to_u8(single(propTable'))];

            % Weigths
            w_v = self.SVM_params.weights;
            weights = self.matrix_to_u8(single(w_v));
            
            % Scale + Shift
            scale = [];
            scale = self.write_BT(scale, [typecast(single(self.SVM_params.scale), "uint8")] );

            shift = [];
            shift = self.write_BT(shift, [typecast(single(self.SVM_params.shift), "uint8")] );

            % Send the Initial Payload
            num_package_SVM = 1;
            result = self.sendCommand(self.SET_SVM_PARAMS, [num_package_SVM; general_information], length(general_information)+1);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.SET_SVM_PARAMS);
            % Wait the 7.5 msec
            pause(7.5/1000);

            % Send the Prop Table
            for iMov = 1:nClasses_transmitted
                num_package_SVM = num_package_SVM + 1;
                result = self.sendCommand(self.SET_SVM_PARAMS, [num_package_SVM; propTable_uint8(:,iMov)], size(propTable_uint8, 1)+1);
                if (result ~= 0)
                    % error message and exit
                    error('LM: error connecting to device.')
                end
                dataHex = self.receiveReply(self.SET_SVM_PARAMS);
                % Wait the 7.5 msec if is not the last package
                pause(7.5/1000);
            end

            % other_params
            other_params = [scale, shift];
            for iParam = 1:size(other_params, 2)
                num_package_SVM = num_package_SVM + 1;
                result = self.sendCommand(self.SET_SVM_PARAMS, [num_package_SVM; other_params(:, iParam)], size(other_params, 1)+1);
                if (result ~= 0)
                    % error message and exit
                    error('LM: error connecting to device.')
                end
                dataHex = self.receiveReply(self.SET_SVM_PARAMS);
                % Wait the 7.5 msec
                pause(7.5/1000);
            end

            % Send the Weights for each class
            for iWeight = 1:size(weights, 2)
                num_package_SVM = num_package_SVM + 1;
                result = self.sendCommand(self.SET_SVM_PARAMS, [num_package_SVM; weights(:,iWeight)], size(weights, 1)+1);
                if (result ~= 0)
                    % error message and exit
                    error('LM: error connecting to device.')
                end
                
                dataHex = self.receiveReply(self.SET_SVM_PARAMS);
                % Wait the 7.5 msec 
                pause(7.5/1000);
            end
            
            error_set_SVM_params = hex2dec(dataHex(1,:));
            % Check the Values of SVM params
            if (error_set_SVM_params == 0)  
                disp('tSVM parameters set successfully \n!')
            else
                disp('tSVM parameters set NOT successfully \n!')
            end
        end

        %% Get SVM Params
        % Routine to Get the SVM parameters, 
        % these parameters are stored in the SVM_params property of the class.
        % More Packages of information are required because the required
        % amount of data is bigger than the Maximum dimension of a BT Package
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function get_SVM_params(self)
            self.SVM_params = [];
            % send command to get the First Package
            result = self.sendCommand(self.GET_SVM_PARAMS, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_SVM_PARAMS);
            dataDec = hex2dec(dataHex);
            dataDec = uint8(dataDec);

            % General Information
            self.reset_read_BT_counter();
            self.controlMode = self.read_BT(dataDec, 1, 'uint8');
            package_counter = self.read_BT(dataDec, 1, 'uint8'); % Useful in case of missed packages
            nClasses = self.read_BT(dataDec, 1, 'uint8');
            nFeatures = self.read_BT(dataDec, 1, 'uint8');
            nChannels = self.read_BT(dataDec, 1, 'uint8');

            FeaturesEnables = self.read_BT(dataDec, self.FEAT_NUM, 'uint8');
            ChannelsEnables = self.read_BT(dataDec, self.EMG_NUM_CHANNELS, 'uint8');
            floorNoise = self.read_BT(dataDec, 1, 'single');
            ntFeatures = self.read_BT(dataDec, 1, 'uint8');
            thresh_Tr = self.read_BT(dataDec, 1, 'single');

            bias = self.read_BT(dataDec, nClasses, 'single');

            nFeatures_uni = self.read_BT(dataDec, 1, 'uint8');
            FeaturesEnables_uni = self.read_BT(dataDec, self.NUM_MAX_FEAT_UNI, 'uint8');
            DimLinear = self.read_BT(dataDec, 1, 'uint8'); 

            % Prosthetic Outputs
            nClasses_transmitted = nClasses + 1; % Rest Class included
            outputs = self.read_BT(dataDec, nClasses_transmitted, 'uint8');
         
            % Save on the LM class
            self.SVM_params.nClasses = nClasses;
            self.SVM_params.nFeatures = nFeatures;
            self.SVM_params.nChannels = nChannels;
            self.SVM_params.FeaturesEnables = FeaturesEnables;
            self.SVM_params.ChannelsEnables = ChannelsEnables;
            self.SVM_params.floorNoise = floorNoise;
            self.SVM_params.thresh_Tr = thresh_Tr;
            self.SVM_params.bias = bias;
            self.SVM_params.ntFeatures = ntFeatures;
            self.SVM_params.nFeatures_uni = nFeatures_uni;
            self.SVM_params.FeaturesEnables_uni = FeaturesEnables_uni;
            self.SVM_params.DimLinear = DimLinear;
            % Prosthetic Output - Classes
            self.SVM_params.outputs = outputs;
            self.SVM_params.propTable = [];

            % Wait the 7.5 msec
            pause(7.5/1000);

            packages_counters = zeros(nClasses + nClasses_transmitted + 2 + 1, 1);
            counter_package = 1;
            packages_counters(counter_package) = package_counter;

            % send command to get the other Packages
            for iPackage = 1:nClasses_transmitted
                result = self.sendCommand(self.GET_SVM_PARAMS, 0, 0);
                if (result ~= 0)
                    % error message and exit
                    error('LM: error connecting to device.')
                end
                dataHex = self.receiveReply(self.GET_SVM_PARAMS);
                dataDec = hex2dec(dataHex);
                dataDec = uint8(dataDec);
                counter_package = counter_package + 1;

                self.reset_read_BT_counter();
                self.controlMode = self.read_BT(dataDec, 1, 'uint8');
                packages_counters(counter_package) = self.read_BT(dataDec, 1, 'uint8');
                self.SVM_params.propTable(:,iPackage) = self.read_BT(dataDec, nChannels, 'single');

                % Wait the 7.5 msec if is not the last package
                pause(7.5/1000);
            end

            % Send Command to get the normalisation Values
            % Scale 
            result = self.sendCommand(self.GET_SVM_PARAMS, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_SVM_PARAMS);
            dataDec = hex2dec(dataHex);
            dataDec = uint8(dataDec);
            counter_package = counter_package + 1;

            self.reset_read_BT_counter();
            self.controlMode = self.read_BT(dataDec, 1, 'uint8');
            packages_counters(counter_package) = self.read_BT(dataDec, 1, 'uint8');
            self.SVM_params.scale = self.read_BT(dataDec, DimLinear, 'single');

            % Wait the 7.5 msec
            pause(7.5/1000);

            % Shift
            result = self.sendCommand(self.GET_SVM_PARAMS, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_SVM_PARAMS);
            dataDec = hex2dec(dataHex);
            dataDec = uint8(dataDec);
            counter_package = counter_package + 1;

            self.reset_read_BT_counter();
            self.controlMode = self.read_BT(dataDec, 1, 'uint8');
            packages_counters(counter_package) = self.read_BT(dataDec, 1, 'uint8');
            self.SVM_params.shift = self.read_BT(dataDec, DimLinear, 'single');

            % Wait the 7.5 msec
            pause(7.5/1000);

            % send command to get the other Packages
            for iPackage = 1:nClasses
                result = self.sendCommand(self.GET_SVM_PARAMS, 0, 0);
                if (result ~= 0)
                    % error message and exit
                    error('LM: error connecting to device.')
                end
                dataHex = self.receiveReply(self.GET_SVM_PARAMS);
                dataDec = hex2dec(dataHex);
                dataDec = uint8(dataDec);
                counter_package = counter_package + 1;

                self.reset_read_BT_counter();
                self.controlMode = self.read_BT(dataDec, 1, 'uint8');
                packages_counters(counter_package) = self.read_BT(dataDec, 1, 'uint8');
    
                self.SVM_params.weights(iPackage, :) = self.read_BT(dataDec, DimLinear, 'single');

                if iPackage ~= nClasses
                    % Wait the 7.5 msec if is not the last package
                    pause(7.5/1000);
                end
            end
            % Save the Counters
            self.SVM_params.counters = packages_counters;
        end

        %% Set MLP Params
        % Routine to set the MLP parameters, 
        % these parameters have to be previously stores in the MLP_params property of the class.
        % More Packages of information are required because the required
        % amount of data is bigger than the Maximum dimension of a BT Package
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function set_MLP_params(self)
            self.controlMode = self.MLP_CONTROL;
            nClasses = self.MLP_params.nClasses;
            nFeatures = self.MLP_params.nFeatures;
            nChannels = self.MLP_params.nChannels;
            FeaturesEnables = [self.MLP_params.FeaturesEnables];
            ChannelsEnables = [self.MLP_params.ChannelsEnables];
            floorNoise = self.MLP_params.floorNoise;
            % Other Features
            nFeatures_uni = self.MLP_params.nFeatures_uni;
            FeaturesEnables_uni = self.MLP_params.FeaturesEnables_uni;
            % Linear Dimention
            DimLinear = self.MLP_params.DimLinear;
            % Prosthetic Output - Classes
            prostheticOutputs = self.MLP_params.outputs;
            propTable = self.MLP_params.propTable;
            nClasses_transmitted = length(prostheticOutputs);

            % Assemble the Data for LimbMATE
            general_information = [];
            general_information = self.write_BT(general_information, uint8(nClasses) );
            general_information = self.write_BT(general_information, uint8(nFeatures) );
            general_information = self.write_BT(general_information, uint8(nChannels) );
            general_information = self.write_BT(general_information, uint8(FeaturesEnables) );
            general_information = self.write_BT(general_information, uint8(ChannelsEnables) );
            general_information = self.write_BT(general_information, [typecast(single(floorNoise), "uint8")]' );
            % Bias 
            fc_b = self.MLP_params.fc_b;
            general_information = self.write_BT(general_information, typecast(single(fc_b), "uint8") );
            % Other Features
            general_information = self.write_BT(general_information, uint8(nFeatures_uni) );
            general_information = self.write_BT(general_information, uint8(FeaturesEnables_uni) );
            general_information = self.write_BT(general_information, uint8(DimLinear) );

            % Prosthetic Output - Classes
            general_information = self.write_BT(general_information, uint8(prostheticOutputs) );
            propTable_uint8 = [self.matrix_to_u8(single(propTable'))];

            % Weigths
            fc_w = self.MLP_params.fc_w;
            weights = self.matrix_to_u8(single(fc_w));
            
            % Mean + Std
            nMean = [];
            nMean = self.write_BT(nMean, [typecast(single(self.MLP_params.nMean), "uint8")] );

            nStd = [];
            nStd = self.write_BT(nStd, [typecast(single(self.MLP_params.nStd), "uint8")] );

            % Send the Initial Payload
            num_package_MLP = 1;
            result = self.sendCommand(self.SET_MLP_PARAMS, [num_package_MLP; general_information], length(general_information)+1);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.SET_MLP_PARAMS);
            % Wait the 7.5 msec
            pause(7.5/1000);

            % Send the Prop Table
            for iMov = 1:nClasses_transmitted
                num_package_MLP = num_package_MLP + 1;
                result = self.sendCommand(self.SET_MLP_PARAMS, [num_package_MLP; propTable_uint8(:,iMov)], size(propTable_uint8, 1)+1);
                if (result ~= 0)
                    % error message and exit
                    error('LM: error connecting to device.')
                end
                dataHex = self.receiveReply(self.SET_MLP_PARAMS);
                % Wait the 7.5 msec if is not the last package
                pause(7.5/1000);
            end

            % other_params
            other_params = [nMean, nStd];
            for iParam = 1:size(other_params, 2)
                num_package_MLP = num_package_MLP + 1;
                result = self.sendCommand(self.SET_MLP_PARAMS, [num_package_MLP; other_params(:, iParam)], size(other_params, 1)+1);
                if (result ~= 0)
                    % error message and exit
                    error('LM: error connecting to device.')
                end
                dataHex = self.receiveReply(self.SET_MLP_PARAMS);
                % Wait the 7.5 msec
                pause(7.5/1000);
            end

            % Send the Weights for each class
            for iWeight = 1:size(weights, 2)
                num_package_MLP = num_package_MLP + 1;
                result = self.sendCommand(self.SET_MLP_PARAMS, [num_package_MLP; weights(:, iWeight)], size(weights, 1)+1);
                if (result ~= 0)
                    % error message and exit
                    error('LM: error connecting to device.')
                end
                dataHex = self.receiveReply(self.SET_MLP_PARAMS);
                % Wait the 7.5 msec 
                pause(7.5/1000);
            end
          
            error_set_MLP_params = hex2dec(dataHex(1,:));
            % Check the Values of MLP params
            if (error_set_MLP_params == 0)  
                disp('MLP parameters set successfully \n!')
            else
                disp('MLP parameters set NOT successfully \n!')
            end
        end

        %% Get MLP Params
        % Routine to Get the MLP parameters, 
        % these parameters are stored in the MLP_params property of the class.
        % More Packages of information are required because the required
        % amount of data is bigger than the Maximum dimension of a BT Package
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function get_MLP_params(self)
            self.MLP_params = [];
            % send command to get the First Package
            result = self.sendCommand(self.GET_MLP_PARAMS, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_MLP_PARAMS);
            dataDec = hex2dec(dataHex);

            % General Information
            dataDec = uint8(dataDec);

            self.reset_read_BT_counter();
            self.controlMode = self.read_BT(dataDec, 1, 'uint8');
            package_counter = self.read_BT(dataDec, 1, 'uint8'); % Useful in case of missed packages
            nClasses = self.read_BT(dataDec, 1, 'uint8');
            nFeatures = self.read_BT(dataDec, 1, 'uint8');
            nChannels = self.read_BT(dataDec, 1, 'uint8');

            FeaturesEnables = self.read_BT(dataDec, self.FEAT_NUM, 'uint8');
            ChannelsEnables = self.read_BT(dataDec, self.EMG_NUM_CHANNELS, 'uint8');
            floorNoise = self.read_BT(dataDec, 1, 'single');
            bias = self.read_BT(dataDec, nClasses, 'single');

            nFeatures_uni = self.read_BT(dataDec, 1, 'uint8');
            FeaturesEnables_uni = self.read_BT(dataDec, self.NUM_MAX_FEAT_UNI, 'uint8');
            DimLinear = self.read_BT(dataDec, 1, 'uint8');

            % Prosthetic Outputs
            nClasses_transmitted = nClasses;
            outputs = self.read_BT(dataDec, nClasses_transmitted, 'uint8');

            % Save on the LM class
            self.MLP_params.nClasses = nClasses;
            self.MLP_params.nFeatures = nFeatures;
            self.MLP_params.nChannels = nChannels;
            self.MLP_params.FeaturesEnables = FeaturesEnables;
            self.MLP_params.ChannelsEnables = ChannelsEnables;
            self.MLP_params.floorNoise = floorNoise;
            self.MLP_params.bias = bias;
            self.MLP_params.nFeatures_uni = nFeatures_uni;
            self.MLP_params.FeaturesEnables_uni = FeaturesEnables_uni;
            self.MLP_params.DimLinear = DimLinear;
            % Prosthetic Output - Classes
            self.MLP_params.outputs = outputs;
            self.MLP_params.propTable = [];

            % Wait the 7.5 msec
            pause(7.5/1000);

            packages_counters = zeros(nClasses + nClasses_transmitted + 2 + 1, 1);
            counter_package = 1;
            packages_counters(counter_package) = package_counter;


            % send command to get the other Packages
            for iPackage = 1:nClasses_transmitted
                result = self.sendCommand(self.GET_MLP_PARAMS, 0, 0);
                if (result ~= 0)
                    % error message and exit
                    error('LM: error connecting to device.')
                end
                dataHex = self.receiveReply(self.GET_MLP_PARAMS);
                dataDec = hex2dec(dataHex);
                dataDec = uint8(dataDec);
                counter_package = counter_package + 1;

                self.reset_read_BT_counter();
                self.controlMode = self.read_BT(dataDec, 1, 'uint8');
                packages_counters(counter_package) = self.read_BT(dataDec, 1, 'uint8');
                self.MLP_params.propTable(:,iPackage) = self.read_BT(dataDec, nChannels, 'single');

                % Wait the 7.5 msec if is not the last package
                pause(7.5/1000);
            end

            % Mean 
            result = self.sendCommand(self.GET_MLP_PARAMS, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_MLP_PARAMS);
            dataDec = hex2dec(dataHex);
            dataDec = uint8(dataDec);
            counter_package = counter_package + 1;

            self.reset_read_BT_counter();
            self.controlMode = self.read_BT(dataDec, 1, 'uint8');
            packages_counters(counter_package) = self.read_BT(dataDec, 1, 'uint8');

            self.MLP_params.nMean = self.read_BT(dataDec, DimLinear, 'single');
            % Wait the 7.5 msec
            pause(7.5/1000);

            % Std
            result = self.sendCommand(self.GET_MLP_PARAMS, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_MLP_PARAMS);
            dataDec = hex2dec(dataHex);
            dataDec = uint8(dataDec);
            counter_package = counter_package + 1;

            self.reset_read_BT_counter();
            self.controlMode = self.read_BT(dataDec, 1, 'uint8');
            packages_counters(counter_package) = self.read_BT(dataDec, 1, 'uint8');

            self.MLP_params.nStd = self.read_BT(dataDec, DimLinear, 'single');
            % Wait the 7.5 msec
            pause(7.5/1000);

            % send command to get the other Packages
            for iPackage = 1:nClasses
                result = self.sendCommand(self.GET_MLP_PARAMS, 0, 0);
                if (result ~= 0)
                    % error message and exit
                    error('LM: error connecting to device.')
                end
                dataHex = self.receiveReply(self.GET_MLP_PARAMS);
                dataDec = hex2dec(dataHex);
                dataDec = uint8(dataDec);
                counter_package = counter_package + 1;

                self.reset_read_BT_counter();
                self.controlMode = self.read_BT(dataDec, 1, 'uint8');
                packages_counters(counter_package) = self.read_BT(dataDec, 1, 'uint8');
    
                self.MLP_params.weights(iPackage, :) = self.read_BT(dataDec, DimLinear, 'single');
                % Wait the 7.5 msec
                pause(7.5/1000);

                if iPackage ~= nClasses
                    % Wait the 7.5 msec if is not the last package
                    pause(7.5/1000);
                end
            end
            % Save the Counters
            self.MLP_params.counters = packages_counters;

        end

        %% Set Reg Params
        % Routine to set the Reg parameters, 
        % these parameters have to be previously stores in the Reg_params property of the class.
        % More Packages of information are required because the required
        % amount of data is bigger than the Maximum dimension of a BT Package
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function set_Reg_params(self)
            self.controlMode = self.REG_CONTROL;
            nDoF = self.Reg_params.nDoF;
            nFeatures = self.Reg_params.nFeatures;
            nChannels = self.Reg_params.nChannels;
            FeaturesEnables = [self.Reg_params.FeaturesEnables];
            ChannelsEnables = [self.Reg_params.ChannelsEnables];
            idxMov = [self.Reg_params.idxMov];

            % Other Features
            nFeatures_uni = self.Reg_params.nFeatures_uni;
            FeaturesEnables_uni = self.Reg_params.FeaturesEnables_uni;
            % Linear Dimention
            DimLinear = self.Reg_params.DimLinear;

            % Assemble the Data for LimbMATE
            general_information = [];
            general_information = self.write_BT(general_information, uint8(nDoF) );
            general_information = self.write_BT(general_information, uint8(nFeatures) );
            general_information = self.write_BT(general_information, uint8(nChannels) );
            general_information = self.write_BT(general_information, uint8(FeaturesEnables) );
            general_information = self.write_BT(general_information, uint8(ChannelsEnables) );
            general_information = self.write_BT(general_information, uint8(idxMov) );
            % Bias 
            bias = self.Reg_params.bias;
            general_information = self.write_BT(general_information, typecast(single(bias), "uint8") );
            % Thresholds
            low_thresh = self.Reg_params.low_thresh;
            general_information = self.write_BT(general_information, typecast(single(low_thresh), "uint8") );

            upp_thresh = self.Reg_params.upp_thresh;
            general_information = self.write_BT(general_information, typecast(single(upp_thresh), "uint8") );

            % Other Features
            general_information = self.write_BT(general_information, uint8(nFeatures_uni) );
            general_information = self.write_BT(general_information, uint8(FeaturesEnables_uni) );
            general_information = self.write_BT(general_information, uint8(DimLinear) );

            % Weigths
            w_v = self.Reg_params.weights;
            weights = self.matrix_to_u8(single(w_v));

            % Send the Initial Payload
            num_package_Reg = 1;
            result = self.sendCommand(self.SET_REG_PARAMS, [num_package_Reg; general_information], length(general_information)+1);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.SET_REG_PARAMS);
            % Wait the 7.5 msec
            pause(7.5/1000);
            % Send the Weights for each class
            for iWeight = 1:size(weights, 2)
                num_package_Reg = num_package_Reg + 1;
                result = self.sendCommand(self.SET_REG_PARAMS, [num_package_Reg; weights(:,iWeight)], size(weights, 1)+1);
                if (result ~= 0)
                    % error message and exit
                    error('LM: error connecting to device.')
                end
                dataHex = self.receiveReply(self.SET_REG_PARAMS);
                if iWeight ~= size(weights, 2)
                    % Wait the 7.5 msec if is not the last package
                    pause(7.5/1000);
                end
            end
            
            error_set_Reg_params = hex2dec(dataHex(1,:));
            % Check the Values of LDA params
            if (error_set_Reg_params == 0)  
                disp('Reg parameters set successfully \n!')
            else
                disp('Reg parameters set NOT successfully \n!')
            end
        end

        %% Get Reg Params
        % Routine to Get the Reg parameters, 
        % these parameters are stored in the Reg_params property of the class.
        % More Packages of information are required because the required
        % amount of data is bigger than the Maximum dimension of a BT Package
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function get_Reg_params(self)
            self.Reg_params = [];
            % send command to get the First Package
            result = self.sendCommand(self.GET_REG_PARAMS, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_REG_PARAMS);
            dataDec = hex2dec(dataHex);

             % General Information
            dataDec = uint8(dataDec);

            self.reset_read_BT_counter();
            self.controlMode = self.read_BT(dataDec, 1, 'uint8');
            package_counter = self.read_BT(dataDec, 1, 'uint8'); % Useful in case of missed packages
            nDoF = self.read_BT(dataDec, 1, 'uint8');
            nFeatures = self.read_BT(dataDec, 1, 'uint8');
            nChannels = self.read_BT(dataDec, 1, 'uint8');

            FeaturesEnables = self.read_BT(dataDec, self.FEAT_NUM, 'uint8');
            ChannelsEnables = self.read_BT(dataDec, self.EMG_NUM_CHANNELS, 'uint8');
            idxMov = self.read_BT(dataDec, 2*nDoF, 'uint8');

            bias = self.read_BT(dataDec, nDoF, 'single');
            low_thresh = self.read_BT(dataDec, 2 * nDoF, 'single');
            upp_thresh = self.read_BT(dataDec, 2 * nDoF, 'single');

            nFeatures_uni = self.read_BT(dataDec, 1, 'uint8');
            FeaturesEnables_uni = self.read_BT(dataDec, self.NUM_MAX_FEAT_UNI, 'uint8');
            DimLinear = self.read_BT(dataDec, 1, 'uint8'); 

            % Save on the LM class
            self.Reg_params.nDoF = nDoF;
            self.Reg_params.nFeatures = nFeatures;
            self.Reg_params.nChannels = nChannels;
            self.Reg_params.FeaturesEnables = FeaturesEnables;
            self.Reg_params.ChannelsEnables = ChannelsEnables;
            self.Reg_params.idxMov = idxMov;
            self.Reg_params.nFeatures_uni = nFeatures_uni;
            self.Reg_params.bias = bias;
            self.Reg_params.low_thresh = low_thresh;
            self.Reg_params.upp_thresh = upp_thresh;
            self.Reg_params.FeaturesEnables_uni = FeaturesEnables_uni;
            self.Reg_params.DimLinear = DimLinear;
            % Wait the 7.5 msec
            pause(7.5/1000);

            packages_counters = zeros(nDoF + 1, 1);
            counter_package = 1;
            packages_counters(counter_package) = package_counter;
            % send command to get the other Packages
            for iPackage = 1:nDoF
                result = self.sendCommand(self.GET_REG_PARAMS, 0, 0);
                if (result ~= 0)
                    % error message and exit
                    error('LM: error connecting to device.')
                end
                dataHex = self.receiveReply(self.GET_REG_PARAMS);
                dataDec = hex2dec(dataHex);
                dataDec = uint8(dataDec);
                counter_package = counter_package + 1;

                self.reset_read_BT_counter();
                self.controlMode = self.read_BT(dataDec, 1, 'uint8');
                packages_counters(counter_package) = self.read_BT(dataDec, 1, 'uint8');
    
                self.Reg_params.weights(iPackage,:) = self.read_BT(dataDec, DimLinear, 'single');

                if iPackage ~= nDoF
                    % Wait the 7.5 msec if is not the last package
                    pause(7.5/1000);
                end
            end
            % Save the Counters
            self.Reg_params.counters = packages_counters;
        end

        %% Set IMU Params
        % Routine to set the IMU parameters, 
        % these parameters have to be previously stores in the imu_params property of the class.
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function set_Imu_params(self)
            self.controlMode = self.IMU_CONTROL;

            low_thresh = self.Imu_params.low_thresh;
            upp_thresh = self.Imu_params.upp_thresh;

            % Assemble the Data for LimbMATE
            general_information = [];
            general_information = self.write_BT(general_information, [typecast(single(low_thresh), "uint8")]' );
            general_information = self.write_BT(general_information, [typecast(single(upp_thresh), "uint8")]' );

            % Send the Initial Payload
            result = self.sendCommand(self.SET_IMU_PARAMS, [general_information], length(general_information));
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.SET_IMU_PARAMS);
            % Wait the 7.5 msec
            pause(7.5/1000);
            
            error_set_Imu_params = hex2dec(dataHex(1,:));
            % Check the Values of IMU params
            if (error_set_Imu_params == 0)  
                disp('IMU parameters set successfully \n!')
            else
                disp('IMU parameters set NOT successfully \n!')
            end
        end

        %% Get Imu Params
        % Routine to Get the Imu parameters, 
        % these parameters are stored in the Imu_params property of the class.
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function get_Imu_params(self)
            self.Imu_params = [];
            % send command to get the First Package
            result = self.sendCommand(self.GET_IMU_PARAMS, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_IMU_PARAMS);
            dataDec = hex2dec(dataHex);
            dataDec = uint8(dataDec);

            self.reset_read_BT_counter();
            self.controlMode = self.read_BT(dataDec, 1, 'uint8');
            self.Imu_params.low_thresh = self.read_BT(dataDec, 2, 'single');
            self.Imu_params.upp_thresh = self.read_BT(dataDec, 2, 'single');

        end

        %% Set PR table - GUI_PatRec >> UpdatePRtable() b
        % Routine to set the PR table parameters, 
        % these parameters have to be previously stores in the patRec_table property of the class.
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        % function set_PR_table(self)
        %     prostheticOutputs = self.patRec_table.outputs;
        %     propTable = self.patRec_table.propTable;
        %     [nChannels, nClasses] = size(propTable);
        % 
        %     % Assemble the Data for LimbMATE
        %     general_information = [];
        %     general_information = self.write_BT(general_information, uint8(nClasses) );
        %     general_information = self.write_BT(general_information, uint8(nChannels) );
        %     general_information = self.write_BT(general_information, uint8(prostheticOutputs) );
        % 
        %     % Weigths
        %     propTable_uint8 = [self.matrix_to_u8(single(propTable'))];
        % 
        %     % Send the Initial Payload
        %     num_package_PR_table = 1;
        %     result = self.sendCommand(self.SET_PR_TABLE, [num_package_PR_table; general_information], length(general_information)+1);
        %     if (result ~= 0)
        %         % error message and exit
        %         error('LM: error connecting to device.')
        %     end
        %     dataHex = self.receiveReply(self.SET_PR_TABLE);
        % 
        %     % Wait the 7.5 msec
        %     pause(7.5/1000);
        %     % Send the Weights for each class
        %     for iMov = 1:nClasses
        %         num_package_PR_table = iMov + 1;
        %         result = self.sendCommand(self.SET_PR_TABLE, [num_package_PR_table; propTable_uint8(:,iMov)], size(propTable_uint8, 1)+1);
        %         if (result ~= 0)
        %             % error message and exit
        %             error('LM: error connecting to device.')
        %         end
        %         dataHex = self.receiveReply(self.SET_PR_TABLE);
        %         if iMov ~= size(propTable_uint8, 1)
        %             % Wait the 7.5 msec if is not the last package
        %             pause(7.5/1000);
        %         end
        %     end
        % 
        %     error_set_PR_table = hex2dec(dataHex(1,:));
        %     % Check the Values of PR table
        %     if (error_set_PR_table == 0)  
        %         disp('PR table set successfully \n!')
        %     else
        %         disp('PR table set NOT successfully \n!')
        %     end
        % end

        %% Get PR table - GUI_PatRec >> UpdatePRtable()
        % Routine to get the PR table parameters, 
        % these parameters are stored in the patRec_table property of the class.
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        % function get_PR_table(self)
        %     self.patRec_table = [];
        %     % send command
        %     result = self.sendCommand(self.GET_PR_TABLE, 0, 0);
        %     if (result ~= 0)
        %         % error message and exit
        %         error('LM: error connecting to device.')
        %     end
        %     dataHex = self.receiveReply(self.GET_PR_TABLE);
        %     dataDec = hex2dec(dataHex);
        %     dataDec = uint8(dataDec);
        % 
        %     self.reset_read_BT_counter();
        %     package_counter = self.read_BT(dataDec, 1, 'uint8');
        %     nClasses = self.read_BT(dataDec, 1, 'uint8');
        %     nChannels = self.read_BT(dataDec, 1, 'uint8');
        %     outputs = self.read_BT(dataDec, nClasses, 'uint8');
        % 
        %     % General Information
        %     self.patRec_table.nMov = nClasses;
        %     self.patRec_table.nCh = nChannels;
        %     % Prosthetic Outputs
        %     self.patRec_table.outputs = outputs;
        % 
        %     % Get the other Packages
        %     % Wait the 7.5 msec
        %     pause(7.5/1000);
        % 
        %     packages_counters = zeros(nClasses + 1, 1);
        %     packages_counters(1) = package_counter;
        %     propTable_single = zeros(nChannels, nClasses, "single");
        %     % send command to get the other Packages
        %     for iPackage = 1:nClasses
        %         result = self.sendCommand(self.GET_PR_TABLE, 0, 0);
        %         if (result ~= 0)
        %             % error message and exit
        %             error('LM: error connecting to device.')
        %         end
        %         dataHex = self.receiveReply(self.GET_PR_TABLE);
        %         dataDec = hex2dec(dataHex);
        %         dataDec = uint8(dataDec);
        % 
        %         self.reset_read_BT_counter();
        %         packages_counters(iPackage + 1) = self.read_BT(dataDec, 1, 'uint8');
        %         self.patRec_table.propTable(:,iPackage) = self.read_BT(dataDec, nChannels, 'single');
        % 
        %         if iPackage ~= nClasses
        %             % Wait the 7.5 msec if is not the last package
        %             pause(7.5/1000);
        %         end
        %     end
        % 
        % end

        %% Set PostProcessing Control Parameters
        % Routine to set the PostProcessing Control Parameters, 
        % these parameters have to be previously stored in the PP_control property of the class.
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function set_PP_control_params(self)
            % ppControlType
            ppControlType = uint8(self.PP_control.controlType);
            % Majority Vote
            mvSteps = uint8(self.PP_control.MV.mvSteps);
            % Ramp
            rampLength = self.PP_control.Ramp.rampLength;
			rampMode = self.PP_control.Ramp.rampMode;
            ramp_params = uint8([rampLength; rampMode]);
            % Inertial
            inertialCoef = self.PP_control.Inertial.inertialCoef; % Vector [3 x 1]
			rampModeInertial = self.PP_control.Inertial.rampMode;
            inertial_params = uint8([inertialCoef; rampModeInertial]);
            % Activation Level LP Filter
            actLevelFilterLength = uint8(self.PP_control.actLevelFilterLength);
            % Penalise Overshoot
            penaliseOvershoot = uint8(self.PP_control.penaliseOvershoot);
            % Hold Open
            holdOpen_enable = self.PP_control.holdOpen.enable; 
            holdOpen_time = self.PP_control.holdOpen.holdOpen_time; 
            holdOpen_thresh_perc = self.PP_control.holdOpen.holdOpen_thresh_perc; 
            holdOpen_params = uint8([holdOpen_enable; holdOpen_time; holdOpen_thresh_perc]);
            % Cocotraction
            coco_enable = self.PP_control.coco.enable;
            coco_time = self.PP_control.coco.coco_time; 
            coco_OpH_thresh = self.PP_control.coco.OH_thresh_perc; 
            coco_ClH_thresh = self.PP_control.coco.CH_thresh_perc; 
            coco_wait_next_coco = self.PP_control.coco.wait_next_coco; 
            
            coco_params = uint8([coco_enable; coco_time; coco_OpH_thresh; coco_ClH_thresh; coco_wait_next_coco]);
            % MIA
            MIA_min_ActThresh = self.PP_control.MIA.min_ActThresh; 
            MIA_min_actLevel = self.PP_control.MIA.min_actLevel; 
            MIA_max_actLevel = self.PP_control.MIA.max_actLevel; 
            MIA_min_closeStep = self.PP_control.MIA.min_closeStep; 
            MIA_max_closeStep = self.PP_control.MIA.max_closeStep; 
            MIA_min_speed = self.PP_control.MIA.min_speed; 
            MIA_max_speed = self.PP_control.MIA.max_speed; 
            MIAenableRestHand = self.PP_control.MIA.enableRestHand; 
            MIA_sensitivity = [typecast(single(self.PP_control.MIA.sensitivity), "uint8")]';
            MIA_changeGraspModality = self.PP_control.MIA.changeGraspModality; 
            MIA_exitPreshape = self.PP_control.MIA.exitPreshape; 
            MIA_blockOHW = self.PP_control.MIA.blockOHW; 
            MIA_changeGrasp_time = self.PP_control.MIA.changeGrasp_time; 
            MIA_restGrasp_time = self.PP_control.MIA.restGrasp_time; 
            MIA_changeGraspLag_time = self.PP_control.MIA.changeGraspLag_time; 
            MIA_disableClassesWirstDisabledWristButton = self.PP_control.MIA.disableClassesWirstDisabledWristButton;
            MIA_params = uint8([MIA_min_ActThresh; MIA_min_actLevel; MIA_max_actLevel; MIA_min_closeStep; MIA_max_closeStep; MIA_min_speed; MIA_max_speed; MIAenableRestHand; MIA_sensitivity; MIA_changeGraspModality; MIA_exitPreshape; MIA_blockOHW; MIA_changeGrasp_time; MIA_restGrasp_time; MIA_changeGraspLag_time; MIA_disableClassesWirstDisabledWristButton]);
            
            % Ottobock
            Otto_min_ActThresh = self.PP_control.Ottobock.min_ActThresh; 
            Otto_min_actLevel_hand = self.PP_control.Ottobock.min_actLevel_hand; 
            Otto_max_actLevel_hand = self.PP_control.Ottobock.max_actLevel_hand; 
            Otto_min_actLevel_wrist = self.PP_control.Ottobock.min_actLevel_wrist; 
            Otto_max_actLevel_wrist = self.PP_control.Ottobock.max_actLevel_wrist; 
            Otto_min_actLevel_elbow = self.PP_control.Ottobock.min_actLevel_elbow; 
            Otto_max_actLevel_elbow = self.PP_control.Ottobock.max_actLevel_elbow; 
            Otto_sensitivity = [typecast(single(self.PP_control.Ottobock.sensitivity), "uint8")]';
            Otto_params = uint8([Otto_min_ActThresh; Otto_min_actLevel_hand; Otto_max_actLevel_hand; Otto_min_actLevel_wrist; Otto_max_actLevel_wrist; Otto_min_actLevel_elbow; Otto_max_actLevel_elbow; Otto_sensitivity]);

            % Assemble the Data for LimbMATE
            general_information = [];
            general_information = self.write_BT(general_information, uint8(ppControlType) );
            general_information = self.write_BT(general_information, uint8(mvSteps) );
            general_information = self.write_BT(general_information, uint8(ramp_params) );
            general_information = self.write_BT(general_information, uint8(inertial_params) );
            general_information = self.write_BT(general_information, uint8(actLevelFilterLength) );
            general_information = self.write_BT(general_information, uint8(penaliseOvershoot) );
            general_information = self.write_BT(general_information, uint8(holdOpen_params) );
            general_information = self.write_BT(general_information, uint8(coco_params) );
            general_information = self.write_BT(general_information, uint8(MIA_params) );
            general_information = self.write_BT(general_information, uint8(Otto_params) );

            result = self.sendCommand(self.SET_PP_PARAMS, general_information, length(general_information));
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.SET_PP_PARAMS);
            error_set_PP_control_params = hex2dec(dataHex(1,:));
            % Check the Values of PP control params
            if (error_set_PP_control_params == 0)  
                disp('Post Processing Parameters set successfully \n!')
            else
                disp('Post Processing Parameters NOT set successfully \n!')
            end
        end

        %% Get PostProcessing Control Parameters
        % Routine to Get the PostProcessing Control Parameters, 
        % these parameters are stored in the PP_control property of the class.
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function get_PP_control_params(self)
            self.PP_control = [];
            % send command
            result = self.sendCommand(self.GET_PP_PARAMS, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_PP_PARAMS);
            dataDec = hex2dec(dataHex);
            dataDec = uint8(dataDec);

            self.reset_read_BT_counter();

            % ppControlType
            self.PP_control.controlType = self.read_BT(dataDec, 1, 'uint8');
            % Majority Vote
            self.PP_control.MV.mvSteps = self.read_BT(dataDec, 1, 'uint8');
            % Ramp
            self.PP_control.Ramp.rampLength = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.Ramp.rampMode = self.read_BT(dataDec, 1, 'uint8');
            % Inertial
            self.PP_control.Inertial.inertialCoef = self.read_BT(dataDec, 3, 'uint8');
            self.PP_control.Inertial.rampMode = self.read_BT(dataDec, 1, 'uint8');
            % Activation Level LP Filter
            self.PP_control.actLevelFilterLength = self.read_BT(dataDec, 1, 'uint8');
            % Penalise Overshoot
            self.PP_control.penaliseOvershoot = self.read_BT(dataDec, 1, 'uint8');
            
            % Hold Open
            self.PP_control.holdOpen.enable = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.holdOpen.holdOpen_time = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.holdOpen.holdOpen_thresh_perc = self.read_BT(dataDec, 1, 'uint8');
            % Cocotraction
            self.PP_control.coco.enable = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.coco.coco_time = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.coco.OH_thresh_perc = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.coco.CH_thresh_perc = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.coco.wait_next_coco = self.read_BT(dataDec, 1, 'uint8');

            % MIA
            self.PP_control.MIA.min_ActThresh = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.MIA.min_actLevel = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.MIA.max_actLevel = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.MIA.min_closeStep = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.MIA.max_closeStep = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.MIA.min_speed = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.MIA.max_speed = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.MIA.enableRestHand = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.MIA.sensitivity = self.read_BT(dataDec, 1, 'single');
            self.PP_control.MIA.changeGraspModality = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.MIA.exitPreshape = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.MIA.blockOHW = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.MIA.changeGrasp_time = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.MIA.restGrasp_time = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.MIA.changeGraspLag_time = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.MIA.disableClassesWirstDisabledWristButton = self.read_BT(dataDec, 1, 'uint8');
            
            % Ottobock
            self.PP_control.Ottobock.min_ActThresh = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.Ottobock.min_actLevel_hand = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.Ottobock.max_actLevel_hand = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.Ottobock.min_actLevel_wrist = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.Ottobock.max_actLevel_wrist = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.Ottobock.min_actLevel_elbow = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.Ottobock.max_actLevel_elbow = self.read_BT(dataDec, 1, 'uint8');
            self.PP_control.Ottobock.sensitivity = self.read_BT(dataDec, 1, 'single');
        end

        %% Extract Features from a Full TW
        % Routine Extract Features from a Full TW + Updates the Max and the min MAV_v
        % Same features as BioPatRec
        % @param[in] TW:    Full TW
        % @return none
        %-----------------------------------------------------------------
        function feature_struct = features_extractions(self, TW)
            feature_struct = [];
            % MAV
            feature_struct.MAV = mean(abs(TW), 2);
            % WL
            feature_struct.WL = sum(abs( TW(:, 2:end) - TW(:, 1:end-1) ), 2);
            % SLP
            diffData = diff(TW, 1, 2);  
            zc = (diffData > 0 ) - (diffData < 0);
            feature_struct.SLP = sum( abs( zc(:, 1:end-1) - zc(:, 2:end) ) > 1 , 2);
            % ZC
            tmp = repmat(feature_struct.MAV,[1, size(TW, 2)] );
            zc_centered = TW - tmp;
            zc_centered_mult = zc_centered(:, 1:end-1).*zc_centered(:, 2:end);
            feature_struct.ZC = sum(zc_centered_mult<0, 2);
            % STD
            feature_struct.STD = std(TW, 0, 2);

        end

        %% Set Class-DAC Parameters
        % Routine to set the Class associated to each DAC channel parameters, 
        % these parameters have to be previously stores in the DC_params property of the class
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function set_class_DAC_params(self)
            % class DAC Params
            payload_class_DAC = self.class_DAC_params;
            result = self.sendCommand(self.SET_CLASS_DAC, payload_class_DAC, length(payload_class_DAC) );
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.SET_CLASS_DAC);
            error_class_DAC_params = hex2dec(dataHex(1,:));
            % Check the Values of set Class-DAC
            if (error_class_DAC_params == 0)  
                disp('Class DAC parameters set successfully \n!')
            else
                disp('Class DAC parameters set NOT successfully \n!')
            end
        end

        %% Get Class-DAC Parameters
        % Routine to get the Class associated to each DAC channel parameters, 
        % these parameters are stored in the DC_params property of the class
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function get_class_DAC_params(self)
            % send command
            result = self.sendCommand(self.GET_CLASS_DAC, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_CLASS_DAC);
            dataDec = hex2dec(dataHex);
            for iCh = 1:self.DAC_CHANNELS
                self.class_DAC_params(iCh) = dataDec(iCh);
            end
        end

        %% Set Feedback Table
        % Routine to set the Feedback Table, 
        % these parameters have to be previously stores in the FB_table property of the class
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function set_feedback_table(self)
            % class DAC Params
            fb_table = self.fb_table;
            general_information = [];            
            for i = 1:length(fb_table)
                general_information = self.write_BT(general_information, uint8(fb_table(i).enable) );
                general_information = self.write_BT(general_information, uint8(fb_table(i).channel) );
                general_information = self.write_BT(general_information, uint8(fb_table(i).activation_sensor) );
                general_information = self.write_BT(general_information, uint8(fb_table(i).activation_comparison) );
                general_information = self.write_BT(general_information, [typecast(single(fb_table(i).activation_threshold), "uint8")]' );
                general_information = self.write_BT(general_information, uint8(fb_table(i).deactivation_sensor) );
                general_information = self.write_BT(general_information, uint8(fb_table(i).deactivation_comparison) );
                general_information = self.write_BT(general_information, [typecast(single(fb_table(i).deactivation_threshold), "uint8")]' );           
                general_information = self.write_BT(general_information, uint8(fb_table(i).feedback_modality) );
                general_information = self.write_BT(general_information, [typecast(uint16(fb_table(i).period_value), "uint8")]' );
                general_information = self.write_BT(general_information, uint8(fb_table(i).activation_period_perc) );
                general_information = self.write_BT(general_information, uint8(fb_table(i).specialHandGrasp) );
            end
            result = self.sendCommand(self.SET_FEEDBACK, uint8(general_information), length(general_information) );
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.SET_FEEDBACK);
            error_class_fb_table = hex2dec(dataHex(1,:));
            % Check the Values of set Class-DAC
            if (error_class_fb_table == 0)  
                disp('Feedback table set successfully \n!')
            else
                disp('Feedback table set NOT successfully \n!')
            end
        end

        %% Get Feedback Table
        % Routine to get the Feedback Table parameters, 
        % these parameters are stored in the FB_table property of the class
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function get_feedback_table(self)
            fb_table = [];
            % send command
            result = self.sendCommand(self.GET_FEEDBACK, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_FEEDBACK);
            dataDec = hex2dec(dataHex);
            dataDec = uint8(dataDec);
            self.reset_read_BT_counter();
            for i = 1:self.FB_NUM_CHANNELS
                fb_table(i).enable                  = self.read_BT(dataDec, 1, 'uint8');
                fb_table(i).channel                 = self.read_BT(dataDec, 1, 'uint8');
                fb_table(i).activation_sensor       = self.read_BT(dataDec, 1, 'uint8');
                fb_table(i).activation_comparison   = self.read_BT(dataDec, 1, 'uint8');
                fb_table(i).activation_threshold    = self.read_BT(dataDec, 1, 'single');
                fb_table(i).deactivation_sensor     = self.read_BT(dataDec, 1, 'uint8');
                fb_table(i).deactivation_comparison = self.read_BT(dataDec, 1, 'uint8');
                fb_table(i).deactivation_threshold  = self.read_BT(dataDec, 1, 'single');
                fb_table(i).feedback_modality       = self.read_BT(dataDec, 1, 'uint8');
                fb_table(i).period_value            = self.read_BT(dataDec, 1, 'uint16');
                fb_table(i).activation_period_perc  = self.read_BT(dataDec, 1, 'uint8');
                fb_table(i).specialHandGrasp        = self.read_BT(dataDec, 1, 'uint8');
            end
            self.fb_table = fb_table;
        end


        %% Set Calibration Routine Params
        % Routine to set the Calibration Routine parameters, 
        % these parameters have to be previously stores in the CR_params property of the class.
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function set_CR_params(self)

            % Segmentation and Incremental States
            segmMode = self.CR_params.SM;
            incrMode = self.CR_params.IM;

            % General Information
            enable = self.CR_params.enable;
            frac = self.CR_params.frac;
            time = self.CR_params.time;
            bufferLength = self.CR_params.bufferLength;
            actLevel_thresh_hand = self.CR_params.actLevel_thresh_hand;
            actLevel_thresh_wrist = self.CR_params.actLevel_thresh_wrist;

            % Assemble the Data for LimbMATE
            general_information = [];
            general_information = self.write_BT(general_information, uint8(segmMode) );
            general_information = self.write_BT(general_information, uint8(incrMode) );
            general_information = self.write_BT(general_information, uint8(enable) );
            general_information = self.write_BT(general_information, [typecast(single(frac), "uint8")]' );
            general_information = self.write_BT(general_information, uint8(time) );
            general_information = self.write_BT(general_information, uint8(bufferLength) );
            general_information = self.write_BT(general_information, [typecast(uint16(actLevel_thresh_hand), "uint8")]' );
            general_information = self.write_BT(general_information, [typecast(uint16(actLevel_thresh_wrist), "uint8")]' );

            % Send the Initial Payload
            result = self.sendCommand(self.SET_CR_PARAMS, general_information, length(general_information));
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.SET_CR_PARAMS);
            % Wait the 7.5 msec
            pause(7.5/1000);
            
            error_set_CR_params = hex2dec(dataHex(1,:));
            % Check the Values of CR params
            if (error_set_CR_params == 0)  
                disp('CR parameters set successfully \n!')
            else
                disp('CR parameters set NOT successfully \n!')
            end
        end

        %% Get Calibration Routine Params
        % Routine to Get the Calibration Routine parameters, 
        % these parameters are stored in the CR_params property of the class.
        % @param[in] none
        % @return none
        %-----------------------------------------------------------------
        function get_CR_params(self) 

            % Clear CR struct
            self.CR_params = [];
            % send command to get the First Package
            result = self.sendCommand(self.GET_CR_PARAMS, 0, 0);
            if (result ~= 0)
                % error message and exit
                error('LM: error connecting to device.')
            end
            dataHex = self.receiveReply(self.GET_CR_PARAMS);
            dataDec = hex2dec(dataHex);
            dataDec = uint8(dataDec);

            % General Information
            self.reset_read_BT_counter();

            % Segmentation and Incremental States
            segmMode = self.read_BT(dataDec, 1, 'uint8');
            incrMode = self.read_BT(dataDec, 1, 'uint8');

            % General Information
            enable = self.read_BT(dataDec, 1, 'uint8');
            frac = self.read_BT(dataDec, 1, 'single');
            time = self.read_BT(dataDec, 1, 'uint8');
            bufferLength = self.read_BT(dataDec, 1, 'uint8');
            actLevel_thresh_hand = self.read_BT(dataDec, 1, 'uint16');
            actLevel_thresh_wrist = self.read_BT(dataDec, 1, 'uint16');
            
            % Save on the CR_params struct
            self.CR_params.SM = segmMode;
            self.CR_params.IM = incrMode;

            self.CR_params.enable = enable;
            self.CR_params.frac = frac;
            self.CR_params.time = time;
            self.CR_params.bufferLength = bufferLength;
            self.CR_params.actLevel_thresh_hand = actLevel_thresh_hand;
            self.CR_params.actLevel_thresh_wrist = actLevel_thresh_wrist;

        end



        %% Encode Start Acquisition Parameters
        % Routine to Encode the ADS parameters
        % @param[in] active_channels_v:     Vector of the Active Channels
        % @param[in] samples_tw:            Number of samples of a TW
        % @param[in] samples_tw_overlap:    Number of samples of a TW overlap
        % @return active_channels_encoded 
        % @return samples_tw_encoded 
        % @return samples_tw_overlap_encoded 
        %-----------------------------------------------------------------
        function [active_channels_encoded, samples_tw_encoded, samples_tw_overlap_encoded] = encode_start_acq_param(self, active_channels_v, samples_tw, samples_tw_overlap) 
            
            % Decode the parameters
            active_channels_bin = '';
            for i = 1 : self.EMG_NUM_CHANNELS
                if active_channels_v(i) == 1
                    active_channels_bin = strcat(active_channels_bin, '1');
                else
                    active_channels_bin = strcat(active_channels_bin, '0');
                end
            end
            active_channels_encoded = uint8(bin2dec(active_channels_bin));

            switch samples_tw
                case 100
                    samples_tw_encoded = 1;
                case 200
                    samples_tw_encoded = 2;
                otherwise
                    samples_tw_encoded = 1;
            end
            switch samples_tw_overlap
                case 0
                   samples_tw_overlap_encoded = 0;
                case 25
                    samples_tw_overlap_encoded = 1;
                case 50
                    samples_tw_overlap_encoded = 2;
                case 75
                    samples_tw_overlap_encoded = 3;
                case 100
                    samples_tw_overlap_encoded = 4;
                otherwise
                    samples_tw_overlap_encoded = 0;
            end
        end


        %% Initialise Graphical Parameters - LimbMATE_GUI >> Acquisition tab
        % Routine to Initialise some graphical Parameters for the plot on LimbMATE_GUI >> Acquisition tab
        % @param[in] active_channels_v:     Vector of the Active Channels
        % @return none
        %-----------------------------------------------------------------
        function initialise_graphical_parameters(self, active_channels_v) 

            self.graphical.color_lines = [[0.7,0,0]; [0,0.7,0]; [0,0,0.7]; [0,0.7,0.7]; [0.7,0.7,0]; [0.7,0,0.7]; [0.7,0.7,0.7]; [0.2,0.2,0.2]];
            self.graphical.xlim_scroll = 2;
            self.graphical.shift_scale_factor = 1.3;
            self.streaming_ymin = -0.01; self.streaming_ymax = 0.01;

            % Initialise the animatedLines
            for num_ch = 1:self.EMG_NUM_CHANNELS
                % Clear Plots
                clearpoints(self.Streaming_plots.h_line{num_ch});
                % Verical Line to the begin
                self.Streaming_plots.v_axes{num_ch}.Value = 0;
                % Limits
                xlim(self.Streaming_plots.plot{num_ch}, [0, self.graphical.xlim_scroll]) 
                ylim(self.Streaming_plots.plot{num_ch}, [self.streaming_ymin, self.streaming_ymax]) 
            end
        end

        %% Initialise MAV Graphical Parameters - LimbMATE_GUI >> Direct Control tab
        % Routine to Initialise some graphical Parameters for the plot on LimbMATE_GUI >> Direct Control tab
        % @param[in] active_channels_v:     Vector of the Active Channels
        %  
        %-----------------------------------------------------------------
        function initialise_graphical_parameters_MAV(self, active_channels_v) 
            self.graphical.color_lines = [[0.7,0,0]; [0,0.7,0]; [0,0,0.7]; [0,0.7,0.7]; [0.7,0.7,0]; [0.7,0,0.7]; [0.7,0.7,0.7]; [0.2,0.2,0.2]];
            % Iterate for each plot
            for iPLot = 1:self.EMG_NUM_CHANNELS
                chIndex = self.DC_params.params{iPLot}.ADS_chIndex;

                % Clear Plots
                clearpoints(self.DC_plots.h_line{iPLot});
                % Verical Line to the begin
                self.DC_plots.v_axes{iPLot}.Value = 0;

                % Update ylim
                if chIndex > 250
                    % DoF Plot
                    ylim(self.DC_plots.plot{iPLot}, [- 0.01, 100])
                    ylabel(self.DC_plots.plot{iPLot}, 'Act Level [%]')
                else
                    ylim(self.DC_plots.plot{iPLot}, [- 0.01, 0.01])
                    ylabel(self.DC_plots.plot{iPLot}, 'MAV [mV]')
                end
                    
            end
            % Other variables
            self.graphical.shift_scale_factor = 1.3;
        end

        %% Initialise Feature_Control Graphical Parameters - LimbMATE_GUI >> Control tab
        % Routine to Initialise some graphical Parameters for the plot on LimbMATE_GUI >> Control tab
        % @param[in] active_channels_v:     Vector of the Active Channels
        % @return none
        %-----------------------------------------------------------------
        function initialise_graphical_parameters_feature_control(self, active_channels_v, seconds_acquisition, seconds_increment) 

            self.graphical.color_lines = [[0.7,0,0]; [0,0.7,0]; [0,0,0.7]; [0,0.7,0.7]; [0.7,0.7,0]; [0.7,0,0.7]; [0.7,0.7,0.7]; [0.2,0.2,0.2]];

            self.graphical.color_bands = [
                [0.7010 0.7010 0.7010]; % "Rest"
                [0.8500 0.0000 0.0000]; % "Op H"
                [0.5500 0.0000 0.0000]; % "Cl H"
                [0.0000 0.8500 0.0000]; % "Pron W"
                [0.0000 0.4500 0.0000]; % "Sup W"
                [0.0000 0.0000 0.8500]; % "Flex W"
                [0.0000 0.0000 0.4500]; % "Ext W"
                [0.3010 0.3010 0.3010]; % "Flex E"
                [0.3010 0.3010 0.3010]; % "Ext E"
                [0.3010 0.3010 0.3010]; % "Next Gr"
                [0.5500 0.3500 0.0000]; % "Lateral"
                [0.5500 0.0000 0.3500]; % "Pinch"
                [0.5500 0.0000 0.0000]];% "Cylindrical"
            self.graphical.color_bands_alpha = [
                0.15; % "Rest"
                0.15; % "Op H"
                0.40; % "Cl H"
                0.25; % "Pron W" 
                0.30; % "Sup W" 
                0.15; % "Flex W"
                0.30; % "Ext W"
                0.10; % "Flex E"
                0.80; % "Ext E"
                0.45; % "Next Gr"
                0.80; % "Lateral"
                0.60; % "Pinch"
                0.40];% "Cylindrical"
            
            % Clear the Animated Lines of Features
            for num_ch = 1:self.EMG_NUM_CHANNELS
                clearpoints(self.Control_plots.OutIndexPlot.h_line{num_ch});
            end
            % Verical Line to the begin
            self.Control_plots.OutIndexPlot.v_axes.Value = 0;
            self.Control_plots.OutIndexPlot.v_axes.Color = self.graphical.color_bands(1,:); 
            % Lim
            xlim(self.Control_plots.OutIndexPlot.plot, [0, round(seconds_acquisition / seconds_increment)*seconds_increment;])
            ylim(self.Control_plots.OutIndexPlot.plot, [-0.05, 0.01])
            % Title and Labels
            title(self.Control_plots.OutIndexPlot.plot, self.graphical.featType);
            switch self.graphical.featType
                case 'MAV'
                    ylabel(self.Control_plots.OutIndexPlot.plot, 'MAV [mV]')
                case 'STD'
                    ylabel(self.Control_plots.OutIndexPlot.plot, 'STD [mV]')
                case 'WL'
                    ylabel(self.Control_plots.OutIndexPlot.plot, 'WL [mV]')
                case 'ZC'
                    ylabel(self.Control_plots.OutIndexPlot.plot, 'ZC [/]')
                case 'SLP'
                    ylabel(self.Control_plots.OutIndexPlot.plot, 'SLP [/]')
                otherwise
                    ylabel(self.Control_plots.OutIndexPlot.plot, 'None')
            end
            % Remove previous Xregion Control
            if self.graphical.enableFinalPlot
                if isgraphics(self.Control_plots.OutIndexPlot.xr)
                    delete(self.Control_plots.OutIndexPlot.xr)
                    self.Control_plots.OutIndexPlot = rmfield(self.Control_plots.OutIndexPlot,'xr');
                end
                % Remove previous Xregion Feedback
                if isgraphics(self.Control_plots.GraspPositionPlot.xr_fb)
                    delete(self.Control_plots.GraspPositionPlot.xr_fb)
                    self.Control_plots.GraspPositionPlot = rmfield(self.Control_plots.GraspPositionPlot,'xr_fb');
                end
            end

            % Clear the Animated Lines of Activation Levels
            for iActLevel = 1:self.NUM_DOF
                clearpoints(self.Control_plots.ActivationLevelPlot.h_line{iActLevel});
            end
            % Verical Line to the begin
            self.Control_plots.ActivationLevelPlot.v_axes.Value = 0;
            self.Control_plots.ActivationLevelPlot.v_axes.Color = self.graphical.color_bands(1,:); 
            % Lim
            xlim(self.Control_plots.ActivationLevelPlot.plot, [0, round(seconds_acquisition / seconds_increment)*seconds_increment;])
            ylim(self.Control_plots.ActivationLevelPlot.plot, [-1, 100])

            % Define the Animated Lines of Hand Parameters
            % In Any Case Check The possibility to show the Feedback or IMU Data
            title_names = [""];
            switch self.graphical.handInfoType
                case 'Feedback'
                    self.graphical.GraspInformation_curves = 8;
                    title_names = ["Ch1", "Ch2", "Ch3", "Ch4", "Ch5", "Ch6", "Ch7", "Ch8"];
                    title(self.Control_plots.GraspPositionPlot.plot, 'Feedback Stimulation Ongoing')
                    ylabel(self.Control_plots.GraspPositionPlot.plot, 'FB Stim. On. [0-1]')
                    ylim(self.Control_plots.GraspPositionPlot.plot, [-0.5, 1.5])
                case 'IMU'
                    self.graphical.GraspInformation_curves = 6;
                    title_names = ["Acc X", "Acc Y", "Acc Z", "Gyr X", "Gyr Y", "Gyr Z"];
                    title(self.Control_plots.GraspPositionPlot.plot, 'IMU [dm/s^2] and [°/sec]')
                    ylabel(self.Control_plots.GraspPositionPlot.plot, 'Imu Values')
                    ylim(self.Control_plots.GraspPositionPlot.plot, [self.min_imu, self.max_imu])
                 case 'Position'
                    if self.handInUse == self.MIA_HAND_NAME
                        self.graphical.GraspInformation_curves = 4;
                        title_names = ["T Close %", "MRL Close %", "I+  Close %", "I- Close %"];
                        title(self.Control_plots.GraspPositionPlot.plot, 'Grasp Position ')
                        ylabel(self.Control_plots.GraspPositionPlot.plot, 'Grasp Pos.')
                        ylim(self.Control_plots.GraspPositionPlot.plot, [-1, 100])
                    end
                case 'Force'
                    if self.handInUse == self.MIA_HAND_NAME
                        self.graphical.GraspInformation_curves = 3;
                        title_names = ["T Force ", "MRL Force", "I Force"];
                        title(self.Control_plots.GraspPositionPlot.plot, ' Grasp Force [mN] ')
                        ylabel(self.Control_plots.GraspPositionPlot.plot,' Grasp Force [mN] ')
                        ylim(self.Control_plots.GraspPositionPlot.plot, [self.min_force, self.max_force])
                    end
                case 'Current'
                    if self.handInUse == self.MIA_HAND_NAME
                        self.graphical.GraspInformation_curves = 3;
                        title_names = ["T Current ", "MRL Current", "I Current"];
                        title(self.Control_plots.GraspPositionPlot.plot, ' Grasp Current [mA] ')
                        ylabel(self.Control_plots.GraspPositionPlot.plot, ' Grasp Current [mA] ')
                        ylim(self.Control_plots.GraspPositionPlot.plot, [self.min_current, self.max_current])
                    end
                otherwise
                    if self.handInUse == self.OTTOBOCK_SENSORHAND_NAME || self.handInUse == self.MICHELANGELO_HAND_NAME  || self.handInUse == self.OTTOBOCK_NAME
                        self.graphical.GraspInformation_curves = 8;
                        title_names = ["DAC 1", "DAC 2", "DAC 3", "DAC 4", "DAC 5", "DAC 6", "DAC 7", "DAC 8"];
                        title(self.Control_plots.GraspPositionPlot.plot, 'DAC Voltages [V]')
                        ylabel(self.Control_plots.GraspPositionPlot.plot, 'DAC Voltages [V] [0-5]')
                        ylim(self.Control_plots.GraspPositionPlot.plot, [-0.1, self.max_DAC])
                    elseif  self.handInUse == self.GENERIC_HAND_NAME
                        self.graphical.GraspInformation_curves = 1;
                        title_names = ["General Grasp Position"];
                        title(self.Control_plots.GraspPositionPlot.plot, 'Grasp Position Information')
                        ylabel(self.Control_plots.GraspPositionPlot.plot, 'Grasp Pos. Info.')
                        ylim(self.Control_plots.GraspPositionPlot.plot, [-0.5, 1.5])
                    % No Information
                    else
                        title(self.Control_plots.GraspPositionPlot.plot, 'None')
                        ylabel(self.Control_plots.GraspPositionPlot.plot, 'None')
                        ylim(self.Control_plots.GraspPositionPlot.plot, [-0.5, 1.5])
                    end
            end
            legend(self.Control_plots.GraspPositionPlot.plot, title_names, 'AutoUpdate','off');
            % Clear the Animated Lines of Hand Parameters
            for iGraspInformation = 1:self.FB_NUM_CHANNELS
                clearpoints(self.Control_plots.GraspPositionPlot.h_line{iGraspInformation});
            end
            % Verical Line to the begin
            self.Control_plots.GraspPositionPlot.v_axes.Value = 0;
            self.Control_plots.GraspPositionPlot.v_axes.Color = self.graphical.color_bands(1,:); 
            % Lim
            xlim(self.Control_plots.GraspPositionPlot.plot, [0, round(seconds_acquisition / seconds_increment)*seconds_increment;])

        end

         %% Initialise Feature_Control Graphical Parameters - LimbMATE_GUI >> Control tab
        % Routine to Initialise some graphical Parameters for the plot on LimbMATE_GUI >> Control tab
        % @param[in] active_channels_v:     Vector of the Active Channels
        % @return none
        %   
        %-----------------------------------------------------------------
        function final_plots(self, active_channels_v, seconds_acquisition, seconds_increment, outIdx, rawGraspInformation) 
            % Create the Region for Each Class
            ending_condition = round(seconds_acquisition / seconds_increment);
            ending_time = ending_condition*seconds_increment;
            pos_ind_mat = zeros(ending_condition, 2);
            samples_v = seconds_increment:seconds_increment:ending_time;
            for i_ind = 1:ending_condition
                pos_ind_mat(i_ind,:) = [samples_v(i_ind)-seconds_increment/2, samples_v(i_ind)+seconds_increment/2];
            end
            self.Control_plots.OutIndexPlot.xr = xregion(self.Control_plots.OutIndexPlot.plot, pos_ind_mat, FaceColor=[1,1,1], FaceAlpha=0.15); 
            self.Control_plots.GraspPositionPlot.xr_fb = xregion(self.Control_plots.GraspPositionPlot.plot, pos_ind_mat, FaceColor=[1,1,1], FaceAlpha=0.15); 
            for iTW = 1:length(outIdx)
                outIndex = outIdx(iTW);
                if outIndex == 0
                    self.Control_plots.OutIndexPlot.xr(iTW).FaceColor = self.graphical.color_bands(1,:);
                    self.Control_plots.OutIndexPlot.xr(iTW).FaceAlpha = self.graphical.color_bands_alpha(1,:);
                elseif outIndex == bitshift(1, 6) % Flexion Elbow
                    self.Control_plots.OutIndexPlot.xr(iTW).FaceColor = self.graphical.color_bands(8,:);
                    self.Control_plots.OutIndexPlot.xr(iTW).FaceAlpha = self.graphical.color_bands_alpha(8,:);
                elseif outIndex == bitshift(1, 7) % Extension Elbow
                    self.Control_plots.OutIndexPlot.xr(iTW).FaceColor = self.graphical.color_bands(9,:);
                    self.Control_plots.OutIndexPlot.xr(iTW).FaceAlpha = self.graphical.color_bands_alpha(9,:);
                elseif outIndex == 255 % Next Grasp
                    self.Control_plots.OutIndexPlot.xr(iTW).FaceColor = self.graphical.color_bands(10,:);
                    self.Control_plots.OutIndexPlot.xr(iTW).FaceAlpha = self.graphical.color_bands_alpha(10,:);
                elseif outIndex == self.LATERAL % Lateral
                    self.Control_plots.OutIndexPlot.xr(iTW).FaceColor = self.graphical.color_bands(11,:); 
                    self.Control_plots.OutIndexPlot.xr(iTW).FaceAlpha = self.graphical.color_bands_alpha(11,:); 
                elseif outIndex == self.PINCH % Pinch
                    self.Control_plots.OutIndexPlot.xr(iTW).FaceColor = self.graphical.color_bands(12,:); 
                    self.Control_plots.OutIndexPlot.xr(iTW).FaceAlpha = self.graphical.color_bands_alpha(12,:);
                elseif outIndex == self.CYLIND % Cylindrical
                    self.Control_plots.OutIndexPlot.xr(iTW).FaceColor = self.graphical.color_bands(13,:); 
                    self.Control_plots.OutIndexPlot.xr(iTW).FaceAlpha = self.graphical.color_bands_alpha(13,:);
                else
                    outIndex_bin = bitget((outIndex), 8:-1:1,'uint8');
                    new_color = zeros(1, 3);
                    new_alpha = zeros(1, 3);
                    % Open Hand
                    if outIndex_bin(8) == 1
                        new_color(1) = self.graphical.color_bands(2,1);
                        new_alpha(1) = self.graphical.color_bands_alpha(2);
                    % Close Hand
                    elseif outIndex_bin(7) == 1
                        new_color(1) = self.graphical.color_bands(3,1);
                        new_alpha(1) = self.graphical.color_bands_alpha(3);
                    end
                    % Pronation Wrist
                    if outIndex_bin(6) == 1
                        new_color(2) = self.graphical.color_bands(4,2);
                        new_alpha(2) = self.graphical.color_bands_alpha(4);
                    % Supination Wrist
                    elseif outIndex_bin(5) == 1
                        new_color(2) = self.graphical.color_bands(5,2);
                        new_alpha(2) = self.graphical.color_bands_alpha(5);
                    end
                    % Flexion Wrist
                    if outIndex_bin(4) == 1
                        new_color(3) = self.graphical.color_bands(6,3);
                        new_alpha(3) = self.graphical.color_bands_alpha(6);
                    % Extension Wrist
                    elseif outIndex_bin(3) == 1
                        new_color(3) = self.graphical.color_bands(7,3);
                        new_alpha(3) = self.graphical.color_bands_alpha(7);
                    end
                    % Flexion Wrist
                    if outIndex_bin(2) == 1
                        new_alpha = ones(1, 3) .* self.graphical.color_bands_alpha(8);
                    % Extension Wrist
                    elseif outIndex_bin(1) == 1
                        new_alpha = ones(1, 3) .* self.graphical.color_bands_alpha(9);
                    end

                    if sum(new_color) == 1
                        % Unexpected Output
                        self.Control_plots.OutIndexPlot.xr(iTW).FaceColor = [1,1,1];
                        self.Control_plots.OutIndexPlot.xr(iTW).FaceAlpha = 1;
                    else
                        % Mixed Output
                        self.Control_plots.OutIndexPlot.xr(iTW).FaceColor = new_color;
                        self.Control_plots.OutIndexPlot.xr(iTW).FaceAlpha = max(new_alpha);
                    end
                end

                % Add the Feedback in the last Plot
                offset_parameters = 10;
                GraspInformation = self.decode_graspInformation(rawGraspInformation);
                for iGraspInformation = 1:self.FB_NUM_CHANNELS
                    % Add the new data  
                    if (GraspInformation(iGraspInformation + offset_parameters, iTW) == 1)
                        new_color_fb = self.graphical.color_lines(iGraspInformation, :);
                        self.Control_plots.GraspPositionPlot.xr_fb(iTW).FaceColor = new_color_fb;
                    end
                end

            end
            
        end

        %% Update Graphical Parameters - LimbMATE_GUI >> Acquisition tab
        % Routine to Initialise some graphical Parameters for the plot on LimbMATE_GUI >> Acquisition tab
        % @param[in] active_channels_v:     Vector of the Active Channels
        % @param[in] samples_tw:            Number of samples of a TW
        % @param[in] temp_timer_TW:         Time Vector of the TE
        % @param[in] EMG_data_TW:           EMG Data of the TW
        % @return    none
        % 
        %-----------------------------------------------------------------
        function update_graphical_parameters(self, active_channels_v, samples_tw)
            % Get the Information
            temp_timer_TW = self.graphical_information.full_timer_TW;
            EMG_data_TW = self.graphical_information.EMG_data_TW;
            
            % Modify the ylim
            current_ymin = 0; current_ymax = 0;
            for num_ch = 1:self.EMG_NUM_CHANNELS
                if active_channels_v(num_ch) == 1
                    current_ymin = min(current_ymin, min(EMG_data_TW(num_ch, :)));
                    current_ymax = max(current_ymax, max(EMG_data_TW(num_ch, :)));
                end
            end
            % Both Changed
            if current_ymin < self.streaming_ymin && current_ymax > self.streaming_ymax
                self.streaming_ymin = current_ymin;
                self.streaming_ymax = current_ymax;
                for num_ch = 1:self.EMG_NUM_CHANNELS
                     if active_channels_v(num_ch) == 1
                        ylim(self.Streaming_plots.plot{num_ch}, [self.streaming_ymin, self.streaming_ymax]);
                     end
                end
            % Only y-min changed
            elseif current_ymin < self.streaming_ymin
                self.streaming_ymin = current_ymin;
                for num_ch = 1:self.EMG_NUM_CHANNELS
                    if active_channels_v(num_ch) == 1
                        ylim(self.Streaming_plots.plot{num_ch}, [self.streaming_ymin, self.streaming_ymax]);
                    end
                end
            % Only y-max changed
            elseif current_ymax > self.streaming_ymax
                 self.streaming_ymax = current_ymax;
                 for num_ch = 1:self.EMG_NUM_CHANNELS
                     if active_channels_v(num_ch) == 1
                        ylim(self.Streaming_plots.plot{num_ch}, [self.streaming_ymin, self.streaming_ymax]);
                     end
                end
            end
            
            % Move the Window
            for num_ch = 1:self.EMG_NUM_CHANNELS
                if temp_timer_TW(end) > self.graphical.xlim_scroll/self.graphical.shift_scale_factor
                    xlim(self.Streaming_plots.plot{num_ch}, [temp_timer_TW(end)-self.graphical.xlim_scroll/self.graphical.shift_scale_factor, temp_timer_TW(end) - self.graphical.xlim_scroll/self.graphical.shift_scale_factor + self.graphical.xlim_scroll])
                end
            end
    
            % Set the new datapoints
            % Refresh Parameters
            for num_ch = 1:self.EMG_NUM_CHANNELS
                if active_channels_v(num_ch) == 1
                    % Add the Data
                    addpoints(self.Streaming_plots.h_line{num_ch}, temp_timer_TW(1:2:end), (EMG_data_TW(num_ch, 1:2:end)));

                    % Move the Pointer
                    self.Streaming_plots.v_axes{num_ch}.Value =  temp_timer_TW(end);
                end
            end
            drawnow limitrate
        end

        %% Update MAV Graphical Parameters MAV - LimbMATE_GUI >> Direct Control tab
        % Routine to Initialise some graphical Parameters for the plot on LimbMATE_GUI >> Direct Control tab
        % @param[in] active_channels_v:     Vector of the Active Channels
        % @param[in] MAV:                   MAV Data of the TW
        % @return    none
        % 
        %-----------------------------------------------------------------
        function update_graphical_parameters_MAV(self, active_channels_v, samples_tw)
            % Get the info from the class
            control_cycle_time = self.graphical_information.control_cycle_time;
            streamed_MAV = self.graphical_information.streamed_MAV;
            actLevels = double(self.graphical_information.actLevels) ./ 255 .* 100;
            % Set the new datapoints  
            for iPLot = 1:self.EMG_NUM_CHANNELS
                chIndex = self.DC_params.params{iPLot}.ADS_chIndex;
                % DoF Plot
                if chIndex > 250 
                    % Move the Pointer
                    self.DC_plots.v_axes{iPLot}.Value = control_cycle_time(end);
                    % If required the Act Level, plot it
                    if chIndex == 251 
                        % Put the Act Level OH/CH Wrist
                        addpoints(self.DC_plots.h_line{iPLot}, control_cycle_time, actLevels(1,:) );
                    elseif chIndex == 252 
                        % Put the Act Level PR/SU Wrist
                        addpoints(self.DC_plots.h_line{iPLot}, control_cycle_time, actLevels(2,:) );
                    elseif chIndex == 253 
                        % Put the Act Level FL/EX Wrist
                        addpoints(self.DC_plots.h_line{iPLot}, control_cycle_time, actLevels(3,:) );
                    elseif chIndex == 254 
                        % Put the Act Level FL/EX Elbow
                        addpoints(self.DC_plots.h_line{iPLot}, control_cycle_time, actLevels(4,:) );
                    end
                else
                    if active_channels_v(chIndex) == 1 
                        % Move the Pointer
                        self.DC_plots.v_axes{iPLot}.Value = control_cycle_time(end);
                        % Otherwise plot the MAV
                        % Update ylim
                        ylim(self.DC_plots.plot{iPLot}, [self.MAV_min_v(chIndex) - 0.01, self.MAV_max_v(chIndex)])
                        % Put the MAV on the graph
                        addpoints(self.DC_plots.h_line{iPLot}, control_cycle_time, streamed_MAV(chIndex,:));
                    end
                end
            end
                
            drawnow limitrate
        
        end

        %% Update Feature Control  - LimbMATE_GUI >> Control tab
        % Routine to Initialise some graphical Parameters for the plot on LimbMATE_GUI >> Direct Control tab
        % @param[in] active_channels_v:     Vector of the Active Channels
        % @param[in] iTW:                   Position of the required Feature in the temp_features_control property of the class
        % @return    none
        % 
        %-----------------------------------------------------------------
        function update_graphical_parameters_feature_control(self, active_channels_v, samples_tw)
            % Get the info from the class
            control_cycle_time = self.graphical_information.control_cycle_time;
            switch self.graphical.featType
                case 'MAV'
                    streamed_MAV = self.graphical_information.streamed_MAV;
                case 'STD'
                    streamed_STD = self.graphical_information.streamed_STD;
                case 'WL'
                    streamed_WL = self.graphical_information.streamed_WL;
                case 'ZC'
                    streamed_ZC = self.graphical_information.streamed_ZC;
                case 'SLP'
                    streamed_SLP = self.graphical_information.streamed_SLP;
                otherwise
                    % No features to plot
            end
            outIndexes = self.graphical_information.outIndexes;
            actLevels = self.graphical_information.actLevels;
            rawGraspInformation = self.graphical_information.rawGraspInformation;
            % Move the Pointers
            if self.graphical.enableClass
                self.Control_plots.OutIndexPlot.v_axes.Value =  control_cycle_time(end);
            end
            if self.graphical.enableActLevel
                self.Control_plots.ActivationLevelPlot.v_axes.Value =  control_cycle_time(end);
            end
            self.Control_plots.GraspPositionPlot.v_axes.Value =  control_cycle_time(end);
            

            % Update
            % Set the new datapoints
            for num_ch = 1:self.EMG_NUM_CHANNELS
                if active_channels_v(num_ch) == 1
                    switch self.graphical.featType
                        case 'MAV'
                            % Update the ylim if necessary
                            maximum_MAV =  max(streamed_MAV(num_ch, :), [], "all");
                            if (maximum_MAV > self.MAV_max)
                                self.MAV_max = maximum_MAV * 1.2;
                            end
                            plot_feature =  streamed_MAV(num_ch, :);
                            ylim(self.Control_plots.OutIndexPlot.plot, [-0.01, self.MAV_max])
                            % Add the new data
                            addpoints(self.Control_plots.OutIndexPlot.h_line{num_ch}, control_cycle_time, plot_feature);
                        case 'STD'
                            % Update the ylim if necessary
                            maximum_STD =  max(streamed_STD(num_ch, :), [], "all");
                            if (maximum_STD > self.STD_max)
                                self.STD_max = maximum_STD * 1.2;
                            end
                            plot_feature =  streamed_STD(num_ch, :);
                            ylim(self.Control_plots.OutIndexPlot.plot, [-0.01, self.STD_max])
                            % Add the new data
                            addpoints(self.Control_plots.OutIndexPlot.h_line{num_ch}, control_cycle_time, plot_feature);
                        case 'WL'
                            % Update the ylim if necessary
                            maximum_WL =  max(streamed_WL(num_ch, :), [], "all");
                            if (maximum_WL > self.WL_max)
                                self.WL_max = maximum_WL * 1.2;
                            end
                            plot_feature =  streamed_WL(num_ch, :);
                            ylim(self.Control_plots.OutIndexPlot.plot, [-0.01, self.WL_max])
                            % Add the new data
                            addpoints(self.Control_plots.OutIndexPlot.h_line{num_ch}, control_cycle_time, plot_feature);
                        case 'ZC'
                            % Update the ylim if necessary
                            maximum_ZC =  max(streamed_ZC(num_ch, :), [], "all");
                            if (maximum_ZC > self.ZC_max)
                                self.ZC_max = maximum_ZC * 1.2;
                            end
                            plot_feature =  streamed_ZC(num_ch, :);
                            ylim(self.Control_plots.OutIndexPlot.plot, [-0.01, self.ZC_max])
                            % Add the new data
                            addpoints(self.Control_plots.OutIndexPlot.h_line{num_ch}, control_cycle_time, plot_feature);
                        case 'SLP'
                            % Update the ylim if necessary
                            maximum_SLP =  max(streamed_SLP(num_ch, :), [], "all");
                            if (maximum_SLP > self.SLP_max)
                                self.SLP_max = maximum_SLP * 1.2;
                            end
                            plot_feature =  streamed_SLP(num_ch, :);
                            ylim(self.Control_plots.OutIndexPlot.plot, [-0.01, self.SLP_max])
                            % Add the new data
                            addpoints(self.Control_plots.OutIndexPlot.h_line{num_ch}, control_cycle_time, plot_feature);
                        otherwise
                            % No features to plot
                    end
                end
            end    

            % Activation Levels
            if self.graphical.enableActLevel
                for iActLevel = 1:self.NUM_DOF
                    % Add the new data
                    addpoints(self.Control_plots.ActivationLevelPlot.h_line{iActLevel}, control_cycle_time,  double(actLevels(iActLevel, :)) ./255 .*100 ); % [% MVC]
                end
            end
            

            % Grasp Information
            GraspInformation = self.decode_graspInformation(rawGraspInformation);
            % In Any Case check for the Possibility of Feedback / IMU
            switch self.graphical.handInfoType
                case 'Feedback'
                    offset_parameters = 10;
                    for iGraspInformation = 1:self.graphical.GraspInformation_curves
                        % Add the new data  
                        addpoints(self.Control_plots.GraspPositionPlot.h_line{iGraspInformation}, control_cycle_time,  GraspInformation(iGraspInformation + offset_parameters, :) );
                    end
                case 'IMU'
                    offset_parameters = 10+self.FB_NUM_CHANNELS;
                    % Update ylim if necessary
                    imu_values = GraspInformation(1 + offset_parameters : self.graphical.GraspInformation_curves + offset_parameters, :);
                    imu_values(1:3, :) = imu_values(1:3, :) .* self.BMI323_ACCEL_CONVERSION_4G_SENS .* 10; % [dm/s^2]
                    imu_values(3+1:end, :) = imu_values(3+1:end, :) .* self.BMI323_GYRO_CONVERSION_250_DPS_SENS; % [°/s]
                            
                    min_imu = min(imu_values(:));
                    if min_imu < self.min_imu
                        self.min_imu = min_imu;
                        ylim(self.Control_plots.GraspPositionPlot.plot, [self.min_imu, self.max_imu])
                    end
                    max_imu = max(imu_values(:));
                    if max_imu > self.max_imu
                        self.max_imu = max_imu;
                        ylim(self.Control_plots.GraspPositionPlot.plot, [self.min_imu, self.max_imu])
                    end

                    for iGraspInformation = 1:self.graphical.GraspInformation_curves
                        % Add the new data  
                        addpoints(self.Control_plots.GraspPositionPlot.h_line{iGraspInformation}, control_cycle_time,  imu_values(iGraspInformation, :) );
                    end

                case 'Position'
                    if self.handInUse == self.MIA_HAND_NAME
                        offset_parameters = 0;
                        grasp_position = GraspInformation(1 + offset_parameters : self.graphical.GraspInformation_curves + offset_parameters, :);
                        % Plot the Data
                        for iGraspInformation = 1 : self.graphical.GraspInformation_curves
                            % Add the new data  
                            addpoints(self.Control_plots.GraspPositionPlot.h_line{iGraspInformation}, control_cycle_time,  grasp_position(iGraspInformation, :) .* 100 ./255 ); % [closure %]
                        end
                    end
                case 'Force'
                    if self.handInUse == self.MIA_HAND_NAME
                        offset_parameters = 4;
                        force_values = single(GraspInformation(1 + offset_parameters : self.graphical.GraspInformation_curves + offset_parameters, :));
                        % Tommaso Correction for the Thumb
                        pos_thumb =  GraspInformation(1, :);
                        force_values(1, :) = force_values(1, :) .* 0.105 ./ cosd(22 + 0.23 .* double(pos_thumb)) .* 1000; % [mN]
                        % Other Fingers
                        force_values(2:end, :) = force_values(2:end, :) .* 4.134 ./ 53 .* 1000; % [mN]
                        % Update ylim if necessary
                        min_force = min(force_values(:));
                        if min_force < self.min_force
                            self.min_force = min_force;
                            ylim(self.Control_plots.GraspPositionPlot.plot, [self.min_force, self.max_force])
                        end
                        max_force = max(force_values(:));
                        if max_force > self.max_force
                            self.max_force = max_force;
                            ylim(self.Control_plots.GraspPositionPlot.plot, [self.min_force, self.max_force])
                        end
                        % Plot the Data
                        for iGraspInformation = 1:self.graphical.GraspInformation_curves
                            addpoints(self.Control_plots.GraspPositionPlot.h_line{iGraspInformation}, control_cycle_time,  force_values(iGraspInformation, :) ); % [mN]
                        end
                    end
                case 'Current'
                    if self.handInUse == self.MIA_HAND_NAME
                        offset_parameters = 7;
                        % Update ylim if necessary
                        current_values = single(GraspInformation(1 + offset_parameters : self.graphical.GraspInformation_curves + offset_parameters, :)) ./ 0.750 ; % [mA]
                        min_current = min(current_values(:));
                        min_current
                        if min_current < self.min_current
                            self.min_current = min_current;
                            ylim(self.Control_plots.GraspPositionPlot.plot, [self.min_current, self.max_current])
                        end
                        max_current = max(current_values(:));
                        if max_current > self.max_current
                            self.max_current = max_current;
                            ylim(self.Control_plots.GraspPositionPlot.plot, [self.min_current, self.max_current])
                        end
                        % Plot the Data
                        for iGraspInformation = 1:self.graphical.GraspInformation_curves
                            % Add the new data  
                            addpoints(self.Control_plots.GraspPositionPlot.h_line{iGraspInformation}, control_cycle_time,  current_values(iGraspInformation, :) ); % [mA]
                        end
                    end

                otherwise
                    if self.handInUse == self.OTTOBOCK_SENSORHAND_NAME || self.handInUse == self.MICHELANGELO_HAND_NAME  || self.handInUse == self.OTTOBOCK_NAME
                        % Update ylim if necessary
                        DAC_values = GraspInformation(1:self.graphical.GraspInformation_curves, :);
                        max_DAC = max(DAC_values(:));
                        if max_DAC > self.max_DAC
                            self.max_DAC = max_DAC;
                            ylim(self.Control_plots.GraspPositionPlot.plot, [-0.1, self.max_DAC])
                        end
                        % Plot the Data
                        for iGraspInformation = 1:self.graphical.GraspInformation_curves
                            % Add the new data  
                            addpoints(self.Control_plots.GraspPositionPlot.h_line{iGraspInformation}, control_cycle_time,  GraspInformation(iGraspInformation, :));
                        end
                    elseif self.handInUse == self.GENERIC_HAND_NAME
                        for iGraspInformation = 1:self.graphical.GraspInformation_curves
                            % Add the new data  
                            addpoints(self.Control_plots.GraspPositionPlot.h_line{iGraspInformation}, control_cycle_time,  GraspInformation(iGraspInformation, :));
                        end
                    else
                        % None
                    end
            end
                             
            % Represent the class as a color of the updaetd region
            if self.graphical.enableClass
                num_control_cycles = length(outIndexes);
                for ioutIndex = 1:num_control_cycles
                    outIndex = outIndexes(ioutIndex);
                    iTW = self.plot_index_counter;
                    if outIndex == 0
                        self.Control_plots.OutIndexPlot.v_axes.Color = self.graphical.color_bands(1,:);  
                        self.Control_plots.OutIndexPlot.v_axes.Alpha = self.graphical.color_bands_alpha(1,:); 
                    elseif outIndex == 255
                        self.Control_plots.OutIndexPlot.v_axes.Color = self.graphical.color_bands(8,:); 
                        self.Control_plots.OutIndexPlot.v_axes.Alpha = self.graphical.color_bands_alpha(8,:); 
                    elseif outIndex == bitshift(1, 6) % Flexion Elbow
                        self.Control_plots.OutIndexPlot.v_axes.Color = self.graphical.color_bands(8,:);
                        self.Control_plots.OutIndexPlot.v_axes.Alpha = self.graphical.color_bands_alpha(8,:);
                    elseif outIndex == bitshift(1, 7) % Extension Elbow
                        self.Control_plots.OutIndexPlot.v_axes.Color = self.graphical.color_bands(9,:);
                        self.Control_plots.OutIndexPlot.v_axes.Alpha = self.graphical.color_bands_alpha(9,:);
                    elseif outIndex == self.LATERAL % Lateral
                        self.Control_plots.OutIndexPlot.v_axes.Color = self.graphical.color_bands(11,:); 
                        self.Control_plots.OutIndexPlot.v_axes.Alpha = self.graphical.color_bands_alpha(11,:); 
                    elseif outIndex == self.PINCH % Pinch
                        self.Control_plots.OutIndexPlot.v_axes.Color = self.graphical.color_bands(12,:); 
                        self.Control_plots.OutIndexPlot.v_axes.Alpha = self.graphical.color_bands_alpha(12,:);
                    elseif outIndex == self.CYLIND % Cylindrical
                        self.Control_plots.OutIndexPlot.v_axes.Color = self.graphical.color_bands(13,:); 
                        self.Control_plots.OutIndexPlot.v_axes.Alpha = self.graphical.color_bands_alpha(13,:);
                    else
                        outIndex_bin = bitget((outIndex), 8:-1:1,'uint8');
                        new_color = zeros(1, 3);
                        new_alpha = zeros(1, 3);
                        % Open Hand
                        if outIndex_bin(8) == 1
                            new_color(1) = self.graphical.color_bands(2,1);
                            new_alpha(1) = self.graphical.color_bands_alpha(2);
                        % Close Hand
                        elseif outIndex_bin(7) == 1
                            new_color(1) = self.graphical.color_bands(3,1);
                            new_alpha(1) = self.graphical.color_bands_alpha(3);
                        end
                        % Pronation Wrist
                        if outIndex_bin(6) == 1
                            new_color(2) = self.graphical.color_bands(4,2);
                            new_alpha(2) = self.graphical.color_bands_alpha(4);
                        % Supination Wrist
                        elseif outIndex_bin(5) == 1
                            new_color(2) = self.graphical.color_bands(5,2);
                            new_alpha(2) = self.graphical.color_bands_alpha(5);
                        end
                        % Flexion Wrist
                        if outIndex_bin(4) == 1
                            new_color(3) = self.graphical.color_bands(6,3);
                            new_alpha(3) = self.graphical.color_bands_alpha(6);
                        % Extension Wrist
                        elseif outIndex_bin(3) == 1
                            new_color(3) = self.graphical.color_bands(7,3);
                            new_alpha(3) = self.graphical.color_bands_alpha(7);
                        end
                        % Flexion Elbow
                        if outIndex_bin(2) == 1
                            new_alpha = ones(1, 3) .* self.graphical.color_bands_alpha(8);
                        % Extension Elbow
                        elseif outIndex_bin(1) == 1
                            new_alpha = ones(1, 3) .* self.graphical.color_bands_alpha(9);
                        end
    
                        if sum(new_color) == 1
                            % Unexpected Output
                            self.Control_plots.OutIndexPlot.v_axes.Color = [1,1,1];
                        else
                            % Mixed Output
                            self.Control_plots.OutIndexPlot.v_axes.Color = new_color;
                            self.Control_plots.OutIndexPlot.v_axes.Alpha = max(new_alpha);
                        end
                    end
                    self.plot_index_counter = self.plot_index_counter + 1;
    
                    % Represent the class as a color of the updaetd region
                    offset_parameters = 10;
                    noFeed = 1;
                    for iGraspInformation = 1:self.FB_NUM_CHANNELS
                        % Add the new data  
                        if (GraspInformation(iGraspInformation + offset_parameters, ioutIndex) == 1)
                            new_color_fb = self.graphical.color_lines(iGraspInformation, :);
                            self.Control_plots.GraspPositionPlot.v_axes.Color = new_color_fb;
                            noFeed = 0;
                        end
                    end
                    if noFeed
                        self.Control_plots.GraspPositionPlot.v_axes.Color = self.graphical.color_bands(1,:);
                    end
                end 
            end

            % VRE movement
            if self.vre_enabled
                outIndex = double(outIndexes);
                actLevel_01  = double(actLevels) ./ 255;
                self.control_VRE_grossoMovements(outIndex, actLevel_01);
                self.control_VRE_grasp(outIndex, actLevel_01);
            end
                
            drawnow limitrate 
        end



        %% Control VRE hand
        % Routine to control the VRE hand
        % @param[in] outIndex:     class 
        % @param[in] actLevel:     Vector of the Active Channels
        % @return    actLevel_mov:          actLevel_mov
        % 
        %-----------------------------------------------------------------
        function actLevel_mov = control_VRE_grossoMovements(self, outIndex, actLevel)

            ack = '';
            % Protocol parameters
            table_DoF = [9; 8; 7; 15]; % Hand, Wrist, Wrist, Elbow

            actLevel_magn = self.max_degree_per_pred .* actLevel; % We can normalise to have the the same °/sec independently on the Sampling Frequency 

            actLevel_OCH = self.summarize_DoF_grossoMovements(outIndex, actLevel_magn(1, :), double(self.OPENHAND), double(self.CLOSEHAND)); % 1: OH, 2: CH
            actLevel_SUPR_W = self.summarize_DoF_grossoMovements(outIndex, actLevel_magn(2, :), double(self.SUPINATIONW), double(self.PRONATIONW)); % 4: PR_W, 8: SU_W
            actLevel_EXFL_W = self.summarize_DoF_grossoMovements(outIndex, actLevel_magn(3, :), double(self.EXTENSIONW), double(self.FLEXIONW)); % 16: FL_W, 32: EX_W
            actLevel_EXFL_E = self.summarize_DoF_grossoMovements(outIndex, actLevel_magn(4, :), double(self.FLEXIONE), double(self.EXTENSIONE)); % 64: FL_E, 128: EX_E

            [actLevel_mov] = [actLevel_OCH; actLevel_SUPR_W; actLevel_EXFL_W; actLevel_EXFL_E];

            final_output = [];
            for iDoF = 1:self.NUM_DOF
                new_out = zeros(self.NUM_CHAR_VR, 1);
                if abs(actLevel_mov(iDoF)) > 0 
                    new_out(1) = self.HANDTYPE;
                    new_out(2) = table_DoF(iDoF);
                    new_out(3) = double(actLevel_mov(iDoF) > 0);
                    new_out(4:5) = self.decompose_num_den(abs(actLevel_mov(iDoF)));
                    final_output = [final_output, new_out];
                end
            end

            % Send Common Commands
            final_output_v = final_output(:);
            if ~isempty(final_output_v)
                fwrite(self.vre_comm, char(final_output_v))
                ack = fread(self.vre_comm, 1); % Read Ack
            end
 
        end

        %% Control VRE hand
        % Routine to control the VRE hand
        % @param[in] outIndex:     class 
        % @param[in] actLevel:     Vector of the Active Channels
        % @return    actLevel_mov:          actLevel_mov
        % 
        %-----------------------------------------------------------------
        function control_VRE_grasp(self, outIndex, actLevel)

            actLevel_magn = self.max_degree_per_pred .* actLevel; % We can normalise to have the the same °/sec independently on the Sampling Frequency 

            % Send Specific Grasps
            self.send_grasp_VRE_command(outIndex, actLevel_magn(1, :), double(self.LATERAL));
            self.send_grasp_VRE_command(outIndex, actLevel_magn(1, :), double(self.PINCH));
            self.send_grasp_VRE_command(outIndex, actLevel_magn(1, :), double(self.CYLIND));

        end


        %% Summarize Degree of Freedom
        % Routine to Summarise 2 Movewments in 1 DoF
        % @param[in] outIndex: Index of the class
        % @param[in] actLevel: Values of the DoF
        % @param[in] label1: Class 1
        % @param[in] label2: Class 2
        % @return: actLevel_DoF: Proportional Value
        % 
        %-----------------------------------------------------------------
        function actLevel_DoF = summarize_DoF_grossoMovements(self, outIndex, actLevel, label1, label2)

            % General output
            index1 = logical((bitand(outIndex, label1) >  0) .* (outIndex ~= self.LATERAL) .* (outIndex ~= self.PINCH) .* (outIndex ~= self.CYLIND));
            index2 = logical((bitand(outIndex, label2) > 0) .* (outIndex ~= self.LATERAL) .* (outIndex ~= self.PINCH) .* (outIndex ~= self.CYLIND));
            if sum(index1 > 0) && sum(index2 > 0)
                actLevel_DoF = sum(actLevel(index1)) - sum(actLevel(index2));
            elseif sum(index1 > 0)
                actLevel_DoF = sum(actLevel(index1));
            elseif sum(index2 > 0)
                actLevel_DoF = sum(-actLevel(index2));
            else
                actLevel_DoF = 0;
            end
        end

        %% Send Grasp VR Command
        % Routine to send a Grasp Command
        % @param[in] outIndex: Index of the class
        % @param[in] actLevel: Values of the DoF
        % @param[in] label1: Class 1
        % @return: actLevel_DoF: Proportional Value
        % 
        %-----------------------------------------------------------------
        function actLevel_grasp = send_grasp_VRE_command(self, outIndex, actLevel, label1)

            % General output
            actLevel_grasp = 0;
            index1 = (outIndex == label1);

            if sum(index1 > 0)
                actLevel_grasp = sum(actLevel(index1));

                new_out = zeros(self.NUM_CHAR_VR, 1);
                new_out(1) = self.HANDTYPE;
                if label1 == self.LATERAL
                    new_out(2) = 13;
                    new_out(3) = 1;
                elseif label1 == self.PINCH
                    new_out(2) = 12;
                    new_out(3) = 1;
                elseif label1 == self.CYLIND
                    new_out(2) = 9;
                    new_out(3) = 0;
                end
                
                new_out(4:5) = self.decompose_num_den(abs(actLevel_grasp));

                fwrite(self.vre_comm, char(new_out))
                ack = fread(self.vre_comm, 1); % Read Ack

            end

        end

        %% Send Grasp VR Command
        % Routine to send a Grasp Command
        % @param[in] outIndex: Index of the class
        % @param[in] actLevel: Values of the DoF
        % @param[in] label1: Class 1
        % @return: actLevel_DoF: Proportional Value
        % @return: correct_grasp: Flag
        % 
        %-----------------------------------------------------------------
        function [actLevel_grasp, correct_grasp] = send_correct_grasp_VRE_command(self, outIndex, actLevel, desired_movements_idx, labelGrasp)

            % General output
            actLevel_grasp = 0;
            correct_grasp = 0;
            index1 = (outIndex == labelGrasp);

            if sum(index1 > 0)
                actLevel_grasp = sum(actLevel(index1));

                new_out = zeros(self.NUM_CHAR_VR, 1);
                new_out(1) = self.HANDTYPE;
                if labelGrasp == self.LATERAL
                    new_out(2) = 13;
                    new_out(3) = 1;
                elseif labelGrasp == self.PINCH
                    new_out(2) = 12;
                    new_out(3) = 1;
                elseif labelGrasp == self.CYLIND
                    new_out(2) = 9;
                    new_out(3) = 0;
                end
                
                new_out(4:5) = self.decompose_num_den(abs(actLevel_grasp));

                % Send the command only if it is the right class
                if sum(desired_movements_idx == labelGrasp) ~= 0
                    correct_grasp = 1;
                    fwrite(self.vre_comm, char(new_out))
                    ack = fread(self.vre_comm, 1); % Read Ack
                end


            end

        end


        %% Convert Single to Num-DEN
        % Routine to Convert Single to Num-DEN
        % @param[in] Number: value to convert in Num-Den
        % @return: num_den: [Num, Den] vector
        % 
        %-----------------------------------------------------------------
        function num_den = decompose_num_den(self, number)
            num_digits = 5; % Constrain the number of digits to avoid unexpected behaviour (probably related to the 'char' conversion) - 5 is the acceptable limmit
            string_decomposed = rats(number, num_digits); 
            position_division = find(string_decomposed == '/');
            if isempty(position_division)
                num = str2double(string_decomposed);
                den = 0; % As required by the protocol
            else
                num = str2double(string_decomposed(1:position_division - 1));
                den = str2double(string_decomposed(position_division + 1 : end));
            end
            num_den = [num, den];
            % num_den = [10, 0];
        end


        %% Reset VRE hand
        % Routine to reset the VRE hand
        % @return    none
        % 
        %-----------------------------------------------------------------
        function reset_VRE_hand(self)
            reset_hand = 1;
            fwrite(self.vre_comm, sprintf('%c%c%c%c', 'r', char(reset_hand), char(0), char(0) ));
            fread(self.vre_comm, 1); % Read Ack
        end

        %% Check ADS Set
        % Routine to check the correctness of the ADS initialization and parameters
        % @param[in] error_detected: value from the Core0 indicating the Error
        % @return none 
        function check_ads_set(self, error_detected)
            switch error_detected
                case self.NO_ERR_CORECORE
                case self.ERR_CC_HEADER
                    disp('Header uncorrect')
                    % error('Header uncorrect');
                case self.ERR_CC_CHECKSUM
                    disp('Checksum uncorrect')
                    % error('Checksum uncorrect');
                case self.ERR_CC_PERIPHERAL
                    disp('Peripheral uncorrect')
                    % error('Peripheral uncorrect');
                case self.ERR_CC_MODALITY
                    disp('Modality uncorrect')
                    % error('Modality uncorrect');
                case self.ERR_CC_DATA
                    disp('Data uncorrect')
                    % error('Data uncorrect');
                case self.ERR_CC_TARGET
                    disp('Target uncorrect')
                    % error('Target uncorrect');
                case self.ERR_SET_ADS
                    disp('Set ADS unsuccessful')
                    % error('Set ADS unsuccessful');
                case self.ERR_CC_WRONG_TRIGGER_C1
                    disp('Wrong Trigger Core1')
                    % error('Wrong Trigger Core1 ');
                case self.ERR_MODALITY_C0
                    disp('Wrong Trigger Core0')
                    % error('Wrong Trigger Core0');
                otherwise
                    error('Unexpected Value on the Message');
            end
        end

        %% Check RTCC Set
        % Routine to check the correctness of the RTCC parameters
        % @param[in] error_detected: value from the RTCC indicating the Error
        % @return none 
        function check_RTCC_set(self, error_detected)
            switch error_detected
                case self.NO_ERR_RTCC
                case self.ERR_RTCC_SEC
                    error('Seconds set RTCC unsuccessful');
                case self.ERR_RTCC_MIN
                    error('Minutes set RTCC unsuccessful');
                case self.ERR_RTCC_HOUR
                    error('Hour set RTCC unsuccessful');
                case self.ERR_RTCC_WDAY
                    error('WeekDay set RTCC unsuccessful');
                case self.ERR_RTCC_DAY
                    error('Day set RTCC unsuccessful');
                case self.ERR_RTCC_MONTH
                    error('Month set RTCC unsuccessful');
                case self.ERR_RTCC_YEAR
                    error('Year set RTCC unsuccessful');
                otherwise
                    error('Unexpected Value on the Message');
            end
        end

        %% Check DAC Set
        % Routine to check the correctness of the DAC parameters
        % @param[in] error_detected: value from the DAC indicating the Error
        % @return none 
        function check_DAC_set(self, error_detected)
            switch error_detected
                case self.NO_ERR_DAC
                case self.ERR_DAC_EXCEEDED_VALUE
                    error('Exceeded the maximum DAC value');
                case self.ERR_DAC_EXCEEDED_CHAN
                    error('Exceeded the maximum Number of channel');
                otherwise
                    error('Unexpected Value on the Message');
            end
        end
    end

    %% Abstact Methods 
    %% Send NeuroStimulation
    % Empty Routine to send a NeuroStimulation Command
    % @param[in] none
    % @return none 
    methods sendNeuroStimulation (Abstract)
    end
    %% Set NeuroStimulation Table
    % Empty Routine to Set a NeuroStimulation Table
    % @param[in] none
    % @return none 
    methods set_neuroStimulation_table (Abstract)
    end
    %% Get NeuroStimulation Table
    % Empty Routine to Get a NeuroStimulation Table
    % @param[in] none
    % @return none 
    methods get_neuroStimulation_table (Abstract)
    end
end



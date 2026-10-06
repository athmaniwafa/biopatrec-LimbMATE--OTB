classdef AcceleGlove < handle
    % AcceleGlove Communication object AcceleGlove
    
    properties(Constant = true)
        THUMB   = 1;    % Sensor index for thumb
        INDEX   = 2;    % Sensor index for index finger
        MIDDLE  = 3;    % Sensor index for middle finger
        RING    = 4;    % Sensor index for ring finger
        PINKY   = 5;    % Sensor index for pinky finger
        PALM    = 6;    % Sensor index for palm

        NSENSORS = 6;

        SUCCESS = 0;    % Success status code
        ERROR   = 1;    % Error status code
    end

    properties 
        ser             % Serial communication object
        sensors         % Accelerometer sensor array
        status          % Status from last function call
        sample_ready    % Indicates if a data sample is ready to process
        last_sample     % Last read sample from AcceleGlove
        callbackFcn     % Data ready callback function
        callbackArgs    % Extra arguments to callback function
    end
    
    methods
        function self = AcceleGlove(comPort)
            % AcceleGlove(comPort) creates an AcceleGlove instance tied to
            % the serial port defined by comPort (must be full port name).
            
            ser = serial(comPort,'BaudRate',38400,'DataBits',8, ...
                        'StopBits',1,'Parity','none', ...
                        'FlowControl','none', 'ByteOrder','BigEndian');
            fopen(ser);
            if ~strcmp(ser.Status,'open')
                self.status = AcceleGlove.ERROR;
                return
            end
            fwrite(ser,'b','char')
            try
                fread(ser,18,'uint8');
            catch
                fprintf('Unable to open port.\n');
                self.status = AcceleGlove.ERROR;
                fclose(ser);
                return
            end
            fclose(ser);
            
            self.sensors = [AcceleSensor(), AcceleSensor(), AcceleSensor(), ...
                            AcceleSensor(), AcceleSensor(), AcceleSensor()];
            self.ser = ser;
            self.sample_ready = 0;
            self.last_sample = zeros(self.NSENSORS*3,1);
            self.callbackFcn = [];
            self.callbackArgs = {};
            self.status = AcceleGlove.SUCCESS;
        end
        
        function self = get_reading(self)
            % GET_READING  
            
            try
                fopen(self.ser);
                fwrite(self.ser,'b','char');
                sData = fread(self.ser,18,'uint8');
            catch
                fprintf('Unable to read data\n');
                fclose(self.ser);
                self.status = AcceleGlove.ERROR;
                return
            end
            fclose(self.ser);
            
            % Reshape data
            sData = reshape(sData,3,6)';
            
            for s = 1:length(self.sensors)
                self.sensors(s).update(sData(s,:));
            end
        end
        
        function self = update(self)
            % UPDATE 
            
            self.sample_ready = 0;
            
            try
                if strcmp(self.ser.Status,'closed')
                    fopen(self.ser);
                end
                % Read binary sensor data
                fwrite(self.ser,'b','char');
            catch
                fprintf('Unable to read data\n');
                fclose(self.ser);
                self.status = AcceleGlove.ERROR;
                return
            end
        end
        
        function data = wait_for_data(self, timeout)
            tic();
            while ~self.sample_ready
                delta = toc();
                if delta > timeout
                    fprintf('AcceleGlove data timeout!\n');
                    self.status = AcceleGlove.ERROR;
                    data = [];
                    return
                end
            end
            self.status = AcceleGlove.SUCCESS;
            data = self.last_sample;
        end
        
        function self = start_acquisition(self, callback, varargin)
            if nargin > 1
                self.callbackFcn = callback;
                self.callbackArgs = varargin;
            else
                self.callbackFcn = [];
                self.callbackArgs = {};
            end
            
            try
                if strcmp(self.ser.Status,'open')
                    fclose(self.ser);
                end
                
                self.ser.BytesAvailableFcnMode = 'byte';
                self.ser.BytesAvailableFcnCount = 18;
                self.ser.BytesAvailableFcn = @self.Serial_OnDataReceived;
                
                fopen(self.ser);
            catch
                fprintf('Unable to open port\n');
                self.status = AcceleGlove.ERROR;
            end
            
            self.sample_ready = 0;
        end
        
        function self = Serial_OnDataReceived(self,varargin)
            try
                if strcmp(self.ser.Status,'closed')
                    fopen(self.ser);
                end
                % Read binary sensor data
                sData = fread(self.ser,18,'uint8');
            catch
                fprintf('Unable to read data\n');
                fclose(self.ser);
                self.status = AcceleGlove.ERROR;
                return
            end
            
            % Reshape data
            sData = reshape(sData,3,6)';
            
            for s = 1:self.NSENSORS
                self.sensors(s).update(sData(s,:));

                idx = (s-1)*3+1;
                self.last_sample(idx:idx+2) = ...
                    [self.sensors(s).x_accel, ...
                     self.sensors(s).y_accel, ...
                     self.sensors(s).z_accel];
            end
            
            if ~isempty(self.callbackFcn)
                self.callbackFcn(self, self.callbackArgs);
            end
            
            self.sample_ready = 1;
        end
        
        function self = stop_acquisition(self)
            %
            try
                if strcmp(self.ser.Status,'open')
                    fclose(self.ser);
                end
                self.ser.BytesAvailableFcn = '';
            catch
                fprintf('Unable to close the port.\n');
                self.status = AcceleGlove.ERROR;
            end
            
            self.sample_ready = 0;
        end
        
        % Returns the angle (in degrees) of wrist along Y-axis
        function angle = get_wrist_pronation(self)
            angle = self.sensors(AcceleGlove.PALM).y_angle;
        end
        
        % Returns the angle (in degrees) of wrist along X-axis
        function angle = get_wrist_flexion(self)
            angle = self.sensors(AcceleGlove.PALM).x_angle;
        end
        
        % Returns the angle (in degrees) of index finger along X-axis
        function angle = get_finger_flexion(self)
            angle = self.sensors(AcceleGlove.MIDDLE).x_angle - self.sensors(AcceleGlove.PALM).x_angle;
        end
    end
end

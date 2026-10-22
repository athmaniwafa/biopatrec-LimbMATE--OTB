classdef AcceleSensor < handle
    properties(Constant = true)
        X_AXIS  = 1;
        Y_AXIS  = 2;
        Z_AXIS  = 3;
        RAD2DEG = 180.0/pi;

        % Calibrated scale and bias factors
        % 0-255 maps to +/- 1G
        SCALE   = 2.0/255;
        BIAS    = 1.0;
        
        % Uncalibrated scale and bias factors
        % These still need to be calculated
        U_BIAS  = 512;
        U_SCALE = 1;
    end
    
    properties
        x_accel
        y_accel
        z_accel
        
        x_angle
        y_angle
    end
    
    methods
        function self = AcceleSensor()
            self.x_accel = 0;
            self.y_accel = 0;
            self.z_accel = 0;
            
            self.x_angle = 0;
            self.y_angle = 0;
        end
        
        function self = update(self, sData)
            self.x_accel = sData(AcceleSensor.X_AXIS)*self.SCALE - self.BIAS;
            self.y_accel = sData(AcceleSensor.Y_AXIS)*self.SCALE - self.BIAS;
            self.z_accel = sData(AcceleSensor.Z_AXIS)*self.SCALE - self.BIAS;
            
            yz_accel = sqrt(self.y_accel^2 + self.z_accel^2);
            xz_accel = sqrt(self.x_accel^2 + self.z_accel^2);
            
            self.x_angle = atan2(self.y_accel,-sign(self.z_accel)*xz_accel)*self.RAD2DEG;
            self.y_angle = atan2(-self.x_accel,yz_accel)*self.RAD2DEG;
        end
        
        function self = update_raw(self, sData)
            self.x_accel = sData(AcceleSensor.X_AXIS)*self.U_SCALE - self.U_BIAS;
            self.y_accel = sData(AcceleSensor.Y_AXIS)*self.U_SCALE - self.U_BIAS;
            self.z_accel = sData(AcceleSensor.Z_AXIS)*self.U_SCALE - self.U_BIAS;
            
            self.x_angle = atan2(self.y_accel,-self.z_accel)*self.RAD2DEG;
            self.y_angle = atan2(self.z_accel, self.x_accel)*self.RAD2DEG;
        end
    end
end

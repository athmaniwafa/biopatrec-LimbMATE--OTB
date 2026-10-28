classdef MIA_Acquire < handle
    properties
        io
        port
    end
    methods
        function obj = MIA_Acquire(port)
            obj.port = port;
            % Open Serial Port at 115200 baud (from your protocol file)
            obj.io = serialport(port, 115200);
            obj.io.configureTerminator('CR');
            
            % Send Complete Calibration command
            writeline(obj.io, '@AK0000000000000*');
            disp('[MIA] Hand Connected and Calibrated.');
        end
        
        function sendMotorCommand(obj, motor, direction, speed)
            % Format: @ [Motor] S [Sign] [Position] [Speed] *
            % Example from your file: '@1S+000055550000*'
            cmd = sprintf('@%dS%s0000%02d0000*', motor, direction, speed);
            writeline(obj.io, cmd);
        end
        
        function disconnect(obj)
            if ~isempty(obj.io)
                delete(obj.io);
            end
            disp('[MIA] Hand disconnected.');
        end
    end
end
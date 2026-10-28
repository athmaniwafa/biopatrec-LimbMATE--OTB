classdef MIA_Acquire < handle
    properties
        io
    end
    methods
        function obj = MIA_Acquire(comPort)
            % Open port at 115200 baud as per your protocol file
            obj.io = serialport(comPort, 115200);
            obj.io.configureTerminator('CR');
            
            % Send Complete Calibration Command (From your file)
            writeline(obj.io, '@AK0000000000000*'); 
            disp('[MIA] Hand connected and calibrated.');
        end
        
        function sendMotor(obj, motorID, direction, speed, position)
            % direction: '+' or '-'
            % speed: '00' to '99'
            % position: '0000' to '0255'
            if motorID == 1
                fprintf('[MIA] Commanding Motor 1 (Thumb)\n');
            elseif motorID == 2
                fprintf('[MIA] Commanding Motor 2 (Fingers)\n');
            end
            cmd = sprintf('@%dS%s%s%s00*', motorID, direction, position, speed);
            writeline(obj.io, cmd);
        end
        
        function sendGrasp(obj, graspType)
            % graspType: 'C' (cylindrical), 'P' (pinch), 'L' (lateral)
            cmd = sprintf('@AG%sA05055000000*', graspType);
            writeline(obj.io, cmd);
        end
        
        function disconnect(obj)
            if ~isempty(obj.io)
                delete(obj.io);
                disp('[MIA] Hand disconnected.');
            end
        end
    end
end
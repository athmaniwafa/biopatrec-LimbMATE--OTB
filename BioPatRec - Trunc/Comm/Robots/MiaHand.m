classdef MiaHand < handle
    % MiaHand: serial control of the Mia hand.
    %   m = MiaHand(7)        % port number
    %   m = MiaHand('COM7')   % port name
    %   m.calibrate();        % ~8 s, blocking (do it before EMG streaming)
    %   m.act('Close Hand');  % used by RealtimePatRec
    %   m.close(); m.open();  % direct control

    properties
        s                       % serialport object
        lastMov     = '';       % last command actually sent via act()
        lastActTime = uint64(0);% tic of last command sent via act()
        minInterval = 0.8;      % s, minimum time between act() commands
    end

    properties (Constant)
        CMD_CLOSE = '@AGeC070060.....*';   % close grasp
        CMD_OPEN  = '@AGeR070060.....*';   % rest / open
        CMD_PINCH = '@AGeP070060.....*';   % fine grip
        CMD_LAT   = '@AGeL070060.....*';   % side (lateral) grip
        CMD_CAL   = '@AK0000000000000*';   % calibration
    end

    methods
        function obj = MiaHand(port)
            if isnumeric(port)
                port = sprintf('COM%d', port);
            end
            obj.s = serialport(char(port), 115200);
            configureTerminator(obj.s, 'CR');
            obj.lastActTime = tic;
        end

        function calibrate(obj)
            fprintf('[Mia] calibrating (8 s)...\n');
            writeline(obj.s, obj.CMD_CAL);
            pause(8);
            fprintf('[Mia] calibration done.\n');
            obj.lastMov = '';
            obj.lastActTime = tic;
        end

        function close(obj)
            fprintf('[Mia] -> CLOSE\n');
            writeline(obj.s, obj.CMD_CLOSE);
        end

        function open(obj)
            fprintf('[Mia] -> OPEN\n');
            writeline(obj.s, obj.CMD_OPEN);
        end

        function act(obj, mov)
            % Map a BioPatRec movement name to a Mia command.
            % Repeats are ignored and commands are rate limited.
            % Rest / unknown names do nothing.
            mov = strtrim(char(mov));
            if strcmp(mov, obj.lastMov), return; end
            if toc(obj.lastActTime) < obj.minInterval, return; end

            switch mov
                case 'Close Hand', cmd = obj.CMD_CLOSE;
                case 'Open Hand',  cmd = obj.CMD_OPEN;
                case 'Fine Grip',  cmd = obj.CMD_PINCH;
                case 'Side Grip',  cmd = obj.CMD_LAT;
                otherwise, return;
            end

            try
                writeline(obj.s, cmd);
                fprintf('[Mia] -> "%s"\n', mov);
                obj.lastMov = mov;          % only after a successful write
                obj.lastActTime = tic;
            catch ME
                warning('MiaHand:writeFailed', 'Write failed: %s', ME.message);
            end
        end

        function delete(obj)
            % Open the hand when the object is destroyed
            try, writeline(obj.s, obj.CMD_OPEN); catch, end
        end
    end
end
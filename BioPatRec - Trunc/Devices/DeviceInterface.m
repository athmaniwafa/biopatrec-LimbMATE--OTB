classdef DeviceInterface < handle
    methods (Abstract)
        start(obj, cfg)        % Begin streaming
        data = read(obj, n)    % Read n samples, returns (n x nCh)
        stop(obj)              % Stop streaming
        disconnect(obj)        % Close connection
    end
end
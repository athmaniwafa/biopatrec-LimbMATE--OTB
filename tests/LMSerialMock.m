classdef LMSerialMock < handle
    properties
        bytes = uint8([])
        writes = {}
    end
    properties (Dependent)
        NumBytesAvailable
    end
    methods
        function self = LMSerialMock(bytes)
            if nargin, self.bytes = uint8(bytes); end
        end
        function n = get.NumBytesAvailable(self), n = numel(self.bytes); end
        function data = read(self,N,~)
            data = self.bytes(1:N);
            self.bytes(1:N) = [];
        end
        function write(self,data,~), self.writes{end+1} = data; end
    end
end

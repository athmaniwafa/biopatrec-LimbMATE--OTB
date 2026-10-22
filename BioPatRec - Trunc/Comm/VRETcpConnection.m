classdef VRETcpConnection < handle
    % Byte-oriented VRE server without Instrument Control Toolbox (Windows).
    properties (SetAccess = private)
        Status = 'closed';
    end
    properties
        Timeout = 15;
    end
    properties (Access = private)
        listener
        client
        stream
    end
    methods
        function obj = VRETcpConnection(port)
            % GUI reloads can discard handles without closing their sockets.
            % Retire only a connection created by this class on the same port.
            persistent connections
            if isempty(connections)
                connections = containers.Map('KeyType','double','ValueType','any');
            end
            port = double(port);
            if isKey(connections, port)
                previous = connections(port);
                if isvalid(previous)
                    previous.fclose();
                end
                remove(connections, port);
            end
            obj.listener = System.Net.Sockets.TcpListener( ...
                System.Net.IPAddress.Parse('127.0.0.1'), int32(port));
            obj.listener.Start();
            connections(port) = obj;
        end
        function fopen(obj)
            deadline = tic;
            while ~obj.listener.Pending()
                if toc(deadline) > obj.Timeout
                    obj.fclose();
                    error('VRE:ConnectionTimeout', ...
                        'La mano virtuale non si e collegata entro %g secondi.', obj.Timeout);
                end
                pause(0.01);
            end
            obj.client = obj.listener.AcceptTcpClient();
            obj.listener.Stop();
            obj.client.NoDelay = true;
            obj.stream = obj.client.GetStream();
            obj.Status = 'open';
        end
        function fwrite(obj, data)
            obj.requireOpen();
            bytes = uint8(data(:));
            obj.stream.WriteTimeout = int32(1000 * obj.Timeout);
            obj.stream.Write(bytes, int32(0), int32(numel(bytes)));
        end
        function data = fread(obj, count)
            obj.requireOpen();
            obj.stream.ReadTimeout = int32(1000 * obj.Timeout);
            data = zeros(count,1);
            for k = 1:count
                try
                    value = obj.stream.ReadByte();
                catch ME
                    obj.fclose();
                    error('VRE:ReadFailed', ...
                        ['La mano virtuale non ha risposto al comando TCP. ' ...
                         'Chiudi e riapri VRE, poi verifica il pulsante Move. Dettaglio: %s'], ...
                        ME.message);
                end
                if value < 0
                    obj.fclose();
                    error('VRE:Disconnected','La mano virtuale ha chiuso la connessione.');
                end
                data(k) = double(value);
            end
        end
        function fclose(obj)
            obj.Status = 'closed';
            if ~isempty(obj.stream), obj.stream.Close(); obj.stream = []; end
            if ~isempty(obj.client), obj.client.Close(); obj.client = []; end
            if ~isempty(obj.listener), obj.listener.Stop(); end
        end
        function delete(obj)
            obj.fclose();
        end
    end
    methods (Access = private)
        function requireOpen(obj)
            if ~strcmp(obj.Status,'open')
                error('VRE:NotConnected','Collega prima la mano virtuale.');
            end
        end
    end
end

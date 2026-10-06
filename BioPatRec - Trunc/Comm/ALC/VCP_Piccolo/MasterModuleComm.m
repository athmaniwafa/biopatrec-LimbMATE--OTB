% ---------------------------- Copyright Notice ---------------------------
% This file is part of BioPatRec © which is open and free software under 
% the GNU Lesser General Public License (LGPL). See the file "LICENSE" for 
% the full license governing this code and copyrights.
%
% BioPatRec was initially developed by Max J. Ortiz C. at Integrum AB and 
% Chalmers University of Technology. All authors’ contributions must be kept
% acknowledged below in the section "Updates % Contributors". 
%
% Would you like to contribute to science and sum efforts to improve 
% amputees’ quality of life? Join this project! or, send your comments to:
% maxo@chalmers.se.
%
% The entire copyright notice must be kept in this or any source file 
% linked to BioPatRec. This will ensure communication with all authors and
% acknowledge contributions here and in the project web page (optional).
%
% -------------------------- Function Description -------------------------
% [Give a short summary about the principle of your function here.]
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 20xx-xx-xx / Author  / Creation
% 20xx-xx-xx / Author  / Comment on update

classdef MasterModuleComm
    %Description
    % Created from mastercom.m made by Marting Magnusson in 2011
    % the use of classes over traditional functions is normally not
    % consider during this developemnt but we gave it a try since MM did it
    % like that already. (probabily we will do this just this time) MO,
    % 11-09-15
    
    
    properties
        io  %Serial Port Object
    end
    
    methods
        %% Comm
        function obj = MasterModuleComm(conn)
            %conn, Connection String
            %Find erial port objects with specified property values
            obj.io=instrfind('Status','open');
            if isempty(obj.io)
                obj.io=serial(conn, 'BaudRate', 14400);
                pause(1)
                % Open io for read and write access
                set(obj.io,'InputBuffer',1024*64)
                fopen(obj.io)
                pause(1)
            end
            
        end
        %% Test Connection
        function result = testConnection(obj)
            %If buffer not empty, 
            if obj.io.BytesAvailable>0
                fread(obj.io,obj.io.BytesAvailable);
            end
            %Send connection test
            fwrite(obj.io,'C');
            pause(0.5);
            if fread(obj.io,1)==1
                result=1;
            else
                result=0;
            end
        end
        %% Read
        function data = read(obj)
            if obj.io.BytesAvailable>0
                data=fread(obj.io,obj.io.BytesAvailable);
            else
                data=0;
                disp('The buffer is empty')
            end
        end
        %% Write
        function data = write(obj,text)
            fwrite(obj.io,text)
        end
        %% Close
        function data=close(obj)
            fclose(obj.io)
        end
        %% Check settings
        function result=checkSettings(obj,ann)
            %Send 'U' to check settings
            fwrite(obj.io,'U')
            %If buffer not empty, 
            if obj.io.BytesAvailable>0
                fread(obj.io,obj.io.BytesAvailable);
            end
            pause(0.1)
            result=1;
            %Send number Inputs
            fwrite(obj.io,ann.nIn,'uint8','async')
            pause(0.1) 
            if fread(obj.io,1)~=ann.nIn;
                disp('Different number of inputs')
                result=0;
                return
            end
            %Send number Hidden neurons
            fwrite(obj.io,ann.nHn,'uint8','async')
            pause(0.1)
            if fread(obj.io,1)~=ann.nHn;
                disp('Different number of hidden neurons')
                result=0;
                return
            end
            %Send number Outputs
            fwrite(obj.io,ann.nOn,'uint8','async')
            pause(0.1) 
            if fread(obj.io,1)~=ann.nOn;
                disp('Different number of outputs')
                result=0;
                return
            end
           pause(0.1)
           disp('Correct settings')            
        end
        %% Set weights
        function result=setWeights(obj,ann)
           %Send 'W' to start set weights
           fwrite(obj.io,'W')
           pause(0.1)
           %If buffer not empty, 
            if obj.io.BytesAvailable>0
                fread(obj.io,obj.io.BytesAvailable);
            end
            pause(0.1)
           result=0;
           nrLayer=length(ann.w(1,1,:));
           %Send first layer
           for iFromNeuron=1:ann.nIn
                for iToNeuron=1:ann.nHn
                    fwrite(obj.io,ann.w(iFromNeuron,iToNeuron,1),'float32','async')
                    pause(0.1)
                end
           end
            
           %Send hidden layer
           if nrLayer>2
               for iLayer=2:(nrLayer-1)
                   for iFromNeuron=1:ann.nHn
                        for iToNeuron=1:ann.nHn
                            fwrite(obj.io,ann.w(iFromNeuron,iToNeuron,iLayer),'float32','async')
                            pause(0.1)
                        end
                   end
               end
           end
           
           %Send output layer
           for iFromNeuron=1:ann.nHn
                for iToNeuron=1:ann.nOn
                    fwrite(obj.io,ann.w(iFromNeuron,iToNeuron,nrLayer),'float32','async')
                    pause(0.1)
                end
           end
           
           if fread(obj.io,1)==1    %If OK
               result=1;
           end
           
        end
        
        %% Set Bias
        function result=setBias(obj,ann)
            %Send 'B' to start set bias
            fwrite(obj.io,'B')
            pause(0.1)
            
            %If buffer not empty, 
            if obj.io.BytesAvailable>0
                fread(obj.io,obj.io.BytesAvailable);
            end
            pause(0.1)
            result=0;
            %Number of layers
            nrLayer=length(ann.b(1,:));
            
            %Send bias for hidden neurons
            for iLayer=1:(nrLayer-1)
                for iNeuron=1:ann.nHn
                    fwrite(obj.io,ann.b(iNeuron,iLayer),'float32','async')
                    pause(0.1)
                end
            end
            
            %Send bias for output neuron
            for iNeuron=1:ann.nOn
                fwrite(obj.io,ann.b(iNeuron,nrLayer),'float32','async')
                pause(0.1)
            end
            
           if fread(obj.io,1)==1    %If OK
               result=1;
           end
                
        end
        
        %% Test ANN
        function output=testAnn(obj,inputs)
            %Send 'T' to test ANN
            fwrite(obj.io,'T')
            pause(0.1)
            
            %If buffer not empty, 
            if obj.io.BytesAvailable>0
                fread(obj.io,obj.io.BytesAvailable);
            end
            pause(0.1)
            
            output=0;
            %Send inputs to device
            for iInput=1:length(inputs)
                fwrite(obj.io,inputs(iInput),'float32','async')
                pause(0.1)
            end
            pause(0.5)
            %Get outputs from device
            output = fread(obj.io,obj.io.BytesAvailable,'float32');
        end
        
        %% Send float
        function data=sendFloat(obj,floatValue)
            %Send float32 with Big-endian
            fwrite(obj.io,floatValue,'float32','async')
        end
        %% Reieved float
        function data=receiveFloat(obj)
            %Receive float32 with Big-endian
            data=fread(obj.io,1,'float32');
        end
    end
end



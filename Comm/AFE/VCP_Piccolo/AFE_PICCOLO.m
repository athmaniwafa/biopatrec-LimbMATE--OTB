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

classdef AFE_PICCOLO<handle
    % obj = AFE_PICCOLO(conn,Fs,Ts,nCh,amplification,vref,dataFormat)
    %
    %   startRecording()
    %   nr = SamplesAcquired()
    %   data = storeFromBuffer()
    
    properties
        io      %Serial Port Object
        Fs      %samplingFrequency (Hz)
        nCh     %Number of Channels
        Ts      %Sample time (sec)
        bytesAcquired %data recived since last data acquisition
        data    %read data buffer
        byteDepth %bytes/sample
        amplification %the Amplification of the AFE, this is order to convert to InputReferredVoltage
        vref %the voltage reference of the ADC,  this is order to convert to InputReferredVoltage
        dataFormat %how the data is received, 1 offsetted, 2 signed.
    end
    
    
    methods
        function obj = AFE_PICCOLO(conn,Fs,Ts,nCh,amplification,vref,dataFormat,tagName,byteDepth,BAUD)
            % obj = AFE_PICCOLO(conn,Fs,Ts,nCh,amplification,vref,dataFormat)
            % obj = AFE_PICCOLO(conn,Fs,Ts,nCh,amplification,vref,dataFormat,tagName,byteDepth,BAUD)
            %
            %   conn            Connection String, ex 'COM1' or '/dev/cu.usbserial-A7006Sdt'
            %   Fs              SamplingFrequency (Hz)
            %   Ts              Sample time (sec)
            %   nCh             Number of Channels
            %   amplification   The amplification of the AFE
            %   vref            The voltage reference of the ADC in the AFE
            %   dataFormat      The format of the data which the AFE is
            %       sending, 1 offsetted, 2 signed
            %   tagName         Device name to tag the serial interface
            %   byteDepth       Bytes/sample, default = 2
            
            if nargin < 7
                error('To few input arguments')
            elseif nargin == 7
                tagName='PICCOLO';
                byteDepth=2;
                BAUD=4800;
            elseif nargin == 8
                byteDepth=2;
                BAUD=4800;
            elseif nargin == 9
                BAUD=4800;
            end
            obj.byteDepth=byteDepth;

            obj.io=instrfind('Tag',tagName);
            if isempty(obj.io)
                obj.io=serial(conn, 'BaudRate', BAUD,'Tag',tagName);
                pause(1)
                % Open io for read and write access, as a file
                set(obj.io,'InputBuffer',640000*3)%1024*64) %Enough buffer inorder to not to lose any data
%                 set(obj.io,'FlowControl','hardware')
                fopen(obj.io);
            else
                if get(obj.io,'BaudRate')~=BAUD
                    set(obj.io,'BaudRate',BAUD)
                end
                if strcmp(get(obj.io,'Status'),'Closed')
                    fopen(obj.io);
                end
            end
            pause(1)
            obj.Fs=Fs;
            obj.nCh=nCh;
            obj.Ts=Ts;
            obj.amplification = amplification;
            obj.vref = vref;
            obj.dataFormat = dataFormat;

            
            % fread(obj.io,obj.io.BytesAvailable)
            
            % send ASCII via serial port I, I for Init
            fwrite(obj.io,'I')
            pause(0.1)
            % send two bytes sampling frequency
            fwrite(obj.io,floor(Fs/256))
            pause(0.1)
            fwrite(obj.io,mod(Fs,256))
            pause(0.1)
            
            % send one byte numberOfSampleSeconds
            fwrite(obj.io, Ts)
            pause(0.1)
            
            % send one byte number of channels
            fwrite(obj.io,nCh)
            
            
            pause(0.1)
            
            disp([ floor(Fs/256) mod(Fs,256) Ts nCh])
        end
        
        function nr = SamplesAcquired(obj)
            nr = floor( (obj.bytesAcquired + obj.io.BytesAvailable) / obj.byteDepth);
        end %End SamplesAcquired
        
        
        function startRecording(obj)
            if obj.io.BytesAvailable > 0
                fread(obj.io,obj.io.BytesAvailable);
            end
            
            obj.bytesAcquired = 0;
            obj.data = [];
            fwrite(obj.io,'S')
            
        end %End startRecording
        
        function data = storeFromBuffer(obj)
            bytesToRead = obj.io.BytesAvailable;
            
            bytesToRead = bytesToRead - mod(bytesToRead,obj.nCh*obj.byteDepth);
            
            [tempData count]=fread(obj.io,[obj.byteDepth,bytesToRead/obj.byteDepth]); 
            
            obj.bytesAcquired = obj.bytesAcquired + count;
            
            temp=ones(1,obj.byteDepth);
            for j=1:obj.byteDepth-1
                temp(j)=256^(obj.byteDepth-j);
            end
            
            tempData=temp*tempData;
            
            if obj.dataFormat==2
                logical=(tempData>=2^(obj.byteDepth*8-1));
                tempData(logical)=tempData(logical)-2^(obj.byteDepth*8);
            elseif obj.dataFormat==1
                tempData=tempData-2^(obj.byteDepth*8-1);
            end
                
            data= reshape(tempData,obj.nCh,(bytesToRead/obj.byteDepth)/obj.nCh)'; % ...
                %-2^(obj.byteDepth*8-1) ) * obj.vref / (obj.amplification*obj.byteDepth*8);
            
        end %End storeFromBuffer
        
        
    end
end

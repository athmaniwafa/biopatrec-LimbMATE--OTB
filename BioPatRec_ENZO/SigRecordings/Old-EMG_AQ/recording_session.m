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
% Funtion to Record Exc Sessions
% Input :
%   Fs = Sampling frequenicy
%   Ne = number of excersices or movements
%   Nr = number of excersice repetition
%   Tc = time that the contractions should last
%   Tr = relaxing time
%   Psr = Porcentage of the signal to record
%   msg = message to be send to the user
%   handles= handles of the axes to plot
% Output = total data and data of interest
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2009-04-17 / Max Ortiz  / Creation
% 2009-06-29 / Max Ortiz  / A dummy repeticion added before start recording
% 2011-06 / Per and Gustav /added the analog front end sections
%20xx-xx /author/ comment on update

function cdata = recording_session(varargin)
%Fs,Ne,Nr,Tc,Tr,Psr,msg,handles,AFE_settings)

filters.PLH=false;   %toggle the PowerLineHarmonics
filters.BP=true;     %toggle the bandpass

Fs=varargin{1};
Ne=varargin{2};
Nr=varargin{3};
Tc=varargin{4};
Tr=varargin{5};
Psr=varargin{6};
msg=varargin{7};
handles=varargin{8};
if nargin == 8      % Check if the afe_settings structure was send
    AFE_settings.ADS.active=0;
    AFE_settings.RHA.active=0;
    AFE_settings.NI.active=1;
    AFE_settings.NI.name='NI';
    AFE_settings.NI.sampleRate=Fs;
    AFE_settings.NI.show=1;
    AFE_settings.NI.ADS=0;
    AFE_settings.NI.RHA=0;
    AFE_settings.prepare=1;
else
    AFE_settings=varargin{9};
end
%Check if AFE_settings is empty %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Initialize plots
% Get number of channels
if AFE_settings.NI.show
    nCh = AFE_settings.NI.channels;
elseif AFE_settings.ADS.show
    nCh = AFE_settings.ADS.channels;
elseif AFE_settings.RHA.show
    nCh = AFE_settings.RHA.channels;    
end

% Create handles for the plots
% this is faster than creating the plot everytime
tt = 0:1/Fs:Tc/100-1/Fs;

if nCh >= 1
    axes(handles.a_t0);
    p_t0 = plot(tt,tt);
    axes(handles.a_f0);
    p_f0 = plot(1,1);
end
if nCh >= 2
    axes(handles.a_t1);
    p_t1 = plot(tt,tt);        
    axes(handles.a_f1);
    p_f1 = plot(1,1);
end
if nCh >= 3
    axes(handles.a_t2);        
    p_t2 = plot(tt,tt);        
    axes(handles.a_f2);
    p_f2 = plot(1,1);
end

if nCh >= 4
    axes(handles.a_t3);        
    p_t3 = plot(tt,tt);
    axes(handles.a_f3);
    p_f3 = plot(1,1);
end

if nCh >= 5
    axes(handles.a_t4);        
    p_t4 = plot(tt,tt);
    %axes(handles.a_f4);
    %p_f4 = plot(1,1);
end

if nCh >= 6
    axes(handles.a_t5);        
    p_t5 = plot(tt,tt);
    %axes(handles.a_f5);
    %p_f5 = plot(1,1);
end

if nCh >= 7
    axes(handles.a_t6);        
    p_t6 = plot(tt,tt);
    %axes(handles.a_f6);
    %p_f6 = plot(1,1);
end

if nCh >= 8
    axes(handles.a_t7);        
    p_t7 = plot(tt,tt);
    %axes(handles.a_f7);
    %p_f7 = plot(1,1);
end

%%
% Initialize DAQ card
Ts = (Tc+Tr)*Nr;                    % Time of contraction + Time of relaxation x Number of repetitions

% Not used anymore since the number of channels is manually selected from
% the GUI_AFESelection
% chp = zeros(4,1);
% if get(handles.cb_ch0,'Value') == 1
%     chp(1)=1;
% end
% if get(handles.cb_ch1,'Value') == 1
%     chp(2)=1;
% end
% if get(handles.cb_ch2,'Value') == 1
%     chp(3)=1;
% end
% if get(handles.cb_ch3,'Value') == 1
%     chp(4)=1;
% end
% 
% Nch = sum(chp);
% % [ai,chp] = init_ai(handles,Fs,Ts);
% % Nch = length(find(chp));            % Number of channels

if AFE_settings.NI.active
    AFE_settings.NI.sampleRate=Fs; %overrides the individual samplerate choise in AFS_select
    ai = Init_NI_AI(handles,AFE_settings.NI.sampleRate,Ts,nCh);
end
if AFE_settings.ADS.active
    Amp=12;
    Vref=2.4*2; %*2 is from bipolar reference
    ByteDepth=3;
    AFE_settings.ADS.sampleRate=Fs;  %overrides the individual samplerate choise in AFS_select
    dataFormat=2;
    ADS = AFE_PICCOLO(AFE_settings.ADS.ComPortType,AFE_settings.ADS.sampleRate, ...
        Ts,nCh,Amp,Vref,dataFormat,AFE_settings.ADS.name,ByteDepth);
end
if AFE_settings.RHA.active
    Amp=200;
    Vref=2.5;
    ByteDepth=2;
    AFE_settings.RHA.sampleRate=Fs;  %overrides the individual samplerate choise in AFS_select
    dataFormat=1;
    RHA = AFE_PICCOLO(AFE_settings.RHA.ComPortType,AFE_settings.RHA.sampleRate, ...
        Ts,nCh,Amp,Vref,dataFormat,AFE_settings.RHA.name,ByteDepth);
end


% allocation of resource to improve speed, total data
tdata = zeros(Fs*Ts,nCh,Ne);
ADStdata = zeros(Fs*Ts,nCh,Ne);
RHAtdata = zeros(Fs*Ts,nCh,Ne);
% Warning to the user
if AFE_settings.prepare
    set(handles.t_msg,'String','Get ready to start: 3');
    pause(1);
    set(handles.t_msg,'String','Get ready to start: 2');
    pause(1);
    set(handles.t_msg,'String','Get ready to start: 1');
    pause(1);
end
relax = importdata('Img/relax.jpg'); % Import Image
for ex = 1 : Ne
    disp(['Start ex: ' num2str(ex) ])
    
    % Warning to the user
    mov = importdata(['Img/mov' num2str(ex) '.jpg']); % Import Image
    set(handles.a_pic,'Visible','on');  % Turn on visibility
    axes(handles.a_pic);        % get handles
    pic = image(mov);           % set image
    axis off;                   % Remove axis tick marks
    if AFE_settings.prepare
        set(handles.t_msg,'String',['Get ready for ' msg(ex) ' in 3 s']);
        pause(1);
        set(handles.t_msg,'String',['Get ready for ' msg(ex) ' in 2 s']);
        pause(1);
        set(handles.t_msg,'String',['Get ready for ' msg(ex) ' in 1 s']);
        %set(handles.a_pic,'Visible','off');  % Turn OFF visibility
        %delete(pic);                          % Delete image
        pause(1);
    end
    % Dummy Contraction
    set(handles.t_msg,'String',msg(ex));
    if AFE_settings.prepare
        pause(Tc);
        set(handles.t_msg,'String','Relax');
        pic = image(relax);           % set image
        axis off;                   % Remove axis tick marks
        pause(Tr);
    end
    %% Start DAQ
    if AFE_settings.NI.active
        start(ai);
    end
    if AFE_settings.ADS.active
        ADS.startRecording
    end
    if AFE_settings.RHA.active
        RHA.startRecording
    end

    for rep = 1 : Nr

        while  AFE_settings.NI.active && AFE_settings.NI.show && (ai.SamplesAcquired < (Tc+Tr)*Fs*rep) || ...
                AFE_settings.ADS.active && AFE_settings.ADS.show && (ADS.SamplesAcquired < (Tc+Tr)*Fs*rep*nCh) || ...
                AFE_settings.RHA.active && AFE_settings.RHA.show && (RHA.SamplesAcquired < (Tc+Tr)*Fs*rep*nCh)
            
            if  AFE_settings.NI.active && AFE_settings.NI.show && (ai.SamplesAcquired <= (Fs*Tc*rep + Fs*Tr*(rep-1)) * 1.1) || ... % this was added to gain some time in flexion
                    AFE_settings.ADS.active && AFE_settings.ADS.show && (ADS.SamplesAcquired <= (Fs*Tc*rep + Fs*Tr*(rep-1)) * nCh) || ...
                    AFE_settings.RHA.active && AFE_settings.RHA.show && (RHA.SamplesAcquired <= (Fs*Tc*rep + Fs*Tr*(rep-1)) * nCh)
                %
                set(handles.t_msg,'String',msg(ex));
                pic = image(mov);           % set image
                axis off;                   % Remove axis tick marks
            else
                set(handles.t_msg,'String','Relax');
                pic = image(relax);           % set image
                axis off;                   % Remove axis tick marks
            end
            drawnow;
            
            %---------------------------------
            if AFE_settings.NI.show
                data = peekdata(ai,Tc*Fs/100);
                data=data/1700; %Converting to input referred voltage
            elseif AFE_settings.ADS.show
                data = ADS.storeFromBuffer;
                %                 data = ADS.getData(Tc*Fs/100*4); %As peekdata but empties buffer and no moving window
                ADS.data = [ADS.data ; data];
                
                if size(ADS.data,1) > (Tc*Fs/100)
                    data = (ADS.data(end-(Tc*Fs/100)+1:end,:) ).* (ADS.vref/(ADS.amplification*2^(ADS.byteDepth*8) )); %Converting to input referred voltage
                else
                    data = zeros((Tc*Fs/100),nCh);
                end
            elseif AFE_settings.RHA.show
                data = RHA.storeFromBuffer;
                %                 data = RHA.getData(Tc*Fs/100*4);
                RHA.data = [RHA.data ; data];
                if size(RHA.data,1) > (Tc*Fs/100)
                    data = (RHA.data(end-(Tc*Fs/100)+1:end,:) ).* (RHA.vref/(RHA.amplification*2^(RHA.byteDepth*8))); %Converting to input referred voltage
                else
                    data = zeros((Tc*Fs/100),nCh);
                end
            end
            
            data = filter_data(data, handles, Fs);  %Filter the data
            
            aNs = length(data(:,1));
            NFFT = 2^nextpow2(aNs);                 % Next power of 2 from number of samples
            f = Fs/2*linspace(0,1,NFFT/2);
            dataf = fft(data(1:aNs,:),NFFT)/aNs;
            m = 2*abs(dataf((1:NFFT/2),:));
            
            
            chi = 1;%Channel Index for map data
            if nCh >= 1
                set(p_t0,'YData',data(:,chi));
                set(p_f0,'XData',f);
                set(p_f0,'YData',m(:,chi));
                chi=chi+1;
            end
            if nCh >= 2
                set(p_t1,'YData',data(:,chi));
                set(p_f1,'XData',f);
                set(p_f1,'YData',m(:,chi));
                chi=chi+1;
            end
            if nCh >= 3
                set(p_t2,'YData',data(:,chi));
                set(p_f2,'XData',f);
                set(p_f2,'YData',m(:,chi));
                chi=chi+1;
            end
            if nCh >= 4
                set(p_t3,'YData',data(:,chi));
                set(p_f3,'XData',f);
                set(p_f3,'YData',m(:,chi));
            end
            if nCh >= 5
                set(p_t4,'YData',data(:,chi));
                chi=chi+1;
                %set(p_f4,'XData',f);
                %set(p_f4,'YData',m(:,chi));
            end
            if nCh >= 6
                set(p_t5,'YData',data(:,chi));
                chi=chi+1;
                %set(p_f5,'XData',f);
                %set(p_f5,'YData',m(:,chi));
            end
            if nCh >= 7
                set(p_t6,'YData',data(:,chi));
                chi=chi+1;
                %set(p_f6,'XData',f);
                %set(p_f6,'YData',m(:,chi));
            end
            if nCh >= 8
                set(p_t7,'YData',data(:,chi));
                %set(p_f7,'XData',f);
                %set(p_f7,'YData',m(:,chi));
            end
            
            
            %---------------------------------
        end

    end
    
    %Check if all data has arrived from the other devices
    while  (AFE_settings.NI.active && (ai.SamplesAcquired < (Tc+Tr)*Fs*Nr)) || ...
            (AFE_settings.ADS.active  && (ADS.SamplesAcquired < (Tc+Tr)*Fs*Nr*nCh)) || ...
            (AFE_settings.RHA.active  && (RHA.SamplesAcquired < (Tc+Tr)*Fs*Nr*nCh))
        
        pause(1)
        disp('Waiting for more data')
        if AFE_settings.NI.active
            disp('NI')
            disp((Tc+Tr)*Fs*Nr-ai.SamplesAcquired)
            disp([ai.SamplesAcquired ai.SamplesAcquired*4])
        end
        if AFE_settings.RHA.active
            disp('RHA')
            disp((Tc+Tr)*Fs*Nr*nCh-RHA.SamplesAcquired)
            disp(RHA.SamplesAcquired)
        end
        if AFE_settings.ADS.active
            disp('ADS')
            disp((Tc+Tr)*Fs*Nr*nCh-ADS.SamplesAcquired)
            disp(ADS.SamplesAcquired)
            disp((Tc+Tr)*Fs*Nr*nCh)
        end
    end
    
    % Save Data
    if AFE_settings.RHA.active
%         disp('RHA:')
%         disp(RHA.SamplesAcquired)
%         disp(RHA.bytesAcquired)
%         disp(size(RHA.data))
        data = [RHA.data ; RHA.storeFromBuffer];
%         disp(size(data))
%         disp(size(RHAtdata))
        RHAtdata(:,:,ex)=data * (RHA.vref/(RHA.amplification*2^(RHA.byteDepth*8))); %Converting to input referred voltage
    end
    if AFE_settings.NI.active
%         disp('NI:')
%         ai.SamplesAcquired
        wait(ai,Ts+1);
        [data,tt,abstime] = getdata(ai);
%         disp(['date = ' num2str(fix(abstime))])
%         size(data)
%         size(tdata)
        tdata(:,:,ex) = data / 1.70e3; %Converting to input referred voltage
    end
    if AFE_settings.ADS.active
%         disp('ADS:')
%         disp(ADS.SamplesAcquired)
%         disp(ADS.bytesAcquired)
%         disp(size(data))
        
        data = [ADS.data ; ADS.storeFromBuffer];
%         disp(size(data))
%         disp(size(ADStdata))
        ADStdata(:,:,ex)=data * (ADS.vref/(ADS.amplification*2^(ADS.byteDepth*8))); %Converting to input referred voltage
    end
    
    
end
set(handles.t_msg,'String','Session Terminated');      % Show message about acquisition
if AFE_settings.NI.active
    stop(ai);
    delete(ai);
end

if AFE_settings.NI.active
    NItdata=tdata;
    NItrdata=computeTrainingData(tdata,Fs,Tc,Tr,Nr,Ne,Psr);
    
    if filters.PLH || filters.BP
        NItdataFiltered=NItdata;
        if filters.PLH
            NItdataFiltered  = BSbutterPLHarmonics(Fs, NItdataFiltered);
        end
        if filters.BP
            NItdataFiltered  = FilterBP_EMG(Fs, NItdataFiltered);
        end
        NItrdataFiltered=computeTrainingData(NItdataFiltered,Fs,Tc,Tr,Nr,Ne,Psr);
    end
else
    NItdata=[];
    NItrdata=[];
end
if AFE_settings.ADS.active
    %     tdata=ADStdata;
    ADStrdata=computeTrainingData(ADStdata,Fs,Tc,Tr,Nr,Ne,Psr);
    
    if filters.PLH || filters.BP
        ADStdataFiltered=ADStdata;
        if filters.PLH
            ADStdataFiltered  = BSbutterPLHarmonics(Fs, ADStdataFiltered);
        end
        if filters.BP
            ADStdataFiltered  = FilterBP_EMG(Fs, ADStdataFiltered);
        end
        ADStrdataFiltered=computeTrainingData(ADStdataFiltered,Fs,Tc,Tr,Nr,Ne,Psr);
    end
else
    ADStdata=[];
    ADStrdata=[];
end
if AFE_settings.RHA.active
    %     tdata=RHAtdata;
    RHAtrdata=computeTrainingData(RHAtdata,Fs,Tc,Tr,Nr,Ne,Psr);
    
    if filters.PLH || filters.BP
        RHAtdataFiltered=RHAtdata;
        if filters.PLH
            RHAtdataFiltered  = BSbutterPLHarmonics(Fs, RHAtdataFiltered);
        end
        if filters.BP
            RHAtdataFiltered  = FilterBP_EMG(Fs, RHAtdataFiltered);
        end
        RHAtrdataFiltered=computeTrainingData(RHAtdataFiltered,Fs,Tc,Tr,Nr,Ne,Psr);
    end
else
    RHAtdata=[];
    RHAtrdata=[];
end


% Save Session to file
% date        = [];%fix(abstime); 
ss.Fs       = Fs;
ss.Ts       = Ts;
ss.Ne       = Ne;
ss.Nr       = Nr;
ss.Tc       = Tc;
ss.Tr       = Tr;
ss.Psr      = Psr;
ss.date     = fix(clock);
ss.msg      = msg;
[filename, pathname] = uiputfile({'*.mat','MAT-files (*.mat)'},'Save as', 'Untitled.mat');
if isequal(filename,0) || isequal(pathname,0)
       disp('User pressed cancel')
    else
       disp(['User selected ', fullfile(pathname, filename)])
       save([pathname,filename(1:end-4), '_session_info_no_data.mat'],'ss');
       if AFE_settings.NI.active
           ss.tdata    = NItdata;
           ss.trdata   = NItrdata;
           %Possible to add string with device info for example ss.device=AFE_settings.NI.name;
           if exist([pathname 'AD2\'],'dir') == 0
               mkdir(pathname,'AD2')
           end
           save([pathname,'AD2\',filename],'ss');
           
           if filters.PLH || filters.BP
               ss.tdata    = NItdataFiltered;
               ss.trdata   = NItrdataFiltered;
               if exist([pathname 'AD2Filtered\'],'dir') == 0
                   mkdir(pathname,'AD2Filtered')
               end
               save([pathname,'AD2Filtered\',filename],'ss');
           end
       end
       if AFE_settings.ADS.active
           ss.tdata    = ADStdata;
           ss.trdata   = ADStrdata; 
           %Possible to add string with device info for example ss.device=AFE_settings.ADS.name;
           if exist([pathname 'ADS1298\'],'dir') == 0
               mkdir(pathname,'ADS1298')
           end
           save([pathname, 'ADS1298\',filename],'ss');
           
           if filters.PLH || filters.BP
               ss.tdata    = ADStdataFiltered;
               ss.trdata   = ADStrdataFiltered;
               if exist([pathname 'ADS1298Filtered\'],'dir') == 0
                   mkdir(pathname,'ADS1298Filtered')
               end
               save([pathname,'ADS1298Filtered\',filename],'ss');
           end
       end
       if AFE_settings.RHA.active
           ss.tdata    = RHAtdata;
           ss.trdata   = RHAtrdata;
           %Possible to add string with device info for example ss.device=AFE_settings.RHA.name;
           if exist([pathname 'RHA2216\'],'dir') == 0
               mkdir(pathname,'RHA2216')
           end
           save([pathname 'RHA2216\',filename],'ss');
           
           if filters.PLH || filters.BP
               ss.tdata    = RHAtdataFiltered;
               ss.trdata   = RHAtrdataFiltered;
               if exist([pathname 'RHA2216Filtered\'],'dir') == 0
                   mkdir(pathname,'RHA2216Filtered')
               end
               save([pathname,'RHA2216Filtered\',filename],'ss');
           end
       end
end

% Copy acquired data from the last excersice into cdata
% Display it

if AFE_settings.NI.show
    data = NItdata(:,:,end);    
elseif AFE_settings.ADS.show
    data = ADStdata(:,:,end).* (ADS.vref/(ADS.amplification*2^(ADS.byteDepth*8)));
elseif AFE_settings.RHA.show
    data = RHAtdata(:,:,end).* (RHA.vref/(RHA.amplification*2^(RHA.byteDepth*8)));
end

chi=1;
if nCh >= 1
    cdata(:,1) = data(:,chi);
    chi=chi+1;
end
if nCh >= 2
    cdata(:,2) = data(:,chi);
    chi=chi+1;
end
if nCh >= 3
    cdata(:,3) = data(:,chi);
    chi=chi+1;
end
if nCh >= 4
    cdata(:,4) = data(:,chi);
    chi=chi+1;
end
if nCh >= 5
    cdata(:,5) = data(:,chi);
    chi=chi+1;
end
if nCh >= 6
    cdata(:,6) = data(:,chi);
    chi=chi+1;
end
if nCh >= 7
    cdata(:,7) = data(:,chi);
    chi=chi+1;
end
if nCh >= 8
    cdata(:,8) = data(:,chi);
end


data_show(handles,cdata,Fs,Ts);
set(handles.a_pic,'Visible','off');  % Turn OFF visibility
delete(pic);        % Delete image
end

function trdata = computeTrainingData(tdata,Fs,Tc,Tr,Nr,Ne,Psr)
%Compute Traning Data

    for ex = 1 : Ne
        tempdata =[];
        for rep = 1 : Nr
            % Samples of the exersice to be consider for training
            % (Fs*Tc*Psr) Number of the samples that wont be consider for training
            % (Fs*Tc*rep) Number of samples that takes a contraction
            % (Fs*Tr*rep) Number of samples that takes a relaxation
            is = (Fs*Tc*Psr) + (Fs*Tc*(rep-1)) + (Fs*Tr*(rep-1)) + 1;
            fs = (Fs*Tc) + (Fs*Tc*(rep-1)) + (Fs*Tr*(rep-1));
            tempdata = [tempdata ; tdata(is:fs,:,ex)];
        end
        trdata(:,:,ex) = tempdata;
    end

end
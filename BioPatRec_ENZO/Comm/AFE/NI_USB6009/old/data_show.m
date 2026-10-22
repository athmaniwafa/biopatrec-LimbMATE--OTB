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
% Funtion to Show the SAVED data on the GUI
% Input = ai object, chp channels pressences
% Output = data and time 
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2009-04-15 / Max Ortiz  / Creation
% 20xx-xx-xx / Author  / Comment on update

function data_show(handles,cdata, Fs, Ts)

    tt  = 0:1/Fs:Ts-1/Fs;            % Create vector of time
    Ns  = length(cdata(:,1));        % It used to be Fs*Ts but due to change in lenght witht training data
    Nch = size(cdata,2);

    %Fast Fourier Transform
    NFFT = 2^nextpow2(Ns);                 % Next power of 2 from number of samples
    f = Fs/2*linspace(0,1,NFFT/2);
    dataf = fft(cdata(1:Ns,:),NFFT)/Ns;    
    m = 2*abs(dataf((1:NFFT/2),:));
    m(1,:) =0; 

    
    if Nch >= 1
        axes(handles.a_t0);
        plot(tt(1:length(cdata(:,1))),cdata(:,1));
        axes(handles.a_f0);
        plot(f,m(:,1));
    end

    if Nch >= 2
        axes(handles.a_t1);
        plot(tt(1:length(cdata(:,1))),cdata(:,2));        
        axes(handles.a_f1);
        plot(f,m(:,2));
    end
    if Nch >= 3
        axes(handles.a_t2);        
        plot(tt(1:length(cdata(:,1))),cdata(:,3));        
        axes(handles.a_f2);
        plot(f,m(:,3));
    end
    if Nch >= 4
        axes(handles.a_t3);        
        plot(tt(1:length(cdata(:,1))),cdata(:,4));
        axes(handles.a_f3);
        plot(f,m(:,4));
    end
    if Nch >= 5
        axes(handles.a_t4);        
        plot(tt(1:length(cdata(:,1))),cdata(:,5));
        %axes(handles.a_f4);
        %plot(f,m(:,5));
    end
    if Nch >= 6
        axes(handles.a_t5);        
        plot(tt(1:length(cdata(:,1))),cdata(:,6));
        %axes(handles.a_f5);
        %plot(f,m(:,6));
    end
    if Nch >= 7
        axes(handles.a_t6);        
        plot(tt(1:length(cdata(:,1))),cdata(:,7));
        %axes(handles.a_f6);
        %plot(f,m(:,7));
    end  
    if Nch >= 8
        axes(handles.a_t7);        
        plot(tt(1:length(cdata(:,1))),cdata(:,8));
        %axes(handles.a_f7);
        %plot(f,m(:,8));
    end    
    
end

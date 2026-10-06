function varargout = GUIcheckFeaturesALCD(varargin)
% GUICHECKFEATURESALCD MATLAB code for GUIcheckFeaturesALCD.fig
%      GUICHECKFEATURESALCD, by itself, creates a new GUICHECKFEATURESALCD or raises the existing
%      singleton*.
%
%      H = GUICHECKFEATURESALCD returns the handle to a new GUICHECKFEATURESALCD or the handle to
%      the existing singleton*.
%
%      GUICHECKFEATURESALCD('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUICHECKFEATURESALCD.M with the given input arguments.
%
%      GUICHECKFEATURESALCD('Property','Value',...) creates a new GUICHECKFEATURESALCD or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUIcheckFeaturesALCD_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUIcheckFeaturesALCD_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUIcheckFeaturesALCD

% Last Modified by GUIDE v2.5 26-Jun-2018 18:40:07

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUIcheckFeaturesALCD_OpeningFcn, ...
                   'gui_OutputFcn',  @GUIcheckFeaturesALCD_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before GUIcheckFeaturesALCD is made visible.
function GUIcheckFeaturesALCD_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUIcheckFeaturesALCD (see VARARGIN)

% Choose default command line output for GUIcheckFeaturesALCD
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = GUIcheckFeaturesALCD_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pb_featcompare.
function pb_featcompare_Callback(hObject, eventdata, handles)
% hObject    handle to pb_featcompare (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    disp('%%%%%%%%%%% Loading Data %%%%%%%%%%%%%');
    set(handles.txt_info,'String','Loading Data...');

    % ss needs to be initialized to avoid conflicts with the class ss of
    % matlab. However, this is only necessary for keeping compatibility
    % with EMG_AQ
    ss = [];
    
    % Dialog box to open a file
    [file, path] = uigetfile({'*.mat';'*.csv'});
    % Check that the loaded file is a "ss" struct
    if ~isequal(file, 0)
        [~,~,ext] = fileparts(file);
        if(strcmp(ext,'.mat'))
            load([path,file]);
            if (exist('recSession','var'))   

                GUIfeatures.data = recSession.tdata(:,:,1);
                GUIfeatures.nCh = recSession.nCh;
                nCh = GUIfeatures.nCh;
                %% CHANGE ME! GUIfeatures.sF = recSession.sF;
                GUIfeatures.sF = 1000;
                nM = 1;
                
            else
                disp('That was not a valid training matrix');
                errordlg('That was not a valid training matrix','Error');
                return;                
            end
        else
            disp('Invalid file format');
            return;
        end
    else
        disp('Operation cancelled by user');
        return;
    end
    
    GUIfeatures.tW = str2double(get(handles.et_tW,'String'))/1000;
    GUIfeatures.iW = str2double(get(handles.et_tWincr,'String'))/1000;
    tWs = GUIfeatures.tW * GUIfeatures.sF;                                 % Samples corresponding Time window
    iWs = GUIfeatures.iW * GUIfeatures.sF;                                 % Samples corresponding Time increment
    oWs = tWs - iWs;
    nW = fix((length(GUIfeatures.data)-tWs)/iWs)+1;
    GUIfeatures.nW = nW;
    waveletSelect = get(handles.pm_wavelet, 'Value');
    
    set(handles.txt_info,'String','Features Extraction on BioPatRec...');
    
    thrShrinkOpts = {'soft','hard','hyperbolic','adaptive','non-negative'};
    
    for e = 1: nM
        for i = 1 : nW
            iidx = 1 + (iWs * (i-1));
            eidx = tWs + (iWs *(i-1));
            if waveletSelect > 1
                tmpWindowedData = MotionFilt(GUIfeatures.data(iidx:eidx,:,e),1000,'ALCD');
                if waveletSelect > 2
                    sigDenoising.waveletType = 'SWT';
                    sigDenoising.waveletName = 'db2';
                    sigDenoising.waveletLevel = 4;
                    sigDenoising.thresholdCycSpin = 0;
                    sigDenoising.thresholdCycSpinNo = 0;
                    sigDenoising.waveletExtWin = 'None';
                    sigDenoising.waveletExtLength = 0;
                    sigDenoising.wienerFilt = 1;
                    sigDenoising.keepApp = 0;
                    sigDenoising.thresholdShrink = thrShrinkOpts{waveletSelect-2};
                    sigDenoising.thresholdSel = 'minimaxi';
                    sigDenoising.thresholdSigma = 'alcd';
                    sigDenoising.thresholdFactor = 1;
                    tmpWindowedData = WaveletSignalDenoising(tmpWindowedData, sigDenoising);
                end
                GUIfeatures.windowedData(:,:,e,i) = tmpWindowedData;
            else
                GUIfeatures.windowedData(:,:,e,i) = GUIfeatures.data(iidx:eidx,:,e);
            end
        end
    end
    
    fData = zeros(nW,5);
    for m = 1: nM
        for i = 1 : nW
            GUIfeatures.BPRfeatures(i,m) = GetSigFeatures(GUIfeatures.windowedData(:,:,m,i),GUIfeatures.sF, {});
            fData(i,1) = mean(GUIfeatures.BPRfeatures(i,1).tmabs);
            fData(i,2) = mean(GUIfeatures.BPRfeatures(i,1).twl);
            fData(i,3) = mean(GUIfeatures.BPRfeatures(i,1).tzc);
            fData(i,4) = mean(GUIfeatures.BPRfeatures(i,1).tslpch2);
            fData(i,5) = mean(GUIfeatures.BPRfeatures(i,1).tstd);
        end
    end
    
    % mean for BioPatRec features
    table = zeros(5,4);
    table(1,1) = mean(fData(:,1));
    table(2,1) = mean(fData(:,2));
    table(3,1) = mean(fData(:,3));
    table(4,1) = mean(fData(:,4));
    table(5,1) = mean(fData(:,5));
    set(handles.tbl_features,'data',table);
    drawnow;
    
    % Send samples to ALC-D and receiving back the filtered samples
    set(handles.txt_info,'String','Features Extraction on ALC-D...');
    
    % Get connection object
    if isfield(handles,'obj')
        obj = handles.obj;
    elseif isfield(handles,'pm_comPort')
        comPorts = get(handles.pm_comPort,'String');
        comPort = comPorts{get(handles.pm_comPort,'Value')};
        obj = serial (comPort, 'baudrate', 460800, 'databits', 8, 'byteorder', 'bigEndian','timeout',10);
    else
        hwInfo = instrhwinfo('serial');
        comPorts = hwInfo.AvailableSerialPorts;
        [indx,~] = listdlg('ListString',comPorts);
        comPort = comPorts{indx};
        obj = serial (comPort, 'baudrate', 460800, 'databits', 8, 'byteorder', 'bigEndian','timeout',10);
    end
    % Open the connection
    fopen(obj);
    % Read available data and discard it
    if obj.BytesAvailable > 1
        fread(obj,obj.BytesAvailable,'uint8');        
    end  
    
    % Set the parameters for features extraction
    FeaturesEnables = zeros(1,5);
    FeaturesEnables(1) = 1;
    FeaturesEnables(2) = 1;
    FeaturesEnables(3) = 1;
    FeaturesEnables(4) = 1;
    FeaturesEnables(5) = 1;
    nFeatures = numel(FeaturesEnables);
    fwrite(obj,'f','char');
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'f')
        fwrite(obj,tWs,'float32');
        fwrite(obj,oWs,'float32');
        fwrite(obj,nFeatures,'char');
        for i = 1:size(FeaturesEnables,2)
            fwrite(obj,FeaturesEnables(i),'char');
        end
        replay = char(fread(obj,1,'char'));
        if strcmp(replay,'f')
            set(handles.txt_info,'String','Features extraction parameters set');
        else
            set(handles.txt_info,'String','Error Setting Features extraction parameters'); 
            fclose(obj);
            return
        end
    else
        set(handles.txt_info,'String','Error Setting Features extraction parameters'); 
        fclose(obj);
        return
    end
    
    % Set sampling rate
    fwrite(obj,'r','char')
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'r')
        fwrite(obj,1000,'uint32');
        replay = char(fread(obj,1,'char'));
        if strcmp(replay,'r')
            set(handles.txt_info,'String','Wavelet processing parameters set');
        else
            set(handles.txt_info,'String','Error Setting Wavelet processing parameter'); 
            fclose(obj);
            return
        end
    else
        set(handles.txt_info,'String','Error Setting Wavelet processing parameter'); 
        fclose(obj);
        return
    end
    
    % Set wavelet denoising option
    fwrite(obj,'E','char')
    replay = char(fread(obj,1,'char'));
    if strcmp(replay,'E')
        fwrite(obj,waveletSelect-1,'char');
        replay = char(fread(obj,1,'char'));
        if strcmp(replay,'E')
            set(handles.txt_info,'String','Wavelet processing parameters set');
        else
            set(handles.txt_info,'String','Error Setting Wavelet processing parameter'); 
            fclose(obj);
            return
        end
    else
        set(handles.txt_info,'String','Error Setting Wavelet processing parameter'); 
        fclose(obj);
        return
    end
   
    tic
    fwrite(obj,'x','char');
    replay = char(fread(obj,1,'char'));
    if ~strcmp(char(replay), 'x')
        set(handles.txt_info,'String','Error retrieving features');
        fclose(obj);
        return
    end
    fwrite(obj,nCh,'char');
    fwrite(obj,tWs,'uint32');
    set(handles.txt_info,'String','Features Extraction can take some minutes...');
    drawnow;
    % transmit the first window tWs
    for sample = 1:tWs
        for ch = 1:nCh
            fwrite(obj,GUIfeatures.data(sample,ch),'float32');
        end   
    end
    % read features first window
    byteData = fread(obj,(nFeatures*nCh),'float32'); 
    features(1,:) = byteData; 
    replay = char(fread(obj,1,'char')); 
    if ~strcmp(char(replay), 'x')
        set(handles.txt_info,'String','Error retrieving features');
        fclose(obj);
        return
    end
    
    % transmit all the other incremental windows iWs
    for window = 1:nW-1
        fwrite(obj,'x','char');
        replay = fread(obj,1,'char');
        if ~strcmp(char(replay), 'x')
            set(handles.txt_info,'String','Error retrieving features');
            fclose(obj);
            return
        end
        
        fwrite(obj,nCh,'char');
        fwrite(obj,iWs,'uint32');
        for sample = 1:iWs
            for ch = 1:nCh
                fwrite(obj,GUIfeatures.data(sample+tWs+iWs*(window-1),ch),'float32');
            end   
        end
         % read features overlapping windows
        byteData = fread(obj,(nFeatures*nCh),'float32');                             
        features(window+1,:) = byteData; 
        message = sprintf('Features Extraction can take some minutes... %d on %d', window+1, nW);
        set(handles.txt_info,'String', message);
        drawnow;
        
        replay = char(fread(obj,1,'char'));
        if ~strcmp(char(replay), 'x')
            set(handles.txt_info,'String','Error retrieving features');
            fclose(obj);
            return
        end
    end
    toc
    set(handles.txt_info,'String','Features extraction completed');
    fclose(obj);
    
    for e = 1:nM
        for i = 1:nW
            GUIfeatures.ALCDfeatures(i,e).tmabs = features(i,1:nCh);
            GUIfeatures.ALCDfeatures(i,e).twl = features(i,nCh+1:nCh*2);
            GUIfeatures.ALCDfeatures(i,e).tzc = features(i,nCh*2+1:nCh*3);
            GUIfeatures.ALCDfeatures(i,e).tslpch2 = features(i,nCh*3+1:nCh*4);
            GUIfeatures.ALCDfeatures(i,e).tstd = features(i,nCh*4+1:nCh*5);
        end
    end
    
    save('GUIfeatures.mat','GUIfeatures');
    
    % mean for ALCD features
    for i= 1:nW
        fData(i,6) = mean(GUIfeatures.ALCDfeatures(i,1).tmabs);
        fData(i,7) = mean(GUIfeatures.ALCDfeatures(i,1).twl);
        fData(i,8) = mean(GUIfeatures.ALCDfeatures(i,1).tzc);
        fData(i,9) = mean(GUIfeatures.ALCDfeatures(i,1).tslpch2);
        fData(i,10) = mean(GUIfeatures.ALCDfeatures(i,1).tstd);
    end
    table(1,2) = mean(fData(:,6));
    table(2,2) = mean(fData(:,7));
    table(3,2) = mean(fData(:,8));
    table(4,2) = mean(fData(:,9));
    table(5,2) = mean(fData(:,10));
    
    % mean difference in percentage
    table(1,3) = 100*abs(table(1,1)-table(1,2))/table(1,1);
    table(2,3) = 100*abs(table(2,1)-table(2,2))/table(2,1);
    table(3,3) = 100*abs(table(3,1)-table(3,2))/table(3,1);
    table(4,3) = 100*abs(table(4,1)-table(4,2))/table(4,1);
    table(5,3) = 100*abs(table(5,1)-table(5,2))/table(5,1);
    
    % samples difference in percentage
    ALCDfeatures = GUIfeatures.ALCDfeatures;
    BPRfeatures = GUIfeatures.BPRfeatures;
    samples = size(ALCDfeatures,1);
    diffTMABS = zeros(1,nCh);
    diffTWL = zeros(1,nCh);
    diffTZC = zeros(1,nCh);
    diffTSLPCH2 = zeros(1,nCh);
    diffTSTD = zeros(1,nCh);
    for n = 1:nCh
        for i=1:samples
            diffTMABS(1,n) = diffTMABS(1,n) + abs(BPRfeatures(i).tmabs(n) - ALCDfeatures(i).tmabs(n));
            diffTWL(1,n) = diffTWL(1,n) + abs(BPRfeatures(i).twl(n) - ALCDfeatures(i).twl(n));
            diffTZC(1,n) = diffTZC(1,n) + abs(BPRfeatures(i).tzc(n) - ALCDfeatures(i).tzc(n));
            diffTSLPCH2(1,n) = diffTSLPCH2(1,n) + abs(BPRfeatures(i).tslpch2(n) - ALCDfeatures(i).tslpch2(n));
            diffTSTD(1,n) = diffTSTD(1,n) + abs(BPRfeatures(i).tstd(n) - ALCDfeatures(i).tstd(n));
            
        end
    end
    disp('TMABS error percentage')
    diffTMABS_percentage = 100*diffTMABS/samples
    disp('TWL error percentage')
    diffTWL_percentage = 100*diffTWL/samples
    disp('TZC error percentage')
    diffTZC_percentage = 100*diffTZC/samples
    disp('TSLPCH2 error percentage')
    diffTSLPCH2_percentage = 100*diffTSLPCH2/samples
    disp('TSTD error percentage')
    diffTSTD_percentage = 100*diffTSTD/samples
    disp('average error over all features')
    avgError_percentage = (mean(diffTMABS_percentage) + mean(diffTWL_percentage) ...
        + mean(diffTZC_percentage) + mean(diffTSLPCH2_percentage) + mean(diffTSTD_percentage))/5
    table(1,4) = mean(diffTMABS_percentage);
    table(2,4) = mean(diffTWL_percentage);
    table(3,4) = mean(diffTZC_percentage);
    table(4,4) = mean(diffTSLPCH2_percentage);
    table(5,4) = mean(diffTSTD_percentage);
    
    set(handles.tbl_features,'data',table);
    featuresPlot(handles,fData);
    


function et_tW_Callback(hObject, eventdata, handles)
% hObject    handle to et_tW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tW as text
%        str2double(get(hObject,'String')) returns contents of et_tW as a double


% --- Executes during object creation, after setting all properties.
function et_tW_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tWincr_Callback(hObject, eventdata, handles)
% hObject    handle to et_tWincr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tWincr as text
%        str2double(get(hObject,'String')) returns contents of et_tWincr as a double


% --- Executes during object creation, after setting all properties.
function et_tWincr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tWincr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function featuresPlot(handles,cdata)

    t             = 1:length(cdata(:,1));           
    nFeat         = size(cdata,2)/2;

    % Offset and scale the data
    ampPP = 5; 
    offVector = 0:nFeat-1;
    offVector = offVector .* ampPP;
    Kt = ampPP./(2*max(abs(cdata)));
    BPR = zeros(size(cdata,1),nFeat);
    ALCD = zeros(size(cdata,1),nFeat);
    for j = 1 : nFeat
        %tempData(:,j) = cdata(:,j)*Kt(j) + offVector(j);
        BPR(:,j) = cdata(:,j)*Kt(j) + offVector(j);
        ALCD(:,j) = cdata(:,j+5)*Kt(j) + offVector(j);
    end
    
    % plot
    axes(handles.plot1);
    h1 = plot(t,BPR,'b');
    h1 = h1(1);
    hold on;
    h2 = plot(t,ALCD,'r');
    h2 = h2(1);
    hold off;
    set(handles.plot1,'YTick',offVector);
    set(handles.plot1,'YTickLabel',{'MAV', 'WL', 'ZC', 'SLPCH', 'STD'});
    ymin = -ampPP*1/3;
    ymax =  ampPP * nFeat;
    ylim(handles.plot1, [ymin ymax]);
    xmax = length(t);
    xlim(handles.plot1, [0 xmax]);
    legend([h1,h2],'BioPatRec','ALC-D','Location','Best'); % BUG: ALC plot is red!!!
    legend('boxoff');
    
    


% --- Executes on selection change in pm_comPort.
function pm_comPort_Callback(hObject, eventdata, handles)
% hObject    handle to pm_comPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pm_comPort contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pm_comPort


% --- Executes during object creation, after setting all properties.
function pm_comPort_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pm_comPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
hwInfo = instrhwinfo('serial');
comPorts = hwInfo.AvailableSerialPorts;
if ~numel(comPorts)
    comPorts = {'COM6'};
end
set(hObject,'String',comPorts);


% --- Executes on selection change in pm_wavelet.
function pm_wavelet_Callback(hObject, eventdata, handles)
% hObject    handle to pm_wavelet (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pm_wavelet contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pm_wavelet


% --- Executes during object creation, after setting all properties.
function pm_wavelet_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pm_wavelet (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

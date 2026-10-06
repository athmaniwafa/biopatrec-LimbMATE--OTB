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
% 20xx-xx-xx / Max Ortiz  / Creation
% 20xx-xx-xx / Author  / Comment on update

function varargout = piccolo_fig(varargin)
% PICCOLO_FIG M-file for piccolo_fig.fig
%      PICCOLO_FIG, by itself, creates a new PICCOLO_FIG or raises the existing
%      singleton*.
%
%      H = PICCOLO_FIG returns the handle to a new PICCOLO_FIG or the handle to
%      the existing singleton*.
%
%      PICCOLO_FIG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PICCOLO_FIG.M with the given input arguments.
%
%      PICCOLO_FIG('Property','Value',...) creates a new PICCOLO_FIG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before piccolo_fig_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to piccolo_fig_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help piccolo_fig

% Last Modified by GUIDE v2.5 24-May-2011 13:38:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @piccolo_fig_OpeningFcn, ...
                   'gui_OutputFcn',  @piccolo_fig_OutputFcn, ...
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


% --- Executes just before piccolo_fig is made visible.
function piccolo_fig_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to piccolo_fig (see VARARGIN)

% Choose default command line output for piccolo_fig
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

backgroundImage = importdata('Img\relax.jpg');
image(backgroundImage);
axis off  

set(handles.pb_connect,'enable','on');
set(handles.pb_disconnect,'enable','off');
set(handles.pb_load,'enable','off');
set(handles.pb_download,'enable','off');
set(handles.pb_start,'enable','off');
set(handles.pb_stop,'enable','off');
set(handles.cb_norm,'enable','off');
set(handles.cb_show,'enable','off');

% UIWAIT makes piccolo_fig wait for user response (see UIRESUME)
% uiwait(handles.pr_fig);


% --- Outputs from this function are returned to the command line.
function varargout = piccolo_fig_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pb_train_ann.
function pb_train_ann_Callback(hObject, eventdata, handles)

    treated_data = get(handles.t_treated_data,'UserData');
    if isempty(treated_data)    
        set(handles.t_msg,'String','No treated data loaded!!!');
        return;
    end
    % Get the effective number of set to be used
    treated_data.etrN = str2double(get(handles.et_trN,'String'));
    treated_data.evN = str2double(get(handles.et_vN,'String'));
    treated_data.etN = str2double(get(handles.et_tN,'String'));
    %Randomize sets            
    treated_data = rand_TrainingData(treated_data);

    % Signal Characteristics
    if get(handles.rb_allchrs,'Value') == 1
        cIdx = 1:21;                                        % Use all properties
    elseif get(handles.rb_4,'Value') == 1
        % cIdx = [2 7 8 9 13];  % tmabs, twl, trms, tzc, tslpch OH08, HK99      
        % cIdx = [2 7 9 13];  % tmabs, twl, tzc, tslpch EH03, HZ09, SL09       
        % cIdx = [2 7 8 9];  % tmabs, twl, trms, tzc 1       
         cIdx = [2 7 9];  % tmabs, twl, tzc       
        % cIdx = [5 19];  % tstd, fmn       
        % cIdx = [3 12];  % tmd, fmvel       
        % cIdx = [5 17 20];  % tstd, fwl, fmd NS2      
        % cIdx = [6 16 20];  % , cv, fmd       
        % cIdx = [1 20];  % tmn, fmd       
        % cIdx = [5 8];  % tstd, trms       
        % cIdx = [2 8];  % tmabs, trms  LS09     
        %  cIdx = 7; %twl       
        %  cIdx = 5; %tstd       
        %  cIdx = 6; %tvar       
        %  cIdx = 19; %fmn       
        %  cIdx = 9; %tzc       
        %  cIdx = 2; %tmabs       
        %  cIdx = 8; %rms       
        %  cIdx = 16; %cv       
        %  cIdx = 17; %fwl       
        % cIdx = [8 16 17]; %trms cv fwl       
        % cIdx = [2 13 18 19]; %tmabs, tslpch, wlr ,fmn       
        % cIdx = [5 14 18]; %tstd, tPwr, fwlr good with eta = 0.1      
    elseif get(handles.rb_opchrs,'Value') == 1
        cIdx = get(handles.t_tchrs,'UserData');
    end

    % PSO Training
    if get(handles.cb_pso,'Value')
        % Old PSO or EA
        if get(handles.cb_oldPSOEA,'Value') == 1
            PSO = get(handles.cb_pso,'UserData');
        else
            PSO = [];
        end
        % Apply trainning       
        [psoANN, PSO] = train_ann_pso(handles, treated_data, cIdx, PSO);    % Run both EA and PSO
        set(handles.t_pso,'UserData',psoANN);                
        set(handles.cb_pso,'UserData',PSO);
    end

    % BACK PROPAGATION Training
    if get(handles.cb_backp,'Value')            
        backpANN = train_ann_backp(handles, treated_data, cIdx);    % Run both EA and PSO
        set(handles.t_bp,'UserData',backpANN);
    end





% --- Executes on selection change in lb_psoDv.
function lb_psoDv_Callback(hObject, eventdata, handles)
% hObject    handle to lb_psoDv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns lb_psoDv contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lb_psoDv


% --- Executes during object creation, after setting all properties.
function lb_psoDv_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lb_psoDv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lb_eaDv.
function lb_eaDv_Callback(hObject, eventdata, handles)
% hObject    handle to lb_eaDv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns lb_eaDv contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lb_eaDv


% --- Executes during object creation, after setting all properties.
function lb_eaDv_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lb_eaDv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lb_msg.
function lb_msg_Callback(hObject, eventdata, handles)
% hObject    handle to lb_msg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns lb_msg contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lb_msg


% --- Executes during object creation, after setting all properties.
function lb_msg_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lb_msg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_test_ann.
function pb_test_ann_Callback(hObject, eventdata, handles)
    test_ann(handles);


% --------------------------------------------------------------------
function t_open_ClickedCallback(hObject, eventdata, handles)
% Open ANNs plus SS
    [file, path] = uigetfile('*.mat');
    if ~isequal(file, 0)
        load([path,file]);
        if(exist('allsets','var')) % Load ANNs
            if (exist('psoANN','var'))
%                 set(handles.t_pso,'UserData',psoANN);
%                 set(handles.lb_msg,'String',psoANN.oname);
%                 set(handles.t_tchrs,'UserData',psoANN.cIdx);
%                 set(handles.lb_chrs,'String',psoANN.Chrs);             
%                 if psoANN.normalize
%                     set(handles.t_allsets,'UserData',allsets);
%                     set(handles.t_allsets,'String',num2str(size(allsets,1)));
%                 end
%                 set(handles.t_msg,'String','psoANN loaded');
            end
            pause(1); %Time to look at the next load 
            if (exist('bpANN','var'))
                set(handles.t_bp,'UserData',bpANN);
                %set(handles.lb_msg,'String',bpANN.oname);
                %set(handles.t_tchrs,'UserData',bpANN.cIdx);
                %set(handles.lb_chrs,'String',bpANN.Chrs);             
                %if bpANN.normalize
                %    set(handles.t_allsets,'UserData',allsets);
                %    set(handles.t_allsets,'String',num2str(size(allsets,1)));
                %end
                set(handles.t_msg,'String','bpANN loaded');
            end
        elseif (exist('treated_data','var')) == 1 % load Trated data
            set(handles.t_treated_data,'UserData',treated_data);
            set(handles.et_trN,'String',num2str(treated_data.trN));    
            set(handles.et_vN,'String',num2str(treated_data.vN));    
            set(handles.et_tN,'String',num2str(treated_data.tN));    
            set(handles.lb_msg,'String',treated_data.msg);
            set(handles.t_msg,'String','Treated data loaded');
            %set(handles.t_vdata,'UserData',vdata);
            %set(handles.t_tdata,'UserData',tdata);
            %set(handles.lb_msg,'UserData',ss);
            %if exist('PLHf','var')
            %    set(handles.cb_PLHf,'Value',PLHf);
            %    set(handles.cb_BPf,'Value',BPf);
            %end
        elseif (exist('PSO','var')) == 1
            set(handles.cb_pso,'UserData',PSO);
            set(handles.t_msg,'String','PSO loaded');            
        elseif (exist('EA','var')) == 1 && (exist('maxfitness','var')) == 0
            set(handles.cb_ea,'UserData',EA);
            set(handles.t_msg,'String','EA loaded');            
        elseif (exist('maxfitness','var')) == 1
            set(handles.lb_ochrs,'String',cChrs);                        
            set(handles.t_omaxf,'UserData',maxfitness);
            set(handles.t_omaxf,'String',num2str(maxfitness));
            set(handles.t_tchrs,'UserData',cIdx);             
            set(handles.t_oEA,'UserData',EA);
            set(handles.t_msg,'String','Optimal Chrs loaded');
            set(handles.text28,'UserData',fitness);
            if exist('tempi','var')
                set(handles.t_ogen,'UserData',tempi);
                set(handles.text26,'UserData',xbest);
                set(handles.t_ss,'UserData',best_individual);
            end
        else
            set(handles.t_msg,'String','File did not cointain ANNs or Trated Data');
        end
    end


% --- Executes on selection change in lb_output.
function lb_output_Callback(hObject, eventdata, handles)
% hObject    handle to lb_output (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns lb_output contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lb_output


% --- Executes during object creation, after setting all properties.
function lb_output_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lb_output (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cb_normalize.
function cb_normalize_Callback(hObject, eventdata, handles)
% hObject    handle to cb_normalize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_normalize


% --- Executes on selection change in lb_psoDtr.
function lb_psoDtr_Callback(hObject, eventdata, handles)
% hObject    handle to lb_psoDtr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns lb_psoDtr contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lb_psoDtr


% --- Executes during object creation, after setting all properties.
function lb_psoDtr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lb_psoDtr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lb_eaDtr.
function lb_eaDtr_Callback(hObject, eventdata, handles)
% hObject    handle to lb_eaDtr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns lb_eaDtr contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lb_eaDtr


% --- Executes during object creation, after setting all properties.
function lb_eaDtr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lb_eaDtr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lb_chrs.
function lb_chrs_Callback(hObject, eventdata, handles)
% hObject    handle to lb_chrs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns lb_chrs contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lb_chrs


% --- Executes during object creation, after setting all properties.
function lb_chrs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lb_chrs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_TreatData.
function pb_TreatData_Callback(hObject, eventdata, handles)

    disp('%%%%%%%%%%% Loading Data %%%%%%%%%%%%%');
    set(handles.t_msg,'String','Loading Data...');

    [file, path] = uigetfile('*.mat');
    if ~isequal(file, 0)
        load([path,file]);
        if(exist('ss','var')) ~= 1
            disp('That was not a valid training matrix');
            errordlg('That was not a valid training matrix','Error');
            return;
        end
    end
    
    %Movements performed to list box
    set(handles.lb_msg,'String',ss.msg);
    %set(handles.lb_msg,'UserData',ss);
    drawnow;

    % Open Fig and load information            
    st = Signal_Treatment_fig();
    stdata = guidata(st);
    set(stdata.et_Fs,'String',num2str(ss.Fs));
    set(stdata.et_Ne,'String',num2str(ss.Ne));
    set(stdata.et_Nr,'String',num2str(ss.Nr));
    set(stdata.et_Tc,'String',num2str(ss.Tc));
    set(stdata.et_Tr,'String',num2str(ss.Tr));        
    set(stdata.et_Psr,'String',num2str(ss.Psr));
    set(stdata.t_path,'UserData',path);

    nw = fix(ss.Tc * ss.Psr * ss.Nr / str2double(get(stdata.et_tw,'String')));
    set(stdata.et_nw,'String',num2str(nw));
    trP = str2double(get(stdata.et_trP,'String'));
    trN = fix(trP * nw);
    set(stdata.et_trN,'String',num2str(trN));
    vP = str2double(get(stdata.et_vP,'String'));
    vN = fix( vP* nw);
    set(stdata.et_vN,'String',num2str(vN));
    tP = str2double(get(stdata.et_tP,'String'));
    tN = fix(tP * nw);
    set(stdata.et_tN,'String',num2str(tN));
    set(stdata.t_totN,'String',num2str(trN+vN+tN));
    set(stdata.t_totP,'String',num2str(trP+vP+tP));

    set(stdata.t_rawdata,'UserData',ss.trdata);
    set(stdata.t_mhandles,'UserData',handles); % Save this GUI handles


    % Routine to treat data
    %[trdata, vdata, tdata] = treat_Data(handles, ss.Fs, ss.Nr, ss.Tc*ss.Psr, ss.trdata);           % Treat Data
    %set(handles.t_trdata,'UserData',trdata);
    %set(handles.t_vdata,'UserData',vdata);
    %set(handles.t_tdata,'UserData',tdata);


% --------------------------------------------------------------------
function m_Save_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function m_SavaTreatedData_Callback(hObject, eventdata, handles)
% Save ANNs plus SS
%    ss          = get(handles.lb_msg,'UserData');
%    trdata      = get(handles.t_trdata,'UserData');
%    vdata       = get(handles.t_vdata,'UserData');
%    tdata       = get(handles.t_tdata,'UserData');
%    PLHf        = get(handles.cb_PLHf,'Value');
%    BPf         = get(handles.cb_BPf,'Value');
%
%if ~isempty(trdata)
%    [filename, pathname] = uiputfile({'*.mat','MAT-files (*.mat)'},'Save as', 'Untitled.mat');
%    save([pathname,filename],'ss','trdata','vdata','tdata','PLHf','BPf');
%    set(handles.t_msg,'String','TrData, VData and TData saved');
%else
%    set(handles.t_msg,'String','No data to save!');    
%end

    treated_data = get(handles.t_treated_data,'UserData');

if ~isempty(treated_data)
    [filename, pathname] = uiputfile({'*.mat','MAT-files (*.mat)'},'Save as', 'Untitled.mat');
    save([pathname,filename],'treated_data');
    set(handles.t_msg,'String','Treated Data saved');
else
    set(handles.t_msg,'String','No data to save!');    
end


% --------------------------------------------------------------------
function m_SaveANNs_Callback(hObject, eventdata, handles)
% Save ANNs plus SS
    %ss          = get(handles.lb_msg,'UserData');
    psoANN      = get(handles.t_pso,'UserData');
    eaANN       = get(handles.t_ea,'UserData');
    bpANN       = get(handles.t_bp,'UserData');
    allsets     = get(handles.t_allsets,'UserData');
    %normalize   = get(handles.cb_normalize,'UserData');
    %cIdx        = get(handles.t_tchrs,'UserData');             
    %Chrs        = get(handles.lb_chrs,'String');             

if ~isempty(psoANN) || ~isempty(bpANN)
    [filename, pathname] = uiputfile({'*.mat','MAT-files (*.mat)'},'Save as', 'Untitled.mat');
    save([pathname,filename],'psoANN','bpANN','eaANN','allsets');
    set(handles.t_msg,'String','ANNs Saved');
else
    set(handles.t_msg,'String','No data to save!');    
end



function et_Nrf_Callback(hObject, eventdata, handles)
% hObject    handle to et_Nrf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_Nrf as text
%        str2double(get(hObject,'String')) returns contents of et_Nrf as a double


% --- Executes during object creation, after setting all properties.
function et_Nrf_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_Nrf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_estep_Callback(hObject, eventdata, handles)
% hObject    handle to et_estep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_estep as text
%        str2double(get(hObject,'String')) returns contents of et_estep as a double


% --- Executes during object creation, after setting all properties.
function et_estep_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_estep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_einit_Callback(hObject, eventdata, handles)
% hObject    handle to et_einit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_einit as text
%        str2double(get(hObject,'String')) returns contents of et_einit as a double


% --- Executes during object creation, after setting all properties.
function et_einit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_einit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_maxsims_Callback(hObject, eventdata, handles)
% hObject    handle to et_maxsims (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_maxsims as text
%        str2double(get(hObject,'String')) returns contents of et_maxsims as a double


% --- Executes during object creation, after setting all properties.
function et_maxsims_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_maxsims (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function m_Optimization_Callback(hObject, eventdata, handles)
% hObject    handle to m_Optimization (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function m_OSignalChrs_Callback(hObject, eventdata, handles)

    [cIdx, maxfitness] = EAchrs(handles);


% --- Executes on selection change in lb_ochrs.
function lb_ochrs_Callback(hObject, eventdata, handles)
% hObject    handle to lb_ochrs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns lb_ochrs contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lb_ochrs


% --- Executes during object creation, after setting all properties.
function lb_ochrs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lb_ochrs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cb_pso.
function cb_pso_Callback(hObject, eventdata, handles)
% hObject    handle to cb_pso (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_pso


% --- Executes on button press in cb_ea.
function cb_ea_Callback(hObject, eventdata, handles)
% hObject    handle to cb_ea (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_ea


% --------------------------------------------------------------------
function m_Spso_Callback(hObject, eventdata, handles)
    PSO = get(handles.cb_pso,'UserData');

    if ~isempty(PSO)
        [filename, pathname] = uiputfile({'*.mat','MAT-files (*.mat)'},'Save as', 'Untitled.mat');
        save([pathname,filename],'PSO');
        set(handles.t_msg,'String','PSO Saved');
    else
        set(handles.t_msg,'String','No PSO to save!');    
    end


% --------------------------------------------------------------------
function m_Sea_Callback(hObject, eventdata, handles)
    EA = get(handles.cb_pso,'UserData');
    if ~isempty(EA)
        [filename, pathname] = uiputfile({'*.mat','MAT-files (*.mat)'},'Save as', 'Untitled.mat');
        save([pathname,filename],'EA');
        set(handles.t_msg,'String','EA Saved');
    else
        set(handles.t_msg,'String','No EA to save!');    
    end


% --------------------------------------------------------------------
function m_Load_Callback(hObject, eventdata, handles)
% hObject    handle to m_Load (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function m_Ltrateddata_Callback(hObject, eventdata, handles)
    t_open_ClickedCallback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function m_Lanns_Callback(hObject, eventdata, handles)
    t_open_ClickedCallback(hObject, eventdata, handles)


% --------------------------------------------------------------------
function m_lpsoea_Callback(hObject, eventdata, handles)
    t_open_ClickedCallback(hObject, eventdata, handles)


% --- Executes on button press in cb_break.
function cb_break_Callback(hObject, eventdata, handles)
% hObject    handle to cb_break (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_break


% --------------------------------------------------------------------
function m_Ssigopt_Callback(hObject, eventdata, handles)
% hObject    handle to m_Ssigopt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maxfitness  = get(handles.t_omaxf,'UserData');
    cIdx        = get(handles.t_tchrs,'UserData');             
    EA          = get(handles.t_oEA,'UserData');
    cChrs       = get(handles.lb_ochrs,'String');                        

    if ~isempty(maxfitness)
        [filename, pathname] = uiputfile({'*.mat','MAT-files (*.mat)'},'Save as', 'Untitled.mat');
        save([pathname,filename],'EA','maxfitness','cIdx','cChrs');
        set(handles.t_msg,'String','cIdx Saved');
    else
        set(handles.t_msg,'String','No EA to save!');    
    end


% --- Executes on button press in cb_oldPSOEA.
function cb_oldPSOEA_Callback(hObject, eventdata, handles)
% hObject    handle to cb_oldPSOEA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_oldPSOEA


% --- Executes on selection change in lb_eaDt.
function lb_eaDt_Callback(hObject, eventdata, handles)
% hObject    handle to lb_eaDt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns lb_eaDt contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lb_eaDt


% --- Executes during object creation, after setting all properties.
function lb_eaDt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lb_eaDt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lb_psoDt.
function lb_psoDt_Callback(hObject, eventdata, handles)
% hObject    handle to lb_psoDt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns lb_psoDt contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lb_psoDt


% --- Executes during object creation, after setting all properties.
function lb_psoDt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lb_psoDt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function Statistics_Callback(hObject, eventdata, handles)
% hObject    handle to Statistics (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function m_STrainAnns_Callback(hObject, eventdata, handles)

%nRep = 100;
nRep = str2double(inputdlg('Write the number of repetitions','Number of Runs'));
if ~(nRep > 1)
    errordlg('Invalid number','Error')
    return;
end

%alls = 1;
alls = str2double(inputdlg('Write 0 for current data or 1 for all','Data'));
if alls ~= 1 && alls ~= 0 
    errordlg('Only select 1 or 0','Error')
    return;
end

%ns = 9;         % Number of sesions to analyze
if alls == 1
    [file path] = uigetfile('*.mat');
    for rn =1 : 1000
        if exist([path num2str(rn) 't.mat'],'file')
            ns = rn;
        else
            break;
        end 
    end
end

fpso = get(handles.cb_pso,'Value');
fea  = get(handles.cb_ea,'Value');
fbp  = get(handles.cb_backp,'Value');

if fpso
    psoAtr = zeros(nRep,1);
    psoFtr = psoAtr;
    psoAv  = psoAtr;
    psoFv  = psoAtr;
    psoAt  = psoAtr;
    psoFt  = psoAtr;
    
    bestpsoAt = 0;
    bestpsoFt = inf;
    psoRes    = zeros(nRep,1);
    psosim    = zeros(nRep,1);
    psoeval   = zeros(nRep,1);
    psofail = 0;
end

if fea
    eaAtr  = zeros(nRep,1);
    eaFtr  = eaAtr;
    eaAv   = eaAtr;
    eaFv   = eaAtr;
    eaAt   = eaAtr;
    eaFt   = eaAtr;
    
    besteaAt = 0;
    besteaFt = inf;
    eaRes    = zeros(nRep,1);
    easim    = zeros(nRep,1);
    eaeval   = zeros(nRep,1);
    eafail = 0;
end

if fbp
    bpAtr  = zeros(nRep,1);
    bpFtr  = bpAtr;
    bpAv   = bpAtr;
    bpFv   = bpAtr;
    bpAt   = bpAtr;
    bpFt   = bpAtr;

    bestbpAt = 0;
    bestbpFt = inf;
    bpRes    = zeros(nRep,1);
    bpsim    = zeros(nRep,1);
    bpeval   = zeros(nRep,1);
    bpfail = 0;
end

maxs = str2double(get(handles.et_maxsims,'String'));

set(handles.t_psosims,'String','0');
set(handles.t_easims,'String','0');
set(handles.t_bpsims,'String','0');

set(handles.t_psoeval,'String','0');
set(handles.t_eaeval,'String','0');
set(handles.t_bpeval,'String','0');

set(handles.t_psoRes,'String','0');
set(handles.t_eaRes,'String','0');
set(handles.t_bpRes,'String','0');

set(handles.t_psofailures,'String','0');
set(handles.t_eafailures,'String','0');
set(handles.t_bpfailures,'String','0');

rn=0;

for i=1 : nRep
    
    if alls == 1
        rn = round(1 + (ns - 1) * rand);
        load([path num2str(rn) 't' '.mat']);    
        set(handles.t_treated_data,'UserData',treated_data);
        set(handles.lb_msg,'String',treated_data.msg);    
        set(handles.t_msg,'String','Treated data loaded');            
        disp('Treated data loaded');            
    end

    set(handles.t_msg2,'String',['Statistics Rep: ' num2str(i) ' from: ' num2str(rn)]);
    
    pb_train_ann_Callback(hObject, eventdata, handles)
    
    if fpso
        psoAtr(i) = str2double(get(handles.t_psoAtr,'String'));    
        psoAv(i)  = str2double(get(handles.t_psoAv,'String'));    
        psoAt(i)  = str2double(get(handles.t_psoAt,'String'));    

        psoFtr(i) = str2double(get(handles.t_psoFtr,'String'));    
        psoFv(i)  = str2double(get(handles.t_psoFv,'String'));    
        psoFt(i)  = str2double(get(handles.t_psoFt,'String'));    
    
        psoRes(i)  = str2double(get(handles.t_psoRes,'String'));
        psosim(i)  = str2double(get(handles.t_psosims,'String'));
        psoeval(i) = str2double(get(handles.t_psoeval,'String'));
        
        if psosim(i) >= maxs || get(handles.cb_break,'Value') == 1
            psofail = psofail + 1;
            set(handles.t_psofailures,'String',num2str(psofail));
            psoAtr(i) = 0;
            psoFtr(i) = 0;    
            psoAv(i)  = 0;
            psoFv(i)  = 0;    
            psoAt(i)  = 0;
            psoFt(i)  = 0;    
            psosim(i) = 0;
            psoeval(i)= 0;
            psoRes(i) = 0;
        end
    end

    if fea
        eaAtr(i)  = str2double(get(handles.t_eaAtr,'String'));    
        eaAv(i)   = str2double(get(handles.t_eaAv,'String'));    
        eaAt(i)   = str2double(get(handles.t_eaAt,'String'));    

        eaFtr(i)  = str2double(get(handles.t_eaFtr,'String'));    
        eaFv(i)   = str2double(get(handles.t_eaFv,'String'));    
        eaFt(i)   = str2double(get(handles.t_eaFt,'String'));    

        eaRes(i)  = str2double(get(handles.t_eaRes,'String'));
        easim(i)  = str2double(get(handles.t_easims,'String'));
        eaeval(i) = str2double(get(handles.t_eaeval,'String'));

        if easim(i) >= maxs || get(handles.cb_break,'Value') == 1
            eafail = eafail + 1;
            set(handles.t_eafailures,'String',num2str(eafail));
            eaAtr(i) = 0;    
            eaFtr(i) = 0;    
            eaAv(i)  = 0;    
            eaFv(i)  = 0;    
            eaAt(i)  = 0;    
            eaFt(i)  = 0;
            easim(i) = 0;
            eaeval(i) = 0;
            eaRes(i) = 0;    
        end
    end

    if fbp
        bpAtr(i) = str2double(get(handles.t_bpAtr,'String'));    
        bpAv(i)  = str2double(get(handles.t_bpAv,'String'));    
        bpAt(i)  = str2double(get(handles.t_bpAt,'String'));    

        bpFtr(i) = str2double(get(handles.t_bpFtr,'String'));    
        bpFv(i)  = str2double(get(handles.t_bpFv,'String'));    
        bpFt(i)  = str2double(get(handles.t_bpFt,'String'));    
    
        bpRes(i)  = str2double(get(handles.t_bpRes,'String'));
        bpsim(i)  = str2double(get(handles.t_bpsims,'String'));
        bpeval(i)  = str2double(get(handles.t_bpeval,'String'));

        %if (bpsim(i) >= maxs && bpFtr(i) >= 0.1) || get(handles.cb_break,'Value') == 1
        if bpsim(i) >= maxs || get(handles.cb_break,'Value') == 1
            bpfail = bpfail + 1;
            set(handles.t_bpfailures,'String',num2str(bpfail));
            bpAtr(i) = 0;
            bpFtr(i) = 0;    
            bpAv(i)  = 0;
            bpFv(i)  = 0;    
            bpAt(i)  = 0;
            bpFt(i)  = 0;    
            bpsim(i) = 0;
            bpeval(i)= 0;
            bpRes(i) = 0;
        end
    end

    % Saving the best ANNs
    if alls == 0
        if fpso && psoAt(i) >= bestpsoAt && psoFt(i) <= bestpsoFt
            bestpsoAt = psoAt(i);
            bestpsoFt = psoFt(i);
            psoANN    = get(handles.t_pso,'UserData');
        end
        if fea  && eaAt(i) >= besteaAt && eaFt(i) <= besteaFt
            besteaAt = eaAt(i);
            besteaFt = eaFt(i);
            eaANN    = get(handles.t_ea,'UserData');
        end
        if fbp  && bpAt(i) >= bestbpAt && bpFt(i) <= bestbpFt
            bestbpAt = bpAt(i);
            bestbpFt = bpFt(i);
            bpANN    = get(handles.t_bp,'UserData');
        end
    end
end


if fpso
    psor = nRep - psofail;

    set(handles.t_psoAtr,'String',num2str(sum(psoAtr)/psor));
    set(handles.t_psoAv,'String',num2str(sum(psoAv)/psor));
    set(handles.t_psoAt,'String',num2str(sum(psoAt)/psor));

    set(handles.t_psoFtr,'String',num2str(sum(psoFtr)/psor));
    set(handles.t_psoFv,'String',num2str(sum(psoFv)/psor));
    set(handles.t_psoFt,'String',num2str(sum(psoFt)/psor));

    set(handles.t_psoRes,'String',num2str(sum(psoRes)/psor));    
    set(handles.t_psosims,'String',num2str(sum(psosim)/psor));
    set(handles.t_psoeval,'String',num2str(sum(psoeval)/psor));
    set(handles.t_psofailures,'String',num2str(psofail));
    
    psoA = mean([psoAtr psoAv psoAt],2);
    psoF = mean([psoFtr psoFv psoFt],2);
    psoA = psoA(find(psoA));
    psoF = psoF(find(psoF));
    psoAt = psoAt(find(psoAt));
    psoFt = psoFt(find(psoFt));

    stats.psoAt     = [mean(psoAt) max(psoAt) min(psoAt) std(psoAt)];
    stats.psoFt     = [mean(psoFt) max(psoFt) min(psoFt) std(psoFt)];
    stats.psoA      = [mean(psoA) max(psoA) min(psoA) std(psoA)];
    stats.psoF      = [mean(psoF) max(psoF) min(psoF) std(psoF)];
    stats.psoRes    = sum(psoRes)/psor;
    stats.psosims      = sum(psosim)/psor;
    stats.psoeval      = sum(psoeval)/psor;
    stats.psofailures  = psofail;

end

if fbp
    bpr = nRep - bpfail;

    set(handles.t_bpAtr,'String',num2str(sum(bpAtr)/bpr));
    set(handles.t_bpAv,'String',num2str(sum(bpAv)/bpr));
    set(handles.t_bpAt,'String',num2str(sum(bpAt)/bpr));

    set(handles.t_bpFtr,'String',num2str(sum(bpFtr)/bpr));
    set(handles.t_bpFv,'String',num2str(sum(bpFv)/bpr));
    set(handles.t_bpFt,'String',num2str(sum(bpFt)/bpr));

    set(handles.t_bpRes,'String',num2str(sum(bpRes)/bpr));    
    set(handles.t_bpsims,'String',num2str(sum(bpsim)/bpr));
    set(handles.t_bpeval,'String',num2str(sum(bpeval)/bpr));
    set(handles.t_bpfailures,'String',num2str(bpfail));
    
    bpA = mean([bpAtr bpAv bpAt],2);
    bpF = mean([bpFtr bpFv bpFt],2);
    bpA = bpA(find(bpA));
    bpF = bpF(find(bpF));
    bpAt = bpAt(find(bpAt));
    bpFt = bpFt(find(bpFt));

    stats.bpAt     = [mean(bpAt) max(bpAt) min(bpAt) std(bpAt)];
    stats.bpFt     = [mean(bpFt) max(bpFt) min(bpFt) std(bpFt)];
    stats.bpA      = [mean(bpA) max(bpA) min(bpA) std(bpA)];
    stats.bpF      = [mean(bpF) max(bpF) min(bpF) std(bpF)];
    stats.bpRes    = sum(bpRes)/bpr;
    stats.bpsims      = sum(bpsim)/bpr;
    stats.bpeval      = sum(bpeval)/bpr;
    stats.bpfailures  = bpfail;

end

set(handles.t_msg2,'String','Statistics for Train ANNs DONE!');    
save('stats.mat','stats');

if alls == 0
    if fpso
        set(handles.t_pso,'UserData',psoANN);
    end
    if fea
        set(handles.t_ea,'UserData',eaANN);
    end
    if fbp
        set(handles.t_bp,'UserData',bpANN);
    end
end


% --- Executes on button press in cb_PLHf.
function cb_PLHf_Callback(hObject, eventdata, handles)
% hObject    handle to cb_PLHf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_PLHf


% --- Executes on button press in cb_BPf.
function cb_BPf_Callback(hObject, eventdata, handles)
% hObject    handle to cb_BPf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_BPf


% --- Executes on button press in pb_test_ann_fast.
function pb_test_ann_fast_Callback(hObject, eventdata, handles)
    test_ann_fast(handles);



function et_tw_Callback(hObject, eventdata, handles)
% hObject    handle to et_tw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tw as text
%        str2double(get(hObject,'String')) returns contents of et_tw as a double


% --- Executes during object creation, after setting all properties.
function et_tw_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_vN_Callback(hObject, eventdata, handles)
% hObject    handle to et_vN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_vN as text
%        str2double(get(hObject,'String')) returns contents of et_vN as a double


% --- Executes during object creation, after setting all properties.
function et_vN_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_vN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tN_Callback(hObject, eventdata, handles)
% hObject    handle to et_tN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tN as text
%        str2double(get(hObject,'String')) returns contents of et_tN as a double


% --- Executes during object creation, after setting all properties.
function et_tN_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_trN_Callback(hObject, eventdata, handles)
% hObject    handle to et_trN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_trN as text
%        str2double(get(hObject,'String')) returns contents of et_trN as a double


% --- Executes during object creation, after setting all properties.
function et_trN_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_trN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_Ts_Callback(hObject, eventdata, handles)
% hObject    handle to et_Ts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_Ts as text
%        str2double(get(hObject,'String')) returns contents of et_Ts as a double


% --- Executes during object creation, after setting all properties.
function et_Ts_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_Ts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cb_backp.
function cb_backp_Callback(hObject, eventdata, handles)
% hObject    handle to cb_backp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_backp



function et_alpha_Callback(hObject, eventdata, handles)
% hObject    handle to et_alpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_alpha as text
%        str2double(get(hObject,'String')) returns contents of et_alpha as a double


% --- Executes during object creation, after setting all properties.
function et_alpha_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_alpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_eta_Callback(hObject, eventdata, handles)
% hObject    handle to et_eta (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_eta as text
%        str2double(get(hObject,'String')) returns contents of et_eta as a double


% --- Executes during object creation, after setting all properties.
function et_eta_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_eta (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lb_bpDt.
function lb_bpDt_Callback(hObject, eventdata, handles)
% hObject    handle to lb_bpDt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns lb_bpDt contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lb_bpDt


% --- Executes during object creation, after setting all properties.
function lb_bpDt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lb_bpDt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lb_bpDtr.
function lb_bpDtr_Callback(hObject, eventdata, handles)
% hObject    handle to lb_bpDtr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns lb_bpDtr contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lb_bpDtr


% --- Executes during object creation, after setting all properties.
function lb_bpDtr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lb_bpDtr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lb_bpDv.
function lb_bpDv_Callback(hObject, eventdata, handles)
% hObject    handle to lb_bpDv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns lb_bpDv contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lb_bpDv


% --- Executes during object creation, after setting all properties.
function lb_bpDv_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lb_bpDv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function m_savepsoANN_Callback(hObject, eventdata, handles)
    psoANN       = get(handles.t_pso,'UserData');
    allsets      = get(handles.t_allsets,'UserData');

if ~isempty(psoANN)
    [filename, pathname] = uiputfile({'*.mat','MAT-files (*.mat)'},'Save as', 'Untitled.mat');
    save([pathname,filename],'psoANN','allsets');
    set(handles.t_msg,'String','PSO ANN Saved');
else
    set(handles.t_msg,'String','No data to save!');    
end


% --------------------------------------------------------------------
function m_savebpANN_Callback(hObject, eventdata, handles)
    bpANN       = get(handles.t_bp,'UserData');
    allsets     = get(handles.t_allsets,'UserData');

if ~isempty(bpANN)
    [filename, pathname] = uiputfile({'*.mat','MAT-files (*.mat)'},'Save as', 'Untitled.mat');
    save([pathname,filename],'bpANN','allsets');
    set(handles.t_msg,'String','BackP ANN Saved');
else
    set(handles.t_msg,'String','No data to save!');    
end


% --------------------------------------------------------------------
function m_saveeaANN_Callback(hObject, eventdata, handles)
    eaANN       = get(handles.t_ea,'UserData');
    allsets     = get(handles.t_allsets,'UserData');

if ~isempty(eaANN)
    [filename, pathname] = uiputfile({'*.mat','MAT-files (*.mat)'},'Save as', 'Untitled.mat');
    save([pathname,filename],'eaANN','allsets');
    set(handles.t_msg,'String','EA ANN Saved');
else
    set(handles.t_msg,'String','No data to save!');    
end



function et_buffer_Callback(hObject, eventdata, handles)
% hObject    handle to et_buffer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_buffer as text
%        str2double(get(hObject,'String')) returns contents of et_buffer as a double


% --- Executes during object creation, after setting all properties.
function et_buffer_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_buffer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function m_STrainPRA_Callback(hObject, eventdata, handles)
% hObject    handle to m_STrainPRA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% MO 2010-05-16

%nRep = 100;
nRep = str2double(inputdlg('Write the number of repetitions per subject','Number of Runs'));
if ~(nRep > 1)
    errordlg('Invalid number','Error')
    return;
end

%alls = 1;
alls = str2double(inputdlg('Write 0 for current data or 1 for all','Data'));
if alls ~= 1 && alls ~= 0 
    errordlg('Only select 1 or 0','Error')
    return;
end

%ns = 9;         % Number of sesions to analyze
% automatic detection of number of subjects to analyze
% they should be in the same folder and have the name "Xt.mat"
if alls == 1
    [file path] = uigetfile('*.mat');
    for rn =1 : 1000
        if exist([path num2str(rn) 't.mat'],'file')
            ns = rn;
        else
            break;
        end 
    end
end


% Check which PRA are selected
fpso = get(handles.cb_pso,'Value');
fea  = get(handles.cb_ea,'Value');
fbp  = get(handles.cb_backp,'Value');

maxs = str2double(get(handles.et_maxsims,'String'));

        % Initialize chosen PRA
        if fbp
            bpAAt   = zeros(ns,4);
            bpAApt  = zeros(ns,4);
            bpAFt   = zeros(ns,4);

            bpAA    = zeros(ns,4);
            bpAAp   = zeros(ns,4);
            bpAF    = zeros(ns,4);

            bpAR    = zeros(ns,4);
        end
        if fpso
            psoAAt   = zeros(ns,4);
            psoAApt  = zeros(ns,4);
            psoAFt   = zeros(ns,4);

            psoAA    = zeros(ns,4);
            psoAAp   = zeros(ns,4);
            psoAF    = zeros(ns,4);

            psoAR    = zeros(ns,4);
        end


for i=1 : ns % Number of subjects

    % clear satistics before each subject
        set(handles.t_psosims,'String','0');
        set(handles.t_easims,'String','0');
        set(handles.t_bpsims,'String','0');

        set(handles.t_psoeval,'String','0');
        set(handles.t_eaeval,'String','0');
        set(handles.t_bpeval,'String','0');

        set(handles.t_psoRes,'String','0');
        set(handles.t_eaRes,'String','0');
        set(handles.t_bpRes,'String','0');

        set(handles.t_psofailures,'String','0');
        set(handles.t_eafailures,'String','0');
        set(handles.t_bpfailures,'String','0');
        
        % Initialize chosen PRA
        if fbp
            bpAtr = zeros(nRep,2);
            bpAv  = bpAtr;
            bpAt  = bpAtr;

            bpFtr = zeros(nRep,1);
            bpFv  = bpFtr;
            bpFt  = bpFtr;

            bestbpAt = 0;
            bestbpFt = inf;
            bpRes    = zeros(nRep,1);
            bpsim    = zeros(nRep,1);
            bpeval   = zeros(nRep,1);
            bpfail   = 0;
        end
        if fpso
            psoAtr = zeros(nRep,2);
            psoAv  = psoAtr;
            psoAt  = psoAtr;

            psoFtr = zeros(nRep,1);
            psoFv  = psoFtr;
            psoFt  = psoFtr;

            bestpsoAt = 0;
            bestpsoFt = inf;
            psoRes    = zeros(nRep,1);
            psosim    = zeros(nRep,1);
            psoeval   = zeros(nRep,1);
            psofail   = 0;
        end


    for j = 1 : nRep

        % load data
        load([path num2str(i) 't' '.mat']);    
        set(handles.t_treated_data,'UserData',treated_data);
        set(handles.lb_msg,'String',treated_data.msg);    
        set(handles.t_msg,'String','Treated data loaded');            
        disp('Treated data loaded');            
        set(handles.t_msg2,'String',['Statistics Rep: ' num2str(j) ' from: ' num2str(i)]);
    
        % Train PRA
        pb_train_ann_Callback(hObject, eventdata, handles)

        % Collect results from GUI
        if fbp
            bpAtr(j,1)  = str2double(get(handles.t_bpAtr,'String'));    
            bpAv(j,1)   = str2double(get(handles.t_bpAv,'String'));    
            bpAt(j,1)   = str2double(get(handles.t_bpAt,'String'));    
            bpAtr(j,2)  = str2double(get(handles.t_bpAptr,'String'));    
            bpAv(j,2)   = str2double(get(handles.t_bpApv,'String'));    
            bpAt(j,2)   = str2double(get(handles.t_bpApt,'String'));    

            bpFtr(j)    = str2double(get(handles.t_bpFtr,'String'));    
            bpFv(j)     = str2double(get(handles.t_bpFv,'String'));    
            bpFt(j)     = str2double(get(handles.t_bpFt,'String'));    

            bpRes(j)    = str2double(get(handles.t_bpRes,'String'));
            bpsim(j)    = str2double(get(handles.t_bpsims,'String'));
            bpeval(j)   = str2double(get(handles.t_bpeval,'String'));

            %if (bpsim(i) >= maxs && bpFtr(i) >= 0.1) || get(handles.cb_break,'Value') == 1
            if bpsim(j) >= maxs || get(handles.cb_break,'Value') == 1
                % Count the failute
                bpfail = bpfail + 1;
                set(handles.t_bpfailures,'String',num2str(bpfail));
                
                % Clear valures for a failure
                bpAtr(j,1) = 0;
                bpAv(j,1)  = 0;
                bpAt(j,1)  = 0;
                bpAtr(j,2) = 0;
                bpAv(j,2)  = 0;
                bpAt(j,2)  = 0;

                bpFtr(j) = 0;    
                bpFv(j)  = 0;    
                bpFt(j)  = 0;    

                bpsim(j) = 0;
                bpeval(j)= 0;
                bpRes(j) = 0;
            end
        end
        
        if fpso
            psoAtr(j,1)  = str2double(get(handles.t_psoAtr,'String'));    
            psoAv(j,1)   = str2double(get(handles.t_psoAv,'String'));    
            psoAt(j,1)   = str2double(get(handles.t_psoAt,'String'));    
            psoAtr(j,2)  = str2double(get(handles.t_psoAptr,'String'));    
            psoAv(j,2)   = str2double(get(handles.t_psoApv,'String'));    
            psoAt(j,2)   = str2double(get(handles.t_psoApt,'String'));    

            psoFtr(j)    = str2double(get(handles.t_psoFtr,'String'));    
            psoFv(j)     = str2double(get(handles.t_psoFv,'String'));    
            psoFt(j)     = str2double(get(handles.t_psoFt,'String'));    

            psoRes(j)    = str2double(get(handles.t_psoRes,'String'));
            psosim(j)    = str2double(get(handles.t_psosims,'String'));
            psoeval(j)   = str2double(get(handles.t_psoeval,'String'));

            %if (bpsim(i) >= maxs && bpFtr(i) >= 0.1) || get(handles.cb_break,'Value') == 1
            if psosim(j) >= maxs || get(handles.cb_break,'Value') == 1
                % Count the failute
                psofail = psofail + 1;
                set(handles.t_psofailures,'String',num2str(psofail));
                
                % Clear valures for a failure
                psoAtr(j,1) = 0;
                psoAv(j,1)  = 0;
                psoAt(j,1)  = 0;
                psoAtr(j,2) = 0;
                psoAv(j,2)  = 0;
                psoAt(j,2)  = 0;

                psoFtr(j) = 0;    
                psoFv(j)  = 0;    
                psoFt(j)  = 0;    

                psosim(j) = 0;
                psoeval(j)= 0;
                psoRes(j) = 0;
            end
        end

        % Saving the best ANNs
        if alls == 0
            if fpso && psoAt(j,2) >= bestpsoAt && psoFt(j,2) <= bestpsoFt
                bestpsoAt = psoAt(j,2);
                bestpsoFt = psoFt(j,2);
                psoANN    = get(handles.t_pso,'UserData');
            end
            if fea  && eaAt(j,2) >= besteaAt && eaFt(j,2) <= besteaFt
                besteaAt = eaAt(j,2);
                besteaFt = eaFt(j,2);
                eaANN    = get(handles.t_ea,'UserData');
            end
            if fbp  && bpAt(j,2) >= bestbpAt && bpFt(j,2) <= bestbpFt
                bestbpAt = bpAt(j,2);
                bestbpFt = bpFt(j,2);
                bpANN    = get(handles.t_bp,'UserData');
            end
        end
        
    end % End of repetitions


    if fbp
        bpr = nRep - bpfail;

        set(handles.t_bpAtr,'String',num2str(sum(bpAtr(:,1))/bpr));
        set(handles.t_bpAv,'String',num2str(sum(bpAv(:,1))/bpr));
        set(handles.t_bpAt,'String',num2str(sum(bpAt(:,1))/bpr));
        set(handles.t_bpAptr,'String',num2str(sum(bpAtr(:,2))/bpr));
        set(handles.t_bpApv,'String',num2str(sum(bpAv(:,2))/bpr));
        set(handles.t_bpApt,'String',num2str(sum(bpAt(:,2))/bpr));

        set(handles.t_bpFtr,'String',num2str(sum(bpFtr)/bpr));
        set(handles.t_bpFv,'String',num2str(sum(bpFv)/bpr));
        set(handles.t_bpFt,'String',num2str(sum(bpFt)/bpr));

        set(handles.t_bpRes,'String',num2str(sum(bpRes)/bpr));    
        set(handles.t_bpsims,'String',num2str(sum(bpsim)/bpr));
        set(handles.t_bpeval,'String',num2str(sum(bpeval)/bpr));
        set(handles.t_bpfailures,'String',num2str(bpfail));

        
        % Accuracy only from testing setss
        bpAnt  = bpAt(find(bpAt(:,1)),1);    % remove the 0s from failures
        bpApt  = bpAt(find(bpAt(:,2)),2);    % remove the 0s from failures
        if isempty(bpAnt)
            bpAnt = 0;
        end
        if isempty(bpApt)
            bpApt = 0;
        end
        
        % Accuracy considering all sets
        bpA = mean([bpAtr(:,1) bpAv(:,1) bpAt(:,1)],2);
        bpA = bpA(find(bpA));       % remove the 0s from failures
        bpAp = mean([bpAtr(:,2) bpAv(:,2) bpAt(:,2)],2);
        bpAp = bpAp(find(bpAp));    % remove the 0s from failures
        if isempty(bpA)
            bpA = 0;
        end
        if isempty(bpAp)
            bpAp = 0;
        end

        %fitness
        bpF = mean([bpFtr bpFv bpFt],2);
        bpF = bpF(find(bpF));
        bpFt = bpFt(find(bpFt));
        if isempty(bpF)
            bpF = 0;
        end
        if isempty(bpFt)
            bpFt = zeros(nRep,1);
        end
                
        
        bpAAt(i,:)  = [mean(bpAnt) max(bpAnt) min(bpAnt) std(bpAnt)];
        bpAApt(i,:) = [mean(bpApt) max(bpApt) min(bpApt) std(bpApt)];
        bpAFt(i,:)  = [mean(bpFt) max(bpFt) min(bpFt) std(bpFt)];

        bpAA(i,:)   = [mean(bpA) max(bpA) min(bpA) std(bpA)];
        bpAAp(i,:)  = [mean(bpAp) max(bpAp) min(bpAp) std(bpAp)];
        bpAF(i,:)   = [mean(bpF) max(bpF) min(bpF) std(bpF)];

        bpAR(i,:)   = [sum(bpsim)/bpr sum(bpeval)/bpr bpfail sum(bpRes)/bpr];

        stats.bpAt   = bpAAt;        
        stats.bpApt  = bpAApt;        
        stats.bpFt   = bpAFt;        
        stats.bpA    = bpAA;        
        stats.bpAp   = bpAAp;        
        stats.bpF    = bpAF;
        stats.bpR    = bpAR;
        
        save('statstemp.mat','stats');
    end

    % Save pso results
    if fpso
        psor = nRep - psofail;

        set(handles.t_psoAtr,'String',num2str(sum(psoAtr(:,1))/psor));
        set(handles.t_psoAv,'String',num2str(sum(psoAv(:,1))/psor));
        set(handles.t_psoAt,'String',num2str(sum(psoAt(:,1))/psor));
        set(handles.t_psoAptr,'String',num2str(sum(psoAtr(:,2))/psor));
        set(handles.t_psoApv,'String',num2str(sum(psoAv(:,2))/psor));
        set(handles.t_psoApt,'String',num2str(sum(psoAt(:,2))/psor));

        set(handles.t_psoFtr,'String',num2str(sum(psoFtr)/psor));
        set(handles.t_psoFv,'String',num2str(sum(psoFv)/psor));
        set(handles.t_psoFt,'String',num2str(sum(psoFt)/psor));

        set(handles.t_psoRes,'String',num2str(sum(psoRes)/psor));    
        set(handles.t_psosims,'String',num2str(sum(psosim)/psor));
        set(handles.t_psoeval,'String',num2str(sum(psoeval)/psor));
        set(handles.t_psofailures,'String',num2str(psofail));

        
        % Accuracy only from testing setss
        psoAnt  = psoAt(find(psoAt(:,1)),1);    % remove the 0s from failures
        psoApt  = psoAt(find(psoAt(:,2)),2);    % remove the 0s from failures
        if isempty(psoAnt)
            psoAnt = 0;
        end
        if isempty(bpApt)
            psoApt = 0;
        end
        
        % Accuracy considering all sets
        psoA = mean([psoAtr(:,1) psoAv(:,1) psoAt(:,1)],2);
        psoA = psoA(find(psoA));       % remove the 0s from failures
        psoAp = mean([psoAtr(:,2) psoAv(:,2) psoAt(:,2)],2);
        psoAp = psoAp(find(psoAp));    % remove the 0s from failures
        if isempty(psoA)
            psoA = 0;
        end
        if isempty(psoAp)
            psoAp = 0;
        end

        %fitness
        psoF = mean([psoFtr psoFv psoFt],2);
        psoF = psoF(find(psoF));
        psoFt = psoFt(find(psoFt));
        if isempty(psoF)
            psoF = 0;
        end
        if isempty(psoFt)
            psoFt = zeros(nRep,1);
        end
                
        
        psoAAt(i,:)  = [mean(psoAnt) max(psoAnt) min(psoAnt) std(psoAnt)];
        psoAApt(i,:) = [mean(psoApt) max(psoApt) min(psoApt) std(psoApt)];
        psoAFt(i,:)  = [mean(psoFt) max(psoFt) min(psoFt) std(psoFt)];

        psoAA(i,:)   = [mean(psoA) max(psoA) min(psoA) std(psoA)];
        psoAAp(i,:)  = [mean(psoAp) max(psoAp) min(psoAp) std(psoAp)];
        psoAF(i,:)   = [mean(psoF) max(psoF) min(psoF) std(psoF)];

        psoAR(i,:)   = [sum(psosim)/psor sum(psoeval)/psor psofail sum(psoRes)/psor];

        stats.psoAt   = psoAAt;        
        stats.psoApt  = psoAApt;        
        stats.psoFt   = psoAFt;        
        stats.psoA    = psoAA;        
        stats.psoAp   = psoAAp;        
        stats.psoF    = psoAF;
        stats.psoR    = psoAR;
        
        save('statstemp.mat','stats');
    end


    set(handles.t_msg2,'String','Statistics for Training PRA DONE!');    
    save('stats.mat','stats');
end

if alls == 0
    if fpso
        set(handles.t_pso,'UserData',psoANN);
    end
    if fea
        set(handles.t_ea,'UserData',eaANN);
    end
    if fbp
        set(handles.t_bp,'UserData',bpANN);
    end
end


% --- Executes on button press in pb_download.
function pb_download_Callback(hObject, eventdata, handles)
% hObject    handle to pb_download (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
bpANN = get(handles.t_bp,'UserData');

set(handles.t_msg,'String','Downloading...');
if handles.com.checkSettings(bpANN)==1
    if handles.com.setWeights(bpANN)==1
        set(handles.t_msg,'String','Weights downloaded, download bias...');
        pause(0.5);
        if handles.com.setBias(bpANN)==1
            set(handles.t_msg,'String','ANN downloaded correctly');
        else
            set(handles.t_msg,'String','Error downloading ANN');
        end
    else
        set(handles.t_msg,'String','Error downloading ANN');
    end
else
    set(handles.t_msg,'String','Settings dont match');
end



function et_com_Callback(hObject, eventdata, handles)
% hObject    handle to et_com (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_com as text
%        str2double(get(hObject,'String')) returns contents of et_com as a double


% --- Executes during object creation, after setting all properties.
function et_com_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_com (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_start.
function pb_start_Callback(hObject, eventdata, handles)
% hObject    handle to pb_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.com.write('R'); %Write R to start program
set(handles.t_msg,'String','Running');


% --- Executes on button press in pb_stop.
function pb_stop_Callback(hObject, eventdata, handles)
% hObject    handle to pb_stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA
handles.com.write('S'); %Write S to stop program
set(handles.t_msg,'String','Stopped');



% --- Executes on button press in pb_load.
function pb_load_Callback(hObject, eventdata, handles)
    t_open_ClickedCallback(hObject, eventdata, handles)


% --- Executes on button press in pb_connect.
function pb_connect_Callback(hObject, eventdata, handles)
% hObject    handle to pb_connect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

compath = get(handles.et_com,'String');
handles.com = mastercom(compath);
if handles.com.testConnection()==1; %Write S to stop program
    set(handles.t_msg,'String','Connection established');
    set(handles.pb_connect,'enable','off');
    set(handles.pb_disconnect,'enable','on');
    set(handles.pb_load,'enable','on');
    set(handles.pb_download,'enable','on');
    set(handles.pb_start,'enable','on');
    set(handles.pb_stop,'enable','on');
    set(handles.cb_norm,'enable','on');
    set(handles.cb_show,'enable','on');

    guidata(hObject,handles);
else
    set(handles.t_msg,'String','Wrong connection');
    handles.com.close();
end
    


% --- Executes on button press in cb_show.
function cb_show_Callback(hObject, eventdata, handles)

while get(hObject,'Value')==1
    read=handles.com.read();
    set(handles.t_msg,'String',read(1));
    if read(1)>0 && read(1)<12
        backgroundImage = importdata(['Img\mov' num2str(read(1)) '.jpg']);
    else
        backgroundImage = importdata('Img\relax.jpg');
    end
    image(backgroundImage);
    axis off    
    pause(0.2);
end


% --- Executes on button press in cb_norm.
function cb_norm_Callback(hObject, eventdata, handles)
    %Send function code for normalize
    handles.com.write('N'); 
    pause(0.5);
    
    %Send normalization on/off
    handles.com.write(get(hObject,'Value'));


% --- Executes on button press in pb_disconnect.
function pb_disconnect_Callback(hObject, eventdata, handles)
handles.com.close();
set(handles.pb_connect,'enable','on');
set(handles.pb_disconnect,'enable','off');
set(handles.pb_load,'enable','off');
set(handles.pb_download,'enable','off');
set(handles.pb_start,'enable','off');
set(handles.pb_stop,'enable','off');
set(handles.cb_norm,'enable','off');
set(handles.cb_show,'enable','off');
set(handles.t_msg,'String','Disconnected');


% --- Executes during object creation, after setting all properties.
function pb_load_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pb_load (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

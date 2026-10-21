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

function varargout = recording_session_show_fig(varargin)
% RECORDING_SESSION_SHOW_FIG M-file for recording_session_show_fig.fig
%      RECORDING_SESSION_SHOW_FIG, by itself, creates a new RECORDING_SESSION_SHOW_FIG or raises the existing
%      singleton*.
%
%      H = RECORDING_SESSION_SHOW_FIG returns the handle to a new RECORDING_SESSION_SHOW_FIG or the handle to
%      the existing singleton*.
%
%      RECORDING_SESSION_SHOW_FIG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RECORDING_SESSION_SHOW_FIG.M with the given input arguments.
%
%      RECORDING_SESSION_SHOW_FIG('Property','Value',...) creates a new RECORDING_SESSION_SHOW_FIG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before recording_session_show_fig_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to recording_session_show_fig_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help recording_session_show_fig

% Last Modified by GUIDE v2.5 20-Apr-2009 10:32:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @recording_session_show_fig_OpeningFcn, ...
                   'gui_OutputFcn',  @recording_session_show_fig_OutputFcn, ...
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


% --- Executes just before recording_session_show_fig is made visible.
function recording_session_show_fig_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to recording_session_show_fig (see VARARGIN)


%load the background image into Matlab
%if image is not in the same directory as the GUI files, you must use the 
%full path name of the iamge file
backgroundImage = importdata('Img/surface.jpg');
%select the axes
axes(handles.axes1);
%place image onto the axes
image(backgroundImage);
%remove the axis tick marks
axis off


% Choose default command line output for recording_session_show_fig
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes recording_session_show_fig wait for user response (see UIRESUME)


% --- Outputs from this function are returned to the command line.
function varargout = recording_session_show_fig_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function et_Fs_Callback(hObject, eventdata, handles)
    input = str2double(get(hObject,'String'));
    if (isempty(input))
         set(hObject,'String','0')
    end
    guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function et_Fs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_Fs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_Ne_Callback(hObject, eventdata, handles)
    input = str2double(get(hObject,'String'));
    if (isempty(input))
         set(hObject,'String','0')
    end
    guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function et_Ne_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_Ne (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_Nr_Callback(hObject, eventdata, handles)
    input = str2double(get(hObject,'String'));
    if (isempty(input))
         set(hObject,'String','0')
    end
    guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function et_Nr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_Nr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_Tc_Callback(hObject, eventdata, handles)
    input = str2double(get(hObject,'String'));
    if (isempty(input))
         set(hObject,'String','0')
    end
    guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function et_Tc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_Tc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_Tr_Callback(hObject, eventdata, handles)
    input = str2double(get(hObject,'String'));
    if (isempty(input))
         set(hObject,'String','0')
    end
    guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function et_Tr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_Tr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_Psr_Callback(hObject, eventdata, handles)
    input = str2double(get(hObject,'String'));
    if (isempty(input))
         set(hObject,'String','0')
    end
    guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function et_Psr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_Psr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function et_msg_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_msg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



function et_msg_Callback(hObject, eventdata, handles)
    num = get(handles.et_msg,'value');
    backgroundImage = importdata(['/../Img/mov' num2str(num) '.JPG']);
    image(backgroundImage);
    axis off


% --- Executes on button press in pb_load.
function pb_load_Callback(hObject, eventdata, handles)
    % get the EMG_AQ Handles
    %h1 = get(handles.t_mhandles,'UserData'); 
    %EMG_AQhandle = guidata(h1);
    EMG_AQhandle = get(handles.t_mhandles,'UserData');

    Fs = str2double(get(handles.et_Fs,'String')); % Sampling Frequency
    Ne = get(handles.pm_Ne,'Value');              % number of excersices or movements
    ss = get(handles.pm_data,'UserData');
    Ts = ss.Ts;
    if get(handles.pm_data,'Value') == 1
        cdata = ss.tdata(:,:,Ne);
    else
        cdata = ss.trdata(:,:,Ne);
    end
    data_show(EMG_AQhandle,cdata,Fs,Ts);
    save('cdata.mat','cdata','Fs','Ts');



% --- Executes on button press in pb_cancel.
function pb_cancel_Callback(hObject, eventdata, handles)
    close(recording_session_show_fig);


% --- Executes on selection change in pm_data.
function pm_data_Callback(hObject, eventdata, handles)
% hObject    handle to pm_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns pm_data contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pm_data


% --- Executes during object creation, after setting all properties.
function pm_data_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pm_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pm_Ne.
function pm_Ne_Callback(hObject, eventdata, handles)
% hObject    handle to pm_Ne (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns pm_Ne contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pm_Ne


% --- Executes during object creation, after setting all properties.
function pm_Ne_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pm_Ne (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



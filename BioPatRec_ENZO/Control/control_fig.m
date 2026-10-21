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

function varargout = control_fig(varargin)
% CONTROL_FIG M-file for control_fig.fig
%      CONTROL_FIG, by itself, creates a new CONTROL_FIG or raises the existing
%      singleton*.
%
%      H = CONTROL_FIG returns the handle to a new CONTROL_FIG or the handle to
%      the existing singleton*.
%
%      CONTROL_FIG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CONTROL_FIG.M with the given input arguments.
%
%      CONTROL_FIG('Property','Value',...) creates a new CONTROL_FIG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before control_fig_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to control_fig_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help control_fig

% Last Modified by GUIDE v2.5 10-Jul-2009 16:23:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @control_fig_OpeningFcn, ...
                   'gui_OutputFcn',  @control_fig_OutputFcn, ...
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


% --- Executes just before control_fig is made visible.
function control_fig_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to control_fig (see VARARGIN)

% Choose default command line output for control_fig
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes control_fig wait for user response (see UIRESUME)
% uiwait(handles.ctrl_fig);


% --- Outputs from this function are returned to the command line.
function varargout = control_fig_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pb_start.
function pb_start_Callback(hObject, eventdata, handles)
    recbreakpres(handles)

% --- Executes on button press in pb_control.
function pb_control_Callback(hObject, eventdata, handles)

    [amin amax] = get_minmaxAmp(handles);

% --- Executes on button press in cb_tmn.
function cb_tmn_Callback(hObject, eventdata, handles)
% hObject    handle to cb_tmn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_tmn



function et_tmn1_Callback(hObject, eventdata, handles)
% hObject    handle to et_tmn1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tmn1 as text
%        str2double(get(hObject,'String')) returns contents of et_tmn1 as a double


% --- Executes during object creation, after setting all properties.
function et_tmn1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tmn1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
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



function et_Fs_Callback(hObject, eventdata, handles)
% hObject    handle to et_Fs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_Fs as text
%        str2double(get(hObject,'String')) returns contents of et_Fs as a double


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



function et_Tp_Callback(hObject, eventdata, handles)
% hObject    handle to et_Tp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_Tp as text
%        str2double(get(hObject,'String')) returns contents of et_Tp as a double


% --- Executes during object creation, after setting all properties.
function et_Tp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_Tp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cb_tmabs.
function cb_tmabs_Callback(hObject, eventdata, handles)
% hObject    handle to cb_tmabs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_tmabs



function et_cIdx2_Callback(hObject, eventdata, handles)
% hObject    handle to et_cIdx2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_cIdx2 as text
%        str2double(get(hObject,'String')) returns contents of et_cIdx2 as a double


% --- Executes during object creation, after setting all properties.
function et_cIdx2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_cIdx2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cb_tmd.
function cb_tmd_Callback(hObject, eventdata, handles)
% hObject    handle to cb_tmd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_tmd


% --- Executes on button press in cb_tmod.
function cb_tmod_Callback(hObject, eventdata, handles)
% hObject    handle to cb_tmod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_tmod


% --- Executes on button press in cb_tstd.
function cb_tstd_Callback(hObject, eventdata, handles)
% hObject    handle to cb_tstd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_tstd


% --- Executes on button press in cb_tvar.
function cb_tvar_Callback(hObject, eventdata, handles)
% hObject    handle to cb_tvar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_tvar



function et_tmn2_Callback(hObject, eventdata, handles)
% hObject    handle to et_tmn2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tmn2 as text
%        str2double(get(hObject,'String')) returns contents of et_tmn2 as a double


% --- Executes during object creation, after setting all properties.
function et_tmn2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tmn2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tmn3_Callback(hObject, eventdata, handles)
% hObject    handle to et_tmn3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tmn3 as text
%        str2double(get(hObject,'String')) returns contents of et_tmn3 as a double


% --- Executes during object creation, after setting all properties.
function et_tmn3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tmn3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tmn4_Callback(hObject, eventdata, handles)
% hObject    handle to et_tmn4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tmn4 as text
%        str2double(get(hObject,'String')) returns contents of et_tmn4 as a double


% --- Executes during object creation, after setting all properties.
function et_tmn4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tmn4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tmabs1_Callback(hObject, eventdata, handles)
% hObject    handle to et_tmabs1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tmabs1 as text
%        str2double(get(hObject,'String')) returns contents of et_tmabs1 as a double


% --- Executes during object creation, after setting all properties.
function et_tmabs1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tmabs1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tmabs2_Callback(hObject, eventdata, handles)
% hObject    handle to et_tmabs2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tmabs2 as text
%        str2double(get(hObject,'String')) returns contents of et_tmabs2 as a double


% --- Executes during object creation, after setting all properties.
function et_tmabs2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tmabs2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tmabs3_Callback(hObject, eventdata, handles)
% hObject    handle to et_tmabs3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tmabs3 as text
%        str2double(get(hObject,'String')) returns contents of et_tmabs3 as a double


% --- Executes during object creation, after setting all properties.
function et_tmabs3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tmabs3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tmabs4_Callback(hObject, eventdata, handles)
% hObject    handle to et_tmabs4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tmabs4 as text
%        str2double(get(hObject,'String')) returns contents of et_tmabs4 as a double


% --- Executes during object creation, after setting all properties.
function et_tmabs4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tmabs4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tmd1_Callback(hObject, eventdata, handles)
% hObject    handle to et_tmd1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tmd1 as text
%        str2double(get(hObject,'String')) returns contents of et_tmd1 as a double


% --- Executes during object creation, after setting all properties.
function et_tmd1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tmd1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tmd2_Callback(hObject, eventdata, handles)
% hObject    handle to et_tmd2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tmd2 as text
%        str2double(get(hObject,'String')) returns contents of et_tmd2 as a double


% --- Executes during object creation, after setting all properties.
function et_tmd2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tmd2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tmd3_Callback(hObject, eventdata, handles)
% hObject    handle to et_tmd3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tmd3 as text
%        str2double(get(hObject,'String')) returns contents of et_tmd3 as a double


% --- Executes during object creation, after setting all properties.
function et_tmd3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tmd3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tmd4_Callback(hObject, eventdata, handles)
% hObject    handle to et_tmd4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tmd4 as text
%        str2double(get(hObject,'String')) returns contents of et_tmd4 as a double


% --- Executes during object creation, after setting all properties.
function et_tmd4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tmd4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tmod1_Callback(hObject, eventdata, handles)
% hObject    handle to et_tmod1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tmod1 as text
%        str2double(get(hObject,'String')) returns contents of et_tmod1 as a double


% --- Executes during object creation, after setting all properties.
function et_tmod1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tmod1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tmod2_Callback(hObject, eventdata, handles)
% hObject    handle to et_tmod2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tmod2 as text
%        str2double(get(hObject,'String')) returns contents of et_tmod2 as a double


% --- Executes during object creation, after setting all properties.
function et_tmod2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tmod2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tmod3_Callback(hObject, eventdata, handles)
% hObject    handle to et_tmod3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tmod3 as text
%        str2double(get(hObject,'String')) returns contents of et_tmod3 as a double


% --- Executes during object creation, after setting all properties.
function et_tmod3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tmod3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tmod4_Callback(hObject, eventdata, handles)
% hObject    handle to et_tmod4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tmod4 as text
%        str2double(get(hObject,'String')) returns contents of et_tmod4 as a double


% --- Executes during object creation, after setting all properties.
function et_tmod4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tmod4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tstd1_Callback(hObject, eventdata, handles)
% hObject    handle to et_tstd1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tstd1 as text
%        str2double(get(hObject,'String')) returns contents of et_tstd1 as a double


% --- Executes during object creation, after setting all properties.
function et_tstd1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tstd1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tstd2_Callback(hObject, eventdata, handles)
% hObject    handle to et_tstd2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tstd2 as text
%        str2double(get(hObject,'String')) returns contents of et_tstd2 as a double


% --- Executes during object creation, after setting all properties.
function et_tstd2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tstd2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tstd3_Callback(hObject, eventdata, handles)
% hObject    handle to et_tstd3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tstd3 as text
%        str2double(get(hObject,'String')) returns contents of et_tstd3 as a double


% --- Executes during object creation, after setting all properties.
function et_tstd3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tstd3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tstd4_Callback(hObject, eventdata, handles)
% hObject    handle to et_tstd4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tstd4 as text
%        str2double(get(hObject,'String')) returns contents of et_tstd4 as a double


% --- Executes during object creation, after setting all properties.
function et_tstd4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tstd4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tvar1_Callback(hObject, eventdata, handles)
% hObject    handle to et_tvar1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tvar1 as text
%        str2double(get(hObject,'String')) returns contents of et_tvar1 as a double


% --- Executes during object creation, after setting all properties.
function et_tvar1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tvar1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tvar2_Callback(hObject, eventdata, handles)
% hObject    handle to et_tvar2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tvar2 as text
%        str2double(get(hObject,'String')) returns contents of et_tvar2 as a double


% --- Executes during object creation, after setting all properties.
function et_tvar2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tvar2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tvar3_Callback(hObject, eventdata, handles)
% hObject    handle to et_tvar3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tvar3 as text
%        str2double(get(hObject,'String')) returns contents of et_tvar3 as a double


% --- Executes during object creation, after setting all properties.
function et_tvar3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tvar3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tvar4_Callback(hObject, eventdata, handles)
% hObject    handle to et_tvar4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tvar4 as text
%        str2double(get(hObject,'String')) returns contents of et_tvar4 as a double


% --- Executes during object creation, after setting all properties.
function et_tvar4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tvar4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cb_twl.
function cb_twl_Callback(hObject, eventdata, handles)
% hObject    handle to cb_twl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_twl



function et_twl1_Callback(hObject, eventdata, handles)
% hObject    handle to et_twl1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_twl1 as text
%        str2double(get(hObject,'String')) returns contents of et_twl1 as a double


% --- Executes during object creation, after setting all properties.
function et_twl1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_twl1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cb_trms.
function cb_trms_Callback(hObject, eventdata, handles)
% hObject    handle to cb_trms (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_trms


% --- Executes on button press in cb_tzc.
function cb_tzc_Callback(hObject, eventdata, handles)
% hObject    handle to cb_tzc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_tzc


% --- Executes on button press in cb_tpks.
function cb_tpks_Callback(hObject, eventdata, handles)
% hObject    handle to cb_tpks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_tpks


% --- Executes on button press in cb_tmpks.
function cb_tmpks_Callback(hObject, eventdata, handles)
% hObject    handle to cb_tmpks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_tmpks


% --- Executes on button press in cb_tmvel.
function cb_tmvel_Callback(hObject, eventdata, handles)
% hObject    handle to cb_tmvel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_tmvel



function et_twl2_Callback(hObject, eventdata, handles)
% hObject    handle to et_twl2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_twl2 as text
%        str2double(get(hObject,'String')) returns contents of et_twl2 as a double


% --- Executes during object creation, after setting all properties.
function et_twl2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_twl2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_twl3_Callback(hObject, eventdata, handles)
% hObject    handle to et_twl3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_twl3 as text
%        str2double(get(hObject,'String')) returns contents of et_twl3 as a double


% --- Executes during object creation, after setting all properties.
function et_twl3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_twl3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_twl4_Callback(hObject, eventdata, handles)
% hObject    handle to et_twl4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_twl4 as text
%        str2double(get(hObject,'String')) returns contents of et_twl4 as a double


% --- Executes during object creation, after setting all properties.
function et_twl4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_twl4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_trms1_Callback(hObject, eventdata, handles)
% hObject    handle to et_trms1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_trms1 as text
%        str2double(get(hObject,'String')) returns contents of et_trms1 as a double


% --- Executes during object creation, after setting all properties.
function et_trms1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_trms1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_trms2_Callback(hObject, eventdata, handles)
% hObject    handle to et_trms2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_trms2 as text
%        str2double(get(hObject,'String')) returns contents of et_trms2 as a double


% --- Executes during object creation, after setting all properties.
function et_trms2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_trms2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_trms3_Callback(hObject, eventdata, handles)
% hObject    handle to et_trms3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_trms3 as text
%        str2double(get(hObject,'String')) returns contents of et_trms3 as a double


% --- Executes during object creation, after setting all properties.
function et_trms3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_trms3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_trms4_Callback(hObject, eventdata, handles)
% hObject    handle to et_trms4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_trms4 as text
%        str2double(get(hObject,'String')) returns contents of et_trms4 as a double


% --- Executes during object creation, after setting all properties.
function et_trms4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_trms4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tzc1_Callback(hObject, eventdata, handles)
% hObject    handle to et_tzc1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tzc1 as text
%        str2double(get(hObject,'String')) returns contents of et_tzc1 as a double


% --- Executes during object creation, after setting all properties.
function et_tzc1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tzc1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tzc2_Callback(hObject, eventdata, handles)
% hObject    handle to et_tzc2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tzc2 as text
%        str2double(get(hObject,'String')) returns contents of et_tzc2 as a double


% --- Executes during object creation, after setting all properties.
function et_tzc2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tzc2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tzc3_Callback(hObject, eventdata, handles)
% hObject    handle to et_tzc3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tzc3 as text
%        str2double(get(hObject,'String')) returns contents of et_tzc3 as a double


% --- Executes during object creation, after setting all properties.
function et_tzc3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tzc3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tzc4_Callback(hObject, eventdata, handles)
% hObject    handle to et_tzc4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tzc4 as text
%        str2double(get(hObject,'String')) returns contents of et_tzc4 as a double


% --- Executes during object creation, after setting all properties.
function et_tzc4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tzc4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tpks1_Callback(hObject, eventdata, handles)
% hObject    handle to et_tpks1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tpks1 as text
%        str2double(get(hObject,'String')) returns contents of et_tpks1 as a double


% --- Executes during object creation, after setting all properties.
function et_tpks1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tpks1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tpks2_Callback(hObject, eventdata, handles)
% hObject    handle to et_tpks2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tpks2 as text
%        str2double(get(hObject,'String')) returns contents of et_tpks2 as a double


% --- Executes during object creation, after setting all properties.
function et_tpks2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tpks2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tpks3_Callback(hObject, eventdata, handles)
% hObject    handle to et_tpks3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tpks3 as text
%        str2double(get(hObject,'String')) returns contents of et_tpks3 as a double


% --- Executes during object creation, after setting all properties.
function et_tpks3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tpks3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tpks4_Callback(hObject, eventdata, handles)
% hObject    handle to et_tpks4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tpks4 as text
%        str2double(get(hObject,'String')) returns contents of et_tpks4 as a double


% --- Executes during object creation, after setting all properties.
function et_tpks4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tpks4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tmpks1_Callback(hObject, eventdata, handles)
% hObject    handle to et_tmpks1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tmpks1 as text
%        str2double(get(hObject,'String')) returns contents of et_tmpks1 as a double


% --- Executes during object creation, after setting all properties.
function et_tmpks1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tmpks1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tmpks2_Callback(hObject, eventdata, handles)
% hObject    handle to et_tmpks2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tmpks2 as text
%        str2double(get(hObject,'String')) returns contents of et_tmpks2 as a double


% --- Executes during object creation, after setting all properties.
function et_tmpks2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tmpks2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tmpks3_Callback(hObject, eventdata, handles)
% hObject    handle to et_tmpks3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tmpks3 as text
%        str2double(get(hObject,'String')) returns contents of et_tmpks3 as a double


% --- Executes during object creation, after setting all properties.
function et_tmpks3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tmpks3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tmpks4_Callback(hObject, eventdata, handles)
% hObject    handle to et_tmpks4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tmpks4 as text
%        str2double(get(hObject,'String')) returns contents of et_tmpks4 as a double


% --- Executes during object creation, after setting all properties.
function et_tmpks4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tmpks4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tmvel1_Callback(hObject, eventdata, handles)
% hObject    handle to et_tmvel1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tmvel1 as text
%        str2double(get(hObject,'String')) returns contents of et_tmvel1 as a double


% --- Executes during object creation, after setting all properties.
function et_tmvel1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tmvel1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tmvel2_Callback(hObject, eventdata, handles)
% hObject    handle to et_tmvel2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tmvel2 as text
%        str2double(get(hObject,'String')) returns contents of et_tmvel2 as a double


% --- Executes during object creation, after setting all properties.
function et_tmvel2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tmvel2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tmvel3_Callback(hObject, eventdata, handles)
% hObject    handle to et_tmvel3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tmvel3 as text
%        str2double(get(hObject,'String')) returns contents of et_tmvel3 as a double


% --- Executes during object creation, after setting all properties.
function et_tmvel3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tmvel3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tmvel4_Callback(hObject, eventdata, handles)
% hObject    handle to et_tmvel4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tmvel4 as text
%        str2double(get(hObject,'String')) returns contents of et_tmvel4 as a double


% --- Executes during object creation, after setting all properties.
function et_tmvel4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tmvel4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cb_tslpch.
function cb_tslpch_Callback(hObject, eventdata, handles)
% hObject    handle to cb_tslpch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_tslpch


% --- Executes on button press in cb_cr.
function cb_cr_Callback(hObject, eventdata, handles)
% hObject    handle to cb_cr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_cr


% --- Executes on button press in cb_cv.
function cb_cv_Callback(hObject, eventdata, handles)
% hObject    handle to cb_cv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_cv


% --- Executes on button press in cb_fwl.
function cb_fwl_Callback(hObject, eventdata, handles)
% hObject    handle to cb_fwl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_fwl



function et_tslpch1_Callback(hObject, eventdata, handles)
% hObject    handle to et_tslpch1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tslpch1 as text
%        str2double(get(hObject,'String')) returns contents of et_tslpch1 as a double


% --- Executes during object creation, after setting all properties.
function et_tslpch1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tslpch1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tslpch2_Callback(hObject, eventdata, handles)
% hObject    handle to et_tslpch2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tslpch2 as text
%        str2double(get(hObject,'String')) returns contents of et_tslpch2 as a double


% --- Executes during object creation, after setting all properties.
function et_tslpch2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tslpch2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tslpch3_Callback(hObject, eventdata, handles)
% hObject    handle to et_tslpch3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tslpch3 as text
%        str2double(get(hObject,'String')) returns contents of et_tslpch3 as a double


% --- Executes during object creation, after setting all properties.
function et_tslpch3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tslpch3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tslpch4_Callback(hObject, eventdata, handles)
% hObject    handle to et_tslpch4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tslpch4 as text
%        str2double(get(hObject,'String')) returns contents of et_tslpch4 as a double


% --- Executes during object creation, after setting all properties.
function et_tslpch4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tslpch4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_cr1_Callback(hObject, eventdata, handles)
% hObject    handle to et_cr1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_cr1 as text
%        str2double(get(hObject,'String')) returns contents of et_cr1 as a double


% --- Executes during object creation, after setting all properties.
function et_cr1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_cr1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_cr2_Callback(hObject, eventdata, handles)
% hObject    handle to et_cr2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_cr2 as text
%        str2double(get(hObject,'String')) returns contents of et_cr2 as a double


% --- Executes during object creation, after setting all properties.
function et_cr2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_cr2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_cr3_Callback(hObject, eventdata, handles)
% hObject    handle to et_cr3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_cr3 as text
%        str2double(get(hObject,'String')) returns contents of et_cr3 as a double


% --- Executes during object creation, after setting all properties.
function et_cr3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_cr3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_cr4_Callback(hObject, eventdata, handles)
% hObject    handle to et_cr4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_cr4 as text
%        str2double(get(hObject,'String')) returns contents of et_cr4 as a double


% --- Executes during object creation, after setting all properties.
function et_cr4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_cr4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_cv1_Callback(hObject, eventdata, handles)
% hObject    handle to et_cv1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_cv1 as text
%        str2double(get(hObject,'String')) returns contents of et_cv1 as a double


% --- Executes during object creation, after setting all properties.
function et_cv1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_cv1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_cv2_Callback(hObject, eventdata, handles)
% hObject    handle to et_cv2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_cv2 as text
%        str2double(get(hObject,'String')) returns contents of et_cv2 as a double


% --- Executes during object creation, after setting all properties.
function et_cv2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_cv2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_cv3_Callback(hObject, eventdata, handles)
% hObject    handle to et_cv3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_cv3 as text
%        str2double(get(hObject,'String')) returns contents of et_cv3 as a double


% --- Executes during object creation, after setting all properties.
function et_cv3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_cv3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_cv4_Callback(hObject, eventdata, handles)
% hObject    handle to et_cv4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_cv4 as text
%        str2double(get(hObject,'String')) returns contents of et_cv4 as a double


% --- Executes during object creation, after setting all properties.
function et_cv4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_cv4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_fwl1_Callback(hObject, eventdata, handles)
% hObject    handle to et_fwl1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_fwl1 as text
%        str2double(get(hObject,'String')) returns contents of et_fwl1 as a double


% --- Executes during object creation, after setting all properties.
function et_fwl1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_fwl1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_fwl2_Callback(hObject, eventdata, handles)
% hObject    handle to et_fwl2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_fwl2 as text
%        str2double(get(hObject,'String')) returns contents of et_fwl2 as a double


% --- Executes during object creation, after setting all properties.
function et_fwl2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_fwl2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_fwl3_Callback(hObject, eventdata, handles)
% hObject    handle to et_fwl3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_fwl3 as text
%        str2double(get(hObject,'String')) returns contents of et_fwl3 as a double


% --- Executes during object creation, after setting all properties.
function et_fwl3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_fwl3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_fwl4_Callback(hObject, eventdata, handles)
% hObject    handle to et_fwl4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_fwl4 as text
%        str2double(get(hObject,'String')) returns contents of et_fwl4 as a double


% --- Executes during object creation, after setting all properties.
function et_fwl4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_fwl4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cb_fmn.
function cb_fmn_Callback(hObject, eventdata, handles)
% hObject    handle to cb_fmn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_fmn



function et_fmn1_Callback(hObject, eventdata, handles)
% hObject    handle to et_fmn1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_fmn1 as text
%        str2double(get(hObject,'String')) returns contents of et_fmn1 as a double


% --- Executes during object creation, after setting all properties.
function et_fmn1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_fmn1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_fmn2_Callback(hObject, eventdata, handles)
% hObject    handle to et_fmn2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_fmn2 as text
%        str2double(get(hObject,'String')) returns contents of et_fmn2 as a double


% --- Executes during object creation, after setting all properties.
function et_fmn2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_fmn2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_fmn3_Callback(hObject, eventdata, handles)
% hObject    handle to et_fmn3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_fmn3 as text
%        str2double(get(hObject,'String')) returns contents of et_fmn3 as a double


% --- Executes during object creation, after setting all properties.
function et_fmn3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_fmn3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_fmn4_Callback(hObject, eventdata, handles)
% hObject    handle to et_fmn4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_fmn4 as text
%        str2double(get(hObject,'String')) returns contents of et_fmn4 as a double


% --- Executes during object creation, after setting all properties.
function et_fmn4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_fmn4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cb_fmd.
function cb_fmd_Callback(hObject, eventdata, handles)
% hObject    handle to cb_fmd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_fmd



function et_fmd1_Callback(hObject, eventdata, handles)
% hObject    handle to et_fmd1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_fmd1 as text
%        str2double(get(hObject,'String')) returns contents of et_fmd1 as a double


% --- Executes during object creation, after setting all properties.
function et_fmd1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_fmd1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_fmd2_Callback(hObject, eventdata, handles)
% hObject    handle to et_fmd2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_fmd2 as text
%        str2double(get(hObject,'String')) returns contents of et_fmd2 as a double


% --- Executes during object creation, after setting all properties.
function et_fmd2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_fmd2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_fmd3_Callback(hObject, eventdata, handles)
% hObject    handle to et_fmd3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_fmd3 as text
%        str2double(get(hObject,'String')) returns contents of et_fmd3 as a double


% --- Executes during object creation, after setting all properties.
function et_fmd3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_fmd3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_fmd4_Callback(hObject, eventdata, handles)
% hObject    handle to et_fmd4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_fmd4 as text
%        str2double(get(hObject,'String')) returns contents of et_fmd4 as a double


% --- Executes during object creation, after setting all properties.
function et_fmd4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_fmd4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cb_fpm.
function cb_fpm_Callback(hObject, eventdata, handles)
% hObject    handle to cb_fpm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_fpm



function et_fpm1_Callback(hObject, eventdata, handles)
% hObject    handle to et_fpm1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_fpm1 as text
%        str2double(get(hObject,'String')) returns contents of et_fpm1 as a double


% --- Executes during object creation, after setting all properties.
function et_fpm1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_fpm1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_fpm2_Callback(hObject, eventdata, handles)
% hObject    handle to et_fpm2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_fpm2 as text
%        str2double(get(hObject,'String')) returns contents of et_fpm2 as a double


% --- Executes during object creation, after setting all properties.
function et_fpm2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_fpm2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_fpm3_Callback(hObject, eventdata, handles)
% hObject    handle to et_fpm3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_fpm3 as text
%        str2double(get(hObject,'String')) returns contents of et_fpm3 as a double


% --- Executes during object creation, after setting all properties.
function et_fpm3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_fpm3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_fpm4_Callback(hObject, eventdata, handles)
% hObject    handle to et_fpm4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_fpm4 as text
%        str2double(get(hObject,'String')) returns contents of et_fpm4 as a double


% --- Executes during object creation, after setting all properties.
function et_fpm4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_fpm4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cb_tPwr.
function cb_tPwr_Callback(hObject, eventdata, handles)
% hObject    handle to cb_tPwr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_tPwr



function et_tPwr1_Callback(hObject, eventdata, handles)
% hObject    handle to et_tPwr1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tPwr1 as text
%        str2double(get(hObject,'String')) returns contents of et_tPwr1 as a double


% --- Executes during object creation, after setting all properties.
function et_tPwr1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tPwr1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tPwr2_Callback(hObject, eventdata, handles)
% hObject    handle to et_tPwr2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tPwr2 as text
%        str2double(get(hObject,'String')) returns contents of et_tPwr2 as a double


% --- Executes during object creation, after setting all properties.
function et_tPwr2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tPwr2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tPwr3_Callback(hObject, eventdata, handles)
% hObject    handle to et_tPwr3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tPwr3 as text
%        str2double(get(hObject,'String')) returns contents of et_tPwr3 as a double


% --- Executes during object creation, after setting all properties.
function et_tPwr3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tPwr3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_tPwr4_Callback(hObject, eventdata, handles)
% hObject    handle to et_tPwr4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_tPwr4 as text
%        str2double(get(hObject,'String')) returns contents of et_tPwr4 as a double


% --- Executes during object creation, after setting all properties.
function et_tPwr4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_tPwr4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cb_fwlr.
function cb_fwlr_Callback(hObject, eventdata, handles)
% hObject    handle to cb_fwlr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_fwlr



function et_fwlr1_Callback(hObject, eventdata, handles)
% hObject    handle to et_fwlr1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_fwlr1 as text
%        str2double(get(hObject,'String')) returns contents of et_fwlr1 as a double


% --- Executes during object creation, after setting all properties.
function et_fwlr1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_fwlr1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_fwlr2_Callback(hObject, eventdata, handles)
% hObject    handle to et_fwlr2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_fwlr2 as text
%        str2double(get(hObject,'String')) returns contents of et_fwlr2 as a double


% --- Executes during object creation, after setting all properties.
function et_fwlr2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_fwlr2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_fwlr3_Callback(hObject, eventdata, handles)
% hObject    handle to et_fwlr3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_fwlr3 as text
%        str2double(get(hObject,'String')) returns contents of et_fwlr3 as a double


% --- Executes during object creation, after setting all properties.
function et_fwlr3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_fwlr3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_fwlr4_Callback(hObject, eventdata, handles)
% hObject    handle to et_fwlr4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_fwlr4 as text
%        str2double(get(hObject,'String')) returns contents of et_fwlr4 as a double


% --- Executes during object creation, after setting all properties.
function et_fwlr4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_fwlr4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_plotall.
function pb_plotall_Callback(hObject, eventdata, handles)

if get(handles.cb_tmn,'Value')
    figure;
    plot(get(handles.cb_tmn,'UserData'));
    title('tMean')
    legend('1','2','3','4')
end
if get(handles.cb_tmabs,'Value')
    figure;
    plot(get(handles.cb_tmabs,'UserData'));
    title('tMeanAbs')
    legend('1','2','3','4')
end
if get(handles.cb_tmd,'Value')
    figure;
    plot(get(handles.cb_tmd,'UserData'));
    title('tMedian')
    legend('1','2','3','4')
end
if get(handles.cb_tmod,'Value')
    figure;
    plot(get(handles.cb_tmod,'UserData'));
    title('tMode')
    legend('1','2','3','4')
end
if get(handles.cb_tstd,'Value')
    figure;
    plot(get(handles.cb_tstd,'UserData'));
    title('tStd')
    legend('1','2','3','4')
end
if get(handles.cb_tvar,'Value')
    figure;
    plot(get(handles.cb_tvar,'UserData'));
    title('tVariance')
    legend('1','2','3','4')
end
if get(handles.cb_twl,'Value')
    figure;
    plot(get(handles.cb_twl,'UserData'));
    title('tWaveLength')
    legend('1','2','3','4')
end
if get(handles.cb_trms,'Value')
    figure;
    plot(get(handles.cb_trms,'UserData'));
    title('tRMS')
    legend('1','2','3','4')
end
if get(handles.cb_tzc,'Value')
    figure;
    plot(get(handles.cb_tzc,'UserData'));
    title('tZeroCross')
    legend('1','2','3','4')
end
if get(handles.cb_tpks,'Value')
    figure;
    plot(get(handles.cb_tpks,'UserData'));
    title('tPeaks')
    legend('1','2','3','4')
end
if get(handles.cb_tmpks,'Value')
    figure;
    plot(get(handles.cb_tmpks,'UserData'));
    title('tMeanPeaks')
    legend('1','2','3','4')
end
if get(handles.cb_tmvel,'Value')
    figure;
    plot(get(handles.cb_tmvel,'UserData'));
    title('tMeanVel')
    legend('1','2','3','4')
end
if get(handles.cb_tslpch,'Value')
    figure;
    plot(get(handles.cb_tslpch,'UserData'));
    title('tSlopeChanges')
    legend('1','2','3','4')
end
if get(handles.cb_cr,'Value')
    figure;
    plot(get(handles.cb_cr,'UserData'));
    title('tCorrelation')
    legend('1','2','3','4')
end
if get(handles.cb_cv,'Value')
    figure;
    plot(get(handles.cb_cv,'UserData'));
    title('tCovariance')
    legend('1','2','3','4')
end
if get(handles.cb_fwl,'Value')
    figure;
    plot(get(handles.cb_fwl,'UserData'));
    title('fWaveLength')
    legend('1','2','3','4')
end
if get(handles.cb_fmn,'Value')
    figure;
    plot(get(handles.cb_fmn,'UserData'));
    title('fMean')
    legend('1','2','3','4')
end
if get(handles.cb_fmd,'Value')
    figure;
    plot(get(handles.cb_fmd,'UserData'));
    title('fMedia')
    legend('1','2','3','4')
end
if get(handles.cb_fpm,'Value')
    figure;
    plot(get(handles.cb_fpm,'UserData'));
    title('fPeaksMean')
    legend('1','2','3','4')
end
if get(handles.cb_tPwr,'Value')
    figure;
    plot(get(handles.cb_tPwr,'UserData'));
    title('tPower')
    legend('1','2','3','4')
end
if get(handles.cb_fwlr,'Value')
    figure;
    plot(get(handles.cb_fwlr,'UserData'));
    title('fPower')
    legend('1','2','3','4')
end


% --- Executes on button press in pb_tmn.
function pb_tmn_Callback(hObject, eventdata, handles)
if get(handles.cb_tmn,'Value')
    figure;
    plot(get(handles.cb_tmn,'UserData'));
    title('tMean')
    legend('1','2','3','4')
end


% --- Executes on button press in pb_tmabs.
function pb_tmabs_Callback(hObject, eventdata, handles)
if get(handles.cb_tmabs,'Value')
    figure;
    plot(get(handles.cb_tmabs,'UserData'));
    title('tMeanAbs')
    legend('1','2','3','4')
end


% --- Executes on button press in pb_tmd.
function pb_tmd_Callback(hObject, eventdata, handles)
if get(handles.cb_tmd,'Value')
    figure;
    plot(get(handles.cb_tmd,'UserData'));
    title('tMedian')
    legend('1','2','3','4')
end


% --- Executes on button press in pb_tmod.
function pb_tmod_Callback(hObject, eventdata, handles)
if get(handles.cb_tmod,'Value')
    figure;
    plot(get(handles.cb_tmod,'UserData'));
    title('tMode')
    legend('1','2','3','4')
end


% --- Executes on button press in pb_tstd.
function pb_tstd_Callback(hObject, eventdata, handles)
if get(handles.cb_tstd,'Value')
    figure;
    plot(get(handles.cb_tstd,'UserData'));
    title('tStd')
    legend('1','2','3','4')
end


% --- Executes on button press in pb_tvar.
function pb_tvar_Callback(hObject, eventdata, handles)
if get(handles.cb_tvar,'Value')
    figure;
    plot(get(handles.cb_tvar,'UserData'));
    title('tVariance')
    legend('1','2','3','4')
end


% --- Executes on button press in pb_twl.
function pb_twl_Callback(hObject, eventdata, handles)
if get(handles.cb_twl,'Value')
    figure;
    plot(get(handles.cb_twl,'UserData'));
    title('tWaveLength')
    legend('1','2','3','4')
end


% --- Executes on button press in pb_trms.
function pb_trms_Callback(hObject, eventdata, handles)
if get(handles.cb_trms,'Value')
    figure;
    plot(get(handles.cb_trms,'UserData'));
    title('tRMS')
    legend('1','2','3','4')
end


% --- Executes on button press in pb_tzc.
function pb_tzc_Callback(hObject, eventdata, handles)
if get(handles.cb_tzc,'Value')
    figure;
    plot(get(handles.cb_tzc,'UserData'));
    title('tZeroCross')
    legend('1','2','3','4')
end


% --- Executes on button press in pb_tpks.
function pb_tpks_Callback(hObject, eventdata, handles)
if get(handles.cb_tpks,'Value')
    figure;
    plot(get(handles.cb_tpks,'UserData'));
    title('tPeaks')
    legend('1','2','3','4')
end



% --- Executes on button press in pb_tmpks.
function pb_tmpks_Callback(hObject, eventdata, handles)
if get(handles.cb_tmpks,'Value')
    figure;
    plot(get(handles.cb_tmpks,'UserData'));
    title('tMeanPeaks')
    legend('1','2','3','4')
end


% --- Executes on button press in pb_tmvel.
function pb_tmvel_Callback(hObject, eventdata, handles)
if get(handles.cb_tmvel,'Value')
    figure;
    plot(get(handles.cb_tmvel,'UserData'));
    title('tMeanVel')
    legend('1','2','3','4')
end


% --- Executes on button press in pb_tslpch.
function pb_tslpch_Callback(hObject, eventdata, handles)
if get(handles.cb_tslpch,'Value')
    figure;
    plot(get(handles.cb_tslpch,'UserData'));
    title('tSlopeChanges')
    legend('1','2','3','4')
end


% --- Executes on button press in pb_cr.
function pb_cr_Callback(hObject, eventdata, handles)
if get(handles.cb_cr,'Value')
    figure;
    plot(get(handles.cb_cr,'UserData'));
    title('tCorrelation')
end


% --- Executes on button press in pb_cv.
function pb_cv_Callback(hObject, eventdata, handles)
if get(handles.cb_cv,'Value')
    figure;
    plot(get(handles.cb_cv,'UserData'));
    title('tCovariance')
end


% --- Executes on button press in pb_fwl.
function pb_fwl_Callback(hObject, eventdata, handles)
if get(handles.cb_fwl,'Value')
    figure;
    plot(get(handles.cb_fwl,'UserData'));
    title('fWaveLength')
    legend('1','2','3','4')
end


% --- Executes on button press in pb_fmn.
function pb_fmn_Callback(hObject, eventdata, handles)
if get(handles.cb_fmn,'Value')
    figure;
    plot(get(handles.cb_fmn,'UserData'));
    title('fMean')
    legend('1','2','3','4')
end


% --- Executes on button press in pb_fmd.
function pb_fmd_Callback(hObject, eventdata, handles)
if get(handles.cb_fmd,'Value')
    figure;
    plot(get(handles.cb_fmd,'UserData'));
    title('fMedia')
    legend('1','2','3','4')
end


% --- Executes on button press in pb_fpm.
function pb_fpm_Callback(hObject, eventdata, handles)
if get(handles.cb_fpm,'Value')
    figure;
    plot(get(handles.cb_fpm,'UserData'));
    title('fPeaksMean')
    legend('1','2','3','4')
end


% --- Executes on button press in pb_tPwr.
function pb_tPwr_Callback(hObject, eventdata, handles)
if get(handles.cb_tPwr,'Value')
    figure;
    plot(get(handles.cb_tPwr,'UserData'));
    title('tPower')
    legend('1','2','3','4')
end


% --- Executes on button press in pb_fwlr.
function pb_fwlr_Callback(hObject, eventdata, handles)
if get(handles.cb_fwlr,'Value')
    figure;
    plot(get(handles.cb_fwlr,'UserData'));
    title('fPower')
    legend('1','2','3','4')
end


% --- Executes on button press in pb_pdata.
function pb_pdata_Callback(hObject, eventdata, handles)
    figure;
    plot(get(handles.pb_start,'UserData'));
    title('Raw Data')
    legend('1','2','3','4')


% --------------------------------------------------------------------
function Untitled_1_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function m_open_Callback(hObject, eventdata, handles)

    [file, path] = uigetfile('*.mat');
    if ~isequal(file, 0)
        load([path,file]);

        set(handles.t_msg,'String',comment);
        set(handles.et_Fs,'String',num2str(Fs));
        set(handles.et_Ts,'String',num2str(Ts));
        set(handles.et_Tp,'String',num2str(Tp));

        if exist('data','var')
            set(handles.pb_start,'UserData',data);
        end

        if exist('tmn','var')
            set(handles.cb_tmn,'UserData',tmn);
            set(handles.cb_tmn,'Value',1);
        else
            set(handles.cb_tmn,'Value',0);
        end
        if exist('tmabs','var')
            set(handles.cb_tmabs,'UserData',tmabs);
            set(handles.cb_tmabs,'Value',1);
        else
            set(handles.cb_tmabs,'Value',0);
        end
        if exist('tmd','var')
            set(handles.cb_tmd,'UserData',tmd);
            set(handles.cb_tmd,'value',1);
        else
            set(handles.cb_tmd,'value',0);            
        end
        if exist('tmod','var')
            set(handles.cb_tmod,'UserData',tmod);
            set(handles.cb_tmod,'Value',1);
        else
            set(handles.cb_tmod,'Value',0);
        end
        if exist('tstd','var')
            set(handles.cb_tstd,'UserData',tstd);
            set(handles.cb_tstd,'Value',1);
        else
            set(handles.cb_tstd,'Value',0);
        end
        if exist('tvar','var')
            set(handles.cb_tvar,'UserData',tvar);
            set(handles.cb_tvar,'Value',1);
        else
            set(handles.cb_tvar,'Value',0);
        end
        if exist('twl','var')
            set(handles.cb_twl,'UserData',twl);
            set(handles.cb_twl,'Value',1);
        else
            set(handles.cb_twl,'Value',0);
        end
        if exist('trms','var')
            set(handles.cb_trms,'UserData',trms);
            set(handles.cb_trms,'Value',1);
        else
            set(handles.cb_trms,'Value',0);
        end
        if exist('tzc','var')
            set(handles.cb_tzc,'UserData',tzc);
            set(handles.cb_tzc,'Value',1);
        else
            set(handles.cb_tzc,'Value',0);
        end
        if exist('tpks','var')
            set(handles.cb_tpks,'UserData',tpks);
            set(handles.cb_tpks,'Value',1);
        else
            set(handles.cb_tpks,'Value',0);
        end
        if exist('tmpks','var')
            set(handles.cb_tmpks,'UserData',tmpks);
            set(handles.cb_tmpks,'Value',1);
        else
            set(handles.cb_tmpks,'Value',0);
        end
        if exist('tmvel','var')
            set(handles.cb_tmvel,'UserData',tmvel);
            set(handles.cb_tmvel,'Value',1);
        else
            set(handles.cb_tmvel,'Value',0);
        end
        if exist('tslpch','var')
            set(handles.cb_tslpch,'UserData',tslpch);
            set(handles.cb_tslpch,'Value',1);
        else
            set(handles.cb_tslpch,'Value',0);
        end
        if exist('tcr','var')
            set(handles.cb_cr,'UserData',cr);
            set(handles.cb_cr,'Value',1);
        else
            set(handles.cb_cr,'Value',0);
        end
        if exist('tcv','var')
            set(handles.cb_cv,'UserData',cv);
            set(handles.cb_cv,'Value',1);
        else
            set(handles.cb_cv,'Value',0);
        end
        if exist('fwl','var')
            set(handles.cb_fwl,'UserData',fwl);
            set(handles.cb_fwl,'Value',1);
        else
            set(handles.cb_fwl,'Value',0);
        end
        if exist('fmn','var')
            set(handles.cb_fmn,'UserData',fmn);
            set(handles.cb_fmn,'Value',1);
        else
            set(handles.cb_fmn,'Value',0);
        end
        if exist('fmd','var')
            set(handles.cb_fmd,'UserData',fmd);
            set(handles.cb_fmd,'Value',1);
        else
            set(handles.cb_fmd,'Value',0);
        end
        if exist('fpm','var')
            set(handles.cb_fpm,'UserData',fpm);
            set(handles.cb_fpm,'Value',1);
        else
            set(handles.cb_fpm,'Value',0);
        end
        if exist('tPwr','var')
            set(handles.cb_tPwr,'UserData',tPwr);
            set(handles.cb_tPwr,'Value',1);
        else
            set(handles.cb_tPwr,'Value',0);
        end
        if exist('fwlr','var')
            set(handles.cb_fwlr,'UserData',fwlr);
            set(handles.cb_fwlr,'Value',1);
        else
            set(handles.cb_fwlr,'Value',0);
        end
    end

% --------------------------------------------------------------------
function m_save_Callback(hObject, eventdata, handles)

comment = inputdlg('Comment about the session','Comment');

Fs = str2double(get(handles.et_Fs,'String'));
Ts = str2double(get(handles.et_Ts,'String'));
Tp = str2double(get(handles.et_Tp,'String'));
data = get(handles.pb_start,'UserData');

if get(handles.cb_tmn,'Value')
    tmn = get(handles.cb_tmn,'UserData');
end
if get(handles.cb_tmabs,'Value')
    tmabs = get(handles.cb_tmabs,'UserData');
end
if get(handles.cb_tmd,'Value')
    tmd = get(handles.cb_tmd,'UserData');
end
if get(handles.cb_tmod,'Value')
    tmod = get(handles.cb_tmod,'UserData');
end
if get(handles.cb_tstd,'Value')
    tstd = get(handles.cb_tstd,'UserData');
end
if get(handles.cb_tvar,'Value')
    tvar = get(handles.cb_tvar,'UserData');
end
if get(handles.cb_twl,'Value')
    twl = get(handles.cb_twl,'UserData');
end
if get(handles.cb_trms,'Value')
    trms = get(handles.cb_trms,'UserData');
end
if get(handles.cb_tzc,'Value')
    tzc = get(handles.cb_tzc,'UserData');
end
if get(handles.cb_tpks,'Value')
    tpks = get(handles.cb_tpks,'UserData');
end
if get(handles.cb_tmpks,'Value')
    tmpks = get(handles.cb_tmpks,'UserData');
end
if get(handles.cb_tmvel,'Value')
    tmvel = get(handles.cb_tmvel,'UserData');
end
if get(handles.cb_tslpch,'Value')
    tslpch = get(handles.cb_tslpch,'UserData');
end
if get(handles.cb_cr,'Value')
    cr = get(handles.cb_cr,'UserData');
end
if get(handles.cb_cv,'Value')
    cv = get(handles.cb_cv,'UserData');
end
if get(handles.cb_fwl,'Value')
    fwl = get(handles.cb_fwl,'UserData');
end
if get(handles.cb_fmn,'Value')
    fmn = get(handles.cb_fmn,'UserData');
end
if get(handles.cb_fmd,'Value')
    fmd = get(handles.cb_fmd,'UserData');
end
if get(handles.cb_fpm,'Value')
    fpm = get(handles.cb_fpm,'UserData');
end
if get(handles.cb_tPwr,'Value')
    tPwr = get(handles.cb_tPwr,'UserData');
end
if get(handles.cb_fwlr,'Value')
    fwlr = get(handles.cb_fwlr,'UserData');
end

clear handles;
clear hObject;
clear eventdata;
[filename, pathname] = uiputfile({'*.mat','MAT-files (*.mat)'},'Save as', 'Untitled.mat');
save([pathname,filename]);


% --- Executes on button press in cb_link.
function cb_link_Callback(hObject, eventdata, handles)
% hObject    handle to cb_link (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_link



function et_Amin_Callback(hObject, eventdata, handles)
% hObject    handle to et_Amin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_Amin as text
%        str2double(get(hObject,'String')) returns contents of et_Amin as a double


% --- Executes during object creation, after setting all properties.
function et_Amin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_Amin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function et_Amax_Callback(hObject, eventdata, handles)
% hObject    handle to et_Amax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_Amax as text
%        str2double(get(hObject,'String')) returns contents of et_Amax as a double


% --- Executes during object creation, after setting all properties.
function et_Amax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_Amax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_controls.
function pb_controls_Callback(hObject, eventdata, handles)
% hObject    handle to pb_controls (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in cb_linkcontrols.
function cb_linkcontrols_Callback(hObject, eventdata, handles)
% hObject    handle to cb_linkcontrols (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_linkcontrols


% --- Executes on button press in cb_ch0.
function cb_ch0_Callback(hObject, eventdata, handles)
% hObject    handle to cb_ch0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_ch0


% --- Executes on button press in cb_ch1.
function cb_ch1_Callback(hObject, eventdata, handles)
% hObject    handle to cb_ch1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_ch1


% --- Executes on button press in cb_ch2.
function cb_ch2_Callback(hObject, eventdata, handles)
% hObject    handle to cb_ch2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_ch2


% --- Executes on button press in cb_ch3.
function cb_ch3_Callback(hObject, eventdata, handles)
% hObject    handle to cb_ch3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_ch3



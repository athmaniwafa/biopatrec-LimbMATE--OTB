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
% Compute the overal all Accuracy of the patRec algorithm
%
% ------------------------- Updates & Contributors ------------------------
% 2011-06-09 / Max Ortiz  / Created new version from EMG_AQ 

function varargout = GUI_BioPatRec_Clinic(varargin)
% GUI_BIOPATREC_CLINIC M-file for GUI_BioPatRec_Clinic.fig
%      GUI_BIOPATREC_CLINIC, by itself, creates a new GUI_BIOPATREC_CLINIC or raises the existing
%      singleton*.
%
%      H = GUI_BIOPATREC_CLINIC returns the handle to a new GUI_BIOPATREC_CLINIC or the handle to
%      the existing singleton*.
%
%      GUI_BIOPATREC_CLINIC('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI_BIOPATREC_CLINIC.M with the given input arguments.
%
%      GUI_BIOPATREC_CLINIC('Property','Value',...) creates a new GUI_BIOPATREC_CLINIC or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI_BioPatRec_Clinic_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI_BioPatRec_Clinic_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUI_BioPatRec_Clinic

% Last Modified by GUIDE v2.5 31-Oct-2013 15:14:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_BioPatRec_Clinic_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_BioPatRec_Clinic_OutputFcn, ...
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


% --- Executes just before GUI_BioPatRec_Clinic is made visible.
function GUI_BioPatRec_Clinic_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI_BioPatRec_Clinic (see VARARGIN)

%load the background image into Matlab
%if image is not in the same directory as the GUI files, you must use the 
%full path name of the iamge file
backgroundImage = importdata('Img/BioPatRec.png');
%select the axes
axes(handles.axes1);
%place image onto the axes
image(backgroundImage);
%remove the axis tick marks
axis off

% Choose default command line output for GUI_BioPatRec_Clinic
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GUI_BioPatRec_Clinic wait for user response (see UIRESUME)
% uiwait(handles.figure1);
movegui(hObject,'center');

% --- Outputs from this function are returned to the command line.
function varargout = GUI_BioPatRec_Clinic_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pb_Recordings.
function pb_Recordings_Callback(hObject, eventdata, handles)
% hObject    handle to pb_Recordings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

GUI_Recordings;


% --- Executes on button press in pb_PatRec.
function pb_PatRec_Callback(hObject, eventdata, handles)
% hObject    handle to pb_PatRec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
GUI_PatRec;

% --- Executes on button press in pb_RecordingSession.
function pb_RecordingSession_Callback(hObject, eventdata, handles)
% hObject    handle to pb_RecordingSession (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
GUI_RecordingSession;


% --- Executes on button press in pb_PatRec_Default.
function pb_PatRec_Default_Callback(hObject, eventdata, handles)
% hObject    handle to pb_PatRec_Default (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
UseDefaults(handles.pb_PatRec_Default, 'false');


% --- Executes on button press in pb_PatRec_DefaultSimul.
function pb_PatRec_DefaultSimul_Callback(hObject, eventdata, handles)
% hObject    handle to pb_PatRec_DefaultSimul (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
UseDefaults(handles.pb_PatRec_DefaultSimul, 'true');


% --- Executes on button press in pb_TestAR.
function pb_TestAR_Callback(hObject, eventdata, handles)
% hObject    handle to pb_TestAR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if(strcmp(get(handles.pb_TestAR,'String'),'Test Augmented Reality'))
    handles = ConnectVRE(handles,'Augmented Reality ARM.exe');
    set(handles.pb_TestAR, 'String', 'Disconnect');
    guidata(hObject,handles);
else
    handles = DisconnectVRE(handles);
    set(handles.pb_TestAR, 'String', 'Test Augmented Reality')
    guidata(hObject, handles);
end

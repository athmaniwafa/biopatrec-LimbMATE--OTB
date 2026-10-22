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
% GUI object for displaying compartment ratio results table from HD-EMG GUI
%
% ------------------------- Updates & Contributors ------------------------
% 2017-09-25 / Simon Nilsson / Created initial version

function varargout = GUI_CRTable(varargin)
% GUI_CRTABLE MATLAB code for GUI_CRTable.fig
%      GUI_CRTABLE, by itself, creates a new GUI_CRTABLE or raises the existing
%      singleton*.
%
%      H = GUI_CRTABLE returns the handle to a new GUI_CRTABLE or the handle to
%      the existing singleton*.
%
%      GUI_CRTABLE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI_CRTABLE.M with the given input arguments.
%
%      GUI_CRTABLE('Property','Value',...) creates a new GUI_CRTABLE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI_CRTable_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI_CRTable_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUI_CRTable

% Last Modified by GUIDE v2.5 16-May-2017 16:16:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_CRTable_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_CRTable_OutputFcn, ...
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


% --- Executes just before GUI_CRTable is made visible.
function GUI_CRTable_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI_CRTable (see VARARGIN)

% Choose default command line output for GUI_CRTable
handles.output = hObject;

disp(varargin);
p = inputParser;
addParameter(p, 'Data', {}, @iscell);
parse(p, varargin{:});

tabData = p.Results.Data;

set(handles.t_cr, 'Data', tabData);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GUI_CRTable wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GUI_CRTable_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

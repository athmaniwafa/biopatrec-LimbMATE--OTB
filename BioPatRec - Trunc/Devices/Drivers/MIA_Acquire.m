% mia_control.m — single-file MIA hand control on COM6
% '+' close  |  '-' open  |  'q' quit

clear; clc;

%% Connect
s = serialport('COM6', 115200);
s.configureTerminator('CR');

% Calibrate
writeline(s, '@AK0000000000000*');
pause(2);
disp('Calibrated. Click window, then press + / - / q.');

%% Send motor command helper (motor 1 = thumb, 2 = fingers)
send = @(id, dir, spd) writeline(s, sprintf('@%dS%s0000%02d550000*', id, dir, spd));

%% Keyboard window
fig = figure('Name','MIA: + close / - open / q quit', ...
             'NumberTitle','off','MenuBar','none','ToolBar','none', ...
             'Position',[500 400 400 150]);
uicontrol(fig,'Style','text','FontSize',16, ...
    'String',{'+   CLOSE hand','-   OPEN hand','q   QUIT'}, ...
    'Units','normalized','Position',[0.1 0.1 0.8 0.8]);

state.quit = false;
state.act  = '';
fig.KeyPressFcn = @(src,evt) setappdata(src,'key',evt.Key);

%% Main loop
SPEED = 55;
while ~state.quit && isvalid(fig)
    k = getappdata(fig,'key');
    if isempty(k), pause(0.05); continue; end
    setappdata(fig,'key','');

    switch k
        case {'add','equal'}           % '+'
            send(1,'+',SPEED); pause(0.3);
            send(2,'+',SPEED);
            disp('+ CLOSE');
        case {'subtract','hyphen'}     % '-'
            send(1,'-',SPEED); pause(0.3);
            send(2,'-',SPEED);
            disp('- OPEN');
        case 'q'
            state.quit = true;
    end
end

%% Cleanup
if isvalid(fig), close(fig); end
delete(s); clear s;
disp('Done.');
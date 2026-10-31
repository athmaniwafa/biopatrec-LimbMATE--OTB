function [el, nCh, ok] = SQ_SelectElectrodes()
% Two-step selection: 1) adapter, 2) grid (only when there is a choice).
%   el.adapter      'AD1x64SP' | 'AD2x32SP' | 'BIPOLAR'
%   el.grid         '8x8' | '13x5' | '4x8' | ''
%   el.MULTIPLE_IN1 legacy code: 'BIG' | 'SMALL' | 'AD2x32SP' | 'BIPOLAR'
el = struct(); nCh = 8; ok = false;

adNames = {'AD1x64SP  -  1 matrix, 64 channels', ...
           'AD2x32SP  -  2 matrices, 32 channels each', ...
           'Bipolar  -  8 channels'};
adKeys  = {'AD1x64SP', 'AD2x32SP', 'BIPOLAR'};

while true
    [s1, ok1] = listdlg('PromptString', 'Step 1/2 - Select adapter:', ...
        'SelectionMode', 'single', 'ListString', adNames, ...
        'ListSize', [320 90], 'Name', 'SQ+ Adapter');
    if ~ok1, return; end
    adapter = adKeys{s1};

    switch adapter
        case 'AD1x64SP'
            gridKeys  = {'8x8', '13x5'};
            gridNames = {'8 x 8   (64 electrodes)', '13 x 5   (64 electrodes + 1 empty position)'};
            [s2, ok2] = listdlg('PromptString', 'Step 2/2 - Select grid:', ...
                'SelectionMode', 'single', 'ListString', gridNames, ...
                'ListSize', [320 70], 'Name', 'SQ+ Grid');
            if ~ok2, continue; end          % back to step 1
            grid = gridKeys{s2};
            nCh = 64; legacy = ternary(strcmp(grid,'8x8'), 'BIG', 'SMALL');
        case 'AD2x32SP'
            grid = '4x8';                   % single standard model
            nCh = 64; legacy = 'AD2x32SP';
        otherwise
            grid = '';
            nCh = 8;  legacy = 'BIPOLAR';
    end
    break;
end

el.adapter = adapter;
el.grid    = grid;
el.MULTIPLE_IN1 = legacy;
ok = true;
end

function r = ternary(c, a, b)
if c, r = a; else, r = b; end
end
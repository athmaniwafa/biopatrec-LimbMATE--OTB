function L = SQ_GridLayout(adapter, grid)
% SQ_GRIDLAYOUT  Electrode layout for the Sessantaquattro+.
%   adapter : 'AD1x64SP' | 'AD2x32SP' | 'BIPOLAR'
%   grid    : '8x8' | '13x5' (AD1x64SP) | '4x8' (AD2x32SP) | '' (BIPOLAR)
%   L.grids(k): rows, cols, ch, map (rows x cols -> channel, NaN = empty), title
%
% VERIFY the channel order against the OT Bioelettronica datasheet
% and change the order string if the map looks scrambled.

% AD2x32SP orientation of EACH of the two matrices:
%   'landscape' = 4 rows x 8 columns (datasheet)
%   'portrait'  = 8 rows x 4 columns
AD2x32_ORIENTATION = 'portrait';

switch upper(adapter)
    case 'AD1X64SP'
        switch lower(grid)
            case '8x8'
                L.grids(1) = makeGrid(8, 8,  1:64, 'colmajor', 'Grid 8x8 (ch 1-64)');
            case '13x5'
                L.grids(1) = makeGrid(13, 5, 1:64, 'colmajor', 'Grid 13x5 (ch 1-64)');
            otherwise
                error('SQ_GridLayout: AD1x64SP does not support grid "%s".', grid);
        end
        L.nCh = 64;
    case 'AD2X32SP'
        % two separate matrices: branch 1 = ch 1-32, branch 2 = ch 33-64
        if strcmp(AD2x32_ORIENTATION, 'portrait')
            r = 8; c = 4; order = 'colmajor';   % ch 1..8 down the first column
        else
            r = 4; c = 8; order = 'rowmajor';   % ch 1..8 along the first row
        end
        L.grids(1) = makeGrid(r, c, 1:32,  order, sprintf('Matrix 1 - %dx%d (ch 1-32)',  r, c));
        L.grids(2) = makeGrid(r, c, 33:64, order, sprintf('Matrix 2 - %dx%d (ch 33-64)', r, c));
        L.nCh = 64;
    case 'BIPOLAR'
        L.grids(1) = makeGrid(1, 8, 1:8, 'rowmajor', 'Bipolar (ch 1-8)');
        L.nCh = 8;
    otherwise
        error('SQ_GridLayout: unknown adapter "%s".', adapter);
end
end

function g = makeGrid(r, c, ch, order, ttl)
g.rows = r; g.cols = c; g.ch = ch; g.title = ttl;
m = nan(r*c, 1);
m(1:numel(ch)) = ch(:);
if strcmp(order, 'rowmajor')
    g.map = reshape(m, c, r).';
else
    g.map = reshape(m, r, c);
end
end
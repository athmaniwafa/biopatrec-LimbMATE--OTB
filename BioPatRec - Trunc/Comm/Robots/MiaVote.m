classdef MiaVote < handle
    properties
        N    = 8;
        need = 6;
        buf  = {};
    end
    methods
        function out = push(obj, mov)
            obj.buf{end+1} = strtrim(char(mov));
            if numel(obj.buf) > obj.N, obj.buf(1) = []; end
            out = '';
            if numel(obj.buf) < obj.N, return; end
            [u, ~, j] = unique(obj.buf);
            c = accumarray(j(:), 1);
            [m, k] = max(c);
            if m >= obj.need, out = u{k}; end
        end
    end
end

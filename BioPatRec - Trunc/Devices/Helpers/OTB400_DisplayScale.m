function gains = OTB400_DisplayScale(data,layout,spacing)
% Independent display gain per physical input; recorded data stay unchanged.
    gains=ones(1,size(data,2));
    for k=1:numel(layout.GroupColumns)
        cols=layout.GroupColumns{k};
        values=abs(double(data(:,cols)));
        peak=max(values(:));
        if isempty(peak) || peak==0, peak=1; end
        gains(cols)=spacing/(2*peak);
    end
end

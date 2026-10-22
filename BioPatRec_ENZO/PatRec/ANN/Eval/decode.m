%decode_chromosome.m

function ANN = decode(ANN,w)

    % First layer
    ANN.w(1:ANN.nIn*ANN.nHn(1))     = w(1 : ANN.nIn*ANN.nHn(1));
    offset                          = ANN.nIn*ANN.nHn(1);
    ANN.b(1:ANN.nHn(1))             = w(offset+1 : offset + ANN.nHn(1));
    offset                          = offset + ANN.nHn(1);
    
    % Hidden Layers
    for i = 2 : length(ANN.nHn)
        tmat                                    = zeros(ANN.nHn(i-1), ANN.nHn(i));
        tmat(1:end)                             = w(offset + 1 : offset + ANN.nHn(i-1)*ANN.nHn(i));
        ANN.w(1:ANN.nHn(i-1),1:ANN.nHn(i),i)    = tmat;
        offset                                  = offset + ANN.nHn(i-1)*ANN.nHn(i);
        ANN.b(1:ANN.nHn(i), i)                  = w(offset + 1 : offset + ANN.nHn(i));
        offset                                  = offset + ANN.nHn(i);
    end

    % Last layer
    tmat                                    = zeros(ANN.nHn(end), ANN.nOn);    
    tmat(1:end)                             = w(offset + 1 : offset + ANN.nHn(end)*ANN.nOn);
    ANN.w(1:ANN.nHn(end),1:ANN.nOn,end)     = tmat;
    offset                                  = offset + ANN.nHn(end)*ANN.nOn;
    ANN.b(1:ANN.nOn,end)                    = w(offset+1 : offset + ANN.nOn);
    
    %w1
%    ANN.w1(1:ANN.nIn*ANN.nHn)   = w(1 : ANN.nIn*ANN.nHn);

    %b1
%    ANN.b1(1:ANN.nHn)           = w(ANN.nIn*ANN.nHn + 1 : ANN.nIn*ANN.nHn + ANN.nHn);

    %w2
%    ANN.w2(1:ANN.nHn*ANN.nOn)   = w(ANN.nIn*ANN.nHn + ANN.nHn + 1 : ANN.nIn*ANN.nHn + ANN.nHn + ANN.nHn*ANN.nOn);

    %b1
%    ANN.b2(1:ANN.nOn)           = w(ANN.nIn*ANN.nHn + ANN.nHn + ANN.nHn*ANN.nOn + 1 : end);

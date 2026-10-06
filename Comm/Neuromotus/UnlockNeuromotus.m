function success = UnlockNeuromotus(obj)
    success = 0;
    
    % Load key file
    if exist('nmkeys.mat', 'file') == 2
        keys = load('nmkeys');
    else
        keyFile = uigetfile('*.mat');
        if keyFile
            keys = load(keyFile);
        else
            fprintf('Neuromotus keys not available.\n');
            return
        end
    end
    
    if ~isfield(keys,'FWkey') || ~isfield(keys,'PCkey')
        fprintf('Invalid key file.\n');
        return
    end
    
    fwrite(obj,20,'char');
    data = fread(obj,2,'uint32');
    data = [data(2),data(1)]; % Switch order
    data = XTEADecipher(32, data, keys.FWkey);
    data = XTEAEncipher(32, data, keys.PCkey);
    % Swap endianness
    fwrite(obj,swapbytes(uint32(data)),'uint32');
    
    rsp = fread(obj,1,'char');
    if rsp == 1
        success = 1;
    end
end
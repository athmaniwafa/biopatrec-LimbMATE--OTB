keyA = rand(1,4);
keyB = rand(1,4);

data = randi(2^32,1,2);
start = data;
fprintf('Original:  0x%08X 0x%08X\n', data(1), data(2));

data = XTEAEncipher(32, data, keyB);
fprintf('FW Cipher: 0x%08X 0x%08X\n', data(1), data(2));

data = XTEADecipher(32, data, keyB);
fprintf('FW Clear:  0x%08X 0x%08X\n', data(1), data(2));

data = XTEAEncipher(32, data, keyA);
fprintf('PC Cipher: 0x%08X 0x%08X\n', data(1), data(2));

data = XTEADecipher(32, data, keyA);
fprintf('PC Clear:  0x%08X 0x%08X\n', data(1), data(2));

if all(start == data)
    fprintf('Test passed\n');
else
    fprintf('Test failed\n');
end
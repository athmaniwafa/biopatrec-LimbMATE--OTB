function float_vec = DecompressData(data)

    % Bias and scale values
    MULAW_BIAS = int32(hex2dec('2100'));
    BLK_BITS = int32(hex2dec('201'));
    INT32_SCALE = 16777216.0;

    % Bit field definitions
    POS_MASK = int16(hex2dec('7F00'));
    LSB_MASK = int16(hex2dec('00FF'));

    % Inputs are ones-complement uint16
    int16_vec = int16(data);
    int16_vec = bitcmp(int16_vec);

    % Extract bit fields
    sgn = data > 0;
    pos = int32(bitshift(bitand(POS_MASK, int16_vec), -8) + 9);
    lsb = int32(bitand(LSB_MASK, int16_vec));

    % Reconstruct number from parts
    int32_vec = bitshift(lsb, pos-8) + bitshift(BLK_BITS, pos-9) - MULAW_BIAS;
    int32_vec(sgn) = -int32_vec(sgn);

    % Convert to floating point
    float_vec = double(int32_vec) / INT32_SCALE;

end
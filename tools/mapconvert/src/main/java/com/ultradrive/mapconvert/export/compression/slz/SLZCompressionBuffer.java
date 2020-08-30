package com.ultradrive.mapconvert.export.compression.slz;

import java.util.ArrayList;
import java.util.List;


class SLZCompressionBuffer
{
    private static final int MAX_TOKENS = 8;

    private final List<Byte> tokenBuffer = new ArrayList<>();

    private int tokenCount = 0;
    private byte tokenCompressionFlags = 0;

    public void writeToken(SLZToken token)
    {
        tokenCompressionFlags <<= 1;
        tokenCount++;

        token.write(tokenBuffer);

        if (token.isCompressed())
        {
            tokenCompressionFlags |= 1;
        }
    }

    public List<Byte> complete()
    {
        List<Byte> compressedBytes = new ArrayList<>();

        if (tokenCount < 8)
        {
            tokenCompressionFlags <<= MAX_TOKENS - tokenCount;

            compressedBytes.add(tokenCompressionFlags);
            compressedBytes.addAll(tokenBuffer);
        }

        return compressedBytes;
    }

    public boolean isFull()
    {
        return tokenCount == MAX_TOKENS;
    }

    public List<Byte> reset()
    {
        List<Byte> compressedBytes = new ArrayList<>();

        if (isFull())
        {
            compressedBytes.add(tokenCompressionFlags);
            compressedBytes.addAll(tokenBuffer);

            tokenBuffer.clear();
            tokenCompressionFlags = 0;
            tokenCount = 0;
        }

        return compressedBytes;
    }
}

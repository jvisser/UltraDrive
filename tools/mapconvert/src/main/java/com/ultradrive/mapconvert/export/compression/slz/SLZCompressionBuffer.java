package com.ultradrive.mapconvert.export.compression.slz;

import java.util.ArrayList;
import java.util.List;


class SLZCompressionBuffer
{
    private final List<Byte> currentTokenBatchCompressionBuffer = new ArrayList<>();

    private int currentTokenCount = 0;
    private byte currentCompressionMarkers = 0;

    public void writeToken(SLZToken token)
    {
        currentCompressionMarkers <<= 1;
        currentTokenCount++;

        token.write(currentTokenBatchCompressionBuffer);
        if (token.isCompressed())
        {
            currentCompressionMarkers |= 1;
        }
    }

    public List<Byte> complete()
    {
        List<Byte> compressedBytes = new ArrayList<>();
        if (currentTokenCount < 8)
        {
            currentCompressionMarkers <<= 8 - currentTokenCount;

            compressedBytes.add(currentCompressionMarkers);
            compressedBytes.addAll(currentTokenBatchCompressionBuffer);
        }
        return compressedBytes;
    }

    public boolean isFull()
    {
        return currentTokenCount == 8;
    }

    public List<Byte> reset()
    {
        List<Byte> compressedBytes = new ArrayList<>();
        if (isFull())
        {
            compressedBytes.add(currentCompressionMarkers);
            compressedBytes.addAll(currentTokenBatchCompressionBuffer);

            currentTokenBatchCompressionBuffer.clear();
            currentCompressionMarkers = 0;
            currentTokenCount = 0;
        }
        return compressedBytes;
    }
}

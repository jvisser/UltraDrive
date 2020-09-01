package com.ultradrive.mapconvert.export.compression.slz;

import com.ultradrive.mapconvert.common.BitPacker;
import java.util.ArrayList;
import java.util.List;


class SLZCompressionBuffer
{
    private static final int MAX_TOKENS = 8;

    private final List<Byte> tokenBuffer = new ArrayList<>();

    private BitPacker tokenCompressionMarkers = new BitPacker(MAX_TOKENS);

    public void writeToken(SLZToken token)
    {
        token.write(tokenBuffer);

        tokenCompressionMarkers = tokenCompressionMarkers.insert(token.isCompressed());
    }

    public List<Byte> complete()
    {
        List<Byte> compressedBytes = new ArrayList<>();

        if (!isFull())
        {
            tokenCompressionMarkers = tokenCompressionMarkers.padStart(MAX_TOKENS - tokenCompressionMarkers.getSize());

            compressedBytes.add(tokenCompressionMarkers.byteValue());
            compressedBytes.addAll(tokenBuffer);
        }

        return compressedBytes;
    }

    public boolean isFull()
    {
        return tokenCompressionMarkers.isFull();
    }

    public List<Byte> reset()
    {
        List<Byte> compressedBytes = new ArrayList<>();

        if (isFull())
        {
            compressedBytes.add(tokenCompressionMarkers.byteValue());
            compressedBytes.addAll(tokenBuffer);

            tokenBuffer.clear();
            tokenCompressionMarkers = new BitPacker(MAX_TOKENS);
        }

        return compressedBytes;
    }
}

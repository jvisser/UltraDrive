package com.ultradrive.mapconvert.export.compression.slz;

import com.ultradrive.mapconvert.common.BitPacker;
import java.util.ArrayList;
import java.util.List;


class SLZCompressionBuffer
{
    private static final int MAX_TOKENS = 8;

    private final List<Byte> compressedResult = new ArrayList<>();
    private final List<Byte> tokenBuffer = new ArrayList<>();

    private BitPacker tokenCompressionMarkers = new BitPacker(MAX_TOKENS);

    public void writeToken(SLZToken token)
    {
        token.write(tokenBuffer);

        tokenCompressionMarkers = tokenCompressionMarkers.insert(token.isCompressed());
        if (tokenCompressionMarkers.isFull())
        {
            compressedResult.add(tokenCompressionMarkers.byteValue());
            compressedResult.addAll(tokenBuffer);

            tokenBuffer.clear();
            tokenCompressionMarkers = new BitPacker(MAX_TOKENS);
        }
    }

    public List<Byte> complete()
    {
        if (!tokenCompressionMarkers.isEmpty())
        {
            tokenCompressionMarkers = tokenCompressionMarkers.padStart(MAX_TOKENS - tokenCompressionMarkers.getSize());

            compressedResult.add(tokenCompressionMarkers.byteValue());
            compressedResult.addAll(tokenBuffer);
        }

        return compressedResult;
    }
}

package com.ultradrive.mapconvert.export.compression;

import com.ultradrive.mapconvert.export.compression.slz.SLZCompressor;


public enum CompressionType
{
    SLZ(new SLZCompressor());

    private final Compressor compressor;

    CompressionType(Compressor compressor)
    {
        this.compressor = compressor;
    }

    public Compressor getCompressor()
    {
        return compressor;
    }
}

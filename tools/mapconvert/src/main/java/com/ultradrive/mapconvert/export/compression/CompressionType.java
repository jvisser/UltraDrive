package com.ultradrive.mapconvert.export.compression;

import com.ultradrive.mapconvert.export.compression.apj.APLibCompressor;
import com.ultradrive.mapconvert.export.compression.comper.ComperCompressor;
import com.ultradrive.mapconvert.export.compression.slz.SLZCompressor;


public enum CompressionType
{
    SLZ(new SLZCompressor()),
    COMPER(new ComperCompressor()),
    APLIB(new APLibCompressor());

    private final Compressor compressor;

    CompressionType(Compressor compressor)
    {
        this.compressor = compressor;
    }

    public CompressionResult compress(Iterable<Byte> bytes)
    {
        return compressor.compress(bytes);
    }
}

package com.ultradrive.mapconvert.export.expression;

import com.ultradrive.mapconvert.export.compression.CompressionResult;
import com.ultradrive.mapconvert.export.compression.CompressionType;
import com.ultradrive.mapconvert.export.compression.Compressor;


public class Compression
{
    public CompressionResult slz(Iterable<Byte> input)
    {
        Compressor compressor = CompressionType.SLZ.getCompressor();

        return compressor.compress(input);
    }

    public CompressionResult comper(Iterable<Byte> input)
    {
        Compressor compressor = CompressionType.COMPER.getCompressor();

        return compressor.compress(input);
    }
}

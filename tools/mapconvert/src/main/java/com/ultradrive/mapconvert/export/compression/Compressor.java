package com.ultradrive.mapconvert.export.compression;

public interface Compressor
{
    CompressionResult compress(Iterable<Byte> input);
}

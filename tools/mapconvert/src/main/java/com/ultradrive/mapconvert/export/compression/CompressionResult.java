package com.ultradrive.mapconvert.export.compression;

import java.util.Iterator;
import java.util.List;


public class CompressionResult implements Iterable<Byte>
{
    private final List<Byte> bytes;
    private final int uncompressedSize;

    public CompressionResult(List<Byte> bytes, int uncompressedSize)
    {
        this.bytes = bytes;
        this.uncompressedSize = uncompressedSize;
    }

    @Override
    public Iterator<Byte> iterator()
    {
        return bytes.iterator();
    }

    public List<Byte> getBytes()
    {
        return bytes;
    }

    public int getCompressedSize()
    {
        return bytes.size();
    }

    public int getUncompressedSize()
    {
        return uncompressedSize;
    }

    public double getCompressionRatio()
    {
        return (double) getCompressedSize() / uncompressedSize;
    }
}

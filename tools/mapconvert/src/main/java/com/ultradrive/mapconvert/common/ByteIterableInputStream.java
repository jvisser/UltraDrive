package com.ultradrive.mapconvert.common;

import java.io.InputStream;
import java.util.Iterator;


public class ByteIterableInputStream extends InputStream
{
    private final Iterator<Byte> byteIterator;

    public ByteIterableInputStream(Iterator<Byte> byteIterator)
    {
        this.byteIterator = byteIterator;
    }

    @Override
    public int read()
    {
        if (byteIterator.hasNext())
        {
            return byteIterator.next();
        }
        return -1;
    }
}

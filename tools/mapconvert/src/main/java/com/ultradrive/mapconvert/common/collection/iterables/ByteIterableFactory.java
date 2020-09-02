package com.ultradrive.mapconvert.common.collection.iterables;

import com.ultradrive.mapconvert.common.Endianess;
import com.ultradrive.mapconvert.common.Packable;


public class ByteIterableFactory
{
    private final Endianess endianess;

    public ByteIterableFactory(Endianess endianess)
    {
        this.endianess = endianess;
    }

    public <T extends Packable> Iterable<Byte>from(Iterable<T> packableIterator)
    {
        return new ObjectToBytesIterable<>(packable -> endianess.toBytes(packable.pack().numberValue()), packableIterator);
    }

    public <T extends Number> Iterable<Byte> from16(Iterable<T> numberIterable)
    {
        return new ObjectToBytesIterable<>(number -> endianess.toBytes(number.shortValue()), numberIterable);
    }

    public <T extends Number> Iterable<Byte> from32(Iterable<T> numberIterable)
    {
        return new ObjectToBytesIterable<>(number -> endianess.toBytes(number.intValue()), numberIterable);
    }

    public Iterable<Short> to16(Iterable<Byte> byteIterable)
    {
        return new BytesToObjectIterable<>(endianess::shortFromBytes, Short.BYTES, byteIterable);
    }

    public Iterable<Integer> to32(Iterable<Byte> byteIterable)
    {
        return new BytesToObjectIterable<>(endianess::intFromBytes, Integer.BYTES, byteIterable);
    }
}

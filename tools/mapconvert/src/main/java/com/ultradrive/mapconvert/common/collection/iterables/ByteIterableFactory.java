package com.ultradrive.mapconvert.common.collection.iterables;

import com.ultradrive.mapconvert.common.Endianess;
import com.ultradrive.mapconvert.common.Packable;
import java.util.List;
import java.util.function.Function;
import java.util.stream.StreamSupport;

import static java.util.stream.Collectors.toList;


public class ByteIterableFactory
{
    private final Endianess endianess;

    public ByteIterableFactory(Endianess endianess)
    {
        this.endianess = endianess;
    }

    public <T extends Packable> Iterable<Byte> from(Iterable<T> packableIterator)
    {
        return objectToBytes(packableIterator, packable -> endianess.toBytes(packable.pack().numberValue()));
    }

    public <T extends Number> Iterable<Byte> from16(Iterable<T> numberIterable)
    {
        return objectToBytes(numberIterable, number -> endianess.toBytes(number.shortValue()));
    }

    public <T extends Number> Iterable<Byte> from32(Iterable<T> numberIterable)
    {
        return objectToBytes(numberIterable, number -> endianess.toBytes(number.intValue()));
    }

    public <T extends Number> Iterable<Byte> from64(Iterable<T> numberIterable)
    {
        return objectToBytes(numberIterable, number -> endianess.toBytes(number.longValue()));
    }

    public Iterable<Short> to16(Iterable<Byte> byteIterable)
    {
        return bytesToObject(byteIterable, endianess::shortFromBytes, Short.BYTES);
    }

    public Iterable<Integer> to32(Iterable<Byte> byteIterable)
    {
        return bytesToObject(byteIterable, endianess::intFromBytes, Integer.BYTES);
    }

    public Iterable<Long> to64(Iterable<Byte> byteIterable)
    {
        return bytesToObject(byteIterable, endianess::longFromBytes, Long.BYTES);
    }

    private <T> Iterable<T> bytesToObject(Iterable<Byte> byteIterable, Function<List<Byte>, T> transform, int byteSize)
    {
        return new TransformingIterable<>(
                new GroupingIterable<>(byteIterable, byteSize),
                a -> transform.apply(StreamSupport.stream(a.spliterator(), false).collect(toList())));
    }

    private <T> Iterable<Byte> objectToBytes(Iterable<T> objectIterator, Function<T, Iterable<Byte>> transform)
    {
        return new FlatteningIterable<>(new TransformingIterable<>(objectIterator, transform));
    }
}

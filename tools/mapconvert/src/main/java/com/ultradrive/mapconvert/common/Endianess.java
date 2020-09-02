package com.ultradrive.mapconvert.common;


import java.util.function.Function;

import static java.util.function.Function.identity;


public enum Endianess
{
    BIG(Long::reverseBytes, Integer::reverseBytes, Short::reverseBytes),
    LITTLE(identity(), identity(), identity());

    private final Function<Long, Long> longTransform;
    private final Function<Integer, Integer> integerTransform;
    private final Function<Short, Short> shortTransform;

    Endianess(Function<Long, Long> longTransform,
              Function<Integer, Integer> integerTransform,
              Function<Short, Short> shortTransform)
    {
        this.longTransform = longTransform;
        this.integerTransform = integerTransform;
        this.shortTransform = shortTransform;
    }

    public byte[] toBytes(long value)
    {
        return toBytes(longTransform.apply(value), Long.BYTES);
    }

    public byte[] toBytes(int value)
    {
        return toBytes(integerTransform.apply(value), Integer.BYTES);
    }

    public byte[] toBytes(short value)
    {
        return toBytes(shortTransform.apply(value), Short.BYTES);
    }

    public byte[] toBytes(Number number)
    {
        if (number instanceof  Integer)
        {
            return toBytes(number.intValue());
        }

        if (number instanceof Short)
        {
            return toBytes(number.shortValue());
        }

        if (number instanceof Byte)
        {
            return toBytes(number.byteValue(), 1);
        }

        return toBytes(number.longValue());
    }

    public long longFromBytes(byte[] bytes)
    {
        long value = fromBytes(bytes, Long.BYTES);

        return longTransform.apply(value);
    }

    public int intFromBytes(byte[] bytes)
    {
        int value = (int) fromBytes(bytes, Integer.BYTES);

        return integerTransform.apply(value);
    }

    public short shortFromBytes(byte[] bytes)
    {
        short value = (short) fromBytes(bytes, Short.BYTES);

        return shortTransform.apply(value);
    }

    private long fromBytes(byte[] bytes, int byteCount)
    {
        if (bytes.length < byteCount)
        {
            throw new IllegalArgumentException("Insufficient data to reconstruct value");
        }

        long result = 0;
        int shift = 0;
        for (byte byteValue : bytes)
        {
            result |= (((long) byteValue & 0xff) << shift);
            shift += 8;
        }
        return result;
    }

    private byte[] toBytes(long value, int byteCount)
    {
        byte[] result = new byte[byteCount];

        for (int i = 0; i < byteCount; i++)
        {
            result[i] = (byte) ((value >>> (i << 3)) & 0xff);
        }

        return result;
    }
}

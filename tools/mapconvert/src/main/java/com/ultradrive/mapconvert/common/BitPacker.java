package com.ultradrive.mapconvert.common;

import static java.lang.String.format;


public final class BitPacker
{
    private final long value;
    private final int shift;
    private final int maxBits;

    public BitPacker()
    {
        this(Long.SIZE);
    }

    public BitPacker(int maxBits)
    {
        if (maxBits > Long.SIZE)
        {
            throw new IllegalArgumentException("Not enough storage");
        }

        this.maxBits = maxBits;
        this.value = 0;
        this.shift = 0;
    }

    private BitPacker(long value, int shift, int maxBits)
    {
        this.value = value;
        this.shift = shift;
        this.maxBits = maxBits;
    }

    public BitPacker add(long value)
    {
        return add(value, maxBits);
    }

    public BitPacker add(int value)
    {
        return add(value, Integer.SIZE);
    }

    public BitPacker add(short value)
    {
        return add(value, Short.SIZE);
    }

    public BitPacker add(byte value)
    {
        return add(value, Byte.SIZE);
    }

    public BitPacker add(long value, int bitCount)
    {
        if (shift + bitCount > maxBits)
        {
            throw new IllegalArgumentException(format("Overflow (shift:%d + bitCount:%d > maxBits:%d)", shift, bitCount, maxBits));
        }

        return new BitPacker(this.value | ((value & ((1L << bitCount) - 1)) << shift),
                             shift + bitCount,
                             maxBits);
    }

    public BitPacker add(boolean value)
    {
        return add(value ? 1 : 0, 1);
    }

    public BitPacker add(BitPacker other)
    {
        return add(other.value, other.shift);
    }

    public BitPacker add(Packable packable)
    {
        return add(packable.pack());
    }

    public int intValue()
    {
        if (value < 0xffffffff)
        {
            throw new IllegalArgumentException("Not enough storage in Integer");
        }

        return (int) value;
    }

    public short shortValue()
    {
        if (value < 0xffff)
        {
            throw new IllegalArgumentException("Not enough storage in Short");
        }

        return (short) value;
    }

    public byte byteValue()
    {
        if (value < 0xff)
        {
            throw new IllegalArgumentException("Not enough storage in Byte");
        }

        return (byte) value;
    }

    public BitPacker pad(int i)
    {
        return add(0, i);
    }

    public int getSize()
    {
        return shift;
    }
}

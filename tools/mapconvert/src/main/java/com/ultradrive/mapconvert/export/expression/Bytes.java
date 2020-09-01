package com.ultradrive.mapconvert.export.expression;

import com.ultradrive.mapconvert.common.Endianess;
import com.ultradrive.mapconvert.common.Packable;
import java.util.Collections;
import java.util.Iterator;
import java.util.NoSuchElementException;
import java.util.function.Function;


public class Bytes
{
    private static class ByteIterator<T> implements Iterator<Byte>
    {
        private final Function<T, byte[]> byteValueTransform;
        private final Iterator<T> delegate;

        private byte[] currentValue;
        private int count;

        public ByteIterator(Function<T, byte[]> byteValueTransform, Iterator<T> delegate)
        {
            this.byteValueTransform = byteValueTransform;
            this.delegate = delegate;

            this.currentValue = null;
            this.count = 0;
        }

        @Override
        public boolean hasNext()
        {
            return count != 0 || delegate.hasNext();
        }

        @Override
        public Byte next()
        {
            if (count == 0)
            {
                currentValue = byteValueTransform.apply(delegate.next());
                count = currentValue.length;
            }

            byte result = currentValue[currentValue.length - count];

            count--;

            return result;
        }
    }

    private static class ByteIterable<T> implements Iterable<Byte>
    {
        private final Function<T, byte[]> byteValueTransform;
        private final Iterable<T> delegate;

        private ByteIterable(Function<T, byte[]> byteValueTransform, Iterable<T> delegate)
        {
            this.byteValueTransform = byteValueTransform;
            this.delegate = delegate;
        }

        @Override
        public Iterator<Byte> iterator()
        {
            return new ByteIterator<>(byteValueTransform, delegate.iterator());
        }
    }

    private static class ByteToNumberIterator<T extends Number> implements Iterator<T>
    {
        private final Function<byte[], T> numberValueTransform;
        private final int byteCountPerValue;
        private final Iterator<Byte> delegate;

        private ByteToNumberIterator(Function<byte[], T> numberValueTransform,
                                     int byteCountPerValue,
                                     Iterator<Byte> delegate)
        {
            this.numberValueTransform = numberValueTransform;
            this.byteCountPerValue = byteCountPerValue;
            this.delegate = delegate;
        }

        @Override
        public boolean hasNext()
        {
            return delegate.hasNext();
        }

        @Override
        public T next()
        {
            byte[] collectedBytes = new byte[byteCountPerValue];

            int collectedByteCount;
            for (collectedByteCount = 0; collectedByteCount < collectedBytes.length && delegate.hasNext(); collectedByteCount++)
            {
                collectedBytes[collectedByteCount] = delegate.next();
            }

            if (collectedByteCount != byteCountPerValue)
            {
                throw new NoSuchElementException("Not enough information available to construct value");
            }

            return numberValueTransform.apply(collectedBytes);
        }
    }

    private static class ByteToNumberIterable<T extends Number> implements Iterable<T>
    {
        private final Function<byte[], T> numberValueTransform;
        private final int byteCountPerValue;
        private final Iterable<Byte> delegate;

        private ByteToNumberIterable(Function<byte[], T> numberValueTransform,
                                     int byteCountPerValue,
                                     Iterable<Byte> delegate)
        {
            this.numberValueTransform = numberValueTransform;
            this.byteCountPerValue = byteCountPerValue;
            this.delegate = delegate;
        }

        @Override
        public Iterator<T> iterator()
        {
            return new ByteToNumberIterator<>(numberValueTransform, byteCountPerValue, delegate.iterator());
        }
    }

    public <T extends Packable> Iterable<Byte>fromBE(Iterable<T> packableIterator)
    {
        return new ByteIterable<>(packable -> Endianess.BIG.toBytes(packable.pack().numberValue()), packableIterator);
    }

    public <T extends Packable> Iterable<Byte>fromLE(Iterable<T> packableIterator)
    {
        return new ByteIterable<>(packable -> Endianess.LITTLE.toBytes(packable.pack().numberValue()), packableIterator);
    }

    public <T extends Number> Iterable<Byte> from16BE(Iterable<T> numberIterable)
    {
        return new ByteIterable<>(number -> Endianess.BIG.toBytes(number.shortValue()), numberIterable);
    }

    public <T extends Number> Iterable<Byte> from32BE(Iterable<T> numberIterable)
    {
        return new ByteIterable<>(number -> Endianess.BIG.toBytes(number.intValue()), numberIterable);
    }

    public <T extends Number> Iterable<Byte> from16LE(Iterable<T> numberIterable)
    {
        return new ByteIterable<>(number -> Endianess.LITTLE.toBytes(number.shortValue()), numberIterable);
    }

    public <T extends Number> Iterable<Byte> from32LE(Iterable<T> numberIterable)
    {
        return new ByteIterable<>(number -> Endianess.LITTLE.toBytes(number.intValue()), numberIterable);
    }

    public Iterable<Short> to16BE(Iterable<Byte> byteIterable)
    {
        return new ByteToNumberIterable<>(Endianess.BIG::shortFromBytes, Short.BYTES, byteIterable);
    }

    public Iterable<Integer> to32BE(Iterable<Byte> byteIterable)
    {
        return new ByteToNumberIterable<>(Endianess.BIG::intFromBytes, Integer.BYTES, byteIterable);
    }

    public Iterable<Short> to16LE(Iterable<Byte> byteIterable)
    {
        return new ByteToNumberIterable<>(Endianess.LITTLE::shortFromBytes, Short.BYTES, byteIterable);
    }

    public Iterable<Integer> to32LE(Iterable<Byte> byteIterable)
    {
        return new ByteToNumberIterable<>(Endianess.LITTLE::intFromBytes, Integer.BYTES, byteIterable);
    }

    public Iterable<Byte> fromString(Iterable<String> stringIterable)
    {
        return new ByteIterable<>(String::getBytes, stringIterable);
    }

    public Iterable<Byte> fromString(String string)
    {
        return fromString(Collections.singleton(string));
    }
}

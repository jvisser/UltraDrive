package com.ultradrive.mapconvert.common.collection.iterables;

import java.util.Iterator;
import java.util.NoSuchElementException;
import java.util.function.Function;


class BytesToObjectIterable<T> implements Iterable<T>
{
    private final Function<byte[], T> numberValueTransform;
    private final int byteCountPerValue;
    private final Iterable<Byte> delegate;

    BytesToObjectIterable(Function<byte[], T> numberValueTransform, int byteCountPerValue, Iterable<Byte> delegate)
    {
        this.numberValueTransform = numberValueTransform;
        this.byteCountPerValue = byteCountPerValue;
        this.delegate = delegate;
    }

    private static class BytesToObjectIterator<T> implements Iterator<T>
    {
        private final Function<byte[], T> numberValueTransform;
        private final int byteCountPerValue;
        private final Iterator<Byte> delegate;

        BytesToObjectIterator(Function<byte[], T> numberValueTransform, int byteCountPerValue, Iterator<Byte> delegate)
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

    @Override
    public Iterator<T> iterator()
    {
        return new BytesToObjectIterator<>(numberValueTransform, byteCountPerValue, delegate.iterator());
    }
}

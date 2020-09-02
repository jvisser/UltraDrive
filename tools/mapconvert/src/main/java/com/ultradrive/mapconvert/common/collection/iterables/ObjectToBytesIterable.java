package com.ultradrive.mapconvert.common.collection.iterables;

import java.util.Iterator;
import java.util.function.Function;


class ObjectToBytesIterable<T> implements Iterable<Byte>
{
    private final Function<T, byte[]> byteValueTransform;
    private final Iterable<T> delegate;

    ObjectToBytesIterable(Function<T, byte[]> byteValueTransform, Iterable<T> delegate)
    {
        this.byteValueTransform = byteValueTransform;
        this.delegate = delegate;
    }

    private static class ObjectToBytesIterator<T> implements Iterator<Byte>
    {
        private final Function<T, byte[]> byteValueTransform;
        private final Iterator<T> delegate;

        private byte[] currentValue;
        private int count;

        public ObjectToBytesIterator(Function<T, byte[]> byteValueTransform, Iterator<T> delegate)
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

    @Override
    public Iterator<Byte> iterator()
    {
        return new ObjectToBytesIterator<>(byteValueTransform, delegate.iterator());
    }
}

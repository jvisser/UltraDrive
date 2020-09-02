package com.ultradrive.mapconvert.common.collection.iterables;

import java.util.Iterator;


public class FlatteningIterable<R, T extends Iterable<R>> implements Iterable<R>
{
    private final Iterable<T> delegate;

    public FlatteningIterable(Iterable<T> delegate)
    {
        this.delegate = delegate;
    }

    private static class FlatteningIterator<R, T extends Iterable<R>> implements Iterator<R>
    {
        private final Iterator<T> delegate;

        private Iterator<R> currentSubIterator;

        private FlatteningIterator(Iterator<T> delegate)
        {
            this.delegate = delegate;

            this.currentSubIterator = null;
        }

        @Override
        public boolean hasNext()
        {
            return delegate.hasNext() || (currentSubIterator != null && currentSubIterator.hasNext());
        }

        @Override
        public R next()
        {
            if (currentSubIterator == null || !currentSubIterator.hasNext())
            {
                currentSubIterator = delegate.next().iterator();
            }

            return currentSubIterator.next();
        }
    }

    @Override
    public Iterator<R> iterator()
    {
        return new FlatteningIterator<>(delegate.iterator());
    }
}

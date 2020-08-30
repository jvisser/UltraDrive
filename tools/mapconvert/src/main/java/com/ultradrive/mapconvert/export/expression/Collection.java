package com.ultradrive.mapconvert.export.expression;

import java.util.Iterator;


public class Collection
{
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

    private static class FlatteningIterable<R, T extends Iterable<R>> implements Iterable<R>
    {
        private final Iterable<T> delegate;

        private FlatteningIterable(Iterable<T> delegate)
        {
            this.delegate = delegate;
        }

        @Override
        public Iterator<R> iterator()
        {
            return new FlatteningIterator<>(delegate.iterator());
        }
    }

    public <R, T extends Iterable<R>> FlatteningIterable<R, T> flatten(Iterable<T> iterableIterable)
    {
        return new FlatteningIterable<>(iterableIterable);
    }
}

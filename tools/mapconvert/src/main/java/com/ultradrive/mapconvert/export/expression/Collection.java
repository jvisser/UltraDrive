package com.ultradrive.mapconvert.export.expression;

import java.util.Iterator;
import java.util.stream.Stream;
import java.util.stream.StreamSupport;


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

    private static class ConcatenatingIterable<T> implements Iterable<T>
    {
        private final Iterable<T> first;
        private final Iterable<T> second;

        private ConcatenatingIterable(Iterable<T> first, Iterable<T> second)
        {
            this.first = first;
            this.second = second;
        }

        @Override
        public Iterator<T> iterator()
        {
            return Stream.concat(
                    StreamSupport.stream(first.spliterator(), false),
                    StreamSupport.stream(second.spliterator(), false)).iterator();
        }
    }

    public <R, T extends Iterable<R>> FlatteningIterable<R, T> flatten(Iterable<T> iterableIterable)
    {
        return new FlatteningIterable<>(iterableIterable);
    }

    public <T> Iterable<T> concat(Iterable<T> first, Iterable<T> second)
    {
        return new ConcatenatingIterable<>(first, second);
    }
}

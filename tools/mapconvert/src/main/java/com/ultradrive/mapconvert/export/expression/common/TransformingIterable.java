package com.ultradrive.mapconvert.export.expression.common;

import java.util.Iterator;
import java.util.function.Function;


public class TransformingIterable<T, R> implements Iterable<R>
{
    private final Iterable<T> delegate;
    private final Function<T, R> transform;

    public TransformingIterable(Iterable<T> delegate, Function<T, R> transform)
    {
        this.delegate = delegate;
        this.transform = transform;
    }

    private static class TransformingIterator<T, R> implements Iterator<R>
    {
        private final Iterator<T> delegate;
        private final Function<T, R> transform;

        private TransformingIterator(Iterator<T> delegate, Function<T, R> transform)
        {
            this.delegate = delegate;
            this.transform = transform;
        }

        @Override
        public boolean hasNext()
        {
            return delegate.hasNext();
        }

        @Override
        public R next()
        {
            return transform.apply(delegate.next());
        }
    }

    @Override
    public Iterator<R> iterator()
    {
        return new TransformingIterator<>(delegate.iterator(), transform);
    }
}

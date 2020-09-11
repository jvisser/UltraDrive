package com.ultradrive.mapconvert.common.collection.iterables;

import java.util.Iterator;
import java.util.function.Function;
import java.util.stream.StreamSupport;
import javax.annotation.Nonnull;


public class TransformingIterable<T, R> implements Iterable<R>
{
    private final Iterable<T> delegate;
    private final Function<T, R> transform;

    public TransformingIterable(Iterable<T> delegate, Function<T, R> transform)
    {
        this.delegate = delegate;
        this.transform = transform;
    }

    @Override
    @Nonnull
    public Iterator<R> iterator()
    {
        return StreamSupport.stream(delegate.spliterator(), false)
                .map(transform)
                .iterator();
    }
}

package com.ultradrive.mapconvert.common.collection.iterables;

import java.util.Iterator;
import java.util.stream.StreamSupport;
import javax.annotation.Nonnull;


public class FlatteningIterable<R, T extends Iterable<R>> implements Iterable<R>
{
    private final Iterable<T> delegate;

    public FlatteningIterable(Iterable<T> delegate)
    {
        this.delegate = delegate;
    }

    @Override
    @Nonnull
    public Iterator<R> iterator()
    {
        return StreamSupport.stream(delegate.spliterator(), false)
                .flatMap(subIterable -> StreamSupport.stream(subIterable.spliterator(), false))
                .iterator();
    }
}

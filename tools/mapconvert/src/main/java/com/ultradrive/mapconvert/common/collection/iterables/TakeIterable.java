package com.ultradrive.mapconvert.common.collection.iterables;

import java.util.Iterator;
import java.util.stream.StreamSupport;
import javax.annotation.Nonnull;


public class TakeIterable<T> implements Iterable<T>
{
    private final Iterable<T> delegate;
    private final int takeCount;

    public TakeIterable(Iterable<T> delegate, int takeCount)
    {
        this.delegate = delegate;
        this.takeCount = takeCount;
    }

    @Override
    @Nonnull
    public Iterator<T> iterator()
    {
        return StreamSupport.stream(delegate.spliterator(), false)
                .limit(takeCount)
                .iterator();
    }
}

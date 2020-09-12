package com.ultradrive.mapconvert.common.collection.iterables;

import java.util.Iterator;
import java.util.stream.StreamSupport;
import javax.annotation.Nonnull;


public class SkipIterable<T> implements Iterable<T>
{
    private final Iterable<T> delegate;
    private final int skipCount;

    public SkipIterable(Iterable<T> delegate, int skipCount)
    {
        this.delegate = delegate;
        this.skipCount = skipCount;
    }

    @Override
    @Nonnull
    public Iterator<T> iterator()
    {
        return StreamSupport.stream(delegate.spliterator(), false)
                .skip(skipCount)
                .iterator();
    }
}

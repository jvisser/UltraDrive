package com.ultradrive.mapconvert.common.collection.iterables;

import java.util.Iterator;
import java.util.stream.Stream;
import java.util.stream.StreamSupport;


public class ConcatenatingIterable<T> implements Iterable<T>
{
    private final Iterable<T> first;
    private final Iterable<T> second;

    public ConcatenatingIterable(Iterable<T> first, Iterable<T> second)
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

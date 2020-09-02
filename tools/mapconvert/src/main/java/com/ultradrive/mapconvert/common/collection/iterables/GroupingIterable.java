package com.ultradrive.mapconvert.common.collection.iterables;

import java.util.Iterator;
import java.util.stream.IntStream;

import static java.util.stream.Collectors.toList;


public class GroupingIterable<T> implements Iterable<Iterable<T>>
{
    private final Iterable<T> delegate;
    private final int groupCount;

    public GroupingIterable(Iterable<T> delegate, int groupCount)
    {
        this.delegate = delegate;
        this.groupCount = groupCount;
    }

    private static class GroupingIterator<T> implements Iterator<Iterable<T>>
    {
        private final Iterator<T> delegate;
        private final int groupCount;

        private GroupingIterator(Iterator<T> delegate, int groupCount)
        {
            this.delegate = delegate;
            this.groupCount = groupCount;
        }

        @Override
        public boolean hasNext()
        {
            return delegate.hasNext();
        }

        @Override
        public Iterable<T> next()
        {
            return IntStream.range(0, groupCount)
                    .takeWhile(value -> delegate.hasNext())
                    .mapToObj(value -> delegate.next())
                    .collect(toList());
        }
    }

    @Override
    public Iterator<Iterable<T>> iterator()
    {
        return new GroupingIterator<>(delegate.iterator(), groupCount);
    }
}
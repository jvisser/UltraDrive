package com.ultradrive.mapconvert.export.expression;


import com.ultradrive.mapconvert.common.collection.iterables.ConcatenatingIterable;
import com.ultradrive.mapconvert.common.collection.iterables.FlatteningIterable;
import com.ultradrive.mapconvert.common.collection.iterables.GroupingIterable;


public class CollectionExpressions
{
    public <T> Iterable<Iterable<T>> group(Iterable<T> iterableIterable, int groupSize)
    {
        return new GroupingIterable<>(iterableIterable, groupSize);
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

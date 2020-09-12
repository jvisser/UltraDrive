package com.ultradrive.mapconvert.export.expression;


import com.ultradrive.mapconvert.common.collection.iterables.ConcatenatingIterable;
import com.ultradrive.mapconvert.common.collection.iterables.FlatteningIterable;
import com.ultradrive.mapconvert.common.collection.iterables.GroupingIterable;
import com.ultradrive.mapconvert.common.collection.iterables.SkipIterable;
import com.ultradrive.mapconvert.common.collection.iterables.TakeIterable;


public class CollectionExpressions
{
    public <T> Iterable<Iterable<T>> group(int groupSize, Iterable<T> iterableIterable)
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

    public <T> Iterable<T> skip(int skipCount, Iterable<T> iterable)
    {
        return new SkipIterable<>(iterable, skipCount);
    }

    public <T> Iterable<T> take(int takeCount, Iterable<T> iterable)
    {
        return new TakeIterable<>(iterable, takeCount);
    }
}

package com.ultradrive.mapconvert.export.expression;


import com.ultradrive.mapconvert.common.collection.iterables.ConcatenatingIterable;
import com.ultradrive.mapconvert.common.collection.iterables.FlatteningIterable;


public class CollectionExpressions
{
    public <R, T extends Iterable<R>> FlatteningIterable<R, T> flatten(Iterable<T> iterableIterable)
    {
        return new FlatteningIterable<>(iterableIterable);
    }

    public <T> Iterable<T> concat(Iterable<T> first, Iterable<T> second)
    {
        return new ConcatenatingIterable<>(first, second);
    }
}

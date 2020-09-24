package com.ultradrive.mapconvert.common.orientable;

public interface OrientableReferenceProducer<T extends OrientablePoolable<T, R>, R extends OrientableReference<R>>
{
    R.Builder<R> getReference(T orientable);
}

package com.ultradrive.mapconvert.common.orientable;

public interface OrientablePoolable<T extends OrientablePoolable<T, ?>, R extends OrientableReference<R>> extends Orientable<T>
{
    OrientableReference.Builder<R> referenceBuilder();
}

package com.ultradrive.mapconvert.common.orientable;

public interface OrientablePoolListener<T extends OrientablePoolable<T, R>, R extends OrientableReference<R>>
{
    void onPoolInsert(R reference, T orientable);
}

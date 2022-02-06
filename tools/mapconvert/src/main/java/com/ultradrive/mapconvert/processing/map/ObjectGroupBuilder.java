package com.ultradrive.mapconvert.processing.map;

interface ObjectGroupBuilder<T extends ObjectGroupBuilder<T>>
{
    void calculateFlag();

    void associateGroup(T objectGroupBuilder);

    boolean isZeroGroup();

    int priority();
}

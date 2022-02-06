package com.ultradrive.mapconvert.processing.map;

interface GroupSubLayer<T extends ObjectGroupBuilder<T>>
{
    T get(int row, int column);
}

package com.ultradrive.mapconvert.processing.map;

import com.ultradrive.mapconvert.common.PropertySource;


class AuxiliaryMapSource<T extends PropertySource>
{
    private final T source;
    private final String propertyName;

    AuxiliaryMapSource(T source, String propertyName)
    {
        this.source = source;
        this.propertyName = propertyName;
    }

    public T getSource()
    {
        return source;
    }

    public String getPropertyName()
    {
        return propertyName;
    }
}

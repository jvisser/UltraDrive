package com.ultradrive.mapconvert.common;

import java.util.Map;


public interface PropertySource
{
    Map<String, Object> getProperties();

    default boolean hasProperty(String name)
    {
        return getProperties().containsKey(name);
    }

    default Object getProperty(String name)
    {
        return getProperties().get(name);
    }
}

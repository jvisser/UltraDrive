package com.ultradrive.mapconvert.datasource.model;

import com.ultradrive.mapconvert.common.PropertySource;
import java.util.Map;


public class MapObject implements PropertySource
{
    private final String name;
    private final int id;
    private final Map<String, Object> properties;
    private final int x;
    private final int y;
    private final boolean horizontalFlip;
    private final boolean verticalFlip;

    public MapObject(String name, int id,
                     Map<String, Object> properties,
                     int x, int y,
                     boolean horizontalFlip, boolean verticalFlip)
    {
        this.name = name;
        this.id = id;
        this.properties = properties;
        this.x = x;
        this.y = y;
        this.horizontalFlip = horizontalFlip;
        this.verticalFlip = verticalFlip;
    }

    public String getName()
    {
        return name;
    }

    public int getId()
    {
        return id;
    }

    @Override
    public Map<String, Object> getProperties()
    {
        return properties;
    }

    public int getX()
    {
        return x;
    }

    public int getY()
    {
        return y;
    }

    public boolean isHorizontalFlip()
    {
        return horizontalFlip;
    }

    public boolean isVerticalFlip()
    {
        return verticalFlip;
    }
}

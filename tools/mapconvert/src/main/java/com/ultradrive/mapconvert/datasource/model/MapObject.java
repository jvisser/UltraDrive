package com.ultradrive.mapconvert.datasource.model;

import com.ultradrive.mapconvert.common.PropertySource;
import java.util.Map;


public class MapObject implements PropertySource, Comparable<MapObject>
{
    private final boolean horizontalFlip;
    private final int id;
    private final String name;
    private final String type;
    private final Map<String, Object> properties;
    private final boolean verticalFlip;
    private final int x;
    private final int y;

    public MapObject(int id,
                     String type,
                     String name,
                     Map<String, Object> properties,
                     int x, int y,
                     boolean horizontalFlip, boolean verticalFlip)
    {
        this.name = name;
        this.id = id;
        this.type = type;
        this.properties = properties;
        this.x = x;
        this.y = y;
        this.horizontalFlip = horizontalFlip;
        this.verticalFlip = verticalFlip;
    }

    @Override
    public int compareTo(MapObject o)
    {
        return name.compareTo(o.name);
    }

    @Override
    public Map<String, Object> getProperties()
    {
        return properties;
    }

    public int getId()
    {
        return id;
    }

    public String getName()
    {
        return name;
    }

    public String getType()
    {
        return type;
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

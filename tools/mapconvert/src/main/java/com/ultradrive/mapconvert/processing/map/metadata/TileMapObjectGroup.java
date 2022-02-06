package com.ultradrive.mapconvert.processing.map.metadata;

import com.google.common.collect.ImmutableList;
import com.ultradrive.mapconvert.datasource.model.MapObject;
import java.util.Collection;
import java.util.List;


public final class TileMapObjectGroup
{
    private final int id;
    private final int flag;
    private final TileMapObjectGroupContainer container;
    private final List<MapObject> objects;

    public TileMapObjectGroup(int id, int flag,
                              TileMapObjectGroupContainer container,
                              Collection<MapObject> objects)
    {
        this.id = id;
        this.flag = flag;
        this.container = container;
        this.objects = ImmutableList.copyOf(objects);
    }

    public int getId()
    {
        return id;
    }

    public int getFlagMask()
    {
        return flag;
    }

    public int getFlag()
    {
        return flag;
    }

    public TileMapObjectGroupContainer getContainer()
    {
        return container;
    }

    public int getFlagNumber()
    {
        return Integer.numberOfTrailingZeros(flag);
    }

    public List<MapObject> getObjects()
    {
        return objects;
    }

    public int getSize()
    {
        return objects.size();
    }
}

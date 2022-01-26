package com.ultradrive.mapconvert.processing.map.metadata;

import com.google.common.collect.ImmutableList;
import com.ultradrive.mapconvert.datasource.model.MapObject;
import java.util.Collection;
import java.util.List;


public final class ObjectGroup
{
    private final int id;
    private final int flag;
    private final List<MapObject> objects;

    public ObjectGroup(int id, int flag, Collection<MapObject> objects)
    {
        this.id = id;
        this.flag = flag;
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

package com.ultradrive.mapconvert.processing.map.object;

import com.google.common.collect.ImmutableList;
import java.util.List;


public class ObjectGroupContainer
{
    private final int id;
    private final List<ObjectGroup> objectGroups;

    ObjectGroupContainer(int id, List<ObjectGroup> objectGroups)
    {
        this.id = id;
        this.objectGroups = ImmutableList.copyOf(objectGroups);
    }

    public int getId()
    {
        return id;
    }

    public List<ObjectGroup> getObjectGroups()
    {
        return objectGroups;
    }
}

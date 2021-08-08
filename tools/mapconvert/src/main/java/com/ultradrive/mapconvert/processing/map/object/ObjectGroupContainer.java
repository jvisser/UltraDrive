package com.ultradrive.mapconvert.processing.map.object;

import java.util.List;


public class ObjectGroupContainer
{
    private final int id;
    private final List<ObjectGroup> objectGroups;

    public ObjectGroupContainer(int id, List<ObjectGroup> objectGroups)
    {
        this.id = id;
        this.objectGroups = objectGroups;
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

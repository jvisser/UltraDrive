package com.ultradrive.mapconvert.processing.map.metadata;

import com.google.common.collect.ImmutableList;
import java.util.List;


public class TileMapMetadataContainer
{
    private final int id;
    private final List<ObjectGroup> objectGroups;

    TileMapMetadataContainer(int id, List<ObjectGroup> objectGroups)
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

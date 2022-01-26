package com.ultradrive.mapconvert.processing.map.metadata;

import com.google.common.collect.ImmutableList;
import com.ultradrive.mapconvert.datasource.model.MapObject;
import java.util.List;
import java.util.stream.Collectors;


public final class TileMapMetadataMap
{
    private final List<TileMapMetadataContainer> metadataContainers;
    private final List<ObjectGroup> objectGroups;
    private final int width;
    private final int height;

    public TileMapMetadataMap(List<TileMapMetadataContainer> metadataContainers,
                       List<ObjectGroup> objectGroups,
                       int width, int height)
    {
        this.metadataContainers = ImmutableList.copyOf(metadataContainers);
        this.objectGroups = ImmutableList.copyOf(objectGroups);
        this.width = width;
        this.height = height;
    }

    public int getHeight()
    {
        return height;
    }

    public List<TileMapMetadataContainer> getMetadataContainers()
    {
        return metadataContainers;
    }

    public List<ObjectGroup> getObjectGroups()
    {
        return objectGroups;
    }

    public List<MapObject> getObjects()
    {
        return objectGroups.stream()
                .flatMap(objectGroup -> objectGroup.getObjects().stream())
                .collect(Collectors.toUnmodifiableList());
    }

    public int getWidth()
    {
        return width;
    }
}

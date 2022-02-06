package com.ultradrive.mapconvert.processing.map.metadata;

import com.google.common.collect.ImmutableList;
import com.ultradrive.mapconvert.datasource.model.MapObject;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;


public final class TileMapMetadataMap
{
    private final List<TileMapMetadataContainer> metadataContainers;
    private final List<TileMapObjectGroupContainer> objectGroupContainers;
    private final List<TileMapObjectGroup> objectGroups;
    private final int width;
    private final int height;
    private final int maxGroupsInView;
    private final int maxNodesInView;
    private final int objectContainerFlagCount;

    public TileMapMetadataMap(List<TileMapMetadataContainer> metadataContainers,
                              List<TileMapObjectGroupContainer> objectGroupContainers,
                              List<TileMapObjectGroup> objectGroups,
                              int width, int height, int maxGroupsInView, int maxNodesInView)
    {
        this.metadataContainers = ImmutableList.copyOf(metadataContainers);
        this.objectGroupContainers = ImmutableList.copyOf(objectGroupContainers);
        this.objectGroups = ImmutableList.copyOf(objectGroups);
        this.width = width;
        this.height = height;
        this.maxGroupsInView = maxGroupsInView;
        this.maxNodesInView = maxNodesInView;
        this.objectContainerFlagCount = objectGroupContainers.stream()
                .map(TileMapObjectGroupContainer::getFlagNumber)
                .max(Comparator.naturalOrder()).orElse(0) + 1;
    }

    public int getHeight()
    {
        return height;
    }

    public List<TileMapMetadataContainer> getMetadataContainers()
    {
        return metadataContainers;
    }

    public List<TileMapObjectGroupContainer> getObjectGroupContainers()
    {
        return objectGroupContainers;
    }

    public List<TileMapObjectGroup> getObjectGroups()
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

    public int getMaxGroupsInView()
    {
        return maxGroupsInView;
    }

    public int getMaxNodesInView()
    {
        return maxNodesInView;
    }

    public int getObjectContainerFlagCount()
    {
        return objectContainerFlagCount;
    }
}

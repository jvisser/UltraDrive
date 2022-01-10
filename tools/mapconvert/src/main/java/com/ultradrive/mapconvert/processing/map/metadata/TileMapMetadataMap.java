package com.ultradrive.mapconvert.processing.map.metadata;

import com.google.common.collect.ImmutableList;
import com.ultradrive.mapconvert.datasource.model.MapModel;
import com.ultradrive.mapconvert.datasource.model.MapObject;
import java.util.List;
import java.util.stream.Collectors;


public class TileMapMetadataMap
{
    private final List<TileMapMetadataContainer> metadataContainers;
    private final List<ObjectGroup> objectGroups;
    private final List<Integer> chunkLocalObjectGroupContainerIndices;
    private final int mapStride;
    private final int width;
    private final int height;

    TileMapMetadataMap(List<TileMapMetadataContainer> metadataContainers,
                       List<ObjectGroup> objectGroups,
                       List<Integer> chunkLocalObjectGroupContainerIndices, int mapStride, int width, int height)
    {
        this.metadataContainers = ImmutableList.copyOf(metadataContainers);
        this.objectGroups = ImmutableList.copyOf(objectGroups);
        this.chunkLocalObjectGroupContainerIndices = ImmutableList.copyOf(chunkLocalObjectGroupContainerIndices);
        this.mapStride = mapStride;
        this.width = width;
        this.height = height;
    }

    public static TileMapMetadataMap fromMapModel(MapModel mapModel)
    {
        return new TileMapMetadataMapBuilder(mapModel, 320, 224).build();
    }

    public int getChunkObjectGroupContainerIndex(int row, int column)
    {
        if (chunkLocalObjectGroupContainerIndices.isEmpty())
        {
            return 0;
        }
        return chunkLocalObjectGroupContainerIndices.get(row * mapStride + column);
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

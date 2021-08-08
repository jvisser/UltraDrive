package com.ultradrive.mapconvert.processing.map.object;

import com.ultradrive.mapconvert.datasource.model.MapModel;
import java.util.List;


public class ObjectGroupMap
{
    private final List<ObjectGroupContainer> objectGroupContainers;
    private final List<ObjectGroup> objectGroups;
    private final List<Integer> chunkLocalObjectGroupContainerIndices;
    private final int mapStride;
    private final int width;
    private final int height;

    ObjectGroupMap(List<ObjectGroupContainer> objectGroupContainers,
                   List<ObjectGroup> objectGroups,
                   List<Integer> chunkLocalObjectGroupContainerIndices, int mapStride, int width, int height)
    {
        this.objectGroupContainers = objectGroupContainers;
        this.objectGroups = objectGroups;
        this.chunkLocalObjectGroupContainerIndices = chunkLocalObjectGroupContainerIndices;
        this.mapStride = mapStride;
        this.width = width;
        this.height = height;
    }

    public static ObjectGroupMap fromMapModel(MapModel mapModel)
    {
        return new ObjectGroupMapBuilder(mapModel, 320, 224).build();
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

    public List<ObjectGroupContainer> getObjectGroupContainers()
    {
        return objectGroupContainers;
    }

    public List<ObjectGroup> getObjectGroups()
    {
        return objectGroups;
    }

    public int getWidth()
    {
        return width;
    }
}

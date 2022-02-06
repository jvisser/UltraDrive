package com.ultradrive.mapconvert.processing.map;

import com.google.common.collect.Sets;
import com.ultradrive.mapconvert.datasource.model.ChunkReferenceModel;
import com.ultradrive.mapconvert.datasource.model.MapLayer;
import com.ultradrive.mapconvert.datasource.model.MapModel;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.Set;


abstract class GroupLayerBuilder<T extends ObjectGroupBuilder<T>>
{
    protected final MapModel mapModel;
    protected final int screenWidth;
    protected final int screenHeight;

    protected final Set<T> groupBuilders;

    protected GroupLayerBuilder(MapModel mapModel, int screenWidth, int screenHeight)
    {
        this.mapModel = mapModel;
        this.screenWidth = screenWidth;
        this.screenHeight = screenHeight;
        this.groupBuilders = new LinkedHashSet<>();
    }

    public void createObjectGroupFlags()
    {
        groupBuilders.stream()
                .sorted(Comparator.comparingLong(T::priority).reversed())
                .forEach(T::calculateFlag);
    }

    protected T[][] createGroupMap(MapLayer mapLayer)
    {
        int width = mapModel.getWidth();
        int height = mapModel.getHeight();

        T[][] groupMap = createMap();

        int[][] sourceGroupIds = new int[height][width];
        for (int row = 0; row < height; row++)
        {
            for (int column = 0; column < width; column++)
            {
                int startGroupId = getGroupId(mapLayer.getChunkReference(row, column));
                T currentGroup = getDefaultGroup(startGroupId);

                if (row > 0 && sourceGroupIds[row - 1][column] == startGroupId)
                {
                    currentGroup = groupMap[row - 1][column];
                }

                int startColumn = column;
                for (int i = column + 1; i < width; i++, column++)
                {
                    int currentGroupId = getGroupId(mapLayer.getChunkReference(row, i));
                    if (startGroupId != currentGroupId)
                    {
                        break;
                    }

                    if (row > 0 && currentGroup == null && sourceGroupIds[row - 1][i] == currentGroupId)
                    {
                        currentGroup = groupMap[row - 1][i];
                    }
                }

                if (currentGroup == null)
                {
                    currentGroup = addGroup();
                }

                for (int i = startColumn; i <= column; i++)
                {
                    sourceGroupIds[row][i] = startGroupId;
                    groupMap[row][i] = currentGroup;
                }
            }
        }

        return groupMap;
    }

    protected abstract T[][] createMap();

    protected abstract int getGroupId(ChunkReferenceModel chunkReference);

    protected abstract T getDefaultGroup(int groupId);

    private T addGroup()
    {
        T group = createGroup();
        groupBuilders.add(group);

        return group;
    }

    protected abstract T createGroup();

    protected void associateObjectGroupsBasedOnScreenSpace(T[][] groupMap)
    {
        int screenHorizontalChunks = (screenWidth + 255) >> 7;
        int screenVerticalChunks = (screenHeight + 255) >> 7;

        for (int rowIndex = 0; rowIndex < groupMap.length - screenVerticalChunks; rowIndex++)
        {
            T[] row = groupMap[rowIndex];
            for (int columnIndex = 0; columnIndex < row.length - screenHorizontalChunks; columnIndex++)
            {
                Set<T> groupsInView = new HashSet<>();
                for (int screenRow = 0; screenRow < screenVerticalChunks; screenRow++)
                {
                    for (int screenColumn = 0; screenColumn < screenHorizontalChunks; screenColumn++)
                    {
                        T objectGroupBuilder = groupMap[rowIndex + screenRow][columnIndex + screenColumn];
                        if (!objectGroupBuilder.isZeroGroup())
                        {
                            groupsInView.add(objectGroupBuilder);
                        }
                    }
                }

                Sets.cartesianProduct(groupsInView, groupsInView)
                        .forEach(associatedGroups ->
                                         associatedGroups.get(0).associateGroup(associatedGroups.get(1)));
            }
        }
    }

    protected T[][] mergeGroupMaps(T[][] chunkGroupMap, T[][] overlayChunkGroupMap)
    {
        int width = mapModel.getWidth();
        int height = mapModel.getHeight();

        T[][] mergedMap = createMap();
        for (int row = 0; row < height; row++)
        {
            for (int column = 0; column < width; column++)
            {
                if (overlayChunkGroupMap[row][column].isZeroGroup())
                {
                    mergedMap[row][column] = chunkGroupMap[row][column];
                }
                else
                {
                    mergedMap[row][column] = overlayChunkGroupMap[row][column];
                }
            }
        }

        return mergedMap;
    }

    public Set<T> getGroupBuilders()
    {
        return groupBuilders;
    }
}

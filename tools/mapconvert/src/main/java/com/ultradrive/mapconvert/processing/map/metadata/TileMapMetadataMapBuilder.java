package com.ultradrive.mapconvert.processing.map.metadata;

import com.google.common.collect.ImmutableList;
import com.google.common.collect.Sets;
import com.ultradrive.mapconvert.datasource.model.ChunkReferenceModel;
import com.ultradrive.mapconvert.datasource.model.MapModel;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import static java.util.stream.Collectors.toMap;


class TileMapMetadataMapBuilder
{
    private final MapModel mapModel;
    private final int objectGroupMapWidth;
    private final int objectGroupMapHeight;
    private final int screenWidth;
    private final int screenHeight;

    private final ObjectGroupBuilder[][] chunkObjectGroupBuilderMap;
    private final Set<ObjectGroupBuilder> objectGroupBuilders;
    private final List<TileMapMetadataContainerBuilder> metadataContainerBuilders;

    public TileMapMetadataMapBuilder(MapModel mapModel, int screenWidth, int screenHeight)
    {
        this.mapModel = mapModel;
        this.objectGroupMapWidth = ((mapModel.getWidth() + 7) >> 3);
        this.objectGroupMapHeight = ((mapModel.getHeight() + 7) >> 3);
        this.screenWidth = screenWidth;
        this.screenHeight = screenHeight;

        this.chunkObjectGroupBuilderMap = new ObjectGroupBuilder[mapModel.getHeight()][mapModel.getWidth()];
        this.objectGroupBuilders = new LinkedHashSet<>();
        this.metadataContainerBuilders = new ArrayList<>();
    }

    public TileMapMetadataMap build()
    {
        createGroupMap();

        addObjects();

        createMetadataContainers();

        linkObjectGroupsBasedOnScreenSpace();

        createGroupFlags();

        return createObjectGroupMap();
    }

    private void createGroupMap()
    {
        int width = mapModel.getWidth();
        int height = mapModel.getHeight();

        int[][] sourceGroupIds = new int[height][width];
        for (int row = 0; row < height; row++)
        {
            for (int column = 0; column < width; column++)
            {
                int startGroupId = mapModel.getChunkReference(row, column).getObjectGroupId();
                ObjectGroupBuilder currentGroup = startGroupId == ChunkReferenceModel.EMPTY_GROUP_ID
                                                  ? ObjectGroupBuilder.ZERO
                                                  : null;

                if (row > 0 && sourceGroupIds[row - 1][column] == startGroupId)
                {
                    currentGroup = chunkObjectGroupBuilderMap[row - 1][column];
                }

                int startColumn = column;
                for (int i = column + 1; i < width; i++, column++)
                {
                    int currentGroupId = mapModel.getChunkReference(row, i).getObjectGroupId();
                    if (startGroupId != currentGroupId)
                    {
                        break;
                    }

                    if (row > 0 && currentGroup == null && sourceGroupIds[row - 1][i] == currentGroupId)
                    {
                        currentGroup = chunkObjectGroupBuilderMap[row - 1][i];
                    }
                }

                if (currentGroup == null)
                {
                    currentGroup = addGroup();
                }

                for (int i = startColumn; i <= column; i++)
                {
                    sourceGroupIds[row][i] = startGroupId;
                    chunkObjectGroupBuilderMap[row][i] = currentGroup;
                }
            }
        }
    }

    private void addObjects()
    {
        mapModel.getObjects()
                .forEach(mapObject ->
                         {
                             int row = mapObject.getY() >> 7;
                             int column = mapObject.getX() >> 7;

                             chunkObjectGroupBuilderMap[row][column].add(mapObject);
                         });
    }

    private void createMetadataContainers()
    {
        Map<Integer, TileMapMetadataContainerBuilder> containers = new LinkedHashMap<>();
        for (int rowIndex = 0; rowIndex < chunkObjectGroupBuilderMap.length; rowIndex++)
        {
            ObjectGroupBuilder[] row = chunkObjectGroupBuilderMap[rowIndex];
            for (int columnIndex = 0; columnIndex < row.length; columnIndex++)
            {
                int groupId = (rowIndex >> 3) * objectGroupMapWidth + (columnIndex >> 3);

                TileMapMetadataContainerBuilder metadataContainerBuilder =
                        containers.computeIfAbsent(groupId, id -> new TileMapMetadataContainerBuilder());

                ObjectGroupBuilder objectGroupBuilder = row[columnIndex];
                if (!objectGroupBuilder.isZeroGroup())
                {
                    metadataContainerBuilder.add(objectGroupBuilder);
                }
            }
        }

        metadataContainerBuilders.addAll(containers.values());
    }

    private void linkObjectGroupsBasedOnScreenSpace()
    {
        int screenHorizontalChunks = (screenWidth + 255) >> 7;
        int screenVerticalChunks = (screenHeight + 255) >> 7;

        for (int rowIndex = 0; rowIndex < chunkObjectGroupBuilderMap.length - screenVerticalChunks; rowIndex++)
        {
            ObjectGroupBuilder[] row = chunkObjectGroupBuilderMap[rowIndex];
            for (int columnIndex = 0; columnIndex < row.length - screenHorizontalChunks; columnIndex++)
            {
                Set<ObjectGroupBuilder> groupsInView = new HashSet<>();
                for (int screenRow = 0; screenRow < screenVerticalChunks; screenRow++)
                {
                    for (int screenColumn = 0; screenColumn < screenHorizontalChunks; screenColumn++)
                    {
                        ObjectGroupBuilder
                                objectGroupBuilder =
                                chunkObjectGroupBuilderMap[rowIndex + screenRow][columnIndex + screenColumn];
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

    private void createGroupFlags()
    {
        objectGroupBuilders.stream()
                .sorted(Comparator.comparingLong(ObjectGroupBuilder::priority).reversed())
                .forEach(ObjectGroupBuilder::calculateFlag);
    }

    private TileMapMetadataMap createObjectGroupMap()
    {
        List<Integer> chunkLocalObjectGroupContainerIndices = new ArrayList<>();
        for (int rowIndex = 0; rowIndex < chunkObjectGroupBuilderMap.length; rowIndex++)
        {
            ObjectGroupBuilder[] row = chunkObjectGroupBuilderMap[rowIndex];
            int rowLength = row.length;
            for (int columnIndex = 0; columnIndex < rowLength; columnIndex++)
            {
                int containerPosition = (rowIndex >> 3) * objectGroupMapWidth + (columnIndex >> 3);

                int groupIndex = metadataContainerBuilders.get(containerPosition)
                        .getGroupIndex(chunkObjectGroupBuilderMap[rowIndex][columnIndex]);

                chunkLocalObjectGroupContainerIndices.add(groupIndex);
            }
        }

        Map<Integer, ObjectGroup> objectGroupsById = objectGroupBuilders.stream()
                .map(ObjectGroupBuilder::build)
                .collect(toMap(ObjectGroup::getId, objectGroup -> objectGroup));

        return new TileMapMetadataMap(metadataContainerBuilders.stream()
                                          .map(metadataContainerBuilder ->
                                                       metadataContainerBuilder.build(objectGroupsById))
                                          .collect(Collectors.toList()),
                                      ImmutableList.copyOf(objectGroupsById.values()),
                                      chunkLocalObjectGroupContainerIndices,
                                      mapModel.getWidth(),
                                      objectGroupMapWidth, objectGroupMapHeight);
    }

    public ObjectGroupBuilder addGroup()
    {
        ObjectGroupBuilder group = new ObjectGroupBuilder();
        objectGroupBuilders.add(group);

        return group;
    }
}

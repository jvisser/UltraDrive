package com.ultradrive.mapconvert.processing.map;

import com.google.common.collect.ImmutableList;
import com.google.common.collect.Sets;
import com.ultradrive.mapconvert.datasource.model.ChunkReferenceModel;
import com.ultradrive.mapconvert.datasource.model.MapLayer;
import com.ultradrive.mapconvert.datasource.model.MapModel;
import com.ultradrive.mapconvert.datasource.model.MapObject;
import com.ultradrive.mapconvert.processing.map.metadata.ObjectGroup;
import com.ultradrive.mapconvert.processing.map.metadata.TileMapMetadataMap;
import com.ultradrive.mapconvert.processing.map.metadata.TileMapOverlay;
import com.ultradrive.mapconvert.processing.tileset.Tileset;
import com.ultradrive.mapconvert.processing.tileset.TilesetReferenceBuilderSource;
import com.ultradrive.mapconvert.processing.tileset.chunk.ChunkReference;
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


class TileMapBuilder
{
    private final MapModel mapModel;
    private final List<TileMapMetadataContainerBuilder> metadataContainerBuilders;
    private final Set<ObjectGroupBuilder> objectGroupBuilders;
    private final int objectGroupMapHeight;
    private final int objectGroupMapWidth;
    private final int screenHeight;
    private final int screenWidth;
    private final TilesetReferenceBuilderSource tilesetReferenceBuilder;

    List<ChunkReference> chunkReferences;
    TileMapMetadataMap mapMetadata;

    public TileMapBuilder(MapModel mapModel,
                          TilesetReferenceBuilderSource tilesetReferenceBuilder,
                          int screenWidth, int screenHeight)
    {
        this.mapModel = mapModel;
        this.objectGroupMapWidth = ((mapModel.getWidth() + 7) >> 3);
        this.objectGroupMapHeight = ((mapModel.getHeight() + 7) >> 3);
        this.tilesetReferenceBuilder = tilesetReferenceBuilder;
        this.screenWidth = screenWidth;
        this.screenHeight = screenHeight;

        this.objectGroupBuilders = new LinkedHashSet<>();
        this.metadataContainerBuilders = new ArrayList<>();
    }

    public void preCompile()
    {
        MapLayer baseLayer = mapModel.getBaseLayer();
        MapLayer overlayLayer = mapModel.getOverlayLayer();

        ObjectGroupBuilder[][] groupMap = createGroupMap(baseLayer);
        ObjectGroupBuilder[][] overlayGroupMap = createGroupMap(overlayLayer);

        addObjects(baseLayer.getObjects(), groupMap);
        addObjects(overlayLayer.getObjects(), overlayGroupMap);

        createMetadataContainers(groupMap, overlayGroupMap);

        linkObjectGroupsBasedOnScreenSpace(groupMap);
        linkObjectGroupsBasedOnScreenSpace(mergeGroupMaps(groupMap, overlayGroupMap));

        createObjectGroupFlags();

        boolean[][] overlayStatus = createOverlays(overlayLayer, overlayGroupMap);

        mapMetadata = createMapMetadata();
        chunkReferences = collectionChunkReferences(baseLayer, groupMap, overlayStatus);
    }

    public TileMap build(Tileset tileset)
    {
        return new TileMap(tileset,
                           chunkReferences,
                           mapMetadata,
                           mapModel.getName(),
                           mapModel.getWidth(),
                           mapModel.getHeight(),
                           mapModel.getProperties());
    }

    private ObjectGroupBuilder[][] createGroupMap(MapLayer mapLayer)
    {
        int width = mapModel.getWidth();
        int height = mapModel.getHeight();

        ObjectGroupBuilder[][] groupMap = new ObjectGroupBuilder[height][width];

        int[][] sourceGroupIds = new int[height][width];
        for (int row = 0; row < height; row++)
        {
            for (int column = 0; column < width; column++)
            {
                int startGroupId = mapLayer.getChunkReference(row, column).getObjectGroupId();
                ObjectGroupBuilder currentGroup = startGroupId == ChunkReferenceModel.EMPTY_GROUP_ID
                                                  ? ObjectGroupBuilder.ZERO
                                                  : null;

                if (row > 0 && sourceGroupIds[row - 1][column] == startGroupId)
                {
                    currentGroup = groupMap[row - 1][column];
                }

                int startColumn = column;
                for (int i = column + 1; i < width; i++, column++)
                {
                    int currentGroupId = mapLayer.getChunkReference(row, i).getObjectGroupId();
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

    private void addObjects(List<MapObject> objects, ObjectGroupBuilder[][] objectGroupBuilderMap)
    {
        objects.forEach(mapObject ->
                        {
                            int row = mapObject.getY() >> 7;
                            int column = mapObject.getX() >> 7;

                            objectGroupBuilderMap[row][column].add(mapObject);
                        });
    }

    private void createMetadataContainers(ObjectGroupBuilder[][] groupMap,
                                          ObjectGroupBuilder[][] overlayGroupMap)
    {
        Map<Integer, Map<String, Object>> containerProperties = mapModel.getMetadataObjects().stream()
                .collect(toMap(mapObject -> (mapObject.getY() >> 10) * objectGroupMapWidth + (mapObject.getX() >> 10),
                               MapObject::getProperties));

        Map<Integer, TileMapMetadataContainerBuilder> containers = new LinkedHashMap<>();
        for (int rowIndex = 0; rowIndex < groupMap.length; rowIndex++)
        {
            ObjectGroupBuilder[] row = groupMap[rowIndex];
            ObjectGroupBuilder[] overlayRow = overlayGroupMap[rowIndex];
            for (int columnIndex = 0; columnIndex < row.length; columnIndex++)
            {
                int groupId = (rowIndex >> 3) * objectGroupMapWidth + (columnIndex >> 3);

                TileMapMetadataContainerBuilder metadataContainerBuilder =
                        containers.computeIfAbsent(groupId, id ->
                                new TileMapMetadataContainerBuilder(
                                        containerProperties.computeIfAbsent(groupId, key -> Map.of())));

                ObjectGroupBuilder objectGroupBuilder = row[columnIndex];
                if (!objectGroupBuilder.isZeroGroup())
                {
                    metadataContainerBuilder.add(objectGroupBuilder);
                }

                ObjectGroupBuilder overlayObjectGroupBuilder = overlayRow[columnIndex];
                if (!overlayObjectGroupBuilder.isZeroGroup())
                {
                    metadataContainerBuilder.add(overlayObjectGroupBuilder);
                }
            }
        }

        metadataContainerBuilders.addAll(containers.values());
    }

    private void linkObjectGroupsBasedOnScreenSpace(ObjectGroupBuilder[][] groupMap)
    {
        int screenHorizontalChunks = (screenWidth + 255) >> 7;
        int screenVerticalChunks = (screenHeight + 255) >> 7;

        for (int rowIndex = 0; rowIndex < groupMap.length - screenVerticalChunks; rowIndex++)
        {
            ObjectGroupBuilder[] row = groupMap[rowIndex];
            for (int columnIndex = 0; columnIndex < row.length - screenHorizontalChunks; columnIndex++)
            {
                Set<ObjectGroupBuilder> groupsInView = new HashSet<>();
                for (int screenRow = 0; screenRow < screenVerticalChunks; screenRow++)
                {
                    for (int screenColumn = 0; screenColumn < screenHorizontalChunks; screenColumn++)
                    {
                        ObjectGroupBuilder
                                objectGroupBuilder =
                                groupMap[rowIndex + screenRow][columnIndex + screenColumn];
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

    private ObjectGroupBuilder[][] mergeGroupMaps(ObjectGroupBuilder[][] chunkGroupMap,
                                                  ObjectGroupBuilder[][] overlayChunkGroupMap)
    {
        int width = mapModel.getWidth();
        int height = mapModel.getHeight();

        ObjectGroupBuilder[][] mergedMap = new ObjectGroupBuilder[height][width];
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

    private void createObjectGroupFlags()
    {
        objectGroupBuilders.stream()
                .sorted(Comparator.comparingLong(ObjectGroupBuilder::priority).reversed())
                .forEach(ObjectGroupBuilder::calculateFlag);
    }

    private boolean[][] createOverlays(MapLayer overlayLayer, ObjectGroupBuilder[][] overlayGroupMap)
    {
        boolean[][] overlayStatus = new boolean[mapModel.getHeight()][mapModel.getWidth()];

        for (int row = 0; row < objectGroupMapHeight; row++)
        {
            for (int column = 0; column < objectGroupMapWidth; column++)
            {
                TileMapMetadataContainerBuilder containerBuilder =
                        metadataContainerBuilders.get(row * objectGroupMapWidth + column);

                int containerWidth = Math.min(mapModel.getWidth() - (column * 8), 8);
                int containerHeight = Math.min(mapModel.getHeight() - (row * 8), 8);

                ChunkReference[][] overlayReferences = new ChunkReference[containerHeight][containerWidth];

                for (int y = 0, yy = row * 8; y < containerHeight; y++, yy++)
                {
                    for (int x = 0, xx = column * 8; x < containerWidth; x++, xx++)
                    {
                        ChunkReferenceModel chunkReferenceModel = overlayLayer.getChunkReference(yy, xx);

                        ChunkReference.Builder chunkReferenceBuilder =
                                tilesetReferenceBuilder.getTileReference(chunkReferenceModel.getChunkId());

                        ObjectGroupBuilder objectGroupBuilder = overlayGroupMap[yy][xx];
                        if (!objectGroupBuilder.isZeroGroup())
                        {
                            chunkReferenceBuilder.setObjectContainerGroupIndex(
                                    containerBuilder.getGroupIndex(objectGroupBuilder));
                        }
                        chunkReferenceBuilder.reorient(chunkReferenceModel.getOrientation());

                        ChunkReference chunkReference = chunkReferenceBuilder.build();
                        overlayReferences[y][x] = chunkReference;
                        overlayStatus[yy][xx] = chunkReference.hasAnyInformation();
                    }
                }

                containerBuilder.setOverlay(TileMapOverlay.create(overlayReferences, containerWidth, containerHeight));
            }
        }

        return overlayStatus;
    }

    private List<ChunkReference> collectionChunkReferences(MapLayer mapLayer,
                                                           ObjectGroupBuilder[][] groupMap,
                                                           boolean[][] overlayStatus)
    {
        List<ChunkReference> references = new ArrayList<>();

        for (int rowIndex = 0; rowIndex < groupMap.length; rowIndex++)
        {
            ObjectGroupBuilder[] row = groupMap[rowIndex];
            for (int columnIndex = 0; columnIndex < row.length; columnIndex++)
            {
                int containerPosition = (rowIndex >> 3) * objectGroupMapWidth + (columnIndex >> 3);

                int groupIndex = metadataContainerBuilders.get(containerPosition)
                        .getGroupIndex(groupMap[rowIndex][columnIndex]);

                ChunkReferenceModel chunkReferenceModel = mapLayer.getChunkReference(rowIndex, columnIndex);

                ChunkReference.Builder chunkReferenceBuilder =
                        tilesetReferenceBuilder.getTileReference(chunkReferenceModel.getChunkId());
                chunkReferenceBuilder.setObjectContainerGroupIndex(groupIndex);
                chunkReferenceBuilder.setHasOverlay(overlayStatus[rowIndex][columnIndex]);
                chunkReferenceBuilder.reorient(chunkReferenceModel.getOrientation());
                references.add(chunkReferenceBuilder.build());
            }
        }

        return references;
    }

    private TileMapMetadataMap createMapMetadata()
    {
        Map<Integer, ObjectGroup> objectGroupsById = objectGroupBuilders.stream()
                .map(ObjectGroupBuilder::build)
                .collect(toMap(ObjectGroup::getId, objectGroup -> objectGroup));

        return new TileMapMetadataMap(metadataContainerBuilders.stream()
                                              .map(metadataContainerBuilder ->
                                                           metadataContainerBuilder.build(objectGroupsById))
                                              .collect(Collectors.toList()),
                                      ImmutableList.copyOf(objectGroupsById.values()),
                                      objectGroupMapWidth, objectGroupMapHeight);
    }

    public ObjectGroupBuilder addGroup()
    {
        ObjectGroupBuilder group = new ObjectGroupBuilder();
        objectGroupBuilders.add(group);

        return group;
    }
}

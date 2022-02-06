package com.ultradrive.mapconvert.processing.map;

import com.ultradrive.mapconvert.datasource.model.ChunkReferenceModel;
import com.ultradrive.mapconvert.datasource.model.MapLayer;
import com.ultradrive.mapconvert.datasource.model.MapModel;
import com.ultradrive.mapconvert.datasource.model.MapObject;
import com.ultradrive.mapconvert.processing.map.metadata.TileMapMetadataMap;
import com.ultradrive.mapconvert.processing.map.metadata.TileMapOverlay;
import com.ultradrive.mapconvert.processing.tileset.Tileset;
import com.ultradrive.mapconvert.processing.tileset.TilesetReferenceBuilderSource;
import com.ultradrive.mapconvert.processing.tileset.chunk.ChunkReference;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import static java.util.stream.Collectors.toMap;


class TileMapBuilder extends GroupLayerBuilder<TileMapObjectGroupBuilder>
{
    private final List<TileMapMetadataContainerBuilder> metadataContainerBuilders;
    private final int objectGroupMapHeight;
    private final int objectGroupMapWidth;
    private final TilesetReferenceBuilderSource tilesetReferenceBuilder;

    private int maxGroupsInView;
    private int maxNodesInView;
    private TileMapMetadataMap mapMetadata;
    private List<ChunkReference> chunkReferences;

    public TileMapBuilder(MapModel mapModel,
                          TilesetReferenceBuilderSource tilesetReferenceBuilder,
                          int screenWidth, int screenHeight)
    {
        super(mapModel, screenWidth, screenHeight);

        this.objectGroupMapWidth = ((mapModel.getWidth() + 7) >> 3);
        this.objectGroupMapHeight = ((mapModel.getHeight() + 7) >> 3);
        this.tilesetReferenceBuilder = tilesetReferenceBuilder;
        this.metadataContainerBuilders = new ArrayList<>();
    }

    @Override
    protected int getGroupId(ChunkReferenceModel chunkReference)
    {
        return chunkReference.getObjectGroupId();
    }

    @Override
    protected TileMapObjectGroupBuilder getDefaultGroup(int groupId)
    {
        return groupId == ChunkReferenceModel.EMPTY_GROUP_ID
               ? TileMapObjectGroupBuilder.ZERO
               : null;
    }

    @Override
    protected TileMapObjectGroupBuilder[][] createMap()
    {
        return new TileMapObjectGroupBuilder[mapModel.getHeight()][mapModel.getWidth()];
    }

    @Override
    protected TileMapObjectGroupBuilder createGroup()
    {
        return new TileMapObjectGroupBuilder();
    }

    public void preCompile()
    {
        TileMapObjectGroupContainerLayerBuilder containerLayerBuilder =
                new TileMapObjectGroupContainerLayerBuilder(mapModel, screenWidth, screenHeight);
        containerLayerBuilder.compile();

        MapLayer baseLayer = mapModel.getBaseLayer();
        MapLayer overlayLayer = mapModel.getOverlayLayer();

        TileMapObjectGroupBuilder[][] groupMap = createGroupMap(baseLayer);
        TileMapObjectGroupBuilder[][] overlayGroupMap = createGroupMap(overlayLayer);

        setGroupContainers(groupMap, containerLayerBuilder.getBaseContainers());
        setGroupContainers(overlayGroupMap, containerLayerBuilder.getOverlayContainers());

        addObjects(baseLayer.getObjects(), groupMap);
        addObjects(overlayLayer.getObjects(), overlayGroupMap);

        createMetadataContainers(groupMap, overlayGroupMap);

        associateObjectGroupsBasedOnScreenSpace(groupMap);
        associateObjectGroupsBasedOnScreenSpace(mergeGroupMaps(groupMap, overlayGroupMap));

        calculateMaxima(groupMap, overlayGroupMap);

        createObjectGroupFlags();

        boolean[][] overlayStatus = createOverlays(overlayLayer, overlayGroupMap);

        mapMetadata = createMapMetadata(containerLayerBuilder);
        chunkReferences = collectChunkReferences(baseLayer, groupMap, overlayStatus);
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

    private void setGroupContainers(TileMapObjectGroupBuilder[][] groupMap,
                                    GroupSubLayer<TileMapObjectGroupContainerBuilder> containerLayer)
    {
        for (int row = 0; row < mapModel.getHeight(); row++)
        {
            for (int column = 0; column < mapModel.getWidth(); column++)
            {
                TileMapObjectGroupBuilder groupBuilder = groupMap[row][column];
                if (!groupBuilder.isZeroGroup())
                {
                    groupBuilder.setContainer(containerLayer.get(row, column));
                }
            }
        }
    }

    private void calculateMaxima(TileMapObjectGroupBuilder[][] groupMap,
                                 TileMapObjectGroupBuilder[][] overlayGroupMap)
    {
        maxGroupsInView = 0;
        maxNodesInView = 0;

        calculateMaxima(groupMap);
        calculateMaxima(mergeGroupMaps(groupMap, overlayGroupMap));
    }

    private void calculateMaxima(TileMapObjectGroupBuilder[][] groupMap)
    {
        int screenHorizontalChunks = (screenWidth + 255) >> 7;
        int screenVerticalChunks = (screenHeight + 255) >> 7;

        for (int rowIndex = 0; rowIndex < groupMap.length - screenVerticalChunks; rowIndex++)
        {
            TileMapObjectGroupBuilder[] row = groupMap[rowIndex];
            for (int columnIndex = 0; columnIndex < row.length - screenHorizontalChunks; columnIndex++)
            {
                Set<TileMapObjectGroupBuilder> groupsInView = new HashSet<>();
                for (int screenRow = 0; screenRow < screenVerticalChunks; screenRow++)
                {
                    for (int screenColumn = 0; screenColumn < screenHorizontalChunks; screenColumn++)
                    {
                        TileMapObjectGroupBuilder objectGroupBuilder = groupMap[rowIndex + screenRow][columnIndex + screenColumn];
                        if (!objectGroupBuilder.isZeroGroup())
                        {
                            groupsInView.add(objectGroupBuilder);
                        }
                    }
                }

                Set<Object> nodesInView = new HashSet<>(groupsInView);
                for (TileMapObjectGroupBuilder groupBuilder : groupsInView)
                {
                    TileMapObjectGroupContainerBuilder parent = groupBuilder.getContainer();
                    while (parent != null)
                    {
                        nodesInView.add(parent);
                        parent = parent.getParent();
                    }
                }
                maxGroupsInView = Math.max(maxGroupsInView, groupsInView.size());
                maxNodesInView = Math.max(maxNodesInView, nodesInView.size());
            }
        }
    }

    private void addObjects(List<MapObject> objects, TileMapObjectGroupBuilder[][] objectGroupBuilderMap)
    {
        objects.forEach(mapObject ->
                        {
                            int row = mapObject.getY() >> 7;
                            int column = mapObject.getX() >> 7;

                            objectGroupBuilderMap[row][column].add(mapObject);
                        });
    }

    private void createMetadataContainers(TileMapObjectGroupBuilder[][] groupMap,
                                          TileMapObjectGroupBuilder[][] overlayGroupMap)
    {
        Map<Integer, Map<String, Object>> containerProperties = mapModel.getMetadataObjects().stream()
                .collect(toMap(mapObject -> (mapObject.getY() >> 10) * objectGroupMapWidth + (mapObject.getX() >> 10),
                               MapObject::getProperties));

        Map<Integer, TileMapMetadataContainerBuilder> containers = new LinkedHashMap<>();
        for (int rowIndex = 0; rowIndex < groupMap.length; rowIndex++)
        {
            TileMapObjectGroupBuilder[] row = groupMap[rowIndex];
            TileMapObjectGroupBuilder[] overlayRow = overlayGroupMap[rowIndex];
            for (int columnIndex = 0; columnIndex < row.length; columnIndex++)
            {
                int groupId = (rowIndex >> 3) * objectGroupMapWidth + (columnIndex >> 3);

                TileMapMetadataContainerBuilder metadataContainerBuilder =
                        containers.computeIfAbsent(groupId, id ->
                                new TileMapMetadataContainerBuilder(
                                        containerProperties.computeIfAbsent(groupId, key -> Map.of())));

                TileMapObjectGroupBuilder objectGroupBuilder = row[columnIndex];
                if (!objectGroupBuilder.isZeroGroup())
                {
                    metadataContainerBuilder.add(objectGroupBuilder);
                }

                TileMapObjectGroupBuilder overlayObjectGroupBuilder = overlayRow[columnIndex];
                if (!overlayObjectGroupBuilder.isZeroGroup())
                {
                    metadataContainerBuilder.add(overlayObjectGroupBuilder);
                }
            }
        }

        metadataContainerBuilders.addAll(containers.values());
    }

    private boolean[][] createOverlays(MapLayer overlayLayer, TileMapObjectGroupBuilder[][] overlayGroupMap)
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

                        TileMapObjectGroupBuilder objectGroupBuilder = overlayGroupMap[yy][xx];
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

    private TileMapMetadataMap createMapMetadata(
            TileMapObjectGroupContainerLayerBuilder containerLayerBuilder)
    {
        return new TileMapMetadataMap(
                metadataContainerBuilders.stream()
                        .map(TileMapMetadataContainerBuilder::build)
                        .collect(Collectors.toList()),
                containerLayerBuilder.getGroupBuilders().stream().map(TileMapObjectGroupContainerBuilder::build)
                        .collect(Collectors.toList()),
                groupBuilders.stream().map(TileMapObjectGroupBuilder::build)
                        .collect(Collectors.toList()),
                objectGroupMapWidth, objectGroupMapHeight,
                maxGroupsInView, maxNodesInView);
    }

    private List<ChunkReference> collectChunkReferences(MapLayer mapLayer,
                                                        TileMapObjectGroupBuilder[][] groupMap,
                                                        boolean[][] overlayStatus)
    {
        List<ChunkReference> references = new ArrayList<>();

        for (int rowIndex = 0; rowIndex < groupMap.length; rowIndex++)
        {
            TileMapObjectGroupBuilder[] row = groupMap[rowIndex];
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
}

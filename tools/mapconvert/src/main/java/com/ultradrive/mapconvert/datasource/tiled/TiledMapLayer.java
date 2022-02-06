package com.ultradrive.mapconvert.datasource.tiled;

import com.google.common.base.Joiner;
import com.ultradrive.mapconvert.common.orientable.Orientation;
import com.ultradrive.mapconvert.datasource.model.ChunkReferenceModel;
import com.ultradrive.mapconvert.datasource.model.MapLayer;
import com.ultradrive.mapconvert.datasource.model.MapObject;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;
import org.tiledreader.TiledTile;
import org.tiledreader.TiledTileLayer;


class TiledMapLayer implements MapLayer
{
    private static final String CHUNK_LAYER_NAME = "Chunk";
    private static final String OBJECT_GROUP_LAYER_NAME = "Blueprint.Room";
    private static final String OBJECT_GROUP_CONTAINER_LAYER_NAME = "Blueprint.Building";
    private static final String OBJECT_LAYER_NAME = "Object";

    private final TiledMapDataSource mapDataSource;
    private final String baseLayerName;

    TiledMapLayer(TiledMapDataSource mapDataSource, String baseLayerName)
    {
        this.mapDataSource = mapDataSource;
        this.baseLayerName = baseLayerName;
    }

    @Override
    public ChunkReferenceModel getChunkReference(int row, int column)
    {
        int objectGroupContainerId = getTileId(OBJECT_GROUP_CONTAINER_LAYER_NAME, row, column);
        int objectGroupId = getTileId(OBJECT_GROUP_LAYER_NAME, row, column);

        Optional<TiledTileLayer> chunkLayerOptional = mapDataSource.getLayerOptional(fullName(CHUNK_LAYER_NAME));
        if (chunkLayerOptional.isEmpty())
        {
            return ChunkReferenceModel.empty(objectGroupContainerId, objectGroupId);
        }

        TiledTileLayer chunkLayer = chunkLayerOptional.get();

        TiledTile chunkTile = chunkLayer.getTile(column, row);
        if (chunkTile == null)
        {
            return ChunkReferenceModel.empty(objectGroupContainerId, objectGroupId);
        }

        return new ChunkReferenceModel(
                chunkTile.getID(),
                objectGroupContainerId,
                objectGroupId,
                Orientation.get(
                        chunkLayer.getTileHorizontalFlip(column, row),
                        chunkLayer.getTileVerticalFlip(column, row)));
    }

    private Integer getTileId(String layerName, int row, int column)
    {
        return mapDataSource.getLayerOptional(fullName(layerName))
                .map(objectGroupLayer ->
                             Optional.ofNullable(objectGroupLayer.getTile(column, row))
                                     .map(TiledTile::getID)
                                     .orElse(0))
                .orElse(0);
    }

    private String fullName(String layerName)
    {
        return Joiner.on(".").join(baseLayerName, layerName);
    }

    @Override
    public List<MapObject> getObjects()
    {
        return mapDataSource.getObjectStream(fullName(OBJECT_LAYER_NAME))
                .map(TiledMapObject::new)
                .collect(Collectors.toList());
    }

    @Override
    public int getWidth()
    {
        return mapDataSource.getWidth();
    }

    @Override
    public int getHeight()
    {
        return mapDataSource.getHeight();
    }
}

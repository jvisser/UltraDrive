package com.ultradrive.mapconvert.datasource.tiled;

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
    private final TiledMapDataSource mapDataSource;
    private final String chunkLayerName ;
    private final String objectGroupLayerName;
    private final String objectLayerName;

    TiledMapLayer(TiledMapDataSource mapDataSource,
                  String chunkLayerName,
                  String objectGroupLayerName,
                  String objectLayerName)
    {
        this.mapDataSource = mapDataSource;
        this.chunkLayerName = chunkLayerName;
        this.objectGroupLayerName = objectGroupLayerName;
        this.objectLayerName = objectLayerName;
    }

    @Override
    public ChunkReferenceModel getChunkReference(int row, int column)
    {
        int objectGroupId = mapDataSource.getLayerOptional(objectGroupLayerName)
                .map(objectGroupLayer ->
                             Optional.ofNullable(objectGroupLayer.getTile(column, row))
                                     .map(TiledTile::getID)
                                     .orElse(0))
                .orElse(0);

        Optional<TiledTileLayer> chunkLayerOptional = mapDataSource.getLayerOptional(chunkLayerName);
        if (chunkLayerOptional.isEmpty())
        {
            return ChunkReferenceModel.empty(objectGroupId);
        }

        TiledTileLayer chunkLayer = chunkLayerOptional.get();

        TiledTile chunkTile = chunkLayer.getTile(column, row);
        if (chunkTile == null)
        {
            return ChunkReferenceModel.empty(objectGroupId);
        }

        return new ChunkReferenceModel(
                chunkTile.getID(),
                objectGroupId,
                Orientation.get(
                        chunkLayer.getTileHorizontalFlip(column, row),
                        chunkLayer.getTileVerticalFlip(column, row)));
    }

    @Override
    public List<MapObject> getObjects()
    {
        return mapDataSource.getObjectStream(objectLayerName)
                .map(TiledMapObject::new)
                .collect(Collectors.toList());
    }
}

package com.ultradrive.mapconvert.datasource.tiled;

import com.ultradrive.mapconvert.common.UID;
import com.ultradrive.mapconvert.common.orientable.Orientation;
import com.ultradrive.mapconvert.datasource.MapDataSource;
import com.ultradrive.mapconvert.datasource.TilesetDataSource;
import com.ultradrive.mapconvert.datasource.model.ChunkReferenceModel;
import com.ultradrive.mapconvert.datasource.model.MapObject;
import java.io.File;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;
import org.tiledreader.TiledMap;
import org.tiledreader.TiledObjectLayer;
import org.tiledreader.TiledTile;
import org.tiledreader.TiledTileLayer;
import org.tiledreader.TiledTileset;

import static java.lang.String.format;


class TiledMapDataSource extends AbstractTiledMap implements MapDataSource
{
    private static final String CHUNK_TILESET_NAME = "chunks";

    private static final String CHUNK_LAYER_NAME = "Base_Chunk";
    private static final String OBJECT_GROUP_LAYER_NAME = "Base_ObjectGroup";
    private static final String OBJECT_LAYER_NAME = "Base_Object";

    private final TiledObjectFactory tiledObjectFactory;
    private final TiledPropertyTransformer propertyTransformer;

    TiledMapDataSource(TiledObjectFactory tiledObjectFactory, TiledMap map,
                       TiledPropertyTransformer propertyTransformer)
    {
        super(map);

        this.tiledObjectFactory = tiledObjectFactory;
        this.propertyTransformer = propertyTransformer;
    }

    @Override
    public TilesetDataSource getTilesetDataSource()
    {
        TiledTileset chunkTileset = map.getTilesets().stream().
                filter(tiledTileset -> tiledTileset.getName().equalsIgnoreCase(CHUNK_TILESET_NAME))
                .findAny().orElseThrow(() ->
                                               new IllegalArgumentException(
                                                       format("No chunk tileset found in map '%s'", map.getPath())));

        return tiledObjectFactory.getTilesetDataSource(chunkTileset.getPath());
    }

    @Override
    public String getName()
    {
        File file = new File(map.getPath());
        String name = file.getName();
        return file.getParentFile().getName() + "_" + name.substring(0, name.indexOf('.'));
    }

    @Override
    public int getWidth()
    {
        return map.getWidth();
    }

    @Override
    public int getHeight()
    {
        return map.getHeight();
    }

    @Override
    public ChunkReferenceModel getChunkReference(int row, int column)
    {
        TiledTileLayer chunkLayer = getLayer(CHUNK_LAYER_NAME);
        TiledTile chunkTile = chunkLayer.getTile(column, row);

        int objectGroupId = getLayerOptional(OBJECT_GROUP_LAYER_NAME)
                .map(objectGroupLayer ->
                             Optional.ofNullable(objectGroupLayer.getTile(column, row))
                                     .map(TiledTile::getID)
                                     .orElse(0))
                .orElse(0);

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
        return map.getNonGroupLayers().stream()
                .filter(tiledLayer -> tiledLayer instanceof TiledObjectLayer &&
                                      getFullLayerName(tiledLayer).equalsIgnoreCase(OBJECT_LAYER_NAME))
                .map(TiledObjectLayer.class::cast)
                .flatMap(tiledObjectLayer -> tiledObjectLayer.getObjects().stream())
                .map(tiledObject -> new
                        MapObject(tiledObject.getName(),
                                  UID.create(),
                                  tiledObject.getProperties(),
                                  (int) (tiledObject.getX() + (Integer) tiledObject.getProperty("objectTypeXCompensation")),
                                  (int) (tiledObject.getY() + (Integer) tiledObject.getProperty("objectTypeYCompensation")),
                                  tiledObject.getTileXFlip(), tiledObject.getTileYFlip()))
                .collect(Collectors.toList());
    }

    @Override
    public Map<String, Object> getProperties()
    {
        return propertyTransformer.getProperties(map);
    }
}

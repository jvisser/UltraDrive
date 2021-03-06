package com.ultradrive.mapconvert.datasource.tiled;

import com.ultradrive.mapconvert.common.orientable.Orientation;
import com.ultradrive.mapconvert.datasource.MapDataSource;
import com.ultradrive.mapconvert.datasource.TilesetDataSource;
import com.ultradrive.mapconvert.datasource.model.ChunkReferenceModel;
import java.io.File;
import java.util.Map;
import org.tiledreader.TiledMap;
import org.tiledreader.TiledTile;
import org.tiledreader.TiledTileLayer;
import org.tiledreader.TiledTileset;

import static java.lang.String.format;

class TiledMapDataSource extends AbstractTiledMap implements MapDataSource
{
    private static final String CHUNK_TILESET_NAME = "chunks";

    private static final String CHUNK_LAYER_NAME = "Chunks";

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
                        new IllegalArgumentException(format("No chunk tileset found in map '%s'", map.getPath())));

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
        TiledTileLayer layer = getLayer(CHUNK_LAYER_NAME);
        TiledTile tile = layer.getTile(column, row);

        if (tile == null)
        {
            return ChunkReferenceModel.empty();
        }

        return new ChunkReferenceModel(
                tile.getID(),
                Orientation.get(
                        layer.getTileHorizontalFlip(column, row),
                        layer.getTileVerticalFlip(column, row)));
    }

    @Override
    public Map<String, Object> getProperties()
    {
        return propertyTransformer.getProperties(map);
    }
}

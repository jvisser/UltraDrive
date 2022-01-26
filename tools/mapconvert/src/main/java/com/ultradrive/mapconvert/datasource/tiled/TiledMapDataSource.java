package com.ultradrive.mapconvert.datasource.tiled;

import com.ultradrive.mapconvert.datasource.MapDataSource;
import com.ultradrive.mapconvert.datasource.TilesetDataSource;
import com.ultradrive.mapconvert.datasource.model.MapLayer;
import com.ultradrive.mapconvert.datasource.model.MapObject;
import java.io.File;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.tiledreader.TiledMap;
import org.tiledreader.TiledTileset;

import static java.lang.String.format;


class TiledMapDataSource extends AbstractTiledMap implements MapDataSource
{
    private static final String CHUNK_TILESET_NAME = "chunks";

    private static final String CHUNK_LAYER_NAME = "Base_Chunk";
    private static final String OBJECT_GROUP_LAYER_NAME = "Base_ObjectGroup";
    private static final String OBJECT_LAYER_NAME = "Base_Object";

    private static final String OVERLAY_CHUNK_LAYER_NAME = "Overlay_Chunk";
    private static final String OVERLAY_OBJECT_GROUP_LAYER_NAME = "Overlay_ObjectGroup";
    private static final String OVERLAY_OBJECT_LAYER_NAME = "Overlay_Object";

    private static final String METADATA_LAYER_NAME = "MetadataContainerProperties";

    private final TiledPropertyTransformer propertyTransformer;
    private final TiledObjectFactory tiledObjectFactory;

    TiledMapDataSource(TiledObjectFactory tiledObjectFactory, TiledMap map,
                       TiledPropertyTransformer propertyTransformer)
    {
        super(map);

        this.tiledObjectFactory = tiledObjectFactory;
        this.propertyTransformer = propertyTransformer;
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
    public MapLayer getBaseLayer()
    {
        return new TiledMapLayer(this,
                                 CHUNK_LAYER_NAME,
                                 OBJECT_GROUP_LAYER_NAME,
                                 OBJECT_LAYER_NAME);
    }

    @Override
    public MapLayer getOverlayLayer()
    {
        return new TiledMapLayer(this,
                                 OVERLAY_CHUNK_LAYER_NAME,
                                 OVERLAY_OBJECT_GROUP_LAYER_NAME,
                                 OVERLAY_OBJECT_LAYER_NAME);
    }

    @Override
    public List<MapObject> getMetadataObjects()
    {
        return getObjectStream(METADATA_LAYER_NAME)
                .map(TiledMapObject::new)
                .collect(Collectors.toList());
    }

    @Override
    public Map<String, Object> getProperties()
    {
        return propertyTransformer.getProperties(map);
    }

    @Override
    public TilesetDataSource getTilesetDataSource()
    {
        TiledTileset chunkTileset = map.getTilesets().stream().
                filter(tiledTileset -> tiledTileset.getName().equalsIgnoreCase(CHUNK_TILESET_NAME))
                .findAny().orElseThrow(() -> new IllegalArgumentException(
                        format("No chunk tileset found in map '%s'", map.getPath())));

        return tiledObjectFactory.getTilesetDataSource(chunkTileset.getPath());
    }
}

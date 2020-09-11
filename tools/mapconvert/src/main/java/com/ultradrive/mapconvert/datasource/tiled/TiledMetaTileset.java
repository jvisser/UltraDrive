package com.ultradrive.mapconvert.datasource.tiled;

import com.ultradrive.mapconvert.common.PropertySource;
import java.util.Map;
import java.util.Objects;
import org.tiledreader.TiledMap;
import org.tiledreader.TiledTileset;


abstract class TiledMetaTileset extends AbstractTiledMap implements PropertySource
{
    protected final TiledTileset tileset;
    protected final TiledPropertyTransformer propertyTransformer;

    TiledMetaTileset(TiledTileset tileset, TiledMap map,
                     TiledPropertyTransformer propertyTransformer)
    {
        super(map);
        this.propertyTransformer = propertyTransformer;

        if (tileset.getTileWidth() != tileset.getTileHeight())
        {
            throw new IllegalArgumentException(
                    String.format("Tileset '%s' containst non square tiles (width: %d, height: %d)",
                           tileset.getPath(), tileset.getTileWidth(), tileset.getTileHeight()));
        }

        this.tileset = tileset;
    }

    @Override
    public boolean equals(Object o)
    {
        if (this == o)
        {
            return true;
        }
        if (o == null || getClass() != o.getClass())
        {
            return false;
        }
        final TiledMetaTileset that = (TiledMetaTileset) o;
        return getSourceFileName().equals(that.getSourceFileName());
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(getSourceFileName());
    }

    @Override
    public Map<String, Object> getProperties()
    {
        return propertyTransformer.getProperties(tileset);
    }

    String getSourceFileName()
    {
        return tileset.getPath();
    }
}

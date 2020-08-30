package com.ultradrive.mapconvert.datasource.tiled;

import org.tiledreader.TiledMap;
import org.tiledreader.TiledTileset;

import java.util.Objects;


abstract class TiledMetaTileset extends AbstractTiledMap
{
    protected final TiledTileset tileset;

    TiledMetaTileset(TiledTileset tileset, TiledMap map)
    {
        super(map);

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

    String getSourceFileName()
    {
        return tileset.getPath();
    }
}

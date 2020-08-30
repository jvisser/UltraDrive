package com.ultradrive.mapconvert.datasource.tiled;

import com.ultradrive.mapconvert.common.Orientation;
import com.ultradrive.mapconvert.datasource.model.ResourceReference;
import org.tiledreader.TiledMap;
import org.tiledreader.TiledTile;
import org.tiledreader.TiledTileLayer;
import org.tiledreader.TiledTileset;

import java.util.Objects;

abstract class AbstractTiledMap
{
    protected final TiledMap map;

    protected AbstractTiledMap(TiledMap map)
    {
        this.map = map;
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
        TiledMapDataSource that = (TiledMapDataSource) o;
        return map.getPath().equals(that.map.getPath());
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(map);
    }

    protected TiledTileset getTileset(String tilesetName)
    {
        return map.getTilesets().stream()
                .filter(tiledTileset -> tiledTileset.getName().equals(tilesetName))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException(
                        String.format("Unable to find tileset '%s' in map '%s'", tilesetName, map.getPath())));
    }

    protected TiledTileLayer getLayer(String layerName)
    {
        return (TiledTileLayer) map.getTopLevelLayers().stream()
                .filter(tiledLayer -> tiledLayer.getName().equals(layerName))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException(String.format("Unable to find layer '%s' in map '%s'", layerName, map.getPath())));
    }

    protected ResourceReference getResourceReference(TiledTileLayer layer, int x, int y)
    {
        if (layer.getTileDiagonalFlip(x, y))
        {
            throw new IllegalArgumentException(
                    String.format("Unsupported tile orientation in layer '%s' (diagonal flip) at (%d, %d)",
                            layer.getName(), x, y));
        }

        TiledTile tile = layer.getTile(x, y);
        if (tile == null)
        {
            return ResourceReference.empty();
        }

        boolean horizontalFlip = layer.getTileHorizontalFlip(x, y);
        boolean verticalFlip = layer.getTileVerticalFlip(x, y);

        return new ResourceReference(tile.getID(), Orientation.get(horizontalFlip, verticalFlip));
    }
}

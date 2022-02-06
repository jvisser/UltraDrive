package com.ultradrive.mapconvert.datasource.tiled;

import com.ultradrive.mapconvert.common.orientable.Orientation;
import com.ultradrive.mapconvert.datasource.model.ResourceReference;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Stream;
import org.tiledreader.TiledGroupLayer;
import org.tiledreader.TiledLayer;
import org.tiledreader.TiledMap;
import org.tiledreader.TiledObject;
import org.tiledreader.TiledObjectLayer;
import org.tiledreader.TiledTile;
import org.tiledreader.TiledTileLayer;
import org.tiledreader.TiledTileset;

abstract class AbstractTiledMap
{
    protected final TiledMap map;

    AbstractTiledMap(TiledMap map)
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
        return getTilesetOptional(tilesetName)
                .orElseThrow(() -> new IllegalArgumentException(
                        String.format("Unable to find tileset '%s' in map '%s'", tilesetName, map.getPath())));
    }

    protected Optional<TiledTileset> getTilesetOptional(String tilesetName)
    {
        return map.getTilesets().stream()
                .filter(tiledTileset -> tiledTileset.getName().equalsIgnoreCase(tilesetName))
                .findAny();
    }

    protected TiledTileLayer getLayer(String layerName)
    {
        return getLayerOptional(layerName)
                .orElseThrow(() -> new IllegalArgumentException(String.format("Unable to find layer '%s' in map '%s'", layerName, map.getPath())));
    }

    protected Optional<TiledTileLayer> getLayerOptional(String layerName)
    {
        return map.getNonGroupLayers().stream()
                .filter(TiledTileLayer.class::isInstance) // This seems to be a bug in TiledReader...
                .map(TiledTileLayer.class::cast)
                .filter(tiledLayer -> getFullLayerName(tiledLayer).equalsIgnoreCase(layerName))
                .findAny();
    }

    protected String getFullLayerName(TiledLayer tiledLayer)
    {
        StringBuilder fullLayerName = new StringBuilder();

        TiledGroupLayer parent = tiledLayer.getParent();
        while (parent != null)
        {
            fullLayerName.insert(0, ".");
            fullLayerName.insert(0, parent.getName());

            parent = parent.getParent();
        }
        fullLayerName.append(tiledLayer.getName());

        return fullLayerName.toString();
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

    protected Stream<TiledObject> getObjectStream(String objectLayerName)
    {
        return map.getNonGroupLayers().stream()
                .filter(tiledLayer -> tiledLayer instanceof TiledObjectLayer &&
                                      getFullLayerName(tiledLayer).equalsIgnoreCase(objectLayerName))
                .map(TiledObjectLayer.class::cast)
                .flatMap(tiledObjectLayer -> tiledObjectLayer.getObjects().stream());
    }
}

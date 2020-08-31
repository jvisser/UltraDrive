package com.ultradrive.mapconvert.processing.tileset.common;

import java.util.List;


public class MetaTileset<T extends MetaTile<T, ?, ?>>
{
    private final List<T> tiles;
    private final MetaTileMetrics tileMetrics;

    public MetaTileset(List<T> tiles, MetaTileMetrics tileMetrics)
    {
        this.tiles = tiles;
        this.tileMetrics = tileMetrics;
    }

    public List<T> getTiles()
    {
        return tiles;
    }

    public T getTile(int referenceId)
    {
        return tiles.get(referenceId);
    }

    public MetaTileMetrics getTileMetrics()
    {
        return tileMetrics;
    }

}

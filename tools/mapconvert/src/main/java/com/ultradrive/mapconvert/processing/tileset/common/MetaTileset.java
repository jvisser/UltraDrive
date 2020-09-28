package com.ultradrive.mapconvert.processing.tileset.common;

import java.util.Iterator;
import java.util.List;
import javax.annotation.Nonnull;


public class MetaTileset<T extends MetaTile<T, ?, ?>> implements Iterable<T>
{
    private final List<T> tiles;
    private final MetaTileMetrics tileMetrics;

    public MetaTileset(List<T> tiles, MetaTileMetrics tileMetrics)
    {
        this.tiles = tiles;
        this.tileMetrics = tileMetrics;
    }

    @Override
    @Nonnull
    public Iterator<T> iterator()
    {
        return tiles.iterator();
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

    public int getSize()
    {
        return tiles.size();
    }
}

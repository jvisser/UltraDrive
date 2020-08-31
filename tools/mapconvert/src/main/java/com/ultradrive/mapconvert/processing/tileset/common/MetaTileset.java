package com.ultradrive.mapconvert.processing.tileset.common;

import java.util.List;


public class MetaTileset<T extends MetaTile<T, ?, ?>>
{
    private final List<T> tiles;
    private final MetaTileMetrics blockMetrics;

    public MetaTileset(List<T> tiles, MetaTileMetrics blockMetrics)
    {
        this.tiles = tiles;
        this.blockMetrics = blockMetrics;
    }

    public List<T> getTiles()
    {
        return tiles;
    }

    public T getTile(int referenceId)
    {
        return tiles.get(referenceId);
    }

    public MetaTileMetrics getBlockMetrics()
    {
        return blockMetrics;
    }

}

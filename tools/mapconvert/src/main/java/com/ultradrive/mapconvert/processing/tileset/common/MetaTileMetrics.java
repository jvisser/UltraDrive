package com.ultradrive.mapconvert.processing.tileset.common;

import com.ultradrive.mapconvert.common.Point;

public class MetaTileMetrics
{
    private final int tileSize;
    private final int subTileSize;

    public MetaTileMetrics(int tileSize, int subTileSize)
    {
        this.tileSize = tileSize;
        this.subTileSize = subTileSize;
    }

    public int getTileSize()
    {
        return tileSize;
    }

    public int getSubTileSize()
    {
        return subTileSize;
    }

    public int getTileSizeInSubTiles()
    {
        return tileSize / subTileSize;
    }

    public int getTotalSubTiles()
    {
        int tileSizeInSubTiles = getTileSizeInSubTiles();

        return tileSizeInSubTiles * tileSizeInSubTiles;
    }

    public Point getSubTilePosition(int subTileId)
    {
        int tileSizeInSubTiles = getTileSizeInSubTiles();

        return new Point(subTileId % tileSizeInSubTiles, subTileId / tileSizeInSubTiles);
    }
}

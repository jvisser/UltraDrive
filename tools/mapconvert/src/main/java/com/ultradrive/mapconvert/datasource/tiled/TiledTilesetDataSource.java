package com.ultradrive.mapconvert.datasource.tiled;

import com.ultradrive.mapconvert.datasource.BlockDataSource;
import com.ultradrive.mapconvert.datasource.ChunkDataSource;
import com.ultradrive.mapconvert.datasource.CollisionDataSource;
import com.ultradrive.mapconvert.datasource.TilesetDataSource;
import java.io.File;
import java.util.Map;
import java.util.Objects;


class TiledTilesetDataSource implements TilesetDataSource
{
    private final TiledChunkDataSource chunkSet;
    private final TiledBlockDataSource blockSet;
    private final CollisionDataSource collisionDataSource;

    TiledTilesetDataSource(TiledChunkDataSource chunkSet, TiledBlockDataSource blockSet,
                           CollisionDataSource collisionDataSource)
    {
        this.chunkSet = chunkSet;
        this.blockSet = blockSet;
        this.collisionDataSource = collisionDataSource;
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
        TiledTilesetDataSource that = (TiledTilesetDataSource) o;
        return chunkSet.equals(that.chunkSet) &&
                blockSet.equals(that.blockSet);
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(chunkSet, blockSet);
    }

    @Override
    public String getName()
    {
        return new File(chunkSet.getSourceFileName()).getParentFile().getName();
    }

    @Override
    public CollisionDataSource getCollisionDataSource()
    {
        return collisionDataSource;
    }

    @Override
    public BlockDataSource getBlockDataSource()
    {
        return blockSet;
    }

    @Override
    public ChunkDataSource getChunkDataSource()
    {
        return chunkSet;
    }

    @Override
    public Map<String, Object> getProperties()
    {
        return getChunkDataSource().getProperties();
    }
}

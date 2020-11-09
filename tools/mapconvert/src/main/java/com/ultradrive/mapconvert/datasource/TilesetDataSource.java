package com.ultradrive.mapconvert.datasource;

import com.ultradrive.mapconvert.common.PropertySource;


public interface TilesetDataSource extends PropertySource
{
    String getName();

    CollisionBlockDataSource getCollisionBlockDataSource();

    BlockDataSource getBlockDataSource();

    ChunkDataSource getChunkDataSource();
}

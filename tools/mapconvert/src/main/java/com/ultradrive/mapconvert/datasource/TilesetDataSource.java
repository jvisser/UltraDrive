package com.ultradrive.mapconvert.datasource;

import com.ultradrive.mapconvert.common.PropertySource;


public interface TilesetDataSource extends PropertySource
{
    String getName();

    CollisionDataSource getCollisionDataSource();

    BlockDataSource getBlockDataSource();

    ChunkDataSource getChunkDataSource();
}

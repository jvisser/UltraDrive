package com.ultradrive.mapconvert.datasource;

public interface TilesetDataSource
{
    String getName();

    CollisionDataSource getCollisionDataSource();

    BlockDataSource getBlockDataSource();

    ChunkDataSource getChunkDataSource();
}

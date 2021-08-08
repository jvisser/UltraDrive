package com.ultradrive.mapconvert.datasource.model;

import com.ultradrive.mapconvert.common.orientable.Orientation;


public final class ChunkReferenceModel
{
    public static final int EMPTY_GROUP_ID = 0;

    private final int chunkId;
    private final int objectGroupId;
    private final Orientation orientation;

    public static ChunkReferenceModel empty(int objectGroupId)
    {
        return new ChunkReferenceModel(0, objectGroupId, Orientation.DEFAULT);
    }

    public ChunkReferenceModel(int chunkId, int objectGroupId, Orientation orientation)
    {
        this.chunkId = chunkId;
        this.objectGroupId = objectGroupId;
        this.orientation = orientation;
    }

    public int getChunkId()
    {
        return chunkId;
    }

    public int getObjectGroupId()
    {
        return objectGroupId;
    }

    public Orientation getOrientation()
    {
        return orientation;
    }
}

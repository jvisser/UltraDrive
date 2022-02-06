package com.ultradrive.mapconvert.datasource.model;

import com.ultradrive.mapconvert.common.orientable.Orientation;


public final class ChunkReferenceModel
{
    public static final int EMPTY_GROUP_ID = 0;
    public static final int EMPTY_GROUP_CONTAINER_ID = 0;

    private final int chunkId;
    private final int objectGroupContainerId;
    private final int objectGroupId;
    private final Orientation orientation;

    public static ChunkReferenceModel empty(int objectGroupContainerId, int objectGroupId)
    {
        return new ChunkReferenceModel(0, objectGroupContainerId, objectGroupId, Orientation.DEFAULT);
    }

    public ChunkReferenceModel(int chunkId, int objectGroupContainerId, int objectGroupId, Orientation orientation)
    {
        this.chunkId = chunkId;
        this.objectGroupContainerId = objectGroupContainerId;
        this.objectGroupId = objectGroupId;
        this.orientation = orientation;
    }

    public int getChunkId()
    {
        return chunkId;
    }

    public int getObjectGroupContainerId()
    {
        return objectGroupContainerId;
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

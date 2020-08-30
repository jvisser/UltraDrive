package com.ultradrive.mapconvert.datasource.model;

import com.ultradrive.mapconvert.common.Orientation;

public final class ChunkReferenceModel
{
    private final int chunkId;
    private final Orientation orientation;

    public static ChunkReferenceModel empty()
    {
        return new ChunkReferenceModel(0, Orientation.DEFAULT);
    }

    public ChunkReferenceModel(int chunkId, Orientation orientation)
    {
        this.chunkId = chunkId;
        this.orientation = orientation;
    }

    public int getChunkId()
    {
        return chunkId;
    }

    public Orientation getOrientation()
    {
        return orientation;
    }
}

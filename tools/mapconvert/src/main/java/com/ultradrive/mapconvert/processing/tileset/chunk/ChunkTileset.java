package com.ultradrive.mapconvert.processing.tileset.chunk;

import com.ultradrive.mapconvert.processing.tileset.common.MetaTileMetrics;

import java.util.List;

public class ChunkTileset
{
    private final List<Chunk> chunks;
    private final MetaTileMetrics chunkMetrics;

    public ChunkTileset(List<Chunk> chunks, MetaTileMetrics chunkMetrics)
    {
        this.chunks = chunks;
        this.chunkMetrics = chunkMetrics;
    }

    public List<Chunk> getChunks()
    {
        return chunks;
    }

    public MetaTileMetrics getChunkMetrics()
    {
        return chunkMetrics;
    }

    public Chunk getChunk(int referenceId)
    {
        return chunks.get(referenceId);
    }
}

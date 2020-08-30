package com.ultradrive.mapconvert.processing.tileset.chunk;

import com.ultradrive.mapconvert.common.OrientablePool;


class ChunkPool extends OrientablePool<Chunk, ChunkReference>
{
    @Override
    public ChunkReference.Builder getReference(Chunk orientable)
    {
        return (ChunkReference.Builder) super.getReference(orientable);
    }
}

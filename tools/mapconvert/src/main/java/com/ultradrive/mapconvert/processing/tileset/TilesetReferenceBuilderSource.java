package com.ultradrive.mapconvert.processing.tileset;

import com.ultradrive.mapconvert.processing.tileset.chunk.ChunkReference;

public interface TilesetReferenceBuilderSource
{
    ChunkReference.Builder getTileReference(int tileId);
}

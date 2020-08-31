package com.ultradrive.mapconvert.processing.tileset.chunk;

import com.ultradrive.mapconvert.processing.tileset.common.MetaTileMetrics;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileset;
import java.util.List;

public class ChunkTileset extends MetaTileset<Chunk>
{
    public ChunkTileset(List<Chunk> chunks, MetaTileMetrics chunkMetrics)
    {
        super(chunks, chunkMetrics);
    }
}

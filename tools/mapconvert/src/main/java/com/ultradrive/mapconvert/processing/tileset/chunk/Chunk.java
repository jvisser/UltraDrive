package com.ultradrive.mapconvert.processing.tileset.chunk;

import com.ultradrive.mapconvert.common.orientable.OrientableGrid;
import com.ultradrive.mapconvert.common.orientable.Orientation;
import com.ultradrive.mapconvert.processing.tileset.block.BlockReference;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTile;
import java.util.List;


public class Chunk extends MetaTile<Chunk, ChunkReference, BlockReference>
{
    private final boolean hasCollision;

    public Chunk(List<BlockReference> blockReferences)
    {
        super(blockReferences);

        hasCollision = blockReferences.stream()
                .reduce(false, (r, blockReference) -> r || blockReference.getSolidity().isSolid(), (a, b) -> a);
    }

    private Chunk(OrientableGrid<BlockReference> blockReferences, boolean hasCollision)
    {
        super(blockReferences);

        this.hasCollision = hasCollision;
    }

    @Override
    public ChunkReference.Builder referenceBuilder()
    {
        return new ChunkReference.Builder();
    }

    @Override
    public Chunk reorient(Orientation orientation)
    {
        return new Chunk(tileReferences.reorient(orientation), hasCollision);
    }

    public boolean isHasCollision()
    {
        return hasCollision;
    }
}

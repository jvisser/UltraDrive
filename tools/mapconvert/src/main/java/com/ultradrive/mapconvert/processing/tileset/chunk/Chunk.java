package com.ultradrive.mapconvert.processing.tileset.chunk;

import com.ultradrive.mapconvert.common.orientable.OrientableGrid;
import com.ultradrive.mapconvert.common.orientable.Orientation;
import com.ultradrive.mapconvert.processing.tileset.block.BlockReference;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTile;
import java.util.List;


public class Chunk extends MetaTile<Chunk, ChunkReference, BlockReference>
{
    private final boolean hasCollision;
    private final boolean empty;

    public Chunk(List<BlockReference> blockReferences)
    {
        super(blockReferences);

        this.empty = blockReferences.stream()
                .reduce(true, (result, blockReference) -> result && blockReference.isEmpty(), (a, b) -> a && b);
        this.hasCollision = blockReferences.stream()
                .reduce(false, (result, blockReference) -> result || blockReference.getSolidity().isSolid(), (a, b) -> a || b);
    }

    private Chunk(OrientableGrid<BlockReference> blockReferences, boolean hasCollision, boolean empty)
    {
        super(blockReferences);

        this.empty = empty;
        this.hasCollision = hasCollision;
    }

    @Override
    public ChunkReference.Builder referenceBuilder()
    {
        ChunkReference.Builder builder = new ChunkReference.Builder();
        builder.setEmpty(empty);
        return builder;
    }

    @Override
    public Chunk reorient(Orientation orientation)
    {
        return new Chunk(tileReferences.reorient(orientation), hasCollision, empty);
    }

    public boolean isHasCollision()
    {
        return hasCollision;
    }

    public boolean isEmpty()
    {
        return empty;
    }
}

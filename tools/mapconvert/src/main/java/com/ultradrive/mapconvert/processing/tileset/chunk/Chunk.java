package com.ultradrive.mapconvert.processing.tileset.chunk;

import com.ultradrive.mapconvert.common.OrientableGrid;
import com.ultradrive.mapconvert.common.OrientablePoolable;
import com.ultradrive.mapconvert.common.Orientation;
import com.ultradrive.mapconvert.common.Point;
import com.ultradrive.mapconvert.processing.tileset.block.BlockReference;

import java.util.Iterator;
import java.util.List;
import java.util.Objects;


public class Chunk implements OrientablePoolable<Chunk, ChunkReference>, Iterable<BlockReference>
{
    private final OrientableGrid<BlockReference> blockReferences;

    public Chunk(List<BlockReference> blockReferences)
    {
        this.blockReferences = new OrientableGrid<>(blockReferences);
    }

    private Chunk(OrientableGrid<BlockReference> blockReferences)
    {
        this.blockReferences = blockReferences;
    }

    @Override
    public boolean equals(Object o)
    {
        if (this == o)
        {
            return true;
        }
        if (!(o instanceof Chunk))
        {
            return false;
        }
        final Chunk chunk = (Chunk) o;
        return blockReferences.equals(chunk.blockReferences);
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(blockReferences);
    }

    @Override
    public ChunkReference.Builder referenceBuilder()
    {
        return new ChunkReference.Builder();
    }

    @Override
    public Chunk reorient(Orientation orientation)
    {
        return new Chunk(blockReferences.reorient(orientation));
    }

    public BlockReference getBlockReference(Point point)
    {
        return blockReferences.getValue(point);
    }

    public BlockReference getBlockReference(int blockReferenceId)
    {
        return blockReferences.getValue(blockReferenceId);
    }

    public Iterator<BlockReference> iterator()
    {
        return blockReferences.iterator();
    }

    public int getBlockCount()
    {
        return blockReferences.getSize();
    }
}

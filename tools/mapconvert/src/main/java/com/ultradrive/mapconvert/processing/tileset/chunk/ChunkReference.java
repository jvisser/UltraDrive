package com.ultradrive.mapconvert.processing.tileset.chunk;

import com.ultradrive.mapconvert.common.Orientation;
import com.ultradrive.mapconvert.processing.tileset.common.TileReference;


public class ChunkReference extends TileReference<ChunkReference>
{
    public static class Builder extends TileReference.Builder<ChunkReference>
    {
        public Builder()
        {
        }

        public Builder(ChunkReference chunkReference)
        {
            super(chunkReference);
        }

        @Override
        public ChunkReference build()
        {
            return new ChunkReference(referenceId, orientation);
        }
    }

    public ChunkReference(int referenceId, Orientation orientation)
    {
        super(referenceId, orientation);
    }

    @Override
    public Builder builder()
    {
        return new Builder(this);
    }

    @Override
    public int pack()
    {
        int packedReference = referenceId & 0x7ff;

        if (orientation.isHorizontalFlip())
        {
            packedReference |= 0x0800;
        }

        if (orientation.isVerticalFlip())
        {
            packedReference |= 0x1000;
        }

        return packedReference;
    }
}

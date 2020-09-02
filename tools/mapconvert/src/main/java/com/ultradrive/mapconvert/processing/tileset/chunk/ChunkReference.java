package com.ultradrive.mapconvert.processing.tileset.chunk;

import com.ultradrive.mapconvert.common.orientable.Orientation;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileReference;
import com.ultradrive.mapconvert.processing.tileset.common.TileReference;


public class ChunkReference extends MetaTileReference<ChunkReference>
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
}

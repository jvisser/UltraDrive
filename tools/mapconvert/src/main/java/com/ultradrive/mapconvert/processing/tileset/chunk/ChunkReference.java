package com.ultradrive.mapconvert.processing.tileset.chunk;

import com.ultradrive.mapconvert.common.BitPacker;
import com.ultradrive.mapconvert.common.orientable.Orientation;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileReference;
import com.ultradrive.mapconvert.processing.tileset.common.TileReference;


public class ChunkReference extends MetaTileReference<ChunkReference>
{
    private final boolean hasCollision;

    public static class Builder extends TileReference.Builder<ChunkReference>
    {
        private boolean hasCollision;

        public Builder()
        {
        }

        public Builder(ChunkReference chunkReference)
        {
            super(chunkReference);

            this.hasCollision = chunkReference.hasCollision;
        }

        public void setHasCollision(boolean hasCollision)
        {
            this.hasCollision = hasCollision;
        }

        @Override
        public ChunkReference build()
        {
            return new ChunkReference(referenceId, orientation, hasCollision);
        }
    }

    public ChunkReference(int referenceId, Orientation orientation, boolean hasCollision)
    {
        super(referenceId, orientation);

        this.hasCollision = hasCollision;
    }

    @Override
    public Builder builder()
    {
        return new Builder(this);
    }

    @Override
    public BitPacker pack()
    {
        return super.pack().add(hasCollision);
    }
}

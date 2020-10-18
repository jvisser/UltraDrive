package com.ultradrive.mapconvert.processing.tileset.chunk;

import com.ultradrive.mapconvert.common.BitPacker;
import com.ultradrive.mapconvert.common.orientable.Orientation;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileReference;


public class ChunkReference extends MetaTileReference<ChunkReference>
{
    private final boolean hasCollision;

    public static class Builder extends MetaTileReference.Builder<ChunkReference>
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
            return new ChunkReference(referenceId, orientation, hasCollision, empty);
        }
    }

    public ChunkReference(int referenceId, Orientation orientation, boolean hasCollision, boolean empty)
    {
        super(referenceId, orientation, empty);

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

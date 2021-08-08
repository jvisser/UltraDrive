package com.ultradrive.mapconvert.processing.tileset.chunk;

import com.ultradrive.mapconvert.common.BitPacker;
import com.ultradrive.mapconvert.common.orientable.Orientation;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileReference;


public class ChunkReference extends MetaTileReference<ChunkReference>
{
    private static final int REFERENCE_ID_BIT_COUNT = 8;
    private static final int OBJECT_CONTAINER_GROUP_INDEX_BIT_COUNT = 3;

    private final int objectContainerGroupIndex;
    private final boolean hasCollision;

    public static class Builder extends MetaTileReference.Builder<ChunkReference>
    {
        private int objectContainerGroupIndex;
        private boolean hasCollision;

        public Builder()
        {
        }

        public Builder(ChunkReference chunkReference)
        {
            super(chunkReference);

            this.objectContainerGroupIndex = chunkReference.objectContainerGroupIndex;
            this.hasCollision = chunkReference.hasCollision;
        }

        public void setObjectContainerGroupIndex(int objectContainerGroupIndex)
        {
            this.objectContainerGroupIndex = objectContainerGroupIndex;
        }

        public void setHasCollision(boolean hasCollision)
        {
            this.hasCollision = hasCollision;
        }

        @Override
        public ChunkReference build()
        {
            return new ChunkReference(referenceId, orientation, objectContainerGroupIndex, hasCollision, empty);
        }
    }

    public ChunkReference(int referenceId, Orientation orientation, int objectContainerGroupIndex, boolean hasCollision, boolean empty)
    {
        super(referenceId, orientation, empty);

        this.objectContainerGroupIndex = objectContainerGroupIndex;
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
        return new BitPacker(Short.SIZE)
                .add(referenceId, REFERENCE_ID_BIT_COUNT)
                .pad(1)                                            // Reserved for future expansion
                .add(hasCollision)
                .add(empty)
                .add(orientation)
                .add(objectContainerGroupIndex, OBJECT_CONTAINER_GROUP_INDEX_BIT_COUNT);
    }
}

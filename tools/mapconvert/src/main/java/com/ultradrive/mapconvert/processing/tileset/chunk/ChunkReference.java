package com.ultradrive.mapconvert.processing.tileset.chunk;

import com.ultradrive.mapconvert.common.BitPacker;
import com.ultradrive.mapconvert.common.orientable.Orientation;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileReference;
import java.util.Objects;


public class ChunkReference extends MetaTileReference<ChunkReference>
{
    private static final int REFERENCE_ID_BIT_COUNT = 8;
    private static final int OBJECT_CONTAINER_GROUP_INDEX_BIT_COUNT = 3;
    private final boolean hasCollision;
    private final boolean hasOverlay;
    private final int objectContainerGroupIndex;

    public static class Builder extends MetaTileReference.Builder<ChunkReference>
    {
        private boolean hasCollision;
        private boolean hasOverlay;
        private int objectContainerGroupIndex;

        public Builder()
        {
        }

        public Builder(ChunkReference chunkReference)
        {
            super(chunkReference);

            this.hasCollision = chunkReference.hasCollision;
            this.hasOverlay = chunkReference.hasOverlay;
            this.objectContainerGroupIndex = chunkReference.objectContainerGroupIndex;
        }

        @Override
        public ChunkReference build()
        {
            return new ChunkReference(referenceId, orientation, objectContainerGroupIndex, hasCollision, empty,
                                      hasOverlay);
        }

        public void setHasCollision(boolean hasCollision)
        {
            this.hasCollision = hasCollision;
        }

        public void setHasOverlay(boolean hasOverlay)
        {
            this.hasOverlay = hasOverlay;
        }

        public void setObjectContainerGroupIndex(int objectContainerGroupIndex)
        {
            this.objectContainerGroupIndex = objectContainerGroupIndex;
        }
    }

    public ChunkReference(int referenceId, Orientation orientation, int objectContainerGroupIndex, boolean hasCollision,
                          boolean empty, boolean hasOverlay)
    {
        super(referenceId, orientation, empty);

        this.objectContainerGroupIndex = objectContainerGroupIndex;
        this.hasCollision = hasCollision;
        this.hasOverlay = hasOverlay;
    }

    @Override
    public Builder builder()
    {
        return new Builder(this);
    }

    @Override
    public boolean equals(Object o)
    {
        if (this == o)
        {
            return true;
        }
        if (o == null || getClass() != o.getClass())
        {
            return false;
        }
        if (!super.equals(o))
        {
            return false;
        }
        final ChunkReference that = (ChunkReference) o;
        return hasCollision == that.hasCollision && hasOverlay == that.hasOverlay &&
               objectContainerGroupIndex == that.objectContainerGroupIndex;
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(super.hashCode(), hasCollision, hasOverlay, objectContainerGroupIndex);
    }

    @Override
    public BitPacker pack()
    {
        return new BitPacker(Short.SIZE)
                .add(referenceId, REFERENCE_ID_BIT_COUNT)
                .add(hasOverlay)
                .add(hasCollision)
                .add(empty)
                .add(orientation)
                .add(objectContainerGroupIndex, OBJECT_CONTAINER_GROUP_INDEX_BIT_COUNT);
    }

    public boolean hasAnyInformation()
    {
        return !isEmpty() || hasCollision() || hasOverlay() || objectContainerGroupIndex > 0;
    }

    public boolean hasCollision()
    {
        return hasCollision;
    }

    public boolean hasOverlay()
    {
        return hasOverlay;
    }

    public int getObjectContainerGroupIndex()
    {
        return objectContainerGroupIndex;
    }
}

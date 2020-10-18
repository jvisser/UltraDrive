package com.ultradrive.mapconvert.processing.tileset.common;

import com.ultradrive.mapconvert.common.BitPacker;
import com.ultradrive.mapconvert.common.orientable.Orientation;


public abstract class MetaTileReference<T extends TileReference<T>> extends TileReference<T>
{
    private static final int REFERENCE_ID_BIT_COUNT = 10;
    protected final boolean empty;

    public static abstract class Builder<T extends TileReference<T>> extends TileReference.Builder<T>
    {
        protected boolean empty;

        public Builder()
        {
        }

        public Builder(MetaTileReference<T> tileReference)
        {
            super(tileReference);

            this.empty = tileReference.empty;
        }

        public void setEmpty(boolean empty)
        {
            this.empty = empty;
        }
    }

    public MetaTileReference(int referenceId, Orientation orientation, boolean empty)
    {
        super(referenceId, orientation);
        this.empty = empty;
    }

    @Override
    public BitPacker pack()
    {
        return new BitPacker(Short.SIZE)
                .add(referenceId, REFERENCE_ID_BIT_COUNT)
                .add(empty)
                .add(orientation);
    }

    public boolean isEmpty()
    {
        return empty;
    }
}

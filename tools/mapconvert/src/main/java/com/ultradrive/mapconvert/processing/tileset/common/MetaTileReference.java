package com.ultradrive.mapconvert.processing.tileset.common;

import com.ultradrive.mapconvert.common.orientable.Orientation;
import java.util.Objects;


public abstract class MetaTileReference<T extends TileReference<T>> extends TileReference<T>
{
    protected final boolean empty;

    public abstract static class Builder<T extends TileReference<T>> extends TileReference.Builder<T>
    {
        protected boolean empty;

        protected Builder()
        {
        }

        protected Builder(MetaTileReference<T> tileReference)
        {
            super(tileReference);

            this.empty = tileReference.empty;
        }

        public void setEmpty(boolean empty)
        {
            this.empty = empty;
        }
    }

    protected MetaTileReference(int referenceId, Orientation orientation, boolean empty)
    {
        super(referenceId, orientation);
        this.empty = empty;
    }

    @Override
    public boolean equals(Object o)
    {
        if (this == o)
        {
            return true;
        }
        if (!(o instanceof MetaTileReference))
        {
            return false;
        }
        if (!super.equals(o))
        {
            return false;
        }
        final MetaTileReference<?> that = (MetaTileReference<?>) o;
        return empty == that.empty;
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(super.hashCode(), empty);
    }

    public boolean isEmpty()
    {
        return empty;
    }
}

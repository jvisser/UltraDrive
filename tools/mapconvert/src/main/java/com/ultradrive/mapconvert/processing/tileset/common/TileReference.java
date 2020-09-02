package com.ultradrive.mapconvert.processing.tileset.common;

import com.ultradrive.mapconvert.common.Packable;
import com.ultradrive.mapconvert.common.orientable.OrientableReference;
import com.ultradrive.mapconvert.common.orientable.Orientation;
import java.util.Objects;


public abstract class TileReference<T extends TileReference<T>> implements OrientableReference<T>, Packable
{
    protected final int referenceId;
    protected final Orientation orientation;

    public static abstract class Builder<T extends TileReference<T>> implements OrientableReference.Builder<T>
    {
        protected int referenceId;
        protected Orientation orientation;

        public Builder()
        {
            referenceId = -1;
            orientation = Orientation.DEFAULT;
        }

        public Builder(TileReference<T> tileReference)
        {
            referenceId = tileReference.referenceId;
            orientation = tileReference.orientation;
        }

        @Override
        public void setOrientation(Orientation orientation)
        {
            this.orientation = orientation;
        }

        @Override
        public void setReferenceId(int referenceId)
        {
            this.referenceId = referenceId;
        }

        public void reorient(Orientation orientation)
        {
            setOrientation(this.orientation.translate(orientation));
        }

        public void offsetReference(int offset)
        {
            referenceId += offset;
        }
    }

    public TileReference(int referenceId, Orientation orientation)
    {
        this.referenceId = referenceId;
        this.orientation = orientation;
    }

    @Override
    public boolean equals(Object o)
    {
        if (this == o)
        {
            return true;
        }
        if (!(o instanceof TileReference))
        {
            return false;
        }
        final TileReference<?> that = (TileReference<?>) o;
        return referenceId == that.referenceId &&
               orientation == that.orientation;
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(referenceId, orientation);
    }

    @Override
    public int getReferenceId()
    {
        return referenceId;
    }

    @Override
    public Orientation getOrientation()
    {
        return orientation;
    }
}

package com.ultradrive.mapconvert.processing.tileset.common;


import com.ultradrive.mapconvert.common.OrientableGrid;
import com.ultradrive.mapconvert.common.OrientablePoolable;
import com.ultradrive.mapconvert.common.Point;
import java.util.Iterator;
import java.util.List;
import java.util.Objects;


public abstract class MetaTile<T extends MetaTile<T, R, S>, R extends TileReference<R>, S extends TileReference<S>> implements OrientablePoolable<T, R>, Iterable<S>
{
    protected final OrientableGrid<S> tileReferences;

    public MetaTile(List<S> tileReferences)
    {
        this.tileReferences = new OrientableGrid<>(tileReferences);
    }

    protected MetaTile(OrientableGrid<S> tileReferences)
    {
        this.tileReferences = tileReferences;
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
        final MetaTile<?, ?, ?> metaTile = (MetaTile<?, ?, ?>) o;
        return tileReferences.equals(metaTile.tileReferences);
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(tileReferences);
    }

    @Override
    public Iterator<S> iterator()
    {
        return tileReferences.iterator();
    }

    public S getTileReference(Point point)
    {
        return tileReferences.getValue(point);
    }

    public S getTileReference(int blockReferenceId)
    {
        return tileReferences.getValue(blockReferenceId);
    }

    public int getTileReferenceCount()
    {
        return tileReferences.getSize();
    }
}

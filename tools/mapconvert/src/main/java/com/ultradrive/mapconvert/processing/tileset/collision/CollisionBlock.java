package com.ultradrive.mapconvert.processing.tileset.collision;

import java.util.Iterator;
import java.util.List;
import java.util.Objects;


public final class CollisionBlock implements Iterable<Integer>
{
    private final List<Integer> heightField;
    private final double angle;

    public CollisionBlock(List<Integer> heightField, double angle)
    {
        this.heightField = heightField;
        this.angle = angle;
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
        final CollisionBlock that = (CollisionBlock) o;
        return Double.compare(that.angle, angle) == 0 &&
               heightField.equals(that.heightField);
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(heightField, angle);
    }

    @Override
    public Iterator<Integer> iterator()
    {
        return heightField.iterator();
    }

    public List<Integer> getHeightField()
    {
        return heightField;
    }

    public double getAngle()
    {
        return angle;
    }
}

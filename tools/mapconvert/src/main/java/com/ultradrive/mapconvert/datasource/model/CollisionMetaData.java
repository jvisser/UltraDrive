package com.ultradrive.mapconvert.datasource.model;

public final class CollisionMetaData
{
    private final double angle;

    public static CollisionMetaData empty()
    {
        return new CollisionMetaData(0);
    }

    public CollisionMetaData(double angle)
    {
        this.angle = angle;
    }

    public double getAngle()
    {
        return angle;
    }
}

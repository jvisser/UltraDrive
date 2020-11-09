package com.ultradrive.mapconvert.datasource.model;

public final class CollisionBlockMetaData
{
    private final double angle;

    public static CollisionBlockMetaData empty()
    {
        return new CollisionBlockMetaData(0);
    }

    public CollisionBlockMetaData(double angle)
    {
        this.angle = angle;
    }

    public double getAngle()
    {
        return angle;
    }
}

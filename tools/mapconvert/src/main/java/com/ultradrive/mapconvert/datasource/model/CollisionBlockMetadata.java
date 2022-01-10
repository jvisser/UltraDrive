package com.ultradrive.mapconvert.datasource.model;

public final class CollisionBlockMetadata
{
    private final double angle;

    public static CollisionBlockMetadata empty()
    {
        return new CollisionBlockMetadata(0);
    }

    public CollisionBlockMetadata(double angle)
    {
        this.angle = angle;
    }

    public double getAngle()
    {
        return angle;
    }
}

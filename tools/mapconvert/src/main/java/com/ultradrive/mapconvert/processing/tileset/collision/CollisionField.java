package com.ultradrive.mapconvert.processing.tileset.collision;

import java.util.List;


public class CollisionField
{
    private final List<Integer> heightField;
    private final double angle;

    public CollisionField(List<Integer> heightField, double angle)
    {
        this.heightField = heightField;
        this.angle = angle;
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

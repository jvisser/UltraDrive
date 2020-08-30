package com.ultradrive.mapconvert.datasource.model;

import com.ultradrive.mapconvert.common.Orientation;


public class ResourceReference
{
    private final int id;
    private final Orientation orientation;

    public static ResourceReference empty()
    {
        return new ResourceReference(0, Orientation.DEFAULT);
    }

    public ResourceReference(int id, Orientation orientation)
    {
        this.id = id;
        this.orientation = orientation;
    }

    public int getId()
    {
        return id;
    }

    public Orientation getOrientation()
    {
        return orientation;
    }
}

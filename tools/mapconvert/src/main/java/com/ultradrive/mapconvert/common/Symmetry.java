package com.ultradrive.mapconvert.common;

public enum Symmetry
{
    SYMMETRICAL(Orientation.DEFAULT),
    ASYMMETRICAL(null),
    HORIZONTAL_MIRRORED(Orientation.HORIZONTAL_FLIP),
    VERTICAL_MIRRORED(Orientation.VERTICAL_FLIP),
    HORIZONTAL_VERTICAL_MIRRORED(Orientation.HORIZONTAL_VERTICAL_FLIP);

    private final Orientation orientation;

    Symmetry(Orientation orientation)
    {
        this.orientation = orientation;
    }

    public Orientation getOrientation()
    {
        return orientation;
    }
}

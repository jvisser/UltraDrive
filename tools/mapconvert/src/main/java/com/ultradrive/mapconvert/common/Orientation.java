package com.ultradrive.mapconvert.common;

public enum Orientation
{
    DEFAULT(false, false),
    HORIZONTAL_FLIP(true, false),
    VERTICAL_FLIP(false, true),
    HORIZONTAL_VERTICAL_FLIP(true, true);

    private final boolean horizontalFlip;
    private final boolean verticalFlip;

    public static Orientation get(boolean horizontalFlip, boolean verticalFlip)
    {
        if (horizontalFlip && verticalFlip)
        {
            return HORIZONTAL_VERTICAL_FLIP;
        }
        else if (horizontalFlip)
        {
            return HORIZONTAL_FLIP;
        }
        else if (verticalFlip)
        {
            return VERTICAL_FLIP;
        }
        return DEFAULT;
    }

    Orientation(boolean horizontalFlip, boolean verticalFlip)
    {
        this.horizontalFlip = horizontalFlip;
        this.verticalFlip = verticalFlip;
    }

    public Point translate(Point point, int dimensionSize)
    {
        return translate(point, dimensionSize, dimensionSize);
    }

    public Point translate(Point point, int horizontalDimensionSize, int verticalDimensionSize)
    {
        int x = isHorizontalFlip()
                ? horizontalDimensionSize - 1 - point.getX()
                : point.getX();

        int y = isVerticalFlip()
                ? verticalDimensionSize - 1 - point.getY()
                : point.getY();

        return new Point(x, y);
    }

    public Orientation translate(Orientation other)
    {
        boolean newHorizontalFlip = horizontalFlip ^ other.horizontalFlip;
        boolean newVerticalFlip = verticalFlip ^ other.verticalFlip;

        return get(newHorizontalFlip, newVerticalFlip);
    }

    public boolean isHorizontalFlip()
    {
        return horizontalFlip;
    }

    public boolean isVerticalFlip()
    {
        return verticalFlip;
    }
}

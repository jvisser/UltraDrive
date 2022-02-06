package com.ultradrive.mapconvert.processing.map.metadata;

public class TileMapObjectGroupContainer
{
    private final int id;
    private final int flag;
    private final TileMapObjectGroupContainer parent;

    public TileMapObjectGroupContainer(int id, int flag,
                                       TileMapObjectGroupContainer parent)
    {
        this.id = id;
        this.flag = flag;
        this.parent = parent;
    }

    public int getFlag()
    {
        return flag;
    }

    public int getFlagNumber()
    {
        return Integer.numberOfTrailingZeros(flag);
    }

    public int getId()
    {
        return id;
    }

    public TileMapObjectGroupContainer getParent()
    {
        return parent;
    }

    public boolean hasParent()
    {
        return parent != null;
    }
}

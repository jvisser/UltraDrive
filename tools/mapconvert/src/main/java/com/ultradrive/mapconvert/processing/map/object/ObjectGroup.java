package com.ultradrive.mapconvert.processing.map.object;

public class ObjectGroup
{
    private final int id;
    private final int flag;

    public ObjectGroup(int id, int flag)
    {
        this.id = id;
        this.flag = flag;
    }

    public int getId()
    {
        return id;
    }

    public int getFlagMask()
    {
        return flag;
    }

    public int getFlagNumber()
    {
        return Integer.numberOfTrailingZeros(flag);
    }
}

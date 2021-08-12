package com.ultradrive.mapconvert.datasource.model;

public class MapObject
{
    private final String name;
    private final int id;
    private final int x;
    private final int y;

    public MapObject(String name, int id, int x, int y)
    {
        this.name = name;
        this.id = id;
        this.x = x;
        this.y = y;
    }

    public String getName()
    {
        return name;
    }

    public int getId()
    {
        return id;
    }

    public int getX()
    {
        return x;
    }

    public int getY()
    {
        return y;
    }
}

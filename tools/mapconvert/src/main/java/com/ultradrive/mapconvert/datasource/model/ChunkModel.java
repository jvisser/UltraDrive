package com.ultradrive.mapconvert.datasource.model;

import java.util.List;


public final class ChunkModel
{
    private final int id;
    private final List<ChunkElementModel> elements;

    public ChunkModel(int id, List<ChunkElementModel> elements)
    {
        this.id = id;
        this.elements = elements;
    }

    public int getId()
    {
        return id;
    }

    public List<ChunkElementModel> getElements()
    {
        return elements;
    }
}

package com.ultradrive.mapconvert.datasource.model;

public final class ChunkElementModel
{
    private final ResourceReference blockReference;
    private final ResourceReference solidityReference;
    private final ResourceReference priorityReference;

    public ChunkElementModel(ResourceReference blockReference,
                             ResourceReference solidityReference,
                             ResourceReference priorityReference)
    {
        this.blockReference = blockReference;
        this.solidityReference = solidityReference;
        this.priorityReference = priorityReference;
    }

    public ResourceReference getBlockReference()
    {
        return blockReference;
    }

    public ResourceReference getSolidityReference()
    {
        return solidityReference;
    }

    public ResourceReference getPriorityReference()
    {
        return priorityReference;
    }
}

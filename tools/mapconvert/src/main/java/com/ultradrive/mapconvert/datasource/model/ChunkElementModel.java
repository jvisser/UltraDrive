package com.ultradrive.mapconvert.datasource.model;

public final class ChunkElementModel
{
    private final ResourceReference blockReference;
    private final ResourceReference solidityReference;
    private final ResourceReference typeReference;

    public ChunkElementModel(ResourceReference blockReference,
                             ResourceReference solidityReference,
                             ResourceReference typeReference)
    {
        this.blockReference = blockReference;
        this.solidityReference = solidityReference;
        this.typeReference = typeReference;
    }

    public ResourceReference getBlockReference()
    {
        return blockReference;
    }

    public ResourceReference getSolidityReference()
    {
        return solidityReference;
    }

    public ResourceReference getTypeReference()
    {
        return typeReference;
    }
}

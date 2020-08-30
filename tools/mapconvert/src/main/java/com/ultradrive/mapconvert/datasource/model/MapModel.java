package com.ultradrive.mapconvert.datasource.model;

public interface MapModel
{
    String getName();
    
    int getWidth();

    int getHeight();

    ChunkReferenceModel getChunkReference(int row, int column);
}

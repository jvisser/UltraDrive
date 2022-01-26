package com.ultradrive.mapconvert.datasource.model;

import java.util.List;


public interface MapLayer
{
    ChunkReferenceModel getChunkReference(int row, int column);

    List<MapObject> getObjects();
}

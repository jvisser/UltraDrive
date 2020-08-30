package com.ultradrive.mapconvert.datasource;

import com.ultradrive.mapconvert.datasource.model.ChunkModel;


public interface ChunkModelProducer
{
    ChunkModel getChunkModel(int chunkId);
}

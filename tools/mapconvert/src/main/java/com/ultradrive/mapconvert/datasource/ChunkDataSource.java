package com.ultradrive.mapconvert.datasource;

import com.ultradrive.mapconvert.common.PropertySource;


public interface ChunkDataSource extends ChunkModelProducer, PropertySource
{
    int getChunkSize();
}

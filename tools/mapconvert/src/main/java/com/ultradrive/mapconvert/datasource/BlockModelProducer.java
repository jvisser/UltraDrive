package com.ultradrive.mapconvert.datasource;

import com.ultradrive.mapconvert.datasource.model.BlockModel;


public interface BlockModelProducer
{
    BlockModel getBlockModel(int blockId);
}

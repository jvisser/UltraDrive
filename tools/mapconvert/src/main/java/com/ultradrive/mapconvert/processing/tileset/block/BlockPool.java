package com.ultradrive.mapconvert.processing.tileset.block;

import com.ultradrive.mapconvert.common.orientable.OrientablePool;


class BlockPool extends OrientablePool<Block, BlockReference>
{
    @Override
    public BlockReference.Builder getReference(Block orientable)
    {
        return (BlockReference.Builder) super.getReference(orientable);
    }
}

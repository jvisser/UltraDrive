package com.ultradrive.mapconvert.processing.tileset.block;

import com.ultradrive.mapconvert.common.BitPacker;
import com.ultradrive.mapconvert.common.Packable;
import java.util.List;


public enum BlockSolidity implements Packable
{
    NONE,
    TOP,
    LEFT_RIGHT_BOTTOM,
    ALL;

    private static final int BIT_COUNT = 2;

    public static BlockSolidity fromId(int id)
    {
        if ((id & -(1 << BIT_COUNT)) != 0)
        {
            return NONE;
        }
        return BlockSolidity.values()[id & ((1 << BIT_COUNT) - 1)];
    }

    @Override
    public BitPacker pack()
    {
        return new BitPacker().add(getValue(), BIT_COUNT);
    }

    public boolean isSolid()
    {
        return this != NONE;
    }

    private int getValue()
    {
        return List.of(values()).indexOf(this);
    }
}

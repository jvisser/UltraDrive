package com.ultradrive.mapconvert.processing.tileset.block;

public enum BlockSolidity
{
    NONE(0x0000),
    TOP(0x1000),
    LEFT_RIGHT_BOTTOM(0x2000),
    ALL(0x3000);

    private final int value;

    BlockSolidity(int value)
    {
        this.value = value;
    }

    public static BlockSolidity fromId(int id)
    {
        if ((id & ~0x03) != 0)
        {
            return NONE;
        }
        return BlockSolidity.values()[id & 0x03];
    }

    int getValue()
    {
        return value;
    }
}

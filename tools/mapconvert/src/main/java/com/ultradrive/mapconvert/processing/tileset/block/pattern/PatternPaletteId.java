package com.ultradrive.mapconvert.processing.tileset.block.pattern;

import com.ultradrive.mapconvert.common.BitPacker;
import com.ultradrive.mapconvert.common.Packable;
import java.util.List;


public enum PatternPaletteId implements Packable
{
    FIRST(0, 15),
    SECOND(16, 31),
    THIRD( 32, 47),
    FORTH( 48, 63),
    INVALID(-1, -1);

    private static final int BIT_COUNT = 2;

    private final int startIndex;
    private final int endIndex;

    public static PatternPaletteId fromId(int paletteId)
    {
        if ((paletteId & -(1 << BIT_COUNT)) != 0)
        {
            return INVALID;
        }
        return PatternPaletteId.values()[paletteId & ((1 << BIT_COUNT) - 1)];
    }

    PatternPaletteId(int startIndex, int endIndex)
    {
        this.startIndex = startIndex;
        this.endIndex = endIndex;
    }

    @Override
    public BitPacker pack()
    {
        return new BitPacker().add(getValue(), BIT_COUNT);
    }

    public int toGlobalColorIndex(int localColorIndex)
    {
        return startIndex + localColorIndex;
    }

    public int getValue()
    {
        if (isInvalid())
        {
            return -1;
        }

        return List.of(values()).indexOf(this);
    }

    public int getEndIndex()
    {
        return endIndex;
    }

    public int getStartIndex()
    {
        return startIndex;
    }

    public boolean isInvalid()
    {
        return this == INVALID;
    }
}

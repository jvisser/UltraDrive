package com.ultradrive.mapconvert.processing.tileset.block.pattern;

public enum PatternPaletteId
{
    FIRST(0x0000, 0, 15),
    SECOND(0x2000, 16, 31),
    THIRD(0x4000, 32, 47),
    FORTH(0x6000, 48, 63),
    INVALID(-1, -1, -1);

    private final int value;
    private final int startIndex;
    private final int endIndex;

    public static PatternPaletteId fromId(int paletteId)
    {
        if ((paletteId & ~0x03) != 0)
        {
            return INVALID;
        }
        return PatternPaletteId.values()[paletteId & 0x03];
    }

    PatternPaletteId(int value, int startIndex, int endIndex)
    {
        this.value = value;
        this.startIndex = startIndex;
        this.endIndex = endIndex;
    }

    public int toGlobalColorIndex(int localColorIndex)
    {
        return startIndex + localColorIndex;
    }

    public int getValue()
    {
        return value;
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

package com.ultradrive.mapconvert.processing.tileset.block.pattern;

public enum PatternPriority
{
    LOW(0x0000),
    HIGH(0x8000);

    private final int value;

    PatternPriority(int value)
    {
        this.value = value;
    }

    public static PatternPriority fromInt(int value)
    {
        return value == 0 ? LOW : HIGH;
    }

    int getValue()
    {
        return value;
    }
}

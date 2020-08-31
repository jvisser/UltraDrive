package com.ultradrive.mapconvert.processing.tileset.block.pattern;

import com.ultradrive.mapconvert.common.BitPacker;
import com.ultradrive.mapconvert.common.Packable;


public enum PatternPriority implements Packable
{
    LOW,
    HIGH;

    public static PatternPriority fromInt(int value)
    {
        return value == 0 ? LOW : HIGH;
    }

    @Override
    public BitPacker pack()
    {
        return new BitPacker().add(isHigh());
    }

    boolean isHigh()
    {
        return this == HIGH;
    }
}

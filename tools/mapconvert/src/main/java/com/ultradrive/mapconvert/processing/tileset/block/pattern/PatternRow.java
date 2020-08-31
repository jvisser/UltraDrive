package com.ultradrive.mapconvert.processing.tileset.block.pattern;

import com.ultradrive.mapconvert.common.BitPacker;
import com.ultradrive.mapconvert.common.Packable;
import java.util.Iterator;
import java.util.List;


public class PatternRow implements Iterable<Integer>, Packable
{
    private static final int PIXEL_BIT_COUNT = 32;

    private final List<Integer> lineValues;

    PatternRow(List<Integer> lineValues)
    {
        this.lineValues = lineValues;
    }

    @Override
    public BitPacker pack()
    {
        int packedValue = lineValues.stream()
                .reduce(0, (i, v) -> (i << Pattern.PIXEL_VALUE_BITS) | v);

        return new BitPacker(PIXEL_BIT_COUNT).add(packedValue, PIXEL_BIT_COUNT);
    }

    @Override
    public Iterator<Integer> iterator()
    {
        return lineValues.iterator();
    }
}

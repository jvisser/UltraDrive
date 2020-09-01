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
        return lineValues.stream()
                .reduce(new BitPacker(PIXEL_BIT_COUNT),
                        (bp, v) -> bp.insert(v, Pattern.PIXEL_VALUE_BITS),
                        BitPacker::add);
    }

    @Override
    public Iterator<Integer> iterator()
    {
        return lineValues.iterator();
    }
}

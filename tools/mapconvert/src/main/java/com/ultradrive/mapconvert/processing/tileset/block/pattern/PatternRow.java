package com.ultradrive.mapconvert.processing.tileset.block.pattern;

import com.ultradrive.mapconvert.common.Packable;
import java.util.Iterator;
import java.util.List;


public class PatternRow implements Iterable<Integer>, Packable
{
    private final List<Integer> lineValues;

    PatternRow(List<Integer> lineValues)
    {
        this.lineValues = lineValues;
    }

    @Override
    public int pack()
    {
        return lineValues.stream().reduce(0, (i, v) -> (i << Pattern.PIXEL_VALUE_BITS) | v);
    }

    @Override
    public Iterator<Integer> iterator()
    {
        return lineValues.iterator();
    }
}

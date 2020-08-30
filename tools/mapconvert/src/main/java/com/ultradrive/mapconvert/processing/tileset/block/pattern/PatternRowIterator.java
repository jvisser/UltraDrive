package com.ultradrive.mapconvert.processing.tileset.block.pattern;


import java.util.Iterator;


class PatternRowIterator implements Iterator<PatternRow>
{
    private final Pattern pattern;

    private int currentRow;

    public PatternRowIterator(Pattern pattern)
    {
        this.pattern = pattern;

        this.currentRow = 0;
    }

    @Override
    public boolean hasNext()
    {
        return currentRow < Pattern.DIMENSION_SIZE;
    }

    @Override
    public PatternRow next()
    {
        return pattern.getPatternRow(currentRow++);
    }
}

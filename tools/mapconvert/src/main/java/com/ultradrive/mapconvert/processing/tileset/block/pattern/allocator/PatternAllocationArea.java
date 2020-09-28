package com.ultradrive.mapconvert.processing.tileset.block.pattern.allocator;

import com.google.common.collect.ImmutableList;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;
import java.util.List;


public class PatternAllocationArea
{
    private final String id;
    private final int size;
    private final int patternBaseId;
    private final int reservedPatternSize;
    private final List<Pattern> patterns;

    PatternAllocationArea(String id, int size, int patternBaseId, int reservedPatternSize, List<Pattern> patterns)
    {
        this.id = id;
        this.size = size;
        this.patternBaseId = patternBaseId;
        this.reservedPatternSize = reservedPatternSize;
        this.patterns = ImmutableList.copyOf(patterns);
    }

    public boolean hasPattern(int patternReferenceId)
    {
        return patternReferenceId >= patternBaseId && patternReferenceId < patternBaseId + patterns.size();
    }

    public Pattern getPattern(int patternReferenceId)
    {
        return patterns.get(patternReferenceId - patternBaseId);
    }

    public String getId()
    {
        return id;
    }

    public int getSize()
    {
        return size;
    }

    public int getPatternBaseId()
    {
        return patternBaseId;
    }

    public int getReservedPatternSize()
    {
        return reservedPatternSize;
    }

    public int getAllocatedPatternSize()
    {
        return patterns.size();
    }

    public List<Pattern> getPatterns()
    {
        return patterns;
    }

    public int getTotalPatternAllocationSize()
    {
        return reservedPatternSize + patterns.size();
    }
}

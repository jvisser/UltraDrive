package com.ultradrive.mapconvert.processing.tileset.block.pattern.allocator;

import com.google.common.collect.ImmutableList;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;
import java.util.List;


public class PatternAllocationArea
{
    private final String id;
    private final int size;
    private final int basePatternId;
    private final int reservedPatternSize;
    private final List<Pattern> patterns;

    PatternAllocationArea(String id, int size, int basePatternId, int reservedPatternSize, List<Pattern> patterns)
    {
        this.id = id;
        this.size = size;
        this.basePatternId = basePatternId;
        this.reservedPatternSize = reservedPatternSize;
        this.patterns = ImmutableList.copyOf(patterns);
    }

    public boolean hasPattern(int patternReferenceId)
    {
        return patternReferenceId >= basePatternId && patternReferenceId < basePatternId + patterns.size();
    }

    public Pattern getPattern(int patternReferenceId)
    {
        return patterns.get(patternReferenceId - basePatternId);
    }

    public String getId()
    {
        return id;
    }

    public int getSize()
    {
        return size;
    }

    public int getBasePatternId()
    {
        return basePatternId;
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

    public int totalPatternAllocationSize()
    {
        return reservedPatternSize + patterns.size();
    }
}

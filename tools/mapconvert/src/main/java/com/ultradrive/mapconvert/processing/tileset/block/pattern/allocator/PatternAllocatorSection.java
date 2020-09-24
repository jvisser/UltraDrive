package com.ultradrive.mapconvert.processing.tileset.block.pattern.allocator;

import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;
import java.util.ArrayList;
import java.util.List;


class PatternAllocatorSection
{
    private final String id;
    private final int startPatternId;
    private final int endPatternPatternId;          // Inclusive
    private final List<Pattern> allocatedPatterns;

    private int reservedPatterns;

    public PatternAllocatorSection(String id, int startPatternId, int endPatternPatternId)
    {
        this.id = id;
        this.startPatternId = startPatternId;
        this.endPatternPatternId = endPatternPatternId;
        this.allocatedPatterns = new ArrayList<>();
    }

    public boolean hasSpace(int amount)
    {
        return getNextFreePatternId() + amount - 1 <= endPatternPatternId;
    }

    public int allocate(Pattern pattern)
    {
        int patternId = getNextFreePatternId();

        allocatedPatterns.add(pattern);

        return patternId;
    }

    public int reserve(int amount)
    {
        int patternId = getNextFreePatternId();

        reservedPatterns += amount;

        return patternId;
    }

    public int getNextFreePatternId()
    {
        return startPatternId + allocatedPatterns.size() + reservedPatterns;
    }

    public PatternAllocationArea compile()
    {
        return new PatternAllocationArea(id, startPatternId, reservedPatterns, allocatedPatterns);
    }
}

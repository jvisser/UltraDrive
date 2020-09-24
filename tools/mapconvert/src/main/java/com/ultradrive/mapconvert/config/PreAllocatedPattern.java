package com.ultradrive.mapconvert.config;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;


public class PreAllocatedPattern
{
    private final int patternId;
    private final Pattern pattern;

    @JsonCreator
    public PreAllocatedPattern(@JsonProperty ("patternId") int patternId,
                        @JsonProperty ("pattern") Pattern pattern)
    {
        this.patternId = patternId;
        this.pattern = pattern;
    }

    public int getPatternId()
    {
        return patternId;
    }

    public Pattern getPattern()
    {
        return pattern;
    }
}

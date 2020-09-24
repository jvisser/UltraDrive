package com.ultradrive.mapconvert.config;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;


public class PatternAllocationRange
{
    private final String id;
    private final int startPatternId;
    private final int endPatternId;

    @JsonCreator
    public PatternAllocationRange(@JsonProperty ("id") String id,
                                  @JsonProperty ("startPatternId") int startPatternId,
                                  @JsonProperty ("endPatternId") int endPatternId)
    {
        this.id = id;
        this.startPatternId = startPatternId;
        this.endPatternId = endPatternId;
    }

    public String getId()
    {
        return id;
    }

    public int getStartPatternId()
    {
        return startPatternId;
    }

    public int getEndPatternId()
    {
        return endPatternId;
    }
}

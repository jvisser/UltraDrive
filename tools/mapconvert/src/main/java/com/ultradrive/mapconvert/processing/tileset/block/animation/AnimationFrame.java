package com.ultradrive.mapconvert.processing.tileset.block.animation;

import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;

import java.util.List;


public class AnimationFrame
{
    private final String frameId;
    private final List<Pattern> patterns;

    AnimationFrame(String frameId, List<Pattern> patterns)
    {
        this.frameId = frameId;
        this.patterns = patterns;
    }

    public String getFrameId()
    {
        return frameId;
    }

    public List<Pattern> getPatterns()
    {
        return patterns;
    }

    public Pattern getPattern(int patternId)
    {
        return patterns.get(patternId);
    }

    public int getSize()
    {
        return patterns.size();
    }
}

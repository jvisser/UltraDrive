package com.ultradrive.mapconvert.processing.tileset.block.animation;

import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Objects;
import javax.annotation.Nonnull;


public class AnimationFrame implements Iterable<Pattern>
{
    private final String frameId;
    private final List<Pattern> patterns;

    AnimationFrame(String frameId, List<Pattern> patterns)
    {
        this.frameId = frameId;
        this.patterns = patterns;
    }

    public static class Builder
    {
        private String frameId;
        private List<Pattern> patterns;

        public Builder(String frameId)
        {
            this.frameId = frameId;
            this.patterns = new ArrayList<>();
        }

        private Builder(AnimationFrame animationFrame)
        {
            this.frameId = animationFrame.getFrameId();
            this.patterns = animationFrame.getPatterns();
        }

        public void setPatterns(List<Pattern> patterns)
        {
            this.patterns = patterns;
        }

        public void addPattern(Pattern pattern)
        {
            patterns.add(pattern);
        }

        public void setFrameId(String frameId)
        {
            this.frameId = frameId;
        }

        public AnimationFrame build()
        {
            return new AnimationFrame(frameId, patterns);
        }
    }

    @Override
    public boolean equals(Object o)
    {
        if (this == o)
        {
            return true;
        }
        if (o == null || getClass() != o.getClass())
        {
            return false;
        }
        final AnimationFrame that = (AnimationFrame) o;
        return frameId.equals(that.frameId) &&
               patterns.equals(that.patterns);
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(frameId, patterns);
    }

    @Override
    @Nonnull
    public Iterator<Pattern> iterator()
    {
        return patterns.iterator();
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

    public Builder builder()
    {
        return new Builder(this);
    }
}

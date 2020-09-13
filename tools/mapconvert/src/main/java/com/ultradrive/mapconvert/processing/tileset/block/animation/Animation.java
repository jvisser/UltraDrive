package com.ultradrive.mapconvert.processing.tileset.block.animation;

import java.util.Iterator;
import java.util.List;
import java.util.Map;
import javax.annotation.Nonnull;

import static java.util.stream.Collectors.toList;


public class Animation implements Iterable<AnimationFrameReference>
{
    private final String animationId;
    private final List<AnimationFrameReference> animationFrames;
    private final Map<String, Object> properties;
    private final int patternBaseId;

    public Animation(String animationId, List<AnimationFrameReference> animationFrames,
                     Map<String, Object> properties, int patternBaseId)
    {
        this.animationId = animationId;
        this.animationFrames = animationFrames;
        this.properties = properties;
        this.patternBaseId = patternBaseId;
    }

    @Override
    @Nonnull
    public Iterator<AnimationFrameReference> iterator()
    {
        return animationFrames.iterator();
    }

    public String getAnimationId()
    {
        return animationId;
    }

    public List<AnimationFrameReference> getAnimationFrameReferences()
    {
        return animationFrames;
    }

    public AnimationFrameReference getAnimationFrameReference(int frameId)
    {
        return animationFrames.get(frameId);
    }

    public Map<String, Object> getProperties()
    {
        return properties;
    }

    public int getPatternBaseId()
    {
        return patternBaseId;
    }

    public int getSize()
    {
        return animationFrames.get(0).getAnimationFrame().getSize();
    }

    Animation remap(Map<AnimationFrame, AnimationFrame> newFrames, int newPatternBaseId)
    {
        return new Animation(animationId,
                             animationFrames.stream()
                                     .map(animationFrameReference -> new AnimationFrameReference(
                                             newFrames.get(animationFrameReference.getAnimationFrame()),
                                             animationFrameReference.getFrameTime()))
                                     .collect(toList()),
                             properties, newPatternBaseId);
    }
}

package com.ultradrive.mapconvert.processing.tileset.block.animation;

import java.util.Iterator;
import java.util.List;
import java.util.Map;

import static java.util.stream.Collectors.toList;


public class Animation implements Iterable<AnimationFrameReference>
{
    private final String animationId;
    private final List<AnimationFrameReference> animationFrames;
    private final int patternBaseId;

    public Animation(String animationId, List<AnimationFrameReference> animationFrames, int patternBaseId)
    {
        this.animationId = animationId;
        this.animationFrames = animationFrames;
        this.patternBaseId = patternBaseId;
    }

    @Override
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
                             newPatternBaseId);
    }
}

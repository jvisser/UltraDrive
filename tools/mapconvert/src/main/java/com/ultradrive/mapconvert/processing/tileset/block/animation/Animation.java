package com.ultradrive.mapconvert.processing.tileset.block.animation;

import java.util.List;

public class Animation
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
}

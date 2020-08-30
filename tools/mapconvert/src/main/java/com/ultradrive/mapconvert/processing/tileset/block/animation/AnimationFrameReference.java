package com.ultradrive.mapconvert.processing.tileset.block.animation;

public class AnimationFrameReference
{
    private final AnimationFrame animationFrame;
    private final int frameTime;

    public AnimationFrameReference(AnimationFrame animationFrame, int frameTime)
    {
        this.animationFrame = animationFrame;
        this.frameTime = frameTime;
    }

    public AnimationFrame getAnimationFrame()
    {
        return animationFrame;
    }

    public int getFrameTime()
    {
        return frameTime;
    }

    public String getFrameId()
    {
        return animationFrame.getFrameId();
    }
}

package com.ultradrive.mapconvert.processing.tileset.block.animation;

import java.util.Objects;


public class AnimationFrameReference
{
    private final AnimationFrame animationFrame;
    private final int frameTime;

    public AnimationFrameReference(AnimationFrame animationFrame, int frameTime)
    {
        this.animationFrame = animationFrame;
        this.frameTime = frameTime;
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
        final AnimationFrameReference that = (AnimationFrameReference) o;
        return frameTime == that.frameTime &&
               animationFrame.equals(that.animationFrame);
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(animationFrame, frameTime);
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

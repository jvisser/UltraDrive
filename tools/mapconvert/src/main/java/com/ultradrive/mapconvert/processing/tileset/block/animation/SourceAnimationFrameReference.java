package com.ultradrive.mapconvert.processing.tileset.block.animation;

import java.util.Objects;


class SourceAnimationFrameReference
{
    private final SourceAnimationFrame animationFrame;
    private final int frameTime;

    public SourceAnimationFrameReference(SourceAnimationFrame animationFrame, int frameTime)
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
        final SourceAnimationFrameReference animationFrame = (SourceAnimationFrameReference) o;
        return this.animationFrame.equals(animationFrame.animationFrame);
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(animationFrame);
    }

    public SourceAnimationFrameReference merge(SourceAnimationFrameReference animationFrame)
    {
        return new SourceAnimationFrameReference(this.animationFrame, frameTime + animationFrame.frameTime);
    }

    public int getFrameTime()
    {
        return frameTime;
    }

    public SourceAnimationFrame getAnimationFrame()
    {
        return animationFrame;
    }
}

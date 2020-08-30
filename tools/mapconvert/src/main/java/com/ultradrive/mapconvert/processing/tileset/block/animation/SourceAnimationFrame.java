package com.ultradrive.mapconvert.processing.tileset.block.animation;

import java.util.List;
import java.util.Objects;


class SourceAnimationFrame
{
    private final List<Integer> frameGraphicIds;

    public SourceAnimationFrame(List<Integer> frameGraphicIds)
    {
        this.frameGraphicIds = frameGraphicIds;
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
        final SourceAnimationFrame that = (SourceAnimationFrame) o;
        return frameGraphicIds.equals(that.frameGraphicIds);
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(frameGraphicIds);
    }

    public List<Integer> getFrameGraphicIds()
    {
        return frameGraphicIds;
    }
}

package com.ultradrive.mapconvert.processing.tileset.block.animation;

import com.ultradrive.mapconvert.processing.tileset.block.Block;
import java.util.List;
import java.util.Map;
import java.util.Objects;


class SourceAnimation
{
    private final String animationId;
    private final List<Block> blocks;
    private final List<SourceAnimationFrameReference> animationFrameReferences;
    private final Map<String, Object> properties;

    SourceAnimation(String animationId, List<Block> blocks,
                    List<SourceAnimationFrameReference> animationFrameReferences,
                    Map<String, Object> properties)
    {
        this.animationId = animationId;
        this.blocks = blocks;
        this.animationFrameReferences = animationFrameReferences;
        this.properties = properties;
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
        final SourceAnimation sourceAnimation = (SourceAnimation) o;
        return animationId.equals(sourceAnimation.animationId);
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(animationId);
    }

    public String getAnimationId()
    {
        return animationId;
    }

    public List<Block> getBlocks()
    {
        return blocks;
    }

    public List<SourceAnimationFrameReference> getAnimationFrameReferences()
    {
        return animationFrameReferences;
    }

    public Map<String, Object> getProperties()
    {
        return properties;
    }
}

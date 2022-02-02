package com.ultradrive.mapconvert.processing.tileset.block.animation;

import com.ultradrive.mapconvert.processing.tileset.block.Block;
import java.util.List;
import java.util.Map;
import java.util.Objects;


class SourceAnimation
{
    private final String id;
    private final String type;
    private final List<Block> blocks;
    private final List<SourceAnimationFrameReference> animationFrameReferences;
    private final Map<String, Object> properties;

    SourceAnimation(String id, String type,
                    List<Block> blocks,
                    List<SourceAnimationFrameReference> animationFrameReferences,
                    Map<String, Object> properties)
    {
        this.id = id;
        this.type = type;
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
        return id.equals(sourceAnimation.id);
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(id);
    }

    public String getId()
    {
        return id;
    }

    public String getType()
    {
        return type;
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

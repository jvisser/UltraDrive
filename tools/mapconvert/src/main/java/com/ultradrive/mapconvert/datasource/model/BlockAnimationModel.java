package com.ultradrive.mapconvert.datasource.model;

import com.ultradrive.mapconvert.common.PropertySource;
import java.util.Collections;
import java.util.List;
import java.util.Map;


public final class BlockAnimationModel implements PropertySource
{
    private final String animationId;
    private final List<BlockAnimationFrameModel> animationFrames;
    private final Map<String, Object> properties;

    public static BlockAnimationModel empty()
    {
        return new BlockAnimationModel("", Collections.emptyList(), Collections.emptyMap());
    }

    public BlockAnimationModel(String animationId, List<BlockAnimationFrameModel> animationFrames,
                               Map<String, Object> properties)
    {
        this.animationId = animationId;
        this.animationFrames = animationFrames;
        this.properties = properties;
    }

    public String getAnimationId()
    {
        return animationId;
    }

    public List<BlockAnimationFrameModel> getAnimationFrames()
    {
        return animationFrames;
    }

    @Override
    public Map<String, Object> getProperties()
    {
        return properties;
    }
}

package com.ultradrive.mapconvert.datasource.model;

import com.ultradrive.mapconvert.common.PropertySource;
import java.util.Collections;
import java.util.List;
import java.util.Map;


public final class BlockAnimationModel implements PropertySource
{
    private final String id;
    private final String type;
    private final List<BlockAnimationFrameModel> animationFrames;
    private final Map<String, Object> properties;

    public static BlockAnimationModel empty()
    {
        return new BlockAnimationModel("", "", Collections.emptyList(), Collections.emptyMap());
    }

    public BlockAnimationModel(String id, String type,
                               List<BlockAnimationFrameModel> animationFrames,
                               Map<String, Object> properties)
    {
        this.id = id;
        this.type = type;
        this.animationFrames = animationFrames;
        this.properties = properties;
    }

    public String getId()
    {
        return id;
    }

    public String getType()
    {
        return type;
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

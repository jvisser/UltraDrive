package com.ultradrive.mapconvert.datasource.model;

import java.util.Collections;
import java.util.List;


public final class BlockAnimationModel
{
    private final String animationId;
    private final List<BlockAnimationFrameModel> animationFrames;

    public static BlockAnimationModel empty()
    {
        return new BlockAnimationModel("", Collections.emptyList());
    }

    public BlockAnimationModel(String animationId, List<BlockAnimationFrameModel> animationFrames)
    {
        this.animationId = animationId;
        this.animationFrames = animationFrames;
    }

    public String getAnimationId()
    {
        return animationId;
    }

    public List<BlockAnimationFrameModel> getAnimationFrames()
    {
        return animationFrames;
    }
}

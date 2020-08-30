package com.ultradrive.mapconvert.datasource.model;


public final class BlockAnimationFrameModel
{
    private final int graphicsId;
    private final int frameTime;

    public BlockAnimationFrameModel(int graphicsId, int frameTime)
    {
        this.graphicsId = graphicsId;
        this.frameTime = frameTime;
    }

    public int getGraphicsId()
    {
        return graphicsId;
    }

    public int getFrameTime()
    {
        return frameTime;
    }
}

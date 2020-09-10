package com.ultradrive.mapconvert.processing.tileset.block;

import com.ultradrive.mapconvert.datasource.model.BlockAnimationFrameModel;
import com.ultradrive.mapconvert.datasource.model.BlockAnimationModel;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import static java.util.stream.Collectors.toUnmodifiableList;


public class BlockAnimationMetaData
{
    private final String animationId;
    private final List<AnimationFrame> animationFrames;
    private final Map<String, Object> properties;

    public BlockAnimationMetaData(BlockAnimationModel animationModel)
    {
        this.animationId = animationModel.getAnimationId();
        this.properties = animationModel.getProperties();
        this.animationFrames = animationModel.getAnimationFrames().stream()
                .map(AnimationFrame::new)
                .collect(toUnmodifiableList());
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
        final BlockAnimationMetaData that = (BlockAnimationMetaData) o;
        return animationId.equals(that.animationId) &&
               animationFrames.equals(that.animationFrames);
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(animationId, animationFrames);
    }

    public int getFrameCount()
    {
        return animationFrames.size();
    }

    public AnimationFrame getFrame(int frameId)
    {
        return animationFrames.get(frameId);
    }

    public boolean isEmpty()
    {
        return animationFrames.isEmpty();
    }

    public String getAnimationId()
    {
        return animationId;
    }

    public Map<String, Object> getProperties()
    {
        return properties;
    }

    public List<AnimationFrame> getAnimationFrames()
    {
        return animationFrames;
    }

    public static class AnimationFrame
    {
        private final int graphicsId;
        private final int frameTime;

        public AnimationFrame(BlockAnimationFrameModel model)
        {
            this.graphicsId = model.getGraphicsId();
            this.frameTime = model.getFrameTime();
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
            final AnimationFrame that = (AnimationFrame) o;
            return graphicsId == that.graphicsId;
        }

        @Override
        public int hashCode()
        {
            return Objects.hash(graphicsId);
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
}

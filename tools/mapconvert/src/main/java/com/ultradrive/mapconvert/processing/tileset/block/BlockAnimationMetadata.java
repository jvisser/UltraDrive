package com.ultradrive.mapconvert.processing.tileset.block;

import com.ultradrive.mapconvert.datasource.model.BlockAnimationFrameModel;
import com.ultradrive.mapconvert.datasource.model.BlockAnimationModel;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import static java.util.stream.Collectors.toUnmodifiableList;


public class BlockAnimationMetadata
{
    private final String animationId;
    private final String type;
    private final List<AnimationFrame> animationFrames;
    private final Map<String, Object> properties;

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
        public int hashCode()
        {
            return Objects.hash(graphicsId);
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

        public int getFrameTime()
        {
            return frameTime;
        }

        public int getGraphicsId()
        {
            return graphicsId;
        }
    }

    public BlockAnimationMetadata(BlockAnimationModel animationModel)
    {
        this.animationId = animationModel.getId();
        this.type = animationModel.getType();
        this.properties = animationModel.getProperties();
        this.animationFrames = animationModel.getAnimationFrames().stream()
                .map(AnimationFrame::new)
                .collect(toUnmodifiableList());
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(animationId, animationFrames);
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
        final BlockAnimationMetadata that = (BlockAnimationMetadata) o;
        return animationId.equals(that.animationId) &&
               animationFrames.equals(that.animationFrames);
    }

    public AnimationFrame getFrame(int frameId)
    {
        return animationFrames.get(frameId);
    }

    public List<AnimationFrame> getAnimationFrames()
    {
        return animationFrames;
    }

    public String getAnimationId()
    {
        return animationId;
    }

    public int getFrameCount()
    {
        return animationFrames.size();
    }

    public Map<String, Object> getProperties()
    {
        return properties;
    }

    public String getType()
    {
        return type;
    }

    public boolean isEmpty()
    {
        return animationFrames.isEmpty();
    }
}

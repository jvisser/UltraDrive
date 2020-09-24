package com.ultradrive.mapconvert.processing.tileset.block.animation;

import com.google.common.collect.ImmutableList;
import com.ultradrive.mapconvert.processing.tileset.block.Block;
import java.util.List;
import java.util.Set;


public class AnimationBlockPostProcessingResult
{
    private final List<Block> blocks;
    private final List<Animation> animations;
    private final List<AnimationFrame> animationFrames;

    AnimationBlockPostProcessingResult(List<Block> blocks, List<Animation> animations, Set<AnimationFrame> animationFrames)
    {
        this.blocks = ImmutableList.copyOf(blocks);
        this.animations = ImmutableList.copyOf(animations);
        this.animationFrames = ImmutableList.copyOf(animationFrames);
    }

    public List<Block> getBlocks()
    {
        return blocks;
    }

    public List<Animation> getAnimations()
    {
        return animations;
    }

    public List<AnimationFrame> getAnimationFrames()
    {
        return animationFrames;
    }
}

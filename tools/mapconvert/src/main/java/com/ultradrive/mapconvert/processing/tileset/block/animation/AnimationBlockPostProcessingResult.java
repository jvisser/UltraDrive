package com.ultradrive.mapconvert.processing.tileset.block.animation;

import com.ultradrive.mapconvert.processing.tileset.block.Block;

import java.util.List;

public class AnimationBlockPostProcessingResult
{
    private final List<Block> blocks;
    private final List<Animation> animations;
    private final List<AnimationFrame> animationFrames;

    public AnimationBlockPostProcessingResult(List<Block> blocks, List<Animation> animations, List<AnimationFrame> animationFrames)
    {
        this.blocks = blocks;
        this.animations = animations;
        this.animationFrames = animationFrames;
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

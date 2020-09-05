package com.ultradrive.mapconvert.processing.tileset.block.animation;

import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternReference;
import java.util.List;
import java.util.Map;
import java.util.Set;

import static java.util.stream.Collectors.toSet;


class AnimationOptimizationResult
{
    private final Map<SourceAnimation, Animation> optimizedAnimations;
    private final Map<Animation, AnimationFrameOptimizationResult> animationOptimizationResultByAnimation;

    public AnimationOptimizationResult(
            Map<SourceAnimation, Animation> optimizedAnimations,
            Map<Animation, AnimationFrameOptimizationResult> animationOptimizationResultByAnimation)
    {
        this.optimizedAnimations = optimizedAnimations;
        this.animationOptimizationResultByAnimation = animationOptimizationResultByAnimation;
    }

    public Set<AnimationFrame> getAnimationFrames()
    {
        return animationOptimizationResultByAnimation.values().stream()
                .flatMap(optimizationGroups -> optimizationGroups.getOptimizedFrames().stream())
                .collect(toSet());
    }

    public List<PatternReference> getAnimationPatternReferences(Animation animation)
    {
        AnimationFrameOptimizationResult frameOptimizationResult = animationOptimizationResultByAnimation.get(animation);

        return frameOptimizationResult.getPatternReferences(animation.getPatternBaseId());
    }

    public List<Animation> getOptimizedAnimations()
    {
        return List.copyOf(optimizedAnimations.values());
    }

    public Map<SourceAnimation, Animation> getOptimizedAnimationMapping()
    {
        return optimizedAnimations;
    }
}

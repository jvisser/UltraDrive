package com.ultradrive.mapconvert.processing.tileset.block.animation;

import com.ultradrive.mapconvert.processing.tileset.block.pattern.allocator.PatternAllocator;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Set;

import static java.util.stream.Collectors.toList;
import static java.util.stream.Collectors.toSet;


class AnimationOptimizer
{
    private final Map<SourceAnimation, Animation> sourceAnimations;
    private final PatternAllocator patternAllocator;

    AnimationOptimizer(Map<SourceAnimation, Animation> sourceAnimations, PatternAllocator patternAllocator)
    {
        this.sourceAnimations = sourceAnimations;
        this.patternAllocator = patternAllocator;
    }

    public AnimationOptimizationResult optimize()
    {
        Map<SourceAnimation, Animation> optimizedAnimations = new HashMap<>();
        Map<Animation, AnimationFrameOptimizationResult> optimizationGroupsByAnimation = new HashMap<>();

        List<AnimationFrameOptimizationResult>
                animationFrameOptimizations = createFrameGroups().stream()
                .map(AnimationFrameOptimizationGroup::optimize)
                .collect(toList());

        for (Map.Entry<SourceAnimation, Animation> sourceAnimationAnimationEntry : sourceAnimations.entrySet())
        {
            Animation unoptimizedAnimation = sourceAnimationAnimationEntry.getValue();

            AnimationFrameOptimizationResult optimizationResultForAnimation =
                    findAnimationOptimizationResult(animationFrameOptimizations, unoptimizedAnimation);

            Animation optimizedAnimation = unoptimizedAnimation
                    .remap(optimizationResultForAnimation.getOptimizedAnimationFrameMapping(),
                           patternAllocator.reserve(optimizationResultForAnimation.getSize()));

            optimizedAnimations.put(sourceAnimationAnimationEntry.getKey(), optimizedAnimation);
            optimizationGroupsByAnimation.put(optimizedAnimation, optimizationResultForAnimation);
        }

        return new AnimationOptimizationResult(
                optimizedAnimations,
                optimizationGroupsByAnimation
        );
    }

    private AnimationFrameOptimizationResult findAnimationOptimizationResult(
            List<AnimationFrameOptimizationResult> animationFrameOptimizations,
            Animation unoptimizedAnimation)
    {
        return animationFrameOptimizations.stream()
                .filter(animationFrameOptimizationResult -> animationFrameOptimizationResult.isForAnimation(unoptimizedAnimation))
                .findAny().orElseThrow(() -> new NoSuchElementException("No matching animation frame group found for animation."));
    }

    private Set<AnimationFrameOptimizationGroup> createFrameGroups()
    {
        Map<AnimationFrame, Set<AnimationFrame>> frameGroupMap = new HashMap<>();
        for (Animation intermediateAnimation : sourceAnimations.values())
        {
            Set<Set<AnimationFrame>> sharedGroups = new HashSet<>();
            Set<AnimationFrame> currentGroup = new HashSet<>();

            for (AnimationFrameReference animationFrameReference : intermediateAnimation)
            {
                Set<AnimationFrame> group = frameGroupMap.get(animationFrameReference.getAnimationFrame());
                if (group == null)
                {
                    currentGroup.add(animationFrameReference.getAnimationFrame());
                }
                else
                {
                    sharedGroups.add(group);
                }
            }
            sharedGroups.add(currentGroup);

            Set<AnimationFrame> superGroup = sharedGroups.stream()
                    .flatMap(Collection::stream)
                    .collect(toSet());

            superGroup.forEach(animationFrame -> frameGroupMap.put(animationFrame, superGroup));
        }

        return frameGroupMap.values().stream()
                .distinct()
                .map(inputFrames -> new AnimationFrameOptimizationGroup(inputFrames, patternAllocator))
                .collect(toSet());
    }
}

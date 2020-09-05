package com.ultradrive.mapconvert.processing.tileset.block.animation;

import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternReference;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.IntStream;

import static java.util.stream.Collectors.toList;


class AnimationFrameOptimizationResult
{
    private final Set<Integer> dynamicPatternIndices;
    private final List<PatternReference> patternReferences;
    private final Map<AnimationFrame, AnimationFrame> optimizedAnimationFrameMapping;

    AnimationFrameOptimizationResult(Set<Integer> dynamicPatternIndices,
                                     List<PatternReference> patternReferences,
                                     Map<AnimationFrame, AnimationFrame> optimizedAnimationFrameMapping)
    {
        this.dynamicPatternIndices = dynamicPatternIndices;
        this.patternReferences = patternReferences;
        this.optimizedAnimationFrameMapping = optimizedAnimationFrameMapping;
    }

    public boolean isForAnimation(Animation unoptimizedAnimation)
    {
        return unoptimizedAnimation.getAnimationFrameReferences().stream()
                .anyMatch(animationFrameReference -> optimizedAnimationFrameMapping
                        .containsKey(animationFrameReference.getAnimationFrame()));
    }

    public List<PatternReference> getPatternReferences(int animationPatternBaseId)
    {
        return IntStream.range(0, patternReferences.size())
                .mapToObj(patternIndex ->
                          {
                              PatternReference reference = patternReferences.get(patternIndex);
                              if (dynamicPatternIndices.contains(patternIndex))
                              {
                                  PatternReference.Builder builder = reference.builder();
                                  builder.offsetReference(animationPatternBaseId);
                                  return builder.build();
                              }
                              return reference;
                          })
                .collect(toList());
    }

    public Set<AnimationFrame> getOptimizedFrames()
    {
        return new HashSet<>(optimizedAnimationFrameMapping.values());
    }

    Map<AnimationFrame, AnimationFrame> getOptimizedAnimationFrameMapping()
    {
        return optimizedAnimationFrameMapping;
    }
}

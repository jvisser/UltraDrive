package com.ultradrive.mapconvert.processing.tileset.block.animation;

import com.google.common.collect.Sets;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternReference;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternReferenceProducer;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.function.Function;

import static java.util.function.Predicate.not;
import static java.util.stream.Collectors.toList;
import static java.util.stream.Collectors.toMap;
import static java.util.stream.Collectors.toSet;


class AnimationFrameOptimizationGroup
{
    private final Set<AnimationFrame> inputFrames;
    private final PatternReferenceProducer patternReferenceProducer;

    AnimationFrameOptimizationGroup(Set<AnimationFrame> inputFrames, PatternReferenceProducer patternReferenceProducer)
    {
        this.inputFrames = inputFrames;
        this.patternReferenceProducer = patternReferenceProducer;
    }

    public AnimationFrameOptimizationResult optimize()
    {
        Set<IntermediateAnimationFrame> intermediateAnimationFrames = createIntermediateAnimationFrames();

        Map<IntermediateAnimationFrame, AnimationFrame.Builder> animationFrameBuilders =
                intermediateAnimationFrames.stream()
                        .collect(toMap(Function.identity(), intermediateAnimationFrame -> new AnimationFrame.Builder(
                                intermediateAnimationFrame.getSourceAnimationFrame().getFrameId())));

        int dynamicPatternCount = 0;
        Set<Integer> dynamicPatternIndices = new HashSet<>();
        PatternReference[] animationPatternReferences = new PatternReference[getFrameSize()];

        for (Set<Integer> patternSimilarityGroup : getPatternSimilarityProjection(intermediateAnimationFrames))
        {
            IntermediateAnimationFrame firstFrame = intermediateAnimationFrames.iterator().next();
            int firstPatternIndex = patternSimilarityGroup.iterator().next();

            PatternReference patternReference;
            if (isSimilarityGroupContentStatic(intermediateAnimationFrames, patternSimilarityGroup))
            {
                Pattern groupPattern = firstFrame.getPattern(firstPatternIndex);

                patternReference = patternReferenceProducer.getReference(groupPattern).build();
            }
            else
            {
                patternReference = new PatternReference(dynamicPatternCount++);

                animationFrameBuilders.forEach((intermediateAnimationFrame, builder) -> builder
                        .addPattern(intermediateAnimationFrame.getPattern(firstPatternIndex)));

                dynamicPatternIndices.addAll(patternSimilarityGroup);
            }

            patternSimilarityGroup.forEach(patternIndex -> animationPatternReferences[patternIndex] =
                    patternReference.reorient(firstFrame.getOrientation(patternIndex)));
        }

        return new AnimationFrameOptimizationResult(
                dynamicPatternIndices,
                Arrays.asList(animationPatternReferences),
                animationFrameBuilders.entrySet().stream()
                        .collect(toMap(entry -> entry.getKey().getSourceAnimationFrame(),
                                       entry -> entry.getValue().build())));
    }

    private Set<IntermediateAnimationFrame> createIntermediateAnimationFrames()
    {
        Set<IntermediateAnimationFrame> intermediateAnimationFrames = inputFrames.stream()
                .map(IntermediateAnimationFrame::new)
                .collect(toSet());

        IntermediateAnimationFrame lastFrame = null;
        IntermediateAnimationFrame firstFrame = null;
        for (IntermediateAnimationFrame intermediateAnimationFrame : intermediateAnimationFrames)
        {
            if (lastFrame == null)
            {
                firstFrame = intermediateAnimationFrame;
            }
            else
            {
                intermediateAnimationFrame.align(lastFrame);
            }
            lastFrame = intermediateAnimationFrame;
        }

        if (firstFrame != null)
        {
            firstFrame.align(lastFrame);
        }

        return intermediateAnimationFrames;
    }

    private boolean isSimilarityGroupContentStatic(Set<IntermediateAnimationFrame> intermediateAnimationFrames,
                                                   Set<Integer> patternSimilarityGroup)
    {
        int anyGroupPatternId = patternSimilarityGroup.iterator().next();

        Pattern lastPattern = null;
        for (IntermediateAnimationFrame intermediateAnimationFrame : intermediateAnimationFrames)
        {
            Pattern currentPattern = intermediateAnimationFrame.getPattern(anyGroupPatternId);
            if (lastPattern != null && !Objects.equals(lastPattern, currentPattern))
            {
                return false;
            }

            lastPattern = currentPattern;
        }

        return true;
    }

    private Set<Set<Integer>> getPatternSimilarityProjection(Set<IntermediateAnimationFrame> intermediateAnimationFrames)
    {
        List<Set<Set<Integer>>> patternSimilarityGroupsPerFrame =
                intermediateAnimationFrames.stream().map(IntermediateAnimationFrame::getPatternSimilarityGroups)
                        .collect(toList());

        return splitByOrientationDifference(intermediateAnimationFrames,
                                            projectFramePatternSimilarityGroups(patternSimilarityGroupsPerFrame));
    }

    private Set<Set<Integer>> projectFramePatternSimilarityGroups(List<Set<Set<Integer>>> similarityGroups)
    {
        Set<Set<Integer>> similarityProjection = similarityGroups.get(0);
        for (int i = 1; i < similarityGroups.size(); i++)
        {
            Set<Set<Integer>> currentSimilarityProjection = new HashSet<>();
            Set<Set<Integer>> nextSimilarityProjection = similarityGroups.get(i);

            for (Set<Integer> similarIndices : similarityProjection)
            {
                for (Set<Integer> nextSimilarIndices : nextSimilarityProjection)
                {
                    Sets.SetView<Integer> intersection = Sets.intersection(nextSimilarIndices, similarIndices);
                    if (!intersection.isEmpty())
                    {
                        currentSimilarityProjection.add(intersection);
                        currentSimilarityProjection.add(Sets.difference(similarIndices, nextSimilarIndices));
                        currentSimilarityProjection.add(Sets.difference(nextSimilarIndices, similarIndices));
                    }
                }
            }

            similarityProjection = currentSimilarityProjection;
        }

        return similarityProjection.stream()
                .filter(not(Set::isEmpty))
                .collect(toSet());
    }

    private Set<Set<Integer>> splitByOrientationDifference(
            Set<IntermediateAnimationFrame> intermediateAnimationFrames,
            Set<Set<Integer>> similarityGroups)
    {
        Set<Set<Integer>> similarityGroupsSplitByOrientation = new HashSet<>();
        for (Set<Integer> similarityGroup : similarityGroups)
        {
            Set<Integer> differentGroup = new HashSet<>();
            Set<Integer> sameGroup = new HashSet<>();
            for (Integer index : similarityGroup)
            {
                boolean same = true;

                IntermediateAnimationFrame lastFrame = null;
                for (IntermediateAnimationFrame intermediateAnimationFrame : intermediateAnimationFrames)
                {
                    if (lastFrame != null && lastFrame.getOrientation(index) != intermediateAnimationFrame.getOrientation(index))
                    {
                        differentGroup.add(index);
                        same = false;
                        break;
                    }
                    lastFrame = intermediateAnimationFrame;
                }

                if (same)
                {
                    sameGroup.add(index);
                }
            }
            similarityGroupsSplitByOrientation.add(differentGroup);
            similarityGroupsSplitByOrientation.add(sameGroup);
        }

        return similarityGroupsSplitByOrientation.stream()
                .filter(not(Set::isEmpty))
                .collect(toSet());
    }

    private int getFrameSize()
    {
        return inputFrames.iterator().next().getPatterns().size();
    }
}

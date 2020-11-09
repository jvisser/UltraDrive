package com.ultradrive.mapconvert.processing.tileset.block.animation;

import com.google.common.collect.Sets;
import com.ultradrive.mapconvert.common.orientable.Orientation;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternReference;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternReferenceProducer;
import com.ultradrive.mapconvert.processing.tileset.common.TileReference;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.Stack;
import java.util.function.Function;
import java.util.stream.Collectors;

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

            if (isSimilarityGroupContentStatic(intermediateAnimationFrames, patternSimilarityGroup))
            {
                Pattern groupPattern = firstFrame.getPattern(firstPatternIndex)
                        .reorient(firstFrame.getOrientation(firstPatternIndex));

                PatternReference patternReference = patternReferenceProducer.getReference(groupPattern).build();

                patternSimilarityGroup.forEach(patternIndex -> animationPatternReferences[patternIndex] =
                        patternReference.reorient(firstFrame.getOrientation(patternIndex)));
            }
            else if (isSimilarityGroupContentMultiOriented(intermediateAnimationFrames, patternSimilarityGroup))
            {
                for (Integer patternIndex : patternSimilarityGroup)
                {
                    PatternReference patternReference = new PatternReference(dynamicPatternCount++);

                    animationFrameBuilders.forEach((intermediateAnimationFrame, builder) -> builder
                            .addPattern(intermediateAnimationFrame.getPattern(patternIndex)
                                                .reorient(firstFrame.getOrientation(patternIndex))));

                    animationPatternReferences[patternIndex] = patternReference.reorient(firstFrame.getOrientation(patternIndex));

                }
                dynamicPatternIndices.addAll(patternSimilarityGroup);
            }
            else
            {
                PatternReference patternReference = new PatternReference(dynamicPatternCount++);

                animationFrameBuilders.forEach((intermediateAnimationFrame, builder) -> builder
                        .addPattern(intermediateAnimationFrame.getPattern(firstPatternIndex)
                                            .reorient(firstFrame.getOrientation(firstPatternIndex))));

                dynamicPatternIndices.addAll(patternSimilarityGroup);

                patternSimilarityGroup.forEach(patternIndex -> animationPatternReferences[patternIndex] =
                        patternReference.reorient(firstFrame.getOrientation(patternIndex)));
            }

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

    private boolean isSimilarityGroupContentMultiOriented(Set<IntermediateAnimationFrame> intermediateAnimationFrames,
                                                          Set<Integer> patternSimilarityGroup)
    {
        List<Orientation> lastOrientations = null;
        for (IntermediateAnimationFrame intermediateAnimationFrame : intermediateAnimationFrames)
        {
            List<Orientation> orientations = patternSimilarityGroup.stream()
                    .map(intermediateAnimationFrame::getOrientation)
                    .collect(toList());

            if (lastOrientations != null && !Objects.equals(lastOrientations, orientations))
            {
                return true;
            }
            lastOrientations = orientations;
        }
        return false;
    }

    private Set<Set<Integer>> getPatternSimilarityProjection(Set<IntermediateAnimationFrame> intermediateAnimationFrames)
    {
        List<Set<Set<Integer>>> patternSimilarityGroupsPerFrame =
                intermediateAnimationFrames.stream().map(IntermediateAnimationFrame::getPatternSimilarityGroups)
                        .collect(toList());

        return splitByOrientationDifference(intermediateAnimationFrames,
                                            projectFramePatternSimilarityGroups(patternSimilarityGroupsPerFrame));
    }

    private Set<Set<Integer>> projectFramePatternSimilarityGroups(List<Set<Set<Integer>>> similarityGroupsPerFrame)
    {
        Map<Integer, Set<Integer>> map = new HashMap<>();

        for (Set<Set<Integer>> currentFrameSimilarityGroup : similarityGroupsPerFrame)
        {
            if (map.isEmpty())
            {
                currentFrameSimilarityGroup
                        .forEach(frameSimilarities -> frameSimilarities
                                .forEach(patternIndex -> map.put(patternIndex, frameSimilarities)));
            }
            else
            {
                Stack<Set<Integer>> currentFrameSimilarities = new Stack<>();
                currentFrameSimilarities.addAll(currentFrameSimilarityGroup);

                while (!currentFrameSimilarities.isEmpty())
                {
                    Set<Set<Integer>> pendingFrameSimilarities = new HashSet<>();
                    while (!currentFrameSimilarities.isEmpty())
                    {
                        Set<Integer> groupSimilarity = currentFrameSimilarities.pop();
                        Set<Set<Integer>> intersectingSimilarityProjections = groupSimilarity.stream()
                                .map(map::get)
                                .collect(toSet());

                        for (Set<Integer> intersectingSimilarityProjection : intersectingSimilarityProjections)
                        {
                            Set<Integer> intersection = Sets.intersection(intersectingSimilarityProjection, groupSimilarity);
                            if (!intersection.equals(intersectingSimilarityProjection))
                            {
                                intersection.forEach(patternIndex -> map.put(patternIndex, intersection));

                                Sets.SetView<Integer> remainingProjection =
                                        Sets.difference(intersectingSimilarityProjection, groupSimilarity);
                                remainingProjection.forEach(patternIndex -> map.put(patternIndex, remainingProjection));

                                pendingFrameSimilarities
                                        .add(Sets.difference(groupSimilarity, intersectingSimilarityProjection));
                            }
                        }
                    }

                    currentFrameSimilarities = pendingFrameSimilarities.stream()
                            .filter(similarities -> !similarities.isEmpty())
                            .collect(Collectors.toCollection(Stack::new));
                }
            }
        }

        return new HashSet<>(map.values());
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

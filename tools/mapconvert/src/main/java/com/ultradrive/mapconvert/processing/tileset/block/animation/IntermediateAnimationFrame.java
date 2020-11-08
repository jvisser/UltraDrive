package com.ultradrive.mapconvert.processing.tileset.block.animation;

import com.ultradrive.mapconvert.common.orientable.Orientation;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternPool;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternReference;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.IntStream;
import java.util.stream.StreamSupport;

import static java.util.stream.Collectors.groupingBy;
import static java.util.stream.Collectors.toList;
import static java.util.stream.Collectors.toSet;


class IntermediateAnimationFrame
{
    private final AnimationFrame sourceAnimationFrame;
    private final PatternPool patternPool;
    private final List<PatternReference> patternReferences;

    IntermediateAnimationFrame(AnimationFrame sourceAnimationFrame)
    {
        this.sourceAnimationFrame = sourceAnimationFrame;

        this.patternPool = new PatternPool();
        this.patternReferences = StreamSupport.stream(sourceAnimationFrame.spliterator(), false)
                .map(pattern -> patternPool.getReference(pattern).build())
                .collect(toList());
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
        final IntermediateAnimationFrame that = (IntermediateAnimationFrame) o;
        return sourceAnimationFrame.equals(that.sourceAnimationFrame);
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(sourceAnimationFrame);
    }

    public void align(IntermediateAnimationFrame otherFrame)
    {
        IntStream.range(0, patternReferences.size())
                .forEach(patternIndex ->
                         {
                             PatternReference thisReference = patternReferences.get(patternIndex);
                             PatternReference otherReference = otherFrame.patternReferences.get(patternIndex);

                             if (thisReference.getOrientation() != otherReference.getOrientation())
                             {
                                 Pattern pattern = patternPool.get(thisReference.getReferenceId());

                                 if (pattern.reorient(thisReference.getOrientation()).equals(
                                         pattern.reorient(otherReference.getOrientation())))
                                 {
                                     PatternReference.Builder newReferenceBuilder = thisReference.builder();
                                     newReferenceBuilder.setOrientation(otherReference.getOrientation());
                                     patternReferences.set(patternIndex, newReferenceBuilder.build());
                                 }
                             }
                         });
    }

    public Set<Set<Integer>> getPatternSimilarityGroups()
    {
        Map<Integer, Set<Integer>> patternReferencesByPattern = IntStream.range(0, patternReferences.size())
                .boxed()
                .collect(groupingBy(o -> patternReferences.get(o).getReferenceId(), toSet()));

        return new HashSet<>(patternReferencesByPattern.values());
    }

    public Orientation getOrientation(int index)
    {
        return patternReferences.get(index).getOrientation();
    }

    public AnimationFrame getSourceAnimationFrame()
    {
        return sourceAnimationFrame;
    }

    public Pattern getPattern(int patternId)
    {
        PatternReference reference = patternReferences.get(patternId);

        return patternPool.get(reference.getReferenceId())
                .reorient(reference.getOrientation());
    }

    public List<PatternReference> getPatternReferences()
    {
        return patternReferences;
    }
}




package com.ultradrive.mapconvert.processing.tileset.block.pattern.allocator;

import com.google.common.collect.ImmutableList;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;
import java.util.Iterator;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Objects;
import java.util.Optional;
import javax.annotation.Nonnull;

import static java.lang.String.format;


public class PatternAllocation implements Iterable<PatternAllocationArea>
{
    private final List<PatternAllocationArea> patternAllocationAreas;

    PatternAllocation(List<PatternAllocationArea> patternAllocationAreas)
    {
        this.patternAllocationAreas = ImmutableList.copyOf(patternAllocationAreas);
    }

    @Nonnull
    @Override
    public Iterator<PatternAllocationArea> iterator()
    {
        return patternAllocationAreas.iterator();
    }

    public int getSize()
    {
        return patternAllocationAreas.stream()
                .map(PatternAllocationArea::totalPatternAllocationSize)
                .reduce(0, Integer::sum);
    }

    public Optional<Pattern> getPattern(int patternReferenceId)
    {
        return patternAllocationAreas.stream()
                .filter(allocation -> allocation.hasPattern(patternReferenceId))
                .map(allocation -> allocation.getPattern(patternReferenceId))
                .findFirst();
    }

    public PatternAllocationArea getAllocationArea(String id)
    {
        return patternAllocationAreas.stream()
                .filter(patternAllocationArea -> Objects.equals(patternAllocationArea.getId(), id))
                .findFirst()
                .orElseThrow(() -> new NoSuchElementException(format("Area with id '%s' not found", id)));

    }

    public List<PatternAllocationArea> getPatternAllocationAreas()
    {
        return patternAllocationAreas;
    }
}

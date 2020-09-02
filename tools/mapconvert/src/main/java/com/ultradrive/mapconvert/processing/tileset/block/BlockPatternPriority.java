package com.ultradrive.mapconvert.processing.tileset.block;

import com.ultradrive.mapconvert.common.Point;
import com.ultradrive.mapconvert.common.orientable.Invariant;
import com.ultradrive.mapconvert.common.orientable.Orientable;
import com.ultradrive.mapconvert.common.orientable.OrientableGrid;
import com.ultradrive.mapconvert.common.orientable.Orientation;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternPriority;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

import static com.ultradrive.mapconvert.common.orientable.Invariant.of;


class BlockPatternPriority implements Orientable<BlockPatternPriority>
{
    private final OrientableGrid<Invariant<PatternPriority>> patternPriorities;

    public BlockPatternPriority(int priorityMask, int width)
    {
        List<Invariant<PatternPriority>> priorities = IntStream.range(0, width * width)
                .mapToObj(bitNumber -> of(PatternPriority.fromInt(priorityMask & (1 << bitNumber))))
                .collect(Collectors.toList());

        patternPriorities = OrientableGrid.symmetricallyOptimized(priorities);
    }

    private BlockPatternPriority(OrientableGrid<Invariant<PatternPriority>> patternPriorities)
    {
        this.patternPriorities = patternPriorities;
    }

    @Override
    public BlockPatternPriority reorient(Orientation orientation)
    {
        if (isInvariant() || orientation == Orientation.DEFAULT)
        {
            return this;
        }

        return new BlockPatternPriority(patternPriorities.reorient(orientation));
    }

    @Override
    public boolean isInvariant()
    {
        return patternPriorities.isInvariant();
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
        final BlockPatternPriority that = (BlockPatternPriority) o;
        return patternPriorities.equals(that.patternPriorities);
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(patternPriorities);
    }

    public PatternPriority getPriority(Point point)
    {
        return patternPriorities.getValue(point).getValue();
    }

    public PatternPriority getPriority(int index)
    {
        return patternPriorities.getValue(index).getValue();
    }
}

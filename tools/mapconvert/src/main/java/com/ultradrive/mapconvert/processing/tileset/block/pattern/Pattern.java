package com.ultradrive.mapconvert.processing.tileset.block.pattern;

import com.ultradrive.mapconvert.common.Invariant;
import com.ultradrive.mapconvert.common.OrientableGrid;
import com.ultradrive.mapconvert.common.OrientablePoolable;
import com.ultradrive.mapconvert.common.Orientation;
import com.ultradrive.mapconvert.common.Point;
import java.util.Iterator;
import java.util.List;
import java.util.Objects;

import static com.ultradrive.mapconvert.common.Invariant.of;
import static java.lang.String.format;
import static java.util.stream.Collectors.toList;


public class Pattern implements OrientablePoolable<Pattern, PatternReference>, Iterable<PatternRow>
{
    public static final int DIMENSION_SIZE = 8;
    public static final int PIXEL_COUNT = DIMENSION_SIZE * DIMENSION_SIZE;
    public static final int PIXEL_VALUE_MASK = 0x0f;
    public static final int PIXEL_VALUE_BITS = 4;

    private final OrientableGrid<Invariant<Integer>> pixels;

    public Pattern(List<Integer> pixels)
    {
        if (pixels.size() != PIXEL_COUNT)
        {
            throw new IllegalArgumentException(
                    format("Invalid number of pixels. Expected %d but got %d", PIXEL_COUNT, pixels.size()));
        }

        this.pixels = OrientableGrid.symmetricallyOptimized(pixels.stream()
                                                                    .map(pixel -> of(pixel & PIXEL_VALUE_MASK))
                                                                    .collect(toList()));
    }

    private Pattern(OrientableGrid<Invariant<Integer>> pixels)
    {
        this.pixels = pixels;
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
        final Pattern pattern = (Pattern) o;
        return pixels.equals(pattern.pixels);
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(pixels);
    }

    @Override
    public Pattern reorient(Orientation orientation)
    {
        if (isInvariant() || orientation == Orientation.DEFAULT)
        {
            return this;
        }

        return new Pattern(pixels.reorient(orientation));
    }

    @Override
    public boolean isInvariant()
    {
        return pixels.isInvariant();
    }

    @Override
    public PatternReference.Builder referenceBuilder()
    {
        return new PatternReference.Builder();
    }

    @Override
    public Iterator<PatternRow> iterator()
    {
        return new PatternRowIterator(this);
    }

    public int getValue(Point point)
    {
        return pixels.getValue(point).getValue();
    }

    public PatternRow getPatternRow(int row)
    {
        return new PatternRow(pixels.getRow(row).stream()
                                      .map(Invariant::getValue)
                                      .collect(toList()));
    }
}
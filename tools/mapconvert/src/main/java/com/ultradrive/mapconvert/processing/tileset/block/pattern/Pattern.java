package com.ultradrive.mapconvert.processing.tileset.block.pattern;

import com.ultradrive.mapconvert.common.Point;
import com.ultradrive.mapconvert.common.orientable.Invariant;
import com.ultradrive.mapconvert.common.orientable.OrientableGrid;
import com.ultradrive.mapconvert.common.orientable.OrientablePoolable;
import com.ultradrive.mapconvert.common.orientable.Orientation;
import java.util.Iterator;
import java.util.List;
import java.util.Objects;
import javax.annotation.Nonnull;

import static com.ultradrive.mapconvert.common.orientable.Invariant.of;
import static java.lang.String.format;
import static java.util.stream.Collectors.toList;


public class Pattern implements OrientablePoolable<Pattern, PatternReference>, Iterable<PatternRow>
{
    public static final int DIMENSION_SIZE = 8;
    public static final int PIXEL_COUNT = DIMENSION_SIZE * DIMENSION_SIZE;
    public static final int PIXEL_VALUE_MASK = 0x0f;
    public static final int PIXEL_VALUE_BITS = 4;

    private final OrientableGrid<Invariant<Integer>> pixels;
    private final boolean transparent;

    public Pattern(List<Integer> pixels)
    {
        if (pixels.size() != PIXEL_COUNT)
        {
            throw new IllegalArgumentException(
                    format("Invalid number of pixels. Expected %d but got %d", PIXEL_COUNT, pixels.size()));
        }

        this.transparent = pixels.stream().reduce(0, Integer::sum) == 0;
        this.pixels = OrientableGrid.symmetricallyOptimized(pixels.stream()
                                                                    .map(pixel -> of(pixel & PIXEL_VALUE_MASK))
                                                                    .collect(toList()));
    }

    private Pattern(OrientableGrid<Invariant<Integer>> pixels, boolean transparent)
    {
        this.pixels = pixels;
        this.transparent = transparent;
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

        return new Pattern(pixels.reorient(orientation), transparent);
    }

    @Override
    public boolean isInvariant()
    {
        return pixels.isInvariant();
    }

    @Override
    public PatternReference.Builder referenceBuilder()
    {
        PatternReference.Builder builder = new PatternReference.Builder();
        builder.setEmpty(transparent);
        return builder;
    }

    @Override
    @Nonnull
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

    public boolean isTransparent()
    {
        return transparent;
    }
}

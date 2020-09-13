package com.ultradrive.mapconvert.common.orientable;

import com.ultradrive.mapconvert.common.Point;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Objects;
import javax.annotation.Nonnull;


public class OrientableGrid<T extends Orientable<T>> implements Orientable<OrientableGrid<T>>, Iterable<T>
{
    private final int dimensionSize;
    private final List<T> elements;

    private static class SymmetricallyOptimizedOrientableGrid<T extends Orientable<T>> extends OrientableGrid<T>
    {
        private final boolean invariant;

        public SymmetricallyOptimizedOrientableGrid(List<T> elements)
        {
            super(elements);

            OrientableGrid<T> horizontalFlipped = reorient(Orientation.HORIZONTAL_FLIP);
            OrientableGrid<T> verticalFlipped = reorient(Orientation.VERTICAL_FLIP);

            invariant = elements.isEmpty() || Objects.equals(horizontalFlipped, verticalFlipped) && equals(horizontalFlipped);
        }

        @Override
        public boolean isInvariant()
        {
            return invariant;
        }
    }

    public static <T extends Orientable<T>> OrientableGrid<T> symmetricallyOptimized(List<T> elements)
    {
        return new SymmetricallyOptimizedOrientableGrid<>(elements);
    }

    public OrientableGrid(List<T> elements)
    {
        double squareRoot = Math.sqrt(elements.size());
        if (Math.floor(squareRoot) != squareRoot)
        {
            throw new IllegalArgumentException("Elements must represent an integer sized square");
        }

        this.dimensionSize = (int) squareRoot;
        this.elements = elements;
    }

    private OrientableGrid(int dimensionSize, List<T> elements)
    {
        this.dimensionSize = dimensionSize;
        this.elements = elements;
    }

    @Override
    public boolean equals(Object o)
    {
        if (this == o)
        {
            return true;
        }
        if (!(o instanceof OrientableGrid<?> that))
        {
            return false;
        }
        return dimensionSize == that.dimensionSize &&
               elements.equals(that.elements);
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(dimensionSize, elements);
    }

    @Override
    public OrientableGrid<T> reorient(Orientation orientation)
    {
        if (isInvariant() || orientation == Orientation.DEFAULT)
        {
            return this;
        }

        List<T> reorientedElements = new ArrayList<>(elements.size());
        for (int y = 0; y < dimensionSize; y++)
        {
            for (int x = 0; x < dimensionSize; x++)
            {
                Point translatedPoint = orientation.translate(new Point(x, y), dimensionSize);

                reorientedElements.add(getValue(translatedPoint).reorient(orientation));
            }
        }

        return new OrientableGrid<>(dimensionSize, reorientedElements);
    }

    @Override
    @Nonnull
    public Iterator<T> iterator()
    {
        return elements.iterator();
    }

    public T getValue(int index)
    {
        return elements.get(index);
    }

    public T getValue(Point point)
    {
        return getValue(point.getY() * dimensionSize + point.getX());
    }

    public int getDimensionSize()
    {
        return dimensionSize;
    }

    public int getSize()
    {
        return elements.size();
    }

    public List<T> getRow(int row)
    {
        int fromIndex = row * dimensionSize;
        int toIndex = fromIndex + dimensionSize;

        return elements.subList(fromIndex, toIndex);
    }
}

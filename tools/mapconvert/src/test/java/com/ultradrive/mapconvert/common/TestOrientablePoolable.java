package com.ultradrive.mapconvert.common;

import java.util.List;
import java.util.Objects;

public class TestOrientablePoolable implements OrientablePoolable<TestOrientablePoolable, TestOrientablePoolableReference>
{
    private final OrientableGrid<TestOrientable> grid;

    public TestOrientablePoolable(TestOrientable... elements)
    {
        grid = new OrientableGrid<>(List.of(elements));
    }

    private TestOrientablePoolable(OrientableGrid<TestOrientable> grid)
    {
        this.grid = grid;
    }

    @Override
    public boolean equals(Object o)
    {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        TestOrientablePoolable that = (TestOrientablePoolable) o;
        return grid.equals(that.grid);
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(grid);
    }

    @Override
    public TestOrientablePoolableReference.Builder referenceBuilder()
    {
        return new TestOrientablePoolableReference.Builder();
    }

    @Override
    public TestOrientablePoolable reorient(Orientation orientation)
    {
        return new TestOrientablePoolable(grid.reorient(orientation));
    }
}

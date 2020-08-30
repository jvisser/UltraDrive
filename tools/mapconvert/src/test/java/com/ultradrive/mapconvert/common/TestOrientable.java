package com.ultradrive.mapconvert.common;

import java.util.Objects;

public class TestOrientable implements Orientable<TestOrientable>
{
    private final int id;
    private final Orientation orientation;

    public TestOrientable(int id, Orientation orientation)
    {
        this.id = id;
        this.orientation = orientation;
    }

    public static TestOrientable of(int id)
    {
        return new TestOrientable(id, Orientation.DEFAULT);
    }

    @Override
    public boolean equals(Object o)
    {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        TestOrientable that = (TestOrientable) o;
        return id == that.id &&
                orientation == that.orientation;
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(id, orientation);
    }

    @Override
    public TestOrientable reorient(Orientation orientation)
    {
        return new TestOrientable(id, this.orientation.translate(orientation));
    }
}

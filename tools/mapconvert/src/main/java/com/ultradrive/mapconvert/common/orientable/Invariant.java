package com.ultradrive.mapconvert.common.orientable;

import java.util.Objects;


public final class Invariant<T> implements Orientable<Invariant<T>>
{
    private final T value;

    public static <T> Invariant<T> of(T value)
    {
        return new Invariant<>(value);
    }

    public Invariant(T value)
    {
        this.value = value;
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
        final Invariant<?> invariant = (Invariant<?>) o;
        return Objects.equals(value, invariant.value);
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(value);
    }

    @Override
    public Invariant<T> reorient(Orientation orientation)
    {
        return this;
    }

    @Override
    public String toString()
    {
        return String.valueOf(value);
    }

    @Override
    public boolean isInvariant()
    {
        return true;
    }

    public T getValue()
    {
        return value;
    }
}

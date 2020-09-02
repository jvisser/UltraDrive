package com.ultradrive.mapconvert.common.orientable;

public interface Orientable<T extends Orientable<?>>
{
    default Symmetry getSymmetry(T other)
    {
        if (equals(other))
        {
            return Symmetry.SYMMETRICAL;
        }

        if (!isInvariant())
        {
            if (equals(other.reorient(Orientation.HORIZONTAL_FLIP)))
            {
                return Symmetry.HORIZONTAL_MIRRORED;
            }

            if (equals(other.reorient(Orientation.VERTICAL_FLIP)))
            {
                return Symmetry.VERTICAL_MIRRORED;
            }

            if (equals(other.reorient(Orientation.HORIZONTAL_VERTICAL_FLIP)))
            {
                return Symmetry.HORIZONTAL_VERTICAL_MIRRORED;
            }
        }

        return Symmetry.ASYMMETRICAL;
    }

    default boolean isInvariant()
    {
        return false;
    }

    T reorient(Orientation orientation);
}

package com.ultradrive.mapconvert.common;

import static org.junit.jupiter.api.Assertions.assertEquals;


public class SymmetryTester<T extends Orientable<T>>
{
    public void testSymmetry(T orientable, T orientableSameByValue, T orientableDifferentByValue)
    {
        assertEquals(Symmetry.SYMMETRICAL, orientable.getSymmetry(orientable));
        assertEquals(Symmetry.SYMMETRICAL, orientable.getSymmetry(orientableSameByValue));
        assertEquals(Symmetry.ASYMMETRICAL, orientable.getSymmetry(orientableDifferentByValue));
        assertEquals(Symmetry.HORIZONTAL_MIRRORED,
                     orientable.getSymmetry(orientable.reorient(Orientation.HORIZONTAL_FLIP)));
        assertEquals(Symmetry.VERTICAL_MIRRORED,
                     orientable.getSymmetry(orientable.reorient(Orientation.VERTICAL_FLIP)));
        assertEquals(Symmetry.HORIZONTAL_VERTICAL_MIRRORED,
                     orientable.getSymmetry(orientable.reorient(Orientation.HORIZONTAL_VERTICAL_FLIP)));
    }

}

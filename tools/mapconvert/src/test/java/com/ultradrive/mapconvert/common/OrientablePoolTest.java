package com.ultradrive.mapconvert.common;

import org.junit.jupiter.api.Test;

import static com.ultradrive.mapconvert.common.TestOrientable.of;
import static org.junit.jupiter.api.Assertions.assertEquals;


class OrientablePoolTest
{
    @Test
    void getReference()
    {
        OrientablePool<TestOrientablePoolable, TestOrientablePoolableReference> pool = new OrientablePool<>();

        TestOrientablePoolable pattern = createOrientablePoolable();
        TestOrientablePoolableReference patternReference = pool.getReference(pattern).build();

        assertEquals(patternReference.getReferenceId(), pool.getSize() - 1);
        assertEquals(patternReference.getOrientation(), Orientation.DEFAULT);

        testReorientation(pool, pattern, Orientation.DEFAULT);
        testReorientation(pool, pattern, Orientation.HORIZONTAL_FLIP);
        testReorientation(pool, pattern, Orientation.VERTICAL_FLIP);
        testReorientation(pool, pattern, Orientation.HORIZONTAL_VERTICAL_FLIP);
    }

    private void testReorientation(OrientablePool<TestOrientablePoolable, TestOrientablePoolableReference> pool, TestOrientablePoolable orientablePoolable, Orientation orientation)
    {
        TestOrientablePoolableReference originalReference = pool.getReference(orientablePoolable).build();

        TestOrientablePoolable reorientedPattern = orientablePoolable.reorient(orientation);
        TestOrientablePoolableReference patternReference = pool.getReference(reorientedPattern).build();

        assertEquals(originalReference.getReferenceId(), patternReference.getReferenceId());
        assertEquals(orientation, patternReference.getOrientation());
    }

    private TestOrientablePoolable createOrientablePoolable()
    {
        return new TestOrientablePoolable(of(1), of(2), of(3), of(4));
    }
}
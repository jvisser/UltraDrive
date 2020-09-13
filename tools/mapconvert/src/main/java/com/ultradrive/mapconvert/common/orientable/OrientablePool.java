package com.ultradrive.mapconvert.common.orientable;

import com.google.common.collect.ImmutableList;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;


public class OrientablePool<T extends OrientablePoolable<T, R>, R extends OrientableReference<R>> implements Iterable<T>
{
    private final Map<T, R> deduplicationIndex = new HashMap<>();
    private final List<T> orientableCache = new ArrayList<>();

    @Override
    public Iterator<T> iterator()
    {
        return orientableCache.iterator();
    }

    public R.Builder<R> getReference(T orientable)
    {
        R reference = deduplicationIndex.get(orientable);
        if (reference != null)
        {
            return reference.builder();
        }

        if (!orientable.isInvariant())
        {
            for (Orientation orientation : Orientation.values())
            {
                T reoriented = orientable.reorient(orientation);

                R existingReference = deduplicationIndex.get(reoriented);
                if (existingReference != null)
                {
                    R orientableReference = existingReference.reorient(orientation);

                    deduplicationIndex.put(orientable, orientableReference);

                    return orientableReference.builder();
                }
            }
        }

        R.Builder<R> newOrientableReferenceBuilder = orientable.referenceBuilder();
        newOrientableReferenceBuilder.setReferenceId(orientableCache.size());
        newOrientableReferenceBuilder.setOrientation(Orientation.DEFAULT);
        R newReference = newOrientableReferenceBuilder.build();

        deduplicationIndex.put(orientable, newReference);
        orientableCache.add(orientable);

        return newOrientableReferenceBuilder;
    }

    public T get(int referenceId)
    {
        return orientableCache.get(referenceId);
    }

    public int getSize()
    {
        return orientableCache.size();
    }

    public List<T> getCache()
    {
        return ImmutableList.copyOf(orientableCache);
    }
}

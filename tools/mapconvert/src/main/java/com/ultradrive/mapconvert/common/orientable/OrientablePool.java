package com.ultradrive.mapconvert.common.orientable;

import com.google.common.collect.ImmutableList;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import javax.annotation.Nonnull;


public class OrientablePool<T extends OrientablePoolable<T, R>, R extends OrientableReference<R>>
        implements OrientableReferenceProducer<T, R>, Iterable<T>
{
    private final Map<T, R> deduplicationIndex = new HashMap<>();
    private final List<T> orientableCache = new ArrayList<>();
    private final Set<OrientablePoolListener<T, R>> listeners = new HashSet<>();

    @Override
    @Nonnull
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

        notify(orientable, newReference);

        return newOrientableReferenceBuilder;
    }

    private void notify(T orientable, R newReference)
    {
        listeners.forEach(l -> l.onPoolInsert(newReference, orientable));
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

    public void addListener(OrientablePoolListener<T, R> listener)
    {
        listeners.add(listener);
    }
}

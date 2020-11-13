package com.ultradrive.mapconvert.export.expression;


import com.ultradrive.mapconvert.common.PropertySource;
import com.ultradrive.mapconvert.common.collection.iterables.ConcatenatingIterable;
import com.ultradrive.mapconvert.common.collection.iterables.FlatteningIterable;
import com.ultradrive.mapconvert.common.collection.iterables.GroupingIterable;
import com.ultradrive.mapconvert.common.collection.iterables.SkipIterable;
import com.ultradrive.mapconvert.common.collection.iterables.TakeIterable;
import java.util.Collection;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.StreamSupport;

import static java.util.stream.Collectors.groupingBy;
import static java.util.stream.Collectors.toList;
import static java.util.stream.Collectors.toSet;


public class CollectionExpressions
{
    public <T> Iterable<Iterable<T>> group(int groupSize, Iterable<T> iterableIterable)
    {
        return new GroupingIterable<>(iterableIterable, groupSize);
    }

    public <R, T extends Iterable<R>> FlatteningIterable<R, T> flatten(Iterable<T> iterableIterable)
    {
        return new FlatteningIterable<>(iterableIterable);
    }

    public <T> Iterable<T> concat(Iterable<T> first, Iterable<T> second)
    {
        return new ConcatenatingIterable<>(first, second);
    }

    public <T> Iterable<T> skip(int skipCount, Iterable<T> iterable)
    {
        return new SkipIterable<>(iterable, skipCount);
    }

    public <T> Iterable<T> take(int takeCount, Iterable<T> iterable)
    {
        return new TakeIterable<>(iterable, takeCount);
    }

    public <T extends PropertySource> Map<Set<Object>, List<T>> groupBy(Collection<String> key, Iterable<T> iterable)
    {
        return StreamSupport.stream(iterable.spliterator(), false)
                .collect(groupingBy(t -> key.stream().map(t::getProperty).collect(toSet()), toList()));
    }

    public <T extends PropertySource> List<T> groupOf(Collection<Object> key, Map<Set<Object>, List<T>> groups)
    {
        return groups.getOrDefault(Set.copyOf(key), Collections.emptyList());
    }

    public <T extends PropertySource> Map<Set<Object>, List<T>> ensureGroups(Collection<Collection<Object>> mandatoryGroups, Map<Set<Object>, List<T>> groups)
    {
        mandatoryGroups.stream()
                .map(HashSet::new)
                .forEach(groupKey -> groups.computeIfAbsent(groupKey, key -> Collections.emptyList()));

        return groups;
    }
}

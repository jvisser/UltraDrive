package com.ultradrive.mapconvert.processing.map.object;

import com.google.common.collect.Iterables;
import com.ultradrive.mapconvert.common.UID;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;


class ObjectGroupContainerBuilder
{
    private final int id;
    private final Set<ObjectGroupBuilder> objectGroupBuilders;

    private int assignedFlags;

    public ObjectGroupContainerBuilder()
    {
        this.id = UID.create();
        this.objectGroupBuilders = new LinkedHashSet<>();
        this.assignedFlags = 0;
    }

    public void add(ObjectGroupBuilder objectGroupBuilder)
    {
        objectGroupBuilders.add(objectGroupBuilder);

        if (objectGroupBuilders.size() > 7)
        {
            throw new IllegalStateException("Too many object groups in container");
        }

        objectGroupBuilder.addContainer(this);
    }

    public void addFlag(int flag)
    {
        assignedFlags |= flag;
    }

    public int getGroupIndex(ObjectGroupBuilder objectGroupBuilder)
    {
        if (objectGroupBuilder.isEmpty())
        {
            return 0;
        }
        return Iterables.indexOf(objectGroupBuilders, input -> Objects.equals(input, objectGroupBuilder)) + 1;
    }

    public ObjectGroupContainer build(Map<Integer, ObjectGroup> objectGroupsById)
    {
        return new ObjectGroupContainer(id, objectGroupBuilders.stream()
                .map(objectGroupBuilder -> objectGroupsById.get(objectGroupBuilder.getId()))
                .collect(Collectors.toUnmodifiableList()));
    }

    public int getAssignedFlags()
    {
        return assignedFlags;
    }

    public int getId()
    {
        return id;
    }
}

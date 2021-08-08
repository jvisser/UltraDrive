package com.ultradrive.mapconvert.processing.map.object;

import com.ultradrive.mapconvert.common.UID;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;


class ObjectGroupBuilder
{
    public static ObjectGroupBuilder EMPTY = new ObjectGroupBuilder();

    private final int id = UID.create();
    private final Set<ObjectGroupContainerBuilder> containers = new HashSet<>();
    private final Set<ObjectGroupBuilder> potentiallyVisibleNonLocalGroups = new HashSet<>();

    private int assignedFlag = 0;

    public int priority()
    {
        return containers.size() * 1000 + potentiallyVisibleNonLocalGroups.size();
    }

    public void addContainer(ObjectGroupContainerBuilder objectGroupContainerBuilder)
    {
        containers.add(objectGroupContainerBuilder);
    }

    public void associateGroup(ObjectGroupBuilder objectGroupBuilder)
    {
        if (Collections.disjoint(containers, objectGroupBuilder.containers))
        {
            potentiallyVisibleNonLocalGroups.add(objectGroupBuilder);
            objectGroupBuilder.potentiallyVisibleNonLocalGroups.add(this);
        }
    }

    public void calculateFlag()
    {
        Set<ObjectGroupContainerBuilder> associatedContainers = getAssociatedContainers();

        int freeFlags = ~associatedContainers.stream()
                .reduce(0, (i, c) -> i | c.getAssignedFlags(), (i, i2) -> i | i2);

        if (freeFlags == 0)
        {
            throw new IllegalStateException("Flag overflow");
        }

        assignedFlag = Integer.lowestOneBit(freeFlags);

        associatedContainers.forEach(objectGroupContainerBuilder -> objectGroupContainerBuilder.addFlag(assignedFlag));
    }

    private Set<ObjectGroupContainerBuilder> getAssociatedContainers()
    {
        return Stream.concat(containers.stream(),
                             potentiallyVisibleNonLocalGroups.stream()
                                     .flatMap(objectGroupBuilder -> objectGroupBuilder.containers.stream()))
                .collect(Collectors.toSet());
    }

    public ObjectGroup build()
    {
        return new ObjectGroup(id, assignedFlag);
    }

    public int getId()
    {
        return id;
    }

    public boolean isEmpty()
    {
        return this == EMPTY;
    }
}

package com.ultradrive.mapconvert.processing.map;

import com.ultradrive.mapconvert.common.UID;
import com.ultradrive.mapconvert.datasource.model.MapObject;
import com.ultradrive.mapconvert.processing.map.metadata.ObjectGroup;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;


class ObjectGroupBuilder
{
    public static final ObjectGroupBuilder ZERO = new ObjectGroupBuilder();

    private final int id = UID.create();
    private final Set<TileMapMetadataContainerBuilder> containers = new HashSet<>();
    private final Set<ObjectGroupBuilder> potentiallyVisibleNonLocalGroups = new HashSet<>();
    private final Set<MapObject> objects = new HashSet<>();

    private int assignedFlag = 0;

    public int priority()
    {
        return containers.size() * 1000 + potentiallyVisibleNonLocalGroups.size();
    }

    public void addContainer(TileMapMetadataContainerBuilder metadataContainerBuilder)
    {
        containers.add(metadataContainerBuilder);
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
        Set<TileMapMetadataContainerBuilder> associatedContainers = getAssociatedContainers();

        int freeFlags = ~associatedContainers.stream()
                .reduce(0, (i, c) -> i | c.getAssignedFlags(), (i, i2) -> i | i2);

        if (freeFlags == 0)
        {
            throw new IllegalStateException("Flag overflow");
        }

        assignedFlag = Integer.lowestOneBit(freeFlags);

        associatedContainers.forEach(metadataContainerBuilder -> metadataContainerBuilder.addFlag(assignedFlag));
    }

    private Set<TileMapMetadataContainerBuilder> getAssociatedContainers()
    {
        return Stream.concat(containers.stream(),
                             potentiallyVisibleNonLocalGroups.stream()
                                     .flatMap(objectGroupBuilder -> objectGroupBuilder.containers.stream()))
                .collect(Collectors.toSet());
    }

    public void add(MapObject mapObject)
    {
        if (!isZeroGroup())
        {
            objects.add(mapObject);
        }
    }

    public boolean isZeroGroup()
    {
        return this == ZERO;
    }

    public ObjectGroup build()
    {
        return new ObjectGroup(id, assignedFlag, objects);
    }

    public int getId()
    {
        return id;
    }

    public boolean isEmpty()
    {
        return objects.isEmpty();
    }
}

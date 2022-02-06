package com.ultradrive.mapconvert.processing.map;

import com.ultradrive.mapconvert.common.UID;
import com.ultradrive.mapconvert.datasource.model.MapObject;
import com.ultradrive.mapconvert.processing.map.metadata.TileMapObjectGroup;
import java.util.Collections;
import java.util.HashSet;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;


class TileMapObjectGroupBuilder implements ObjectGroupBuilder<TileMapObjectGroupBuilder>
{
    public static final TileMapObjectGroupBuilder ZERO = new TileMapObjectGroupBuilder();

    private final int id = UID.create();
    private final Set<TileMapMetadataContainerBuilder> metadataContainers = new HashSet<>();
    private final Set<TileMapObjectGroupBuilder> potentiallyVisibleNonLocalGroups = new HashSet<>();
    private final Set<MapObject> objects = new HashSet<>();

    private TileMapObjectGroupContainerBuilder container;
    private int assignedFlag = 0;

    @Override
    public void calculateFlag()
    {
        Set<TileMapMetadataContainerBuilder> associatedContainers = getAssociatedContainers();

        int freeFlags = ~associatedContainers.stream()
                .reduce(0, (i, c) -> i | c.getAssignedFlags(), (i, i2) -> i | i2);

        if (freeFlags == 0)
        {
            throw new IllegalStateException("ObjectGroup flag overflow");
        }

        assignedFlag = Integer.lowestOneBit(freeFlags);

        associatedContainers.forEach(metadataContainerBuilder -> metadataContainerBuilder.addFlag(assignedFlag));
    }

    @Override
    public void associateGroup(TileMapObjectGroupBuilder objectGroupBuilder)
    {
        if (Collections.disjoint(metadataContainers, objectGroupBuilder.metadataContainers))
        {
            potentiallyVisibleNonLocalGroups.add(objectGroupBuilder);
            objectGroupBuilder.potentiallyVisibleNonLocalGroups.add(this);
        }
    }

    @Override
    public boolean isZeroGroup()
    {
        return this == ZERO;
    }

    @Override
    public int priority()
    {
        return metadataContainers.size() * 1000 + potentiallyVisibleNonLocalGroups.size();
    }

    private Set<TileMapMetadataContainerBuilder> getAssociatedContainers()
    {
        return Stream.concat(metadataContainers.stream(),
                             potentiallyVisibleNonLocalGroups.stream()
                                     .flatMap(objectGroupBuilder -> objectGroupBuilder.metadataContainers.stream()))
                .collect(Collectors.toSet());
    }

    public void add(MapObject mapObject)
    {
        if (!isZeroGroup())
        {
            objects.add(mapObject);
        }
    }

    public void addMetadataContainer(TileMapMetadataContainerBuilder metadataContainerBuilder)
    {
        metadataContainers.add(metadataContainerBuilder);
    }

    public TileMapObjectGroup build()
    {
        if (container == null)
        {
            throw new IllegalStateException("ObjectGroup requires a container");
        }
        return new TileMapObjectGroup(id, assignedFlag, container.build(), objects);
    }

    public void setContainer(TileMapObjectGroupContainerBuilder container)
    {
        if (this.container != null && !Objects.equals(this.container, container))
        {
            throw new IllegalStateException("ObjectGroup can have only have one container");
        }
        this.container = container;
    }

    public TileMapObjectGroupContainerBuilder getContainer()
    {
        return container;
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

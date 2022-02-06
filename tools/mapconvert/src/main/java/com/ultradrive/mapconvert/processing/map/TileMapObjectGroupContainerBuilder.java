package com.ultradrive.mapconvert.processing.map;

import com.ultradrive.mapconvert.common.UID;
import com.ultradrive.mapconvert.processing.map.metadata.TileMapObjectGroupContainer;
import java.util.HashSet;
import java.util.Set;


class TileMapObjectGroupContainerBuilder implements ObjectGroupBuilder<TileMapObjectGroupContainerBuilder>
{
    public static final TileMapObjectGroupContainerBuilder ZERO = new TileMapObjectGroupContainerBuilder(null);

    private final int id;
    private final Set<TileMapObjectGroupContainerBuilder> associatedGroupContainers;

    private TileMapObjectGroupContainerBuilder parent;
    private int assignedFlag = 0;

    public TileMapObjectGroupContainerBuilder(TileMapObjectGroupContainerBuilder parent)
    {
        this.id = UID.create();
        this.associatedGroupContainers = new HashSet<>();

        setParent(parent);
    }

    @Override
    public void calculateFlag()
    {
        int freeFlags = ~associatedGroupContainers.stream()
                .reduce(0, (i, c) -> i | c.getAssignedFlag(), (a, b) -> a | b);

        if (freeFlags == 0)
        {
            throw new IllegalStateException("ObjectGroupContainer flag overflow");
        }

        assignedFlag = Integer.lowestOneBit(freeFlags);
    }

    public TileMapObjectGroupContainerBuilder getParent()
    {
        return parent;
    }

    public int getAssignedFlag()
    {
        return assignedFlag;
    }

    @Override
    public void associateGroup(TileMapObjectGroupContainerBuilder objectGroupBuilder)
    {
        if (objectGroupBuilder != this)
        {
            associatedGroupContainers.add(objectGroupBuilder);
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
        return 0;
    }

    public TileMapObjectGroupContainer build()
    {
        return new TileMapObjectGroupContainer(id, assignedFlag, parent == null ? null : parent.build());
    }

    public void setParent(TileMapObjectGroupContainerBuilder parent)
    {
        this.parent = parent;

        if (parent != null)
        {
            associateGroup(parent);
        }
    }
}

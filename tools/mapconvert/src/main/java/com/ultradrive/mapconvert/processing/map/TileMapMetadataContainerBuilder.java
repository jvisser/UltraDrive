package com.ultradrive.mapconvert.processing.map;

import com.google.common.collect.Iterables;
import com.ultradrive.mapconvert.common.UID;
import com.ultradrive.mapconvert.processing.map.metadata.ObjectGroup;
import com.ultradrive.mapconvert.processing.map.metadata.TileMapMetadataContainer;
import com.ultradrive.mapconvert.processing.map.metadata.TileMapOverlay;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;


class TileMapMetadataContainerBuilder
{
    private final int id;
    private final Set<ObjectGroupBuilder> objectGroupBuilders;
    private final Map<String, Object> properties;

    private int assignedFlags;
    private TileMapOverlay mapOverlay;

    TileMapMetadataContainerBuilder(Map<String, Object> properties)
    {
        this.properties = properties;
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

    public TileMapMetadataContainer build(Map<Integer, ObjectGroup> objectGroupsById)
    {
        return new TileMapMetadataContainer(
                id,
                properties,
                objectGroupBuilders.stream()
                        .map(objectGroupBuilder -> objectGroupsById.get(objectGroupBuilder.getId()))
                        .collect(Collectors.toList()),
                mapOverlay);
    }

    public int getGroupIndex(ObjectGroupBuilder objectGroupBuilder)
    {
        if (objectGroupBuilder.isZeroGroup())
        {
            return 0;
        }
        return Iterables.indexOf(objectGroupBuilders, input -> Objects.equals(input, objectGroupBuilder)) + 1;
    }

    public int getAssignedFlags()
    {
        return assignedFlags;
    }

    public int getId()
    {
        return id;
    }

    public void setOverlay(TileMapOverlay mapOverlay)
    {
        this.mapOverlay = mapOverlay;
    }
}

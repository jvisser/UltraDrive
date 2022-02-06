package com.ultradrive.mapconvert.processing.map.metadata;

import com.google.common.collect.ImmutableList;
import com.ultradrive.mapconvert.common.PropertySource;
import java.util.List;
import java.util.Map;


public final class TileMapMetadataContainer implements PropertySource
{
    private final int id;
    private final Map<String, Object> properties;
    private final List<TileMapObjectGroup> objectGroups;
    private final TileMapOverlay mapOverlay;

    public TileMapMetadataContainer(int id,
                             Map<String, Object> properties,
                             List<TileMapObjectGroup> objectGroups,
                             TileMapOverlay mapOverlay)
    {
        this.id = id;
        this.objectGroups = ImmutableList.copyOf(objectGroups);
        this.properties = properties;
        this.mapOverlay = mapOverlay;
    }

    @Override
    public Map<String, Object> getProperties()
    {
        return properties;
    }

    public int getId()
    {
        return id;
    }

    public List<TileMapObjectGroup> getObjectGroups()
    {
        return objectGroups;
    }

    public TileMapOverlay getMapOverlay()
    {
        return mapOverlay;
    }
}

package com.ultradrive.mapconvert.processing.map;

import com.ultradrive.mapconvert.common.PropertySource;
import com.ultradrive.mapconvert.processing.tileset.Tileset;
import com.ultradrive.mapconvert.processing.tileset.chunk.ChunkReference;
import java.util.Collections;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import javax.annotation.Nonnull;


public class TileMap implements PropertySource, Iterable<ChunkReference>
{
    private final Tileset tileset;
    private final List<ChunkReference> chunkReferences;
    private final Map<String, Object> properties;

    private final String name;
    private final int width;
    private final int height;

    TileMap(Tileset tileset, List<ChunkReference> chunkReferences, String name, int width, int height)
    {
        this.tileset = tileset;
        this.chunkReferences = chunkReferences;
        this.properties = Collections.emptyMap();
        this.name = name;
        this.width = width;
        this.height = height;
    }

    private TileMap(TileMap source, Map<String, Object> properties)
    {
        this.tileset = source.tileset;
        this.chunkReferences = source.chunkReferences;
        this.properties = new HashMap<>(source.properties);
        this.name = source.name;
        this.width = source.width;
        this.height = source.height;

        this.properties.putAll(properties);
    }

    @Override
    @Nonnull
    public Iterator<ChunkReference> iterator()
    {
        return chunkReferences.iterator();
    }

    @Override
    public Map<String, Object> getProperties()
    {
        return properties;
    }

    public TileMap withProperties(Map<String, Object> properties)
    {
        return new TileMap(this, properties);
    }

    public Tileset getTileset()
    {
        return tileset;
    }

    public String getName()
    {
        return name;
    }

    public int getWidth()
    {
        return width;
    }

    public int getHeight()
    {
        return height;
    }

    public ChunkReference getChunkReference(int row, int column)
    {
        return chunkReferences.get(row * width + column);
    }

    public SquashedTileMap squash()
    {
        return new SquashedTileMap(this);
    }
}

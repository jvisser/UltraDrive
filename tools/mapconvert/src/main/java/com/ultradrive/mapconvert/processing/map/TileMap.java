package com.ultradrive.mapconvert.processing.map;

import com.ultradrive.mapconvert.processing.tileset.Tileset;
import com.ultradrive.mapconvert.processing.tileset.chunk.ChunkReference;
import java.util.Iterator;
import java.util.List;

public class TileMap implements Iterable<ChunkReference>
{
    private final Tileset tileset;
    private final List<ChunkReference> chunkReferences;

    private final String name;
    private final int width;
    private final int height;

    public TileMap(Tileset tileset, List<ChunkReference> chunkReferences, String name, int width, int height)
    {
        this.tileset = tileset;
        this.chunkReferences = chunkReferences;
        this.name = name;
        this.width = width;
        this.height = height;
    }

    @Override
    public Iterator<ChunkReference> iterator()
    {
        return chunkReferences.iterator();
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

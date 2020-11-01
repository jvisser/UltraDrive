package com.ultradrive.mapconvert.processing.map;

import com.ultradrive.mapconvert.config.PreAllocatedPattern;
import com.ultradrive.mapconvert.processing.tileset.Tileset;
import java.util.List;

public class TileMapCompilation
{
    private final List<TileMap> maps;
    private final List<Tileset> tilesets;
    private final List<PreAllocatedPattern> externalPatterns;

    TileMapCompilation(List<TileMap> maps, List<Tileset> tilesets,
                       List<PreAllocatedPattern> externalPatterns)
    {
        this.maps = maps;
        this.tilesets = tilesets;
        this.externalPatterns = externalPatterns;
    }

    public List<TileMap> getMaps()
    {
        return maps;
    }

    public List<Tileset> getTilesets()
    {
        return tilesets;
    }

    public List<PreAllocatedPattern> getExternalPatterns()
    {
        return externalPatterns;
    }
}

package com.ultradrive.mapconvert.processing.map;

import com.ultradrive.mapconvert.processing.tileset.Tileset;
import java.util.List;

public class TileMapCompilation
{
    private final List<TileMap> maps;
    private final List<Tileset> tilesets;

    TileMapCompilation(List<TileMap> maps, List<Tileset> tilesets)
    {
        this.maps = maps;
        this.tilesets = tilesets;
    }

    public List<TileMap> getMaps()
    {
        return maps;
    }

    public List<Tileset> getTilesets()
    {
        return tilesets;
    }
}

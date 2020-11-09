package com.ultradrive.mapconvert.processing.map;

import com.ultradrive.mapconvert.config.PreAllocatedPattern;
import com.ultradrive.mapconvert.processing.tileset.Tileset;
import com.ultradrive.mapconvert.processing.tileset.collision.CollisionBlockList;
import java.util.List;
import java.util.stream.Collectors;


public class TileMapCompilation
{
    private final List<TileMap> maps;
    private final List<Tileset> tilesets;
    private final List<PreAllocatedPattern> externalPatterns;
    private final List<CollisionBlockList> collisionBlockLists;

    TileMapCompilation(List<TileMap> maps, List<Tileset> tilesets,
                       List<PreAllocatedPattern> externalPatterns)
    {
        this.maps = maps;
        this.tilesets = tilesets;
        this.externalPatterns = externalPatterns;
        this.collisionBlockLists = tilesets.stream()
                .map(Tileset::getCollisionBlockList)
                .distinct()
                .collect(Collectors.toList());
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

    public List<CollisionBlockList> getCollisionBlockLists()
    {
        return collisionBlockLists;
    }
}

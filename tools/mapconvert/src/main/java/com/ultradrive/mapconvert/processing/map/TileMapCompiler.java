package com.ultradrive.mapconvert.processing.map;

import com.ultradrive.mapconvert.datasource.MapDataSource;
import com.ultradrive.mapconvert.datasource.TilesetDataSource;
import com.ultradrive.mapconvert.processing.tileset.Tileset;
import com.ultradrive.mapconvert.processing.tileset.TilesetBuilder;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import static java.util.List.copyOf;
import static java.util.stream.Collectors.toList;
import static java.util.stream.Collectors.toMap;


public class TileMapCompiler
{
    private final Set<MapDataSource> mapDataSources;
    private final int basePatternId;

    public TileMapCompiler(int basePatternId)
    {
        this.mapDataSources = new HashSet<>();
        this.basePatternId = basePatternId;
    }

    public void addMapDataSource(MapDataSource mapDataSource)
    {
        mapDataSources.add(mapDataSource);
    }

    public TileMapCompilation compile()
    {
        Map<TilesetDataSource, TilesetBuilder> tilesetBuildersByTilesetDataSource = new HashMap<>();
        Map<MapDataSource, TileMapBuilder> mapBuilders = new HashMap<>();

        for (MapDataSource mapDataSource : mapDataSources)
        {
            TilesetDataSource tilesetDataSource = mapDataSource.getTilesetDataSource();
            TilesetBuilder tilesetBuilder = tilesetBuildersByTilesetDataSource
                    .computeIfAbsent(tilesetDataSource,
                                     tsd -> TilesetBuilder.fromTilesetSource(tsd, basePatternId));

            mapBuilders.put(mapDataSource, new TileMapBuilder(tilesetBuilder, mapDataSource));
        }

        preCompile(mapBuilders);

        Map<TilesetDataSource, Tileset> tilesetsByTilesetDataSource =
                compileTilesets(tilesetBuildersByTilesetDataSource);
        List<TileMap> maps = compileMaps(mapBuilders, tilesetsByTilesetDataSource);

        return new TileMapCompilation(maps, copyOf(tilesetsByTilesetDataSource.values()));
    }

    private void preCompile(Map<MapDataSource, TileMapBuilder> mapBuilders)
    {
        mapBuilders.values().forEach(TileMapBuilder::collectReferences);
    }

    private List<TileMap> compileMaps(Map<MapDataSource, TileMapBuilder> mapBuilders,
                                      Map<TilesetDataSource, Tileset> tilesetsByTilesetDataSource)
    {
        return mapBuilders.entrySet().stream()
                .map(mapBuilderEntry ->
                     {
                         MapDataSource mapDataSource = mapBuilderEntry.getKey();
                         TileMapBuilder mapBuilder = mapBuilderEntry.getValue();

                         return mapBuilder.build(tilesetsByTilesetDataSource.get(mapDataSource.getTilesetDataSource()));
                     })
                .collect(toList());
    }

    private Map<TilesetDataSource, Tileset> compileTilesets(
            Map<TilesetDataSource, TilesetBuilder> tilesetBuildersByTilesetDataSource)
    {
        return tilesetBuildersByTilesetDataSource.entrySet().stream()
                .collect(toMap(Map.Entry::getKey, e -> e.getValue().compile()));
    }
}

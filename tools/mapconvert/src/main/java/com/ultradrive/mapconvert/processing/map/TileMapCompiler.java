package com.ultradrive.mapconvert.processing.map;

import com.google.common.collect.ImmutableList;
import com.google.common.collect.Sets;
import com.ultradrive.mapconvert.datasource.MapDataSource;
import com.ultradrive.mapconvert.datasource.TilesetDataSource;
import com.ultradrive.mapconvert.processing.tileset.Tileset;
import com.ultradrive.mapconvert.processing.tileset.TilesetBuilder;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

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

        Map<MapDataSource, Set<AuxiliaryMapSource<MapDataSource>>> auxiliaryMaps = collectAuxiliaryMaps();

        for (MapDataSource mapDataSource : Sets.union(mapDataSources, auxiliaryMaps.keySet()))
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

        List<TileMap> maps = bindAuxiliaryMaps(auxiliaryMaps, compileMaps(mapBuilders, tilesetsByTilesetDataSource));

        return new TileMapCompilation(maps, ImmutableList.copyOf(tilesetsByTilesetDataSource.values()));
    }

    private Map<MapDataSource, Set<AuxiliaryMapSource<MapDataSource>>> collectAuxiliaryMaps()
    {
        Map<MapDataSource, Set<AuxiliaryMapSource<MapDataSource>>> collector = new HashMap<>();

        mapDataSources.forEach(source -> collectAuxiliaryMaps(collector, source));

        return collector;
    }

    private void collectAuxiliaryMaps(Map<MapDataSource, Set<AuxiliaryMapSource<MapDataSource>>> collector, MapDataSource source)
    {
        for (Map.Entry<String, Object> propertyEntry : source.getProperties().entrySet())
        {
            if (propertyEntry.getValue() instanceof MapDataSource auxiliaryMapDataSource)
            {
                collector.computeIfAbsent(auxiliaryMapDataSource, auxMapSource -> new HashSet<>())
                        .add(new AuxiliaryMapSource<>(source, propertyEntry.getKey()));

                if (!collector.containsKey(auxiliaryMapDataSource))
                {
                    collectAuxiliaryMaps(collector, auxiliaryMapDataSource);
                }
            }
        }
    }

    private void preCompile(Map<MapDataSource, TileMapBuilder> mapBuilders)
    {
        mapBuilders.values().forEach(TileMapBuilder::collectReferences);
    }

    private Map<TilesetDataSource, Tileset> compileTilesets(
            Map<TilesetDataSource, TilesetBuilder> tilesetBuildersByTilesetDataSource)
    {
        return tilesetBuildersByTilesetDataSource.entrySet().stream()
                .collect(toMap(Map.Entry::getKey, e -> e.getValue().compile()));
    }

    private Map<MapDataSource, TileMap> compileMaps(Map<MapDataSource, TileMapBuilder> mapBuilders,
                                      Map<TilesetDataSource, Tileset> tilesetsByTilesetDataSource)
    {
        return mapBuilders.entrySet().stream()
                .collect(toMap(Map.Entry::getKey, mapBuilderEntry ->
                     {
                         MapDataSource mapDataSource = mapBuilderEntry.getKey();
                         TileMapBuilder mapBuilder = mapBuilderEntry.getValue();

                         return mapBuilder.build(tilesetsByTilesetDataSource.get(mapDataSource.getTilesetDataSource()));
                     }));
    }

    private List<TileMap> bindAuxiliaryMaps(Map<MapDataSource, Set<AuxiliaryMapSource<MapDataSource>>> auxiliaryMaps,
                                            Map<MapDataSource, TileMap> compiledMaps)
    {
        Map<MapDataSource, TileMap> resultMaps = new HashMap<>(compiledMaps);

        auxiliaryMaps.forEach((mapDataSource, auxiliaryMapSources) -> {
            TileMap compiledAuxiliaryMap = compiledMaps.get(mapDataSource);

            auxiliaryMapSources.forEach(source -> {
                MapDataSource mapSourceToRewriteProperties = source.getSource();

                Map<String, Object> rewrittenProperties = new HashMap<>(mapSourceToRewriteProperties.getProperties());
                rewrittenProperties.put(source.getPropertyName(), compiledAuxiliaryMap);

                resultMaps.put(mapSourceToRewriteProperties,
                               compiledMaps.get(mapSourceToRewriteProperties).withProperties(rewrittenProperties));
            });
        });

        return ImmutableList.copyOf(resultMaps.values());
    }
}

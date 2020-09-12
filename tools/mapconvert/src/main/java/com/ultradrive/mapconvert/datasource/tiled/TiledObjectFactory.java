package com.ultradrive.mapconvert.datasource.tiled;

import com.ultradrive.mapconvert.datasource.MapDataSource;
import com.ultradrive.mapconvert.datasource.TilesetDataSource;
import java.io.File;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.tiledreader.FileSystemTiledReader;
import org.tiledreader.TiledCustomizable;
import org.tiledreader.TiledFile;
import org.tiledreader.TiledReader;

import static java.util.stream.Collectors.toMap;


public class TiledObjectFactory
{
    private static final String MAP_EXTENSION = ".TMX";
    private static final String TILESET_EXTENSION = ".TSX";

    private final TiledReader tiledReader;

    private final TiledPropertyTransformer propertyTransformer;
    private final Map<String, TiledMapDataSource> mapDataSourceCache;
    private final Map<String, TiledTilesetDataSource> tilesetDataSourceCache;

    public TiledObjectFactory()
    {
        tiledReader = new FileSystemTiledReader();

        propertyTransformer = new PropertyTransformer();
        mapDataSourceCache = new HashMap<>();
        tilesetDataSourceCache = new HashMap<>();

        disableTiledReaderLogger();
    }

    public TiledObjectFactory(String objectTypesFile)
    {
        this();

        if (objectTypesFile != null)
        {
            tiledReader.setObjectTypes(tiledReader.readObjectTypes(objectTypesFile));
        }
    }

    private void disableTiledReaderLogger()
    {
        Logger.getLogger("org.tiledreader").setLevel(Level.OFF);
    }

    private boolean isFileOfType(String filePath, String extension)
    {
        return filePath.toUpperCase(Locale.ROOT).endsWith(extension);
    }

    public TilesetDataSource getTilesetDataSource(String tilesetFileName)
    {
        return tilesetDataSourceCache.computeIfAbsent(tilesetFileName, fileName ->
        {
            TiledChunkDataSource chunkSet =
                    TiledChunkDataSource.fromFile(tiledReader, fileName, propertyTransformer);
            TiledBlockDataSource blockSet = chunkSet.readBlockDataSource(tiledReader);
            TiledCollisionDataSource collisionSet = blockSet.readCollisionTileset(tiledReader);

            return new TiledTilesetDataSource(chunkSet, blockSet, collisionSet);
        });
    }

    public MapDataSource getMapDataSource(String mapFileName)
    {
        return mapDataSourceCache
                .computeIfAbsent(mapFileName,
                                 fileName -> new TiledMapDataSource(this, tiledReader.getMap(fileName),
                                                                    propertyTransformer));
    }

    private class PropertyTransformer implements TiledPropertyTransformer
    {
        @Override
        public Map<String, Object> getProperties(TiledCustomizable tiledObject)
        {
            return tiledObject.getProperties().entrySet().stream()
                    .collect(toMap(Map.Entry::getKey, e -> transformValue(e.getValue())));
        }

        private Object transformValue(Object value)
        {
            if (value instanceof TiledFile tiledFile)
            {
                String filePath = tiledFile.getPath();

                if (isFileOfType(filePath, MAP_EXTENSION))
                {
                    return getMapDataSource(filePath);
                }
                if (isFileOfType(filePath, TILESET_EXTENSION))
                {
                    return getTilesetDataSource(filePath);
                }

                return new File(filePath);
            }

            return value;
        }
    }
}

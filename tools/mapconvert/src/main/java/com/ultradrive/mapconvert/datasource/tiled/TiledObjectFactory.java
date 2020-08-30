package com.ultradrive.mapconvert.datasource.tiled;

import java.util.HashMap;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.tiledreader.FileSystemTiledReader;
import org.tiledreader.TiledReader;

public class TiledObjectFactory
{
    private final TiledReader tiledReader;

    private final Map<String, TiledMapDataSource> mapDataSourceCache;
    private final Map<String, TiledTilesetDataSource> tilesetDataSourceCache;

    public TiledObjectFactory()
    {
        tiledReader = new FileSystemTiledReader();

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

    public TiledTilesetDataSource getTilesetDataSource(String tilesetFileName)
    {
        return tilesetDataSourceCache.computeIfAbsent(tilesetFileName, fileName ->
        {
            TiledChunkDataSource chunkSet = TiledChunkDataSource.fromFile(tiledReader, fileName);
            TiledBlockDataSource blockSet = chunkSet.readBlockTileset(tiledReader);

            return new TiledTilesetDataSource(chunkSet, blockSet);
        });
    }

    public TiledMapDataSource getMapDataSource(String mapFileName)
    {
        return mapDataSourceCache.computeIfAbsent(mapFileName,
                fileName -> new TiledMapDataSource(this, tiledReader.getMap(fileName)));
    }
}

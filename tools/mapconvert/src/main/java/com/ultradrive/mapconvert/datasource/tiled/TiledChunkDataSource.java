package com.ultradrive.mapconvert.datasource.tiled;

import com.ultradrive.mapconvert.datasource.ChunkDataSource;
import com.ultradrive.mapconvert.datasource.model.ChunkElementModel;
import com.ultradrive.mapconvert.datasource.model.ChunkModel;
import java.util.ArrayList;
import java.util.List;
import org.tiledreader.TiledMap;
import org.tiledreader.TiledReader;
import org.tiledreader.TiledTile;
import org.tiledreader.TiledTileLayer;
import org.tiledreader.TiledTileset;


class TiledChunkDataSource extends TiledMetaTileset implements ChunkDataSource
{
    private static final String BLOCK_TILESET_NAME = "blocks";

    private static final String CHUNK_TYPE_LAYER_NAME = "Type";
    private static final String CHUNK_SOLIDITY_LAYER_NAME = "Solidity";
    private static final String CHUNK_BLOCK_LAYER_NAME = "Block";

    static TiledChunkDataSource fromFile(TiledReader reader, String path, TiledPropertyTransformer propertyTransformer)
    {
        TiledTileset chunkTileset = reader.getTileset(path);
        TiledMap chunkMap = reader.getMap(chunkTileset.getImage().getSource());

        return new TiledChunkDataSource(chunkTileset, chunkMap, propertyTransformer);
    }

    private TiledChunkDataSource(TiledTileset chunkTileset, TiledMap chunkMap,
                                 TiledPropertyTransformer propertyTransformer)
    {
        super(chunkTileset, chunkMap, propertyTransformer);
    }

    public TiledBlockDataSource readBlockDataSource(TiledReader reader)
    {
        TiledTileset blockTileset = getTileset(BLOCK_TILESET_NAME);
        TiledMap blockMap = reader.getMap(blockTileset.getImage().getSource());

        return new TiledBlockDataSource(blockTileset, blockMap, propertyTransformer);
    }

    @Override
    public int getChunkSize()
    {
        return tileset.getTileWidth();
    }

    @Override
    public ChunkModel getChunkModel(int chunkId)
    {
        TiledTileLayer typeLayer = getLayer(CHUNK_TYPE_LAYER_NAME);
        TiledTileLayer solidityLayer = getLayer(CHUNK_SOLIDITY_LAYER_NAME);
        TiledTileLayer blockLayer = getLayer(CHUNK_BLOCK_LAYER_NAME);

        TiledTile chunkTile = tileset.getTile(chunkId);

        int blocksInChunk = tileset.getTileWidth() / map.getTileWidth();
        int tileX = chunkTile.getTilesetX() * blocksInChunk;
        int tileY = chunkTile.getTilesetY() * blocksInChunk;

        List<ChunkElementModel> elements = new ArrayList<>();
        for (int y = 0; y < blocksInChunk; y++)
        {
            for (int x = 0; x < blocksInChunk; x++)
            {
                int blockX = tileX + x;
                int blockY = tileY + y;

                elements.add(new ChunkElementModel(
                        getResourceReference(blockLayer, blockX, blockY),
                        getResourceReference(solidityLayer, blockX, blockY),
                        getResourceReference(typeLayer, blockX, blockY)
                ));
            }
        }

        return new ChunkModel(chunkId, elements);
    }
}

package com.ultradrive.mapconvert.processing.map;

import com.ultradrive.mapconvert.datasource.model.ChunkReferenceModel;
import com.ultradrive.mapconvert.datasource.model.MapModel;
import com.ultradrive.mapconvert.processing.tileset.Tileset;
import com.ultradrive.mapconvert.processing.tileset.TilesetReferenceBuilderSource;
import com.ultradrive.mapconvert.processing.tileset.chunk.ChunkReference;
import java.util.ArrayList;
import java.util.List;

class TileMapBuilder
{
    private final TilesetReferenceBuilderSource tilesetReferenceBuilder;
    private final MapModel mapModel;

    private final List<ChunkReference> chunkReferences;

    TileMapBuilder(TilesetReferenceBuilderSource tilesetReferenceBuilder, MapModel mapModel)
    {
        this.tilesetReferenceBuilder = tilesetReferenceBuilder;
        this.mapModel = mapModel;

        this.chunkReferences = new ArrayList<>();
    }

    public void collectReferences()
    {
        for (int row = 0; row < mapModel.getHeight(); row++)
        {
            for (int column = 0; column < mapModel.getWidth(); column++)
            {
                ChunkReferenceModel chunkReferenceModel = mapModel.getChunkReference(row, column);

                ChunkReference.Builder chunkReferenceBuilder = tilesetReferenceBuilder.getTileReference(chunkReferenceModel.getChunkId());
                chunkReferenceBuilder.reorient(chunkReferenceModel.getOrientation());
                chunkReferences.add(chunkReferenceBuilder.build());
            }
        }
    }

    public TileMap build(Tileset tileset)
    {
        return new TileMap(tileset, chunkReferences,
                           mapModel.getName(),
                           mapModel.getWidth(),
                           mapModel.getHeight(),
                           mapModel.getProperties());
    }
}

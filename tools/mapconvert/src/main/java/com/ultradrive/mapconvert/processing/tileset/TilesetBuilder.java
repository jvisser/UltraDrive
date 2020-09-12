package com.ultradrive.mapconvert.processing.tileset;

import com.ultradrive.mapconvert.datasource.BlockDataSource;
import com.ultradrive.mapconvert.datasource.ChunkDataSource;
import com.ultradrive.mapconvert.datasource.CollisionDataSource;
import com.ultradrive.mapconvert.datasource.TilesetDataSource;
import com.ultradrive.mapconvert.processing.tileset.block.BlockAggregator;
import com.ultradrive.mapconvert.processing.tileset.block.image.ImageBlockPatternProducer;
import com.ultradrive.mapconvert.processing.tileset.block.image.TileSetImageFactory;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;
import com.ultradrive.mapconvert.processing.tileset.chunk.ChunkAggregator;
import com.ultradrive.mapconvert.processing.tileset.chunk.ChunkReference;
import com.ultradrive.mapconvert.processing.tileset.collision.CollisionFieldSet;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileMetrics;
import java.util.Map;

import static java.lang.String.format;


public class TilesetBuilder implements TilesetReferenceBuilderSource
{
    private final BlockAggregator blockAggregator;
    private final ChunkAggregator chunkAggregator;
    private final CollisionFieldSet collisionFieldSet;
    private final Map<String, Object> properties;

    private final String tileSetName;

    public static TilesetBuilder fromTilesetSource(TilesetDataSource tilesetDataSource, int basePatternId)
    {
        verifyDimensions(tilesetDataSource);

        BlockDataSource blockDataSource = tilesetDataSource.getBlockDataSource();
        MetaTileMetrics blockMetrics = new MetaTileMetrics(blockDataSource.getBlockSize(), Pattern.DIMENSION_SIZE);
        BlockAggregator blockAggregator =
                new BlockAggregator(
                        blockDataSource,
                        new ImageBlockPatternProducer(TileSetImageFactory.fromURL(blockDataSource.getBlockImageSource()), blockMetrics),
                        blockMetrics,
                        basePatternId);

        ChunkDataSource chunkDataSource = tilesetDataSource.getChunkDataSource();
        ChunkAggregator chunkAggregator =
                new ChunkAggregator(
                        chunkDataSource,
                        new MetaTileMetrics(chunkDataSource.getChunkSize(), blockMetrics.getTileSize()),
                        blockAggregator);

        CollisionFieldSet collisionFieldSet = CollisionFieldSet.parse(tilesetDataSource.getCollisionDataSource());

        return new TilesetBuilder(blockAggregator, chunkAggregator, collisionFieldSet,
                                  tilesetDataSource.getProperties(),
                                  tilesetDataSource.getName());
    }

    private static void verifyDimensions(TilesetDataSource tilesetDataSource)
    {
        BlockDataSource blockDataSource = tilesetDataSource.getBlockDataSource();
        ChunkDataSource chunkDataSource = tilesetDataSource.getChunkDataSource();
        CollisionDataSource collisionDataSource = tilesetDataSource.getCollisionDataSource();

        if (blockDataSource.getBlockSize() != collisionDataSource.getCollisionFieldSize())
        {
            throw new IllegalArgumentException(format("Collision tile size (%d) does not match block tilesize (%d)",
                                                      blockDataSource.getBlockSize(),
                                                      collisionDataSource.getCollisionFieldSize()));
        }

        if (chunkDataSource.getChunkSize() % blockDataSource.getBlockSize() != 0)
        {
            throw new IllegalArgumentException("Chunk and block sizes do not align");
        }
    }

    public TilesetBuilder(BlockAggregator blockAggregator,
                          ChunkAggregator chunkAggregator,
                          CollisionFieldSet collisionFieldSet,
                          Map<String, Object> properties, String tileSetName)
    {
        this.blockAggregator = blockAggregator;
        this.chunkAggregator = chunkAggregator;
        this.collisionFieldSet = collisionFieldSet;
        this.properties = properties;
        this.tileSetName = tileSetName;
    }

    @Override
    public ChunkReference.Builder getTileReference(int tileId)
    {
        return chunkAggregator.getChunkReference(tileId);
    }

    public Tileset compile()
    {
        return new Tileset(
                chunkAggregator.compile(),
                blockAggregator.compile(),
                collisionFieldSet,
                properties,
                tileSetName);
    }
}

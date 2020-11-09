package com.ultradrive.mapconvert.processing.tileset;

import com.ultradrive.mapconvert.config.PatternAllocationConfiguration;
import com.ultradrive.mapconvert.datasource.BlockDataSource;
import com.ultradrive.mapconvert.datasource.ChunkDataSource;
import com.ultradrive.mapconvert.datasource.CollisionBlockDataSource;
import com.ultradrive.mapconvert.datasource.TilesetDataSource;
import com.ultradrive.mapconvert.processing.tileset.block.BlockAggregator;
import com.ultradrive.mapconvert.processing.tileset.block.image.ImageBlockPatternProducer;
import com.ultradrive.mapconvert.processing.tileset.block.image.TileSetImageFactory;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.allocator.PatternAllocator;
import com.ultradrive.mapconvert.processing.tileset.chunk.ChunkAggregator;
import com.ultradrive.mapconvert.processing.tileset.chunk.ChunkReference;
import com.ultradrive.mapconvert.processing.tileset.collision.CollisionBlockList;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileMetrics;
import java.util.Map;

import static java.lang.String.format;


public class TilesetBuilder implements TilesetReferenceBuilderSource
{
    private final BlockAggregator blockAggregator;
    private final ChunkAggregator chunkAggregator;
    private final CollisionBlockList collisionBlockList;
    private final Map<String, Object> properties;

    private final String tileSetName;

    public static TilesetBuilder fromTilesetSource(TilesetDataSource tilesetDataSource,
                                                   PatternAllocationConfiguration patternAllocationConfiguration)
    {
        verifyDimensions(tilesetDataSource);

        BlockDataSource blockDataSource = tilesetDataSource.getBlockDataSource();
        MetaTileMetrics blockMetrics = new MetaTileMetrics(blockDataSource.getBlockSize(), Pattern.DIMENSION_SIZE);
        BlockAggregator blockAggregator =
                new BlockAggregator(
                        blockDataSource,
                        new ImageBlockPatternProducer(TileSetImageFactory.fromURL(blockDataSource.getBlockImageSource()), blockMetrics),
                        createPatternAllocator(patternAllocationConfiguration),
                        blockMetrics);

        ChunkDataSource chunkDataSource = tilesetDataSource.getChunkDataSource();
        ChunkAggregator chunkAggregator =
                new ChunkAggregator(
                        chunkDataSource,
                        new MetaTileMetrics(chunkDataSource.getChunkSize(), blockMetrics.getTileSize()),
                        blockAggregator);

        CollisionBlockList collisionBlockList = CollisionBlockList.parse(tilesetDataSource.getCollisionBlockDataSource());

        return new TilesetBuilder(blockAggregator, chunkAggregator, collisionBlockList,
                                  tilesetDataSource.getProperties(),
                                  tilesetDataSource.getName());
    }

    private static void verifyDimensions(TilesetDataSource tilesetDataSource)
    {
        BlockDataSource blockDataSource = tilesetDataSource.getBlockDataSource();
        ChunkDataSource chunkDataSource = tilesetDataSource.getChunkDataSource();
        CollisionBlockDataSource collisionBlockDataSource = tilesetDataSource.getCollisionBlockDataSource();

        if (blockDataSource.getBlockSize() != collisionBlockDataSource.getCollisionBlockFieldSize())
        {
            throw new IllegalArgumentException(format("Collision tile size (%d) does not match block tilesize (%d)",
                                                      blockDataSource.getBlockSize(),
                                                      collisionBlockDataSource.getCollisionBlockFieldSize()));
        }

        if (chunkDataSource.getChunkSize() % blockDataSource.getBlockSize() != 0)
        {
            throw new IllegalArgumentException("Chunk and block sizes do not align");
        }
    }

    private static PatternAllocator createPatternAllocator(
            PatternAllocationConfiguration patternAllocationConfiguration)
    {
        PatternAllocator patternAllocator = new PatternAllocator();

        patternAllocationConfiguration.getPatternRanges().forEach(patternRange -> patternAllocator
                .addSection(patternRange.getId(),
                            patternRange.getStartPatternId(),
                            patternRange.getEndPatternId()));

        patternAllocationConfiguration.getPreAllocatedPatterns().forEach(preAllocatedPattern -> patternAllocator
                .addPreAllocatedPattern(preAllocatedPattern.getPatternId(),
                                        preAllocatedPattern.getPattern()));

        return patternAllocator;
    }


    public TilesetBuilder(BlockAggregator blockAggregator,
                          ChunkAggregator chunkAggregator,
                          CollisionBlockList collisionBlockList,
                          Map<String, Object> properties, String tileSetName)
    {
        this.blockAggregator = blockAggregator;
        this.chunkAggregator = chunkAggregator;
        this.collisionBlockList = collisionBlockList;
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
                collisionBlockList,
                properties,
                tileSetName);
    }
}

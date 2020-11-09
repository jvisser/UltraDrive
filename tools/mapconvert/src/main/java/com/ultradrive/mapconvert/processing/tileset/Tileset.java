package com.ultradrive.mapconvert.processing.tileset;

import com.ultradrive.mapconvert.common.PropertySource;
import com.ultradrive.mapconvert.processing.tileset.block.Block;
import com.ultradrive.mapconvert.processing.tileset.block.BlockTileset;
import com.ultradrive.mapconvert.processing.tileset.block.animation.Animation;
import com.ultradrive.mapconvert.processing.tileset.block.animation.AnimationFrame;
import com.ultradrive.mapconvert.processing.tileset.block.image.TilesetImagePalette;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.allocator.PatternAllocation;
import com.ultradrive.mapconvert.processing.tileset.chunk.Chunk;
import com.ultradrive.mapconvert.processing.tileset.chunk.ChunkTileset;
import com.ultradrive.mapconvert.processing.tileset.collision.CollisionBlockList;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileMetrics;
import java.util.List;
import java.util.Map;
import java.util.Optional;


public class Tileset implements PropertySource
{
    private final ChunkTileset chunkTileset;
    private final BlockTileset blockTileset;
    private final CollisionBlockList collisionBlockList;
    private final Map<String, Object> properties;

    private final String name;

    public Tileset(ChunkTileset chunkTileset, BlockTileset blockTileset, CollisionBlockList collisionBlockList,
                   Map<String, Object> properties, String name)
    {
        this.chunkTileset = chunkTileset;
        this.blockTileset = blockTileset;
        this.collisionBlockList = collisionBlockList;
        this.properties = properties;
        this.name = name;
    }

    @Override
    public Map<String, Object> getProperties()
    {
        return properties;
    }

    public ChunkTileset getChunkTileset()
    {
        return chunkTileset;
    }

    public BlockTileset getBlockTileset()
    {
        return blockTileset;
    }

    public CollisionBlockList getCollisionBlockList()
    {
        return collisionBlockList;
    }

    public String getName()
    {
        return name;
    }

    public MetaTileMetrics getChunkMetrics()
    {
        return chunkTileset.getTileMetrics();
    }

    public Chunk getChunk(int chunkId)
    {
        return chunkTileset.getTile(chunkId);
    }

    public MetaTileMetrics getBlockMetrics()
    {
        return blockTileset.getTileMetrics();
    }

    public Block getBlock(int blockId)
    {
        return blockTileset.getTile(blockId);
    }

    public Optional<Pattern> getPattern(int patternId)
    {
        return blockTileset.getPattern(patternId);
    }

    public TilesetImagePalette getPalette()
    {
        return blockTileset.getPalette();
    }

    public PatternAllocation getPatternAllocation()
    {
        return blockTileset.getPatternAllocation();
    }

    public List<AnimationFrame> getAnimationFrames()
    {
        return blockTileset.getAnimationFrames();
    }

    public List<Animation> getAnimations()
    {
        return blockTileset.getAnimations();
    }
}

package com.ultradrive.mapconvert.processing.tileset;

import com.ultradrive.mapconvert.processing.tileset.block.Block;
import com.ultradrive.mapconvert.processing.tileset.block.BlockTileset;
import com.ultradrive.mapconvert.processing.tileset.block.image.TilesetImagePalette;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;
import com.ultradrive.mapconvert.processing.tileset.chunk.Chunk;
import com.ultradrive.mapconvert.processing.tileset.chunk.ChunkTileset;
import com.ultradrive.mapconvert.processing.tileset.collision.CollisionFieldSet;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileMetrics;


public class Tileset
{
    private final ChunkTileset chunkTileset;
    private final BlockTileset blockTileset;
    private final CollisionFieldSet collisionFieldSet;

    private final String name;

    public Tileset(ChunkTileset chunkTileset, BlockTileset blockTileset, CollisionFieldSet collisionFieldSet, String name)
    {
        this.chunkTileset = chunkTileset;
        this.blockTileset = blockTileset;
        this.collisionFieldSet = collisionFieldSet;
        this.name = name;
    }

    public ChunkTileset getChunkTileset()
    {
        return chunkTileset;
    }

    public BlockTileset getBlockTileset()
    {
        return blockTileset;
    }

    public CollisionFieldSet getCollisionFieldSet()
    {
        return collisionFieldSet;
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

    public Pattern getPattern(int patternId)
    {
        return blockTileset.getPattern(patternId);
    }

    public TilesetImagePalette getPalette()
    {
        return blockTileset.getPalette();
    }
}

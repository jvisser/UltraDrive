package com.ultradrive.mapconvert.processing.tileset.block.image;

import com.ultradrive.mapconvert.processing.tileset.common.MetaTileMetrics;


public class ImageBlockPatternProducer
{
    private final TilesetImage image;
    private final MetaTileMetrics blockMetrics;

    public ImageBlockPatternProducer(TilesetImage image, MetaTileMetrics blockMetrics)
    {
        this.image = image;
        this.blockMetrics = blockMetrics;
    }

    public TilesetImagePattern getTilesetImagePattern(int graphicsId, int blockLocalPatternId)
    {
        int blockImageStride = image.getWidth() / blockMetrics.getTileSize();
        int patternsPerBlockDimension = blockMetrics.getTileSizeInSubTiles();

        int blockX = (graphicsId % blockImageStride) * patternsPerBlockDimension;
        int blockY = (graphicsId / blockImageStride) * patternsPerBlockDimension;

        int patternX = blockLocalPatternId % patternsPerBlockDimension;
        int patternY = blockLocalPatternId / patternsPerBlockDimension;

        return image.getImagePattern(blockY + patternY, blockX + patternX);
    }

    public TilesetImagePalette getPalette()
    {
        return image.getPalette();
    }
}

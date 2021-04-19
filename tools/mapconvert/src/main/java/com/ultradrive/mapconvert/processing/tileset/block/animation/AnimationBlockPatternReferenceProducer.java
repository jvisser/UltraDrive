package com.ultradrive.mapconvert.processing.tileset.block.animation;

import com.ultradrive.mapconvert.processing.tileset.block.BlockPatternReferenceProducer;
import com.ultradrive.mapconvert.processing.tileset.block.image.ImageBlockPatternProducer;
import com.ultradrive.mapconvert.processing.tileset.block.image.TilesetImagePattern;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternReference;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileMetrics;


public class AnimationBlockPatternReferenceProducer implements BlockPatternReferenceProducer
{
    private final MetaTileMetrics blockMetrics;
    private final ImageBlockPatternProducer imagePatternProducer;

    public AnimationBlockPatternReferenceProducer(MetaTileMetrics blockMetrics,
                                                  ImageBlockPatternProducer imagePatternProducer)
    {
        this.blockMetrics = blockMetrics;
        this.imagePatternProducer = imagePatternProducer;
    }

    @Override
    public PatternReference.Builder getReference(int graphicsId, int blockLocalPatternId)
    {
        PatternReference.Builder patternReferenceBuilder =
                new AnimationBlockPatternReferenceEncoding(blockMetrics, graphicsId, blockLocalPatternId)
                        .createPatternReference();

        TilesetImagePattern tilesetImagePattern =
                imagePatternProducer.getTilesetImagePattern(graphicsId, blockLocalPatternId);

        patternReferenceBuilder.setPaletteId(tilesetImagePattern.getPaletteId());

        return patternReferenceBuilder;
    }
}

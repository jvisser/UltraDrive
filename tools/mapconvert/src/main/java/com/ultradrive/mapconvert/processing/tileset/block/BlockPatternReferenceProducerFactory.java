package com.ultradrive.mapconvert.processing.tileset.block;

import com.ultradrive.mapconvert.datasource.model.BlockModel;
import com.ultradrive.mapconvert.processing.tileset.block.animation.AnimationBlockPatternReferenceProducer;
import com.ultradrive.mapconvert.processing.tileset.block.image.ImageBlockPatternProducer;
import com.ultradrive.mapconvert.processing.tileset.block.image.ImageBlockPatternReferenceProducer;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternReferenceProducer;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileMetrics;


public class BlockPatternReferenceProducerFactory
{
    private final AnimationBlockPatternReferenceProducer animationBlockPatternReferenceProducer;
    private final ImageBlockPatternReferenceProducer imageBlockPatternReferenceProducer;

    public BlockPatternReferenceProducerFactory(MetaTileMetrics blockMetrics,
                                                ImageBlockPatternProducer imageBlockPatternProducer,
                                                PatternReferenceProducer patternReferenceProducer)
    {
        animationBlockPatternReferenceProducer =
                new AnimationBlockPatternReferenceProducer(blockMetrics, imageBlockPatternProducer);
        imageBlockPatternReferenceProducer =
                new ImageBlockPatternReferenceProducer(imageBlockPatternProducer, patternReferenceProducer);
    }

    public BlockPatternReferenceProducer getBlockPatternReferenceProducer(BlockModel blockModel)
    {
        return blockModel.hasAnimation()
               ? animationBlockPatternReferenceProducer
               : imageBlockPatternReferenceProducer;
    }
}

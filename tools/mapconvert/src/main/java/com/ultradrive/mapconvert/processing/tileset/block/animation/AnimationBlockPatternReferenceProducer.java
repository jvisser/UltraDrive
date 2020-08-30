package com.ultradrive.mapconvert.processing.tileset.block.animation;

import com.ultradrive.mapconvert.processing.tileset.block.BlockPatternReferenceProducer;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternReference;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileMetrics;


public class AnimationBlockPatternReferenceProducer implements BlockPatternReferenceProducer
{
    private final MetaTileMetrics blockMetrics;

    public AnimationBlockPatternReferenceProducer(MetaTileMetrics blockMetrics)
    {
        this.blockMetrics = blockMetrics;
    }

    @Override
    public PatternReference.Builder getReference(int graphicsId, int blockLocalPatternId)
    {
        return new AnimationBlockPatternReferenceEncoding(blockMetrics, graphicsId, blockLocalPatternId)
                .createPatternReference();
    }
}

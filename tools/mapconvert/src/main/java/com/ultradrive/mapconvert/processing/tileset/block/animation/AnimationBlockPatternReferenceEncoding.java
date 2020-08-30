package com.ultradrive.mapconvert.processing.tileset.block.animation;

import com.ultradrive.mapconvert.common.Point;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternReference;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileMetrics;


class AnimationBlockPatternReferenceEncoding
{
    private final MetaTileMetrics blockMetrics;
    private final int referenceId;

    public AnimationBlockPatternReferenceEncoding(MetaTileMetrics blockMetrics, PatternReference patternReference)
    {
        this.blockMetrics = blockMetrics;
        this.referenceId = patternReference.getReferenceId();
    }

    public AnimationBlockPatternReferenceEncoding(MetaTileMetrics blockMetrics, int graphicsId, int blockLocalPatternId)
    {
        this.blockMetrics = blockMetrics;
        this.referenceId = -(graphicsId * blockMetrics.getTotalSubTiles() + blockLocalPatternId);
    }

    public PatternReference.Builder createPatternReference()
    {
        PatternReference.Builder referenceBuilder = new PatternReference.Builder();
        referenceBuilder.setReferenceId(referenceId);
        return referenceBuilder;
    }

    public int getGraphicsId()
    {
        return -referenceId / blockMetrics.getTotalSubTiles();
    }

    public int getBlockLocalPatternId()
    {
        return -referenceId % blockMetrics.getTotalSubTiles();
    }

    public Point getBlockPatternPosition()
    {
        int blockLocalPatternId = getBlockLocalPatternId();

        return blockMetrics.getSubTilePosition(blockLocalPatternId);
    }
}

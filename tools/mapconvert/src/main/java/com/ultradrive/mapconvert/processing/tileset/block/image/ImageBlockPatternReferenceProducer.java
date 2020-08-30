package com.ultradrive.mapconvert.processing.tileset.block.image;

import com.ultradrive.mapconvert.processing.tileset.block.BlockPatternReferenceProducer;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternPool;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternReference;


public class ImageBlockPatternReferenceProducer implements BlockPatternReferenceProducer
{
    private final ImageBlockPatternProducer imagePatternProducer;
    private final int patternBaseId;
    private final PatternPool patternPool;

    public ImageBlockPatternReferenceProducer(ImageBlockPatternProducer imagePatternProducer, int patternBaseId)
    {
        this.imagePatternProducer = imagePatternProducer;
        this.patternBaseId = patternBaseId;
        this.patternPool = new PatternPool();
    }

    @Override
    public PatternReference.Builder getReference(int graphicsId, int blockLocalPatternId)
    {
        TilesetImagePattern imagePattern = imagePatternProducer.getTilesetImagePattern(graphicsId, blockLocalPatternId);

        PatternReference.Builder patternReferenceBuilder = patternPool.getReference(imagePattern.getPattern());
        patternReferenceBuilder.setPaletteId(imagePattern.getPaletteId());
        patternReferenceBuilder.offsetReference(patternBaseId);

        return patternReferenceBuilder;
    }

    public PatternPool getPatternPool()
    {
        return patternPool;
    }
}

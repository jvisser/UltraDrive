package com.ultradrive.mapconvert.processing.tileset.block.image;

import com.ultradrive.mapconvert.processing.tileset.block.BlockPatternReferenceProducer;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;
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

        PatternReference.Builder patternReferenceBuilder = getReference(imagePattern.getPattern());
        patternReferenceBuilder.setPaletteId(imagePattern.getPaletteId());

        return patternReferenceBuilder;
    }

    public PatternReference.Builder getReference(Pattern pattern)
    {
        PatternReference.Builder patternReferenceBuilder = patternPool.getReference(pattern);
        patternReferenceBuilder.offsetReference(patternBaseId);
        return patternReferenceBuilder;
    }

    public int getNextPatternId()
    {
        return patternPool.getSize() + patternBaseId;
    }

    public PatternPool getPatternPool()
    {
        return patternPool;
    }
}

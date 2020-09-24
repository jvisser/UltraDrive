package com.ultradrive.mapconvert.processing.tileset.block.image;

import com.ultradrive.mapconvert.processing.tileset.block.BlockPatternReferenceProducer;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternReference;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternReferenceProducer;


public class ImageBlockPatternReferenceProducer implements BlockPatternReferenceProducer, PatternReferenceProducer
{
    private final ImageBlockPatternProducer imagePatternProducer;
    private final PatternReferenceProducer patternReferenceProducer;

    public ImageBlockPatternReferenceProducer(ImageBlockPatternProducer imagePatternProducer,
                                              PatternReferenceProducer patternReferenceProducer)
    {
        this.imagePatternProducer = imagePatternProducer;
        this.patternReferenceProducer = patternReferenceProducer;
    }

    @Override
    public PatternReference.Builder getReference(int graphicsId, int blockLocalPatternId)
    {
        TilesetImagePattern imagePattern = imagePatternProducer.getTilesetImagePattern(graphicsId, blockLocalPatternId);

        PatternReference.Builder patternReferenceBuilder = getReference(imagePattern.getPattern());
        patternReferenceBuilder.setPaletteId(imagePattern.getPaletteId());

        return patternReferenceBuilder;
    }

    @Override
    public PatternReference.Builder getReference(Pattern pattern)
    {
        return patternReferenceProducer.getReference(pattern);
    }
}

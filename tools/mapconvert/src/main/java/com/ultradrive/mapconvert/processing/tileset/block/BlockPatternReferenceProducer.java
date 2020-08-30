package com.ultradrive.mapconvert.processing.tileset.block;

import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternReference;


public interface BlockPatternReferenceProducer
{
    PatternReference.Builder getReference(int graphicsId, int blockLocalPatternId);
}

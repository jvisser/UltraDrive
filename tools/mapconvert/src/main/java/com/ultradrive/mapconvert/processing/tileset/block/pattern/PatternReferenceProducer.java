package com.ultradrive.mapconvert.processing.tileset.block.pattern;

import com.ultradrive.mapconvert.common.orientable.OrientableReferenceProducer;


public interface PatternReferenceProducer extends OrientableReferenceProducer<Pattern, PatternReference>
{
    @Override
    PatternReference.Builder getReference(Pattern orientable);
}

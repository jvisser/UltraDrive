package com.ultradrive.mapconvert.processing.tileset.block.pattern;

import com.ultradrive.mapconvert.common.orientable.OrientablePool;


public class PatternPool extends OrientablePool<Pattern, PatternReference>
{
    @Override
    public PatternReference.Builder getReference(Pattern orientable)
    {
        return (PatternReference.Builder) super.getReference(orientable);
    }
}

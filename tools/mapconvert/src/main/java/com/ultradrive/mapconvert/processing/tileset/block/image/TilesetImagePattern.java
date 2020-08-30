package com.ultradrive.mapconvert.processing.tileset.block.image;

import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternPaletteId;


public class TilesetImagePattern
{
    private final Pattern pattern;
    private final PatternPaletteId paletteId;

    public TilesetImagePattern(Pattern pattern, PatternPaletteId paletteId)
    {
        this.pattern = pattern;
        this.paletteId = paletteId;
    }

    public PatternPaletteId getPaletteId()
    {
        return paletteId;
    }

    public Pattern getPattern()
    {
        return pattern;
    }
}

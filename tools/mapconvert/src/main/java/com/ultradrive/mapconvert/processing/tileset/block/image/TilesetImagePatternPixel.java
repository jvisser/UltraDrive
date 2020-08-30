package com.ultradrive.mapconvert.processing.tileset.block.image;

import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternPaletteId;


class TilesetImagePatternPixel
{
    private static final int COLOR_INDEX_MASK = 0x0f;
    private static final int PALETTE_ID_MASK = 0x30;
    private static final int PALETTE_ID_SHIFT = 4;

    private final int colorIndex;
    private final PatternPaletteId paletteId;

    TilesetImagePatternPixel(int value)
    {
        if ((value & ~(COLOR_INDEX_MASK | PALETTE_ID_MASK)) != 0)
        {
            throw new IllegalArgumentException("Invalid pattern pixel value");
        }

        colorIndex = value & COLOR_INDEX_MASK;
        paletteId = PatternPaletteId.fromId((value & PALETTE_ID_MASK) >>> PALETTE_ID_SHIFT);
    }

    public int getColorIndex()
    {
        return colorIndex;
    }

    public PatternPaletteId getPaletteId()
    {
        return paletteId;
    }
}

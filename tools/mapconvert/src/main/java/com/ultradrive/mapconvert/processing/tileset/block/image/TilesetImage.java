package com.ultradrive.mapconvert.processing.tileset.block.image;

import java.util.List;


public class TilesetImage
{
    private final List<TilesetImagePattern> patterns;
    private final TilesetImagePalette palette;
    private final int width;
    private final int height;

    public TilesetImage(List<TilesetImagePattern> patterns, TilesetImagePalette palette, int width, int height)
    {
        this.patterns = patterns;
        this.palette = palette;
        this.width = width;
        this.height = height;
    }

    public TilesetImagePattern getImagePattern(int row, int column)
    {
        return patterns.get(row * width / 8 + column);
    }

    public TilesetImagePalette getPalette()
    {
        return palette;
    }

    public int getHeight()
    {
        return height;
    }

    public int getWidth()
    {
        return width;
    }
}

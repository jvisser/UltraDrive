package com.ultradrive.mapconvert.render;

import com.ultradrive.mapconvert.common.Point;
import com.ultradrive.mapconvert.processing.map.SquashedTileMap;
import com.ultradrive.mapconvert.processing.map.TileMap;
import com.ultradrive.mapconvert.processing.tileset.block.image.TilesetImagePalette;
import com.ultradrive.mapconvert.processing.tileset.block.image.TilesetImagePattern;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.awt.image.WritableRaster;


public class MapRenderer
{
    private final Color backgroundColor;

    public MapRenderer()
    {
        this.backgroundColor = Color.GRAY;
    }

    public MapRenderer(Color backgroundColor)
    {
        this.backgroundColor = backgroundColor;
    }

    public BufferedImage renderMap(TileMap map)
    {
        SquashedTileMap squashedTileMap = map.squash();

        int mapWidth = squashedTileMap.getWidth();
        int mapHeight = squashedTileMap.getHeight();

        int imageWidth = mapWidth * Pattern.DIMENSION_SIZE;
        int imageHeight = mapHeight * Pattern.DIMENSION_SIZE;

        BufferedImage image = new BufferedImage(imageWidth, imageHeight, BufferedImage.TYPE_INT_ARGB);
        WritableRaster raster = image.getRaster();

        for (int row = 0; row < mapHeight; row++)
        {
            for (int column = 0; column < mapWidth; column++)
            {
                renderPattern(raster, squashedTileMap, row, column);
            }
        }

        return image;
    }

    private void renderPattern(WritableRaster raster, SquashedTileMap squashedTileMap, int row, int column)
    {
        int patternX = column * Pattern.DIMENSION_SIZE;
        int patternY = row * Pattern.DIMENSION_SIZE;

        TilesetImagePattern imagePattern = squashedTileMap.getImagePattern(row, column);
        Pattern pattern = imagePattern.getPattern();

        TilesetImagePalette palette = squashedTileMap.getTileset().getPalette();
        for (int y = 0; y < Pattern.DIMENSION_SIZE; y++)
        {
            for (int x = 0; x < Pattern.DIMENSION_SIZE; x++)
            {
                Color color = backgroundColor;

                int pixelValue = pattern.getValue(new Point(x, y));
                if (pixelValue != 0)
                {
                    color = new Color(palette.getColor(imagePattern.getPaletteId().toGlobalColorIndex(pixelValue)).getRGB(), false);
                }

                int[] rgba = new int[] { color.getRed(), color.getGreen(), color.getBlue(), color.getAlpha() };

                raster.setPixel(patternX + x, patternY + y, rgba);
            }
        }
    }
}

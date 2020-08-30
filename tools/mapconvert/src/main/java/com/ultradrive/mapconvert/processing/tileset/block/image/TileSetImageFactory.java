package com.ultradrive.mapconvert.processing.tileset.block.image;

import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternPaletteId;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.awt.image.IndexColorModel;
import java.awt.image.Raster;
import java.io.IOException;
import java.net.URL;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static java.lang.String.format;


public class TileSetImageFactory
{
    private TileSetImageFactory()
    {
    }

    public static TilesetImage fromURL(URL url)
    {
        try
        {
            return fromBufferedImage(ImageIO.read(url));
        }
        catch (IOException ioe)
        {
            throw new IllegalArgumentException(format("Invalid image url: %s", url), ioe);
        }
    }

    public static TilesetImage fromBufferedImage(BufferedImage image)
    {
        verifyImage(image);

        int width = image.getWidth();
        int height = image.getHeight();

        List<TilesetImagePattern> imagePatterns = new ArrayList<>((width * height) / Pattern.PIXEL_COUNT);
        IndexColorModel colorModel = (IndexColorModel) image.getColorModel();

        Raster raster = image.getData();
        for (int y = 0; y < height; y += Pattern.DIMENSION_SIZE)
        {
            for (int x = 0; x < width; x += Pattern.DIMENSION_SIZE)
            {
                try
                {
                    imagePatterns.add(
                            pixelsToTilesetImagePattern(
                                    raster.getPixels(x, y,
                                                     Pattern.DIMENSION_SIZE,
                                                     Pattern.DIMENSION_SIZE,
                                                     new int[Pattern.PIXEL_COUNT]),
                                    colorModel.getTransparentPixel()));
                }
                catch (IllegalArgumentException eae)
                {
                    throw new IllegalArgumentException(format("At (x: %d, y: %d): %s", x, y, eae.getMessage()), eae);
                }
            }
        }

        return new TilesetImage(imagePatterns, createPalette(colorModel), width, height);
    }

    private static void verifyImage(BufferedImage image)
    {
        if (image.getType() != BufferedImage.TYPE_BYTE_INDEXED)
        {
            throw new IllegalArgumentException(
                    format("Incorrect image type (%d). Only TYPE_BYTE_INDEXED supported.", image.getType()));
        }

        if (((image.getWidth() | image.getHeight()) & (Pattern.DIMENSION_SIZE - 1)) != 0)
        {
            throw new IllegalArgumentException(
                    format("Image width and height must be a multiple of %d", Pattern.DIMENSION_SIZE));
        }
    }

    private static TilesetImagePattern pixelsToTilesetImagePattern(int[] pixels, int transParentPixel)
    {
        Integer[] patternData = new Integer[Pattern.PIXEL_COUNT];

        int patternIndex = 0;
        int transparentPixelCount = 0;
        PatternPaletteId paletteId = PatternPaletteId.INVALID;
        for (int y = 0; y < Pattern.DIMENSION_SIZE; y++)
        {
            for (int x = 0; x < Pattern.DIMENSION_SIZE; x++)
            {
                int pixelValue = pixels[patternIndex];
                if (pixelValue == transParentPixel)
                {
                    patternData[patternIndex++] = 0;
                    transparentPixelCount++;
                }
                else
                {
                    try
                    {
                        TilesetImagePatternPixel patternPixel = new TilesetImagePatternPixel(pixelValue);
                        if (paletteId.isInvalid())
                        {
                            paletteId = patternPixel.getPaletteId();
                        }

                        if (patternPixel.getPaletteId() != paletteId)
                        {
                            throw new IllegalArgumentException("8x8 pixel block references more than one palette");
                        }

                        patternData[patternIndex++] = patternPixel.getColorIndex();
                    }
                    catch (IllegalArgumentException eae)
                    {
                        throw new IllegalArgumentException(
                                format("%s at local coordinates: x: %d, y: %d", eae.getMessage(), x, y), eae);
                    }
                }
            }
        }

        if (transparentPixelCount == Pattern.PIXEL_COUNT)
        {
            paletteId = PatternPaletteId.FIRST;
        }

        return new TilesetImagePattern(new Pattern(Arrays.asList(patternData)), paletteId);
    }

    private static TilesetImagePalette createPalette(IndexColorModel colorModel)
    {
        List<Integer> palette = new ArrayList<>(TilesetImagePalette.PALETTE_SIZE);
        for (int i = 0; i < TilesetImagePalette.PALETTE_SIZE; i++)
        {
            palette.add(colorModel.getRGB(i));
        }

        return new TilesetImagePalette(palette);
    }
}

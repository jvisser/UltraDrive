package com.ultradrive.mapconvert.processing.tileset.block.image;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.stream.Collectors;
import javax.annotation.Nonnull;

import static java.util.stream.Collectors.toUnmodifiableList;


public class TilesetImagePalette implements Iterable<TilesetImageColor>
{
    public static final int PALETTE_SIZE = 64;

    private final List<TilesetImageColor> colors;

    public TilesetImagePalette(List<Integer> rgb)
    {
        this.colors = rgb.stream()
                .limit(PALETTE_SIZE)
                .map(TilesetImageColor::new)
                .collect(toUnmodifiableList());
    }

    private TilesetImagePalette(ArrayList<TilesetImageColor> colors) // F'n type erasure
    {
        this.colors = colors;
    }

    @Override
    @Nonnull
    public Iterator<TilesetImageColor> iterator()
    {
        return colors.iterator();
    }

    public TilesetImageColor getColor(int index)
    {
        return colors.get(index);
    }

    public TilesetImagePalette blend(TilesetImageColor color, float amount)
    {
        return new TilesetImagePalette(colors.stream()
                                               .map(sourceColor -> sourceColor.blend(color, amount))
                                               .collect(Collectors.toCollection(ArrayList::new)));
    }

    public int getSize()
    {
        return colors.size();
    }
}

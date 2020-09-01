package com.ultradrive.mapconvert.processing.tileset.block.image;

import com.ultradrive.mapconvert.common.BitPacker;
import com.ultradrive.mapconvert.common.Packable;
import java.util.Map;
import java.util.TreeMap;

public class TilesetImageColor implements Packable
{
    // See: http://gendev.spritesmind.net/forum/viewtopic.php?f=22&t=2188
    private static final TreeMap<Integer, Integer> componentColorRamp = new TreeMap<>(
            Map.of(0, 0,
                    52, 1,
                    87, 2,
                    116, 3,
                    144, 4,
                    172, 5,
                    206, 6,
                    255, 7));

    private static int get3BitComponentValue(int component)
    {
        Integer floorKey = componentColorRamp.floorKey(component);
        Integer ceilKey = componentColorRamp.ceilingKey(component);

        return componentColorRamp.get(component - floorKey > ceilKey - component ? ceilKey : floorKey);
    }

    private final int rgb;

    public TilesetImageColor(int rgb)
    {
        this.rgb = rgb;
    }

    public int getRGB()
    {
        return rgb;
    }

    @Override
    public BitPacker pack()
    {
        int r = get3BitComponentValue((rgb >> 16) & 0xff);
        int g = get3BitComponentValue((rgb >> 8) & 0xff);
        int b = get3BitComponentValue(rgb & 0xff);

        return new BitPacker(Short.SIZE)
                .pad(1).add(b, 3)
                .pad(1).add(g, 3)
                .pad(1).add(r, 3);
    }
}

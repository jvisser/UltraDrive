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

    private static int get8BitComponentValue(int component)
    {
        Integer floorKey = componentColorRamp.floorKey(component);
        Integer ceilKey = componentColorRamp.ceilingKey(component);

        return component - floorKey > ceilKey - component ? ceilKey : floorKey;
    }

    private static int get3BitComponentValue(int component)
    {
        return componentColorRamp.get(get8BitComponentValue(component));
    }

    private final int rgb;

    public TilesetImageColor(int rgb)
    {
        this.rgb = rgb;
    }

    public TilesetImageColor blend(TilesetImageColor color, float ratio)
    {
        float thisRatio = 1.0f - ratio;

        int ra = (rgb >> 16) & 0xff;
        int ga = (rgb >> 8) & 0xff;
        int ba = rgb & 0xff;

        int rb = (color.rgb >> 16) & 0xff;
        int gb = (color.rgb >> 8) & 0xff;
        int bb = color.rgb & 0xff;

        int r = (int)((ra * thisRatio) + (rb * ratio));
        int g = (int)((ga * thisRatio) + (gb * ratio));
        int b = (int)((ba * thisRatio) + (bb * ratio));

        return new TilesetImageColor((r << 16) | (g << 8) | b);
    }

    public int getRGB()
    {
        return rgb;
    }

    public int getClampedRGB()
    {
        int r = get8BitComponentValue((rgb >> 16) & 0xff);
        int g = get8BitComponentValue((rgb >> 8) & 0xff);
        int b = get8BitComponentValue(rgb & 0xff);

        return r << 16 | g << 8 | b;
    }

    @Override
    public BitPacker pack()
    {
        int r = get3BitComponentValue((rgb >> 16) & 0xff);
        int g = get3BitComponentValue((rgb >> 8) & 0xff);
        int b = get3BitComponentValue(rgb & 0xff);

        return new BitPacker(Short.SIZE)
                .pad(1).add(r, 3)
                .pad(1).add(g, 3)
                .pad(1).add(b, 3);
    }
}

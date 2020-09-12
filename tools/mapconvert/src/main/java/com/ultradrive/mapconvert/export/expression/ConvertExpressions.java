package com.ultradrive.mapconvert.export.expression;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ultradrive.mapconvert.common.ByteIterableInputStream;
import com.ultradrive.mapconvert.processing.tileset.block.image.TilesetImageColor;
import java.io.IOException;
import java.util.HashMap;


public class ConvertExpressions
{
    private final ObjectMapper jsonMapper;

    public ConvertExpressions()
    {
        jsonMapper = new ObjectMapper();
    }

    public HashMap<?, ?> json(Iterable<Byte> byteIterable) throws IOException
    {
        try
        {
            return jsonMapper.readValue(new ByteIterableInputStream(byteIterable.iterator()), HashMap.class);
        }
        catch (JsonProcessingException e)
        {
            return null;
        }
    }

    public HashMap<?, ?> json(String json)
    {
        try
        {
            return jsonMapper.readValue(json, HashMap.class);
        }
        catch (JsonProcessingException e)
        {
            return null;
        }
    }

    public Number hex(String prefix, String value)
    {
        return Long.parseUnsignedLong(value.substring(prefix.length()), 16);
    }

    public Number hex(String value)
    {
        return hex("", value);
    }

    public TilesetImageColor color(Number rgb)
    {
        return new TilesetImageColor(rgb.intValue());
    }

    public TilesetImageColor color(String prefix, String hexRgb)
    {
        return color(hex(prefix, hexRgb));
    }

    public TilesetImageColor color(String hexRgb)
    {
        return color(hex(hexRgb));
    }
}

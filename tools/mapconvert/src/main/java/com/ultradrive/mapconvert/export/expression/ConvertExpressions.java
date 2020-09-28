package com.ultradrive.mapconvert.export.expression;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLMapper;
import com.ultradrive.mapconvert.common.ByteIterableInputStream;
import com.ultradrive.mapconvert.processing.tileset.block.image.TilesetImageColor;
import java.io.IOException;
import java.util.HashMap;


public class ConvertExpressions
{
    private final ObjectMapper jsonMapper;
    private final YAMLMapper yamlMapper;

    public ConvertExpressions()
    {
        jsonMapper = new ObjectMapper();
        yamlMapper = new YAMLMapper();
    }

    public HashMap<?, ?> json(Iterable<Byte> byteIterable) throws IOException
    {
        return readJsonable(jsonMapper, byteIterable);
    }

    public HashMap<?, ?> yaml(Iterable<Byte> byteIterable) throws IOException
    {
        return readJsonable(yamlMapper, byteIterable);
    }

    public HashMap<?, ?> readJsonable(ObjectMapper mapper, Iterable<Byte> byteIterable) throws IOException
    {
        try
        {
            return mapper.readValue(new ByteIterableInputStream(byteIterable.iterator()), HashMap.class);
        }
        catch (JsonProcessingException e)
        {
            return null;
        }
    }

    public HashMap<?, ?> json(String json)
    {
        return readJsonable(jsonMapper, json);
    }

    public HashMap<?, ?> yaml(String json)
    {
        return readJsonable(yamlMapper, json);
    }

    public HashMap<?, ?> readJsonable(ObjectMapper mapper, String json)
    {
        try
        {
            return mapper.readValue(json, HashMap.class);
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

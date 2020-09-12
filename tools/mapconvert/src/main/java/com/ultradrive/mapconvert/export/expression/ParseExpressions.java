package com.ultradrive.mapconvert.export.expression;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ultradrive.mapconvert.common.ByteIterableInputStream;
import java.io.IOException;
import java.util.HashMap;


public class ParseExpressions
{
    private final ObjectMapper jsonMapper;

    public ParseExpressions()
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
}

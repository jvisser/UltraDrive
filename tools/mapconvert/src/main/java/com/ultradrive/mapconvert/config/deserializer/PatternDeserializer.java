package com.ultradrive.mapconvert.config.deserializer;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.JsonDeserializer;
import com.google.common.base.Splitter;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;
import java.io.IOException;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;


public class PatternDeserializer extends JsonDeserializer<Pattern>
{
    @Override
    public Pattern deserialize(JsonParser p, DeserializationContext context) throws IOException
    {
        String value = p.getValueAsString();

        if (value.length() == 128)
        {
            return new Pattern(StreamSupport.stream(Splitter.fixedLength(2).split(value).spliterator(), false)
                    .map(v -> Integer.parseUnsignedInt(v, 16))
                    .collect(Collectors.toList()));
        }
        else
        {
            throw context.weirdStringException(value, Pattern.class, "Expected 64 hex bytes");
        }
    }
}
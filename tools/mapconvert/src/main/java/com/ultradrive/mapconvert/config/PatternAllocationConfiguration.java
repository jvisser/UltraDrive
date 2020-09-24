package com.ultradrive.mapconvert.config;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.module.SimpleModule;
import com.fasterxml.jackson.dataformat.yaml.YAMLMapper;
import com.ultradrive.mapconvert.config.deserializer.PatternDeserializer;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;
import java.io.File;
import java.io.IOException;
import java.util.List;


public class PatternAllocationConfiguration
{
    private final List<PatternAllocationRange> patternAllocationRanges;
    private final List<PreAllocatedPattern> preAllocatedPatterns;

    public static PatternAllocationConfiguration read(File file) throws IOException
    {
        YAMLMapper mapper = new YAMLMapper();

        SimpleModule module = new SimpleModule();
        module.addDeserializer(Pattern.class, new PatternDeserializer());
        mapper.registerModule(module);

        return mapper.readValue(file, PatternAllocationConfiguration.class);
    }

    @JsonCreator
    public PatternAllocationConfiguration(@JsonProperty ("patternRanges") List<PatternAllocationRange> patternAllocationRanges,
                                          @JsonProperty ("preAllocatedPatterns") List<PreAllocatedPattern> preAllocatedPatterns)
    {
        this.patternAllocationRanges = patternAllocationRanges;
        this.preAllocatedPatterns = preAllocatedPatterns;
    }

    public List<PatternAllocationRange> getPatternRanges()
    {
        return patternAllocationRanges;
    }

    public List<PreAllocatedPattern> getPreAllocatedPatterns()
    {
        return preAllocatedPatterns;
    }
}

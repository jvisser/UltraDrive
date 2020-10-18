package com.ultradrive.mapconvert.processing.tileset.block.pattern.allocator;

import com.ultradrive.mapconvert.common.orientable.OrientablePoolListener;
import com.ultradrive.mapconvert.common.orientable.Orientation;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternPool;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternReference;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternReferenceProducer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import static java.lang.String.format;


public class PatternAllocator implements OrientablePoolListener<Pattern, PatternReference>, PatternReferenceProducer
{
    private final PatternPool patternPool = new PatternPool();
    private final Map<Pattern, PatternReference> preAllocatedPatterns = new HashMap<>();
    private final Map<Integer, Integer> patternAllocation = new HashMap<>();
    private final List<PatternAllocatorSection> sections = new ArrayList<>();

    public PatternAllocator()
    {
        patternPool.addListener(this);
    }

    @Override
    public void onPoolInsert(PatternReference reference, Pattern pattern)
    {
        patternAllocation.put(reference.getReferenceId(), allocate(pattern));
    }

    @Override
    public PatternReference.Builder getReference(Pattern pattern)
    {
        PatternReference preAllocatedPatternReference = preAllocatedPatterns.get(pattern);
        if (preAllocatedPatternReference != null)
        {
            return preAllocatedPatternReference.builder();
        }

        PatternReference.Builder referenceBuilder = patternPool.getReference(pattern);

        referenceBuilder.setReferenceId(patternAllocation.get(referenceBuilder.getReferenceId()));

        return referenceBuilder;
    }

    public void addPreAllocatedPattern(int patternId, Pattern pattern)
    {
        for (Orientation orientation : Orientation.values())
        {
            PatternReference.Builder referenceBuilder = pattern.referenceBuilder();
            referenceBuilder.setOrientation(orientation);
            referenceBuilder.setReferenceId(patternId);

            preAllocatedPatterns.put(pattern.reorient(orientation), referenceBuilder.build());
        }
    }

    public void addSection(String id, int startPatternId, int endPatternPatternId)
    {
        sections.add(new PatternAllocatorSection(id, startPatternId, endPatternPatternId));
    }

    private int allocate(Pattern pattern)
    {
        return getAllocatableSection(1).allocate(pattern);
    }

    public int reserve(int numberOfPatterns)
    {
        return getAllocatableSection(numberOfPatterns).reserve(numberOfPatterns);
    }

    private PatternAllocatorSection getAllocatableSection(int numberOfPatterns)
    {
        return sections.stream()
                .filter(section -> section.hasSpace(numberOfPatterns))
                .findFirst()
                .orElseThrow(() -> new PatternAllocationException(
                        format("Unable for allocation space for %d pattern(s)", numberOfPatterns)));
    }

    public PatternAllocation compile()
    {
        return new PatternAllocation(sections.stream()
                .map(PatternAllocatorSection::compile)
                .collect(Collectors.toList()));
    }
}

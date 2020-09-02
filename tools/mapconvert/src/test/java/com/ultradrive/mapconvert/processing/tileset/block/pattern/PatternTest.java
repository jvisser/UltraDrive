package com.ultradrive.mapconvert.processing.tileset.block.pattern;

import com.ultradrive.mapconvert.common.orientable.SymmetryTester;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.StreamSupport;
import org.junit.jupiter.api.Test;

import static com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern.PIXEL_COUNT;
import static com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern.PIXEL_VALUE_MASK;
import static org.junit.jupiter.api.Assertions.assertArrayEquals;


class PatternTest
{
    @Test
    void getSymmetry()
    {
        Pattern base = createPattern(0);
        Pattern equalsByValue = createPattern(0);
        Pattern notEqualsByValue = createPattern(1);

        SymmetryTester<Pattern> symmetryTester = new SymmetryTester<>();
        symmetryTester.testSymmetry(base, equalsByValue, notEqualsByValue);
    }

    @Test
    void pack()
    {
        Integer[] packedPattern = StreamSupport.stream(createPattern(0).spliterator(), false)
                .map(patternRow -> patternRow.pack().intValue())
                .toArray(Integer[]::new);

        assertArrayEquals(new Integer[] {
                0x01234567,
                0x89abcdef,
                0x01234567,
                0x89abcdef,
                0x01234567,
                0x89abcdef,
                0x01234567,
                0x89abcdef,
                }, packedPattern);
    }

    private Pattern createPattern(int seed)
    {
        List<Integer> data = new ArrayList<>(PIXEL_COUNT);
        for (int i = 0; i < PIXEL_COUNT; i++)
        {
            data.add((seed + i) & PIXEL_VALUE_MASK);
        }
        return new Pattern(data);
    }
}
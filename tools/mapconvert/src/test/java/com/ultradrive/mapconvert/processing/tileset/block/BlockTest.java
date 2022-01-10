package com.ultradrive.mapconvert.processing.tileset.block;

import com.ultradrive.mapconvert.common.orientable.Orientation;
import com.ultradrive.mapconvert.common.orientable.SymmetryTester;
import com.ultradrive.mapconvert.datasource.model.BlockAnimationModel;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternPaletteId;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternPriority;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternReference;
import java.util.List;
import org.junit.jupiter.api.Test;


class BlockTest
{
    @Test
    void getSymmetry()
    {
        List<PatternReference> patternReferences = createPatternReferences();

        Block base = block(0, patternReferences);
        Block equalsByValue = block(0, patternReferences);
        Block notEqualsByValue = block(1, patternReferences);

        SymmetryTester<Block> symmetryTester = new SymmetryTester<>();
        symmetryTester.testSymmetry(base, equalsByValue, notEqualsByValue);
    }

    private Block block(int collisionId, List<PatternReference> patternReferences)
    {
        return new Block(collisionId, new BlockAnimationMetadata(BlockAnimationModel.empty()), patternReferences);
    }

    private List<PatternReference> createPatternReferences()
    {
        return List.of(
                new PatternReference(0, PatternPaletteId.FIRST, PatternPriority.LOW, Orientation.DEFAULT, false),
                new PatternReference(1, PatternPaletteId.FIRST, PatternPriority.LOW, Orientation.DEFAULT, false),
                new PatternReference(2, PatternPaletteId.FIRST, PatternPriority.LOW, Orientation.DEFAULT, false),
                new PatternReference(3, PatternPaletteId.FIRST, PatternPriority.LOW, Orientation.DEFAULT, false)
                );
    }
}
package com.ultradrive.mapconvert.processing.tileset.chunk;

import com.ultradrive.mapconvert.common.orientable.Orientation;
import com.ultradrive.mapconvert.common.orientable.SymmetryTester;
import com.ultradrive.mapconvert.processing.tileset.block.BlockReference;
import com.ultradrive.mapconvert.processing.tileset.block.BlockSolidity;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;


class ChunkTest
{

    @Test
    void reorient()
    {
        List<BlockReference> blockReferences =
                createChunkBlockReferences(0);

        Chunk base = new Chunk(createChunkBlockReferences(0));
        Chunk equalsByValue = new Chunk(createChunkBlockReferences(0));
        Chunk notEqualsByValue = new Chunk(createChunkBlockReferences(1));

        SymmetryTester<Chunk> symmetryTester = new SymmetryTester<>();
        symmetryTester.testSymmetry(base, equalsByValue, notEqualsByValue);
    }

    private List<BlockReference> createChunkBlockReferences(int seed)
    {
        return IntStream.range(0, 8 * 8)
                .mapToObj(value -> new BlockReference(seed + value, Orientation.DEFAULT, BlockSolidity.ALL, 0))
                .collect(Collectors.toList());
    }
}
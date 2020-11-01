package com.ultradrive.mapconvert.processing.map;

import com.ultradrive.mapconvert.common.Point;
import com.ultradrive.mapconvert.common.orientable.Orientation;
import com.ultradrive.mapconvert.config.PreAllocatedPattern;
import com.ultradrive.mapconvert.processing.tileset.Tileset;
import com.ultradrive.mapconvert.processing.tileset.block.Block;
import com.ultradrive.mapconvert.processing.tileset.block.BlockReference;
import com.ultradrive.mapconvert.processing.tileset.block.image.TilesetImagePattern;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternReference;
import com.ultradrive.mapconvert.processing.tileset.chunk.Chunk;
import com.ultradrive.mapconvert.processing.tileset.chunk.ChunkReference;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileMetrics;
import java.util.Iterator;
import java.util.List;
import java.util.NoSuchElementException;
import javax.annotation.Nonnull;

import static java.lang.String.format;


/**
 * For testing/debugging purposes only
 */
public class SquashedTileMap implements Iterable<PatternReference>
{
    private final TileMap map;
    private final Tileset tileset;
    private final List<PreAllocatedPattern> externalPatterns;

    SquashedTileMap(TileMap map, List<PreAllocatedPattern> externalPatterns)
    {
        this.map = map;
        this.tileset = map.getTileset();
        this.externalPatterns = externalPatterns;
    }

    @Override
    @Nonnull
    public Iterator<PatternReference> iterator()
    {
        return new Iterator<>()
        {
            int current = 0;

            @Override
            public boolean hasNext()
            {
                int total = getWidth() * getHeight();

                return current < total;
            }

            @Override
            public PatternReference next()
            {
                int row = current / getWidth();
                int column = current % getWidth();

                PatternReference patternReference = getPatternReference(row, column);

                current++;

                return patternReference;
            }
        };
    }

    public String getName()
    {
        return map.getName();
    }

    public int getWidth()
    {
        return map.getWidth() * getChunkSizeInPatterns();
    }

    public int getHeight()
    {
        return map.getHeight() * getChunkSizeInPatterns();
    }

    public PatternReference getPatternReference(int row, int column)
    {
        MetaTileMetrics chunkMetrics = tileset.getChunkMetrics();
        int chunkSizeInBlocks = chunkMetrics.getTileSizeInSubTiles();

        int chunkSizeInPatterns = getChunkSizeInPatterns();
        int blockSizeInPatterns = tileset.getBlockMetrics().getTileSizeInSubTiles();

        int chunkRow = row / chunkSizeInPatterns;
        int chunkColumn = column / chunkSizeInPatterns;

        int blockRow = (row % chunkSizeInPatterns) / blockSizeInPatterns;
        int blockColumn = (column % chunkSizeInPatterns) / blockSizeInPatterns;

        int patternRow = row % blockSizeInPatterns;
        int patternColumn = column % blockSizeInPatterns;

        ChunkReference chunkReference = map.getChunkReference(chunkRow, chunkColumn);
        Chunk chunk = tileset.getChunk(chunkReference.getReferenceId());

        Point blockCoordinate =
                chunkReference.getOrientation().translate(new Point(blockColumn, blockRow), chunkSizeInBlocks);
        BlockReference blockReference = chunk.getTileReference(blockCoordinate);
        Block block = tileset.getBlock(blockReference.getReferenceId());

        Orientation patternReferenceOrientation =
                blockReference.getOrientation().translate(chunkReference.getOrientation());
        Point patternReferenceCoordinate =
                patternReferenceOrientation.translate(new Point(patternColumn, patternRow), blockSizeInPatterns);

        return block.getTileReference(patternReferenceCoordinate)
                .reorient(patternReferenceOrientation);
    }

    public TilesetImagePattern getImagePattern(int row, int column)
    {
        PatternReference patternReference = getPatternReference(row, column);

        int referenceId = patternReference.getReferenceId();
        Pattern pattern = tileset.getPattern(referenceId)
                .or(() -> externalPatterns.stream()
                        .filter(preAllocatedPattern -> preAllocatedPattern.getPatternId() == referenceId)
                        .map(PreAllocatedPattern::getPattern)
                        .findAny())
                .orElseThrow(() -> new NoSuchElementException(format("No pattern found in pre-allocated, static or animation patterns for pattern id %d", referenceId)))
                .reorient(patternReference.getOrientation());

        return new TilesetImagePattern(pattern, patternReference.getPaletteId());
    }

    private int getChunkSizeInPatterns()
    {
        MetaTileMetrics chunkMetrics = tileset.getChunkMetrics();
        MetaTileMetrics blockMetrics = tileset.getBlockMetrics();

        return chunkMetrics.getTileSizeInSubTiles() * blockMetrics.getTileSizeInSubTiles();
    }

    public TileMap getMap()
    {
        return map;
    }

    public Tileset getTileset()
    {
        return tileset;
    }
}

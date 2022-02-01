package com.ultradrive.mapconvert.processing.map.metadata;

import com.ultradrive.mapconvert.processing.tileset.chunk.ChunkReference;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;
import javax.annotation.Nonnull;


public final class TileMapOverlay implements Iterable<ChunkReference>
{
    private final List<Integer> rowOffsets;
    private final List<ChunkReference> chunkReferences;

    private TileMapOverlay(List<Integer> rowOffsets, List<ChunkReference> chunkReferences)
    {
        this.rowOffsets = rowOffsets;
        this.chunkReferences = chunkReferences;
    }

    @Nonnull
    @Override
    public Iterator<ChunkReference> iterator()
    {
        return chunkReferences.iterator();
    }

    public static TileMapOverlay create(ChunkReference[][] overlayReferences, int width, int height)
    {
        List<Integer> rowOffsets = new ArrayList<>();
        List<ChunkReference> chunkReferences = new ArrayList<>();

        Map<List<ChunkReference>, Integer> rowDeduplicationMap = new HashMap<>();

        int rowIndex = 0;
        for (int row = 0; row < height; row++)
        {
            boolean hasData = Stream.of(overlayReferences[row])
                    .reduce(false,
                            (intermediatResult, chunkReference) ->
                                    intermediatResult || chunkReference.hasAnyInformation(),
                            (a, b) -> a);

            if (hasData)
            {
                List<ChunkReference> overlayRow = List.of(overlayReferences[row]);

                if (rowDeduplicationMap.containsKey(overlayRow))
                {
                    rowOffsets.add(rowDeduplicationMap.get(overlayRow));
                }
                else
                {
                    chunkReferences.addAll(overlayRow);
                    rowDeduplicationMap.put(overlayRow, rowIndex);
                    rowOffsets.add(rowIndex);

                    rowIndex += width;
                }
            }
            else
            {
                rowOffsets.add(0);
            }
        }

        for (int i = rowOffsets.size(); i < 8; i++)
        {
            rowOffsets.add(0);
        }

        return new TileMapOverlay(rowOffsets, chunkReferences);
    }

    public List<Integer> getRowOffsets()
    {
        return rowOffsets;
    }

    public boolean isEmpty()
    {
        return getChunkReferences().isEmpty();
    }

    public List<ChunkReference> getChunkReferences()
    {
        return chunkReferences;
    }
}

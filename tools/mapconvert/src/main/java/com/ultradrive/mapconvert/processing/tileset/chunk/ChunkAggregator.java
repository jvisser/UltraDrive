package com.ultradrive.mapconvert.processing.tileset.chunk;

import com.ultradrive.mapconvert.datasource.ChunkModelProducer;
import com.ultradrive.mapconvert.datasource.model.ChunkElementModel;
import com.ultradrive.mapconvert.datasource.model.ChunkModel;
import com.ultradrive.mapconvert.datasource.model.ResourceReference;
import com.ultradrive.mapconvert.processing.tileset.block.BlockAggregator;
import com.ultradrive.mapconvert.processing.tileset.block.BlockReference;
import com.ultradrive.mapconvert.processing.tileset.block.BlockSolidity;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileMetrics;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;


public class ChunkAggregator
{
    private final ChunkModelProducer chunkModelProducer;
    private final MetaTileMetrics chunkMetrics;
    private final BlockAggregator blockAggregator;

    private final ChunkPool chunkPool;
    private final Map<Integer, ChunkReference> chunkReferenceIndex;

    public ChunkAggregator(ChunkModelProducer chunkModelProducer, MetaTileMetrics chunkMetrics, BlockAggregator blockAggregator)
    {
        this.chunkModelProducer = chunkModelProducer;
        this.chunkMetrics = chunkMetrics;
        this.blockAggregator = blockAggregator;

        this.chunkPool = new ChunkPool();
        this.chunkReferenceIndex = new HashMap<>();
    }

    public ChunkReference.Builder getChunkReference(int chunkId)
    {
        ChunkReference chunkReference = chunkReferenceIndex.get(chunkId);
        if (chunkReference == null)
        {
            return addChunk(chunkId);
        }

        return chunkReference.builder();
    }

    private ChunkReference.Builder addChunk(int chunkId)
    {
        ChunkModel chunkModel = chunkModelProducer.getChunkModel(chunkId);

        List<BlockReference> blockReferences =
                chunkModel.getElements().stream()
                        .map(this::getChunkBlockReference)
                        .collect(Collectors.toList());
        Chunk chunk = new Chunk(blockReferences);

        ChunkReference.Builder chunkReferenceBuilder = chunkPool.getReference(chunk);
        chunkReferenceIndex.put(chunkId, chunkReferenceBuilder.build());

        return chunkReferenceBuilder;
    }

    private BlockReference getChunkBlockReference(ChunkElementModel chunkElementModel)
    {
        ResourceReference chunkBlockResourceReference = chunkElementModel.getBlockReference();

        BlockReference.Builder blockReferenceBuilder = blockAggregator.getReference(chunkBlockResourceReference.getId());
        blockReferenceBuilder.reorient(chunkBlockResourceReference.getOrientation());
        blockReferenceBuilder.setSolidity(BlockSolidity.fromId(chunkElementModel.getSolidityReference().getId()));
        blockReferenceBuilder.setType(chunkElementModel.getTypeReference().getId());

        return blockReferenceBuilder.build();
    }

    public ChunkTileset compile()
    {
        return new ChunkTileset(chunkPool.getCache(), chunkMetrics);
    }
}

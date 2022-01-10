package com.ultradrive.mapconvert.processing.tileset.block;

import com.ultradrive.mapconvert.datasource.model.BlockModel;
import com.ultradrive.mapconvert.datasource.model.ResourceReference;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternReference;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileMetrics;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.IntStream;


class BlockFactory
{
    private final MetaTileMetrics blockMetrics;
    private final BlockPatternReferenceProducerFactory blockPatternReferenceProducerFactory;

    BlockFactory(MetaTileMetrics blockMetrics, BlockPatternReferenceProducerFactory blockPatternReferenceProducerFactory)
    {
        this.blockMetrics = blockMetrics;
        this.blockPatternReferenceProducerFactory = blockPatternReferenceProducerFactory;
    }

    public Block createBlock(BlockModel blockModel)
    {
        ResourceReference graphicReference = blockModel.getGraphicReference();
        ResourceReference collisionReference = blockModel.getCollisionReference();

        return new Block(collisionReference.getId(),
                         new BlockAnimationMetadata(blockModel.getAnimation()),
                         getPatternReferences(
                                 blockPatternReferenceProducerFactory.getBlockPatternReferenceProducer(blockModel),
                                 graphicReference,
                                 blockModel.getPriorityReference()))
                .reorient(graphicReference.getOrientation());
    }

    private List<PatternReference> getPatternReferences(
            BlockPatternReferenceProducer patternReferenceProducer,
            ResourceReference graphicReference,
            ResourceReference patternPriorityReference)
    {
        int patternsPerBlockDimension = blockMetrics.getTileSizeInSubTiles();

        BlockPatternPriority priorityMask =
                new BlockPatternPriority(patternPriorityReference.getId(), patternsPerBlockDimension)
                        .reorient(patternPriorityReference.getOrientation())
                        .reorient(graphicReference.getOrientation());

        return IntStream.range(0, patternsPerBlockDimension * patternsPerBlockDimension)
                .mapToObj(patternId -> {
                    PatternReference.Builder referenceBuilder =
                            patternReferenceProducer.getReference(graphicReference.getId(), patternId);
                    referenceBuilder.setPriority(priorityMask.getPriority(patternId));
                    return referenceBuilder.build();
                })
                .collect(Collectors.toList());
    }
}

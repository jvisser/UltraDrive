package com.ultradrive.mapconvert.processing.tileset.block;

import com.ultradrive.mapconvert.datasource.model.BlockModel;
import com.ultradrive.mapconvert.datasource.model.ResourceReference;
import com.ultradrive.mapconvert.processing.tileset.block.animation.AnimationBlockPatternReferenceProducer;
import com.ultradrive.mapconvert.processing.tileset.block.image.ImageBlockPatternReferenceProducer;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternReference;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileMetrics;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.IntStream;


class BlockFactory
{
    private final ImageBlockPatternReferenceProducer imagePatternReferenceProducer;
    private final AnimationBlockPatternReferenceProducer animationPatternReferenceProducer;

    private final MetaTileMetrics blockMetrics;

    BlockFactory(MetaTileMetrics blockMetrics, ImageBlockPatternReferenceProducer imagePatternReferenceProducer)
    {
        this.imagePatternReferenceProducer = imagePatternReferenceProducer;
        this.animationPatternReferenceProducer = new AnimationBlockPatternReferenceProducer(blockMetrics);
        this.blockMetrics = blockMetrics;
    }

    public Block createBlock(BlockModel blockModel)
    {
        ResourceReference graphicReference = blockModel.getGraphicReference();
        ResourceReference collisionReference = blockModel.getCollisionReference();

        return new Block(collisionReference.getId(),
                                new BlockAnimationMetaData(blockModel.getAnimation()),
                                getPatternReferences(
                                        selectPatternReferenceProducer(blockModel),
                                        graphicReference,
                                        blockModel.getPriorityReference()))
                .reorient(graphicReference.getOrientation());
    }

    private BlockPatternReferenceProducer selectPatternReferenceProducer(BlockModel blockModel)
    {
        return blockModel.hasAnimation()
               ? animationPatternReferenceProducer
               : imagePatternReferenceProducer;
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

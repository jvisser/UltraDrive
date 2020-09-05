package com.ultradrive.mapconvert.processing.tileset.block;

import com.ultradrive.mapconvert.datasource.BlockModelProducer;
import com.ultradrive.mapconvert.datasource.model.BlockModel;
import com.ultradrive.mapconvert.datasource.model.ResourceReference;
import com.ultradrive.mapconvert.processing.tileset.block.animation.AnimationBlockPostProcessingResult;
import com.ultradrive.mapconvert.processing.tileset.block.animation.AnimationBlockPostProcessor;
import com.ultradrive.mapconvert.processing.tileset.block.image.ImageBlockPatternProducer;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternPool;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileMetrics;
import java.util.HashMap;
import java.util.Map;


public class BlockAggregator
{
    private final BlockModelProducer blockModelProducer;
    private final ImageBlockPatternProducer imagePatternProducer;
    private final MetaTileMetrics blockMetrics;
    private final int patternBaseId;

    private final BlockFactory blockFactory;
    private final BlockPool blockPool;
    private final Map<Integer, BlockReference> blockReferenceIndex;

    public BlockAggregator(BlockModelProducer blockModelProducer,
                           ImageBlockPatternProducer imagePatternProducer,
                           MetaTileMetrics blockMetrics,
                           int patternBaseId)
    {
        this.blockModelProducer = blockModelProducer;
        this.imagePatternProducer = imagePatternProducer;
        this.blockMetrics = blockMetrics;
        this.patternBaseId = patternBaseId;


        this.blockFactory = new BlockFactory(blockMetrics, patternBaseId, imagePatternProducer);
        this.blockPool = new BlockPool();
        this.blockReferenceIndex = new HashMap<>();
    }

    public BlockReference.Builder getReference(int blockId)
    {
        BlockReference blockReference = blockReferenceIndex.get(blockId);
        if (blockReference == null)
        {
            return addBlock(blockModelProducer.getBlockModel(blockId));
        }

        return blockReference.builder();
    }

    private BlockReference.Builder addBlock(BlockModel blockModel)
    {
        Block block = blockFactory.createBlock(blockModel);

        // Store collision aligned block in block pool
        ResourceReference collisionReference = blockModel.getCollisionReference();
        Block collisionAlignedBlock = block.reorient(collisionReference.getOrientation());
        BlockReference.Builder blockReferenceBuilder = blockPool.getReference(collisionAlignedBlock);

        // Reorient reference to original block graphics orientation
        blockReferenceBuilder.reorient(collisionReference.getOrientation());

        // Map block id to reference
        blockReferenceIndex.put(blockModel.getId(), blockReferenceBuilder.build());

        return blockReferenceBuilder;
    }

    public BlockTileset compile()
    {
        PatternPool patternPool = blockFactory.getPatternPool();
        AnimationBlockPostProcessor animationBlockPostProcessor =
                new AnimationBlockPostProcessor(blockPool.getCache(),
                                                blockMetrics,
                                                imagePatternProducer,
                                                blockFactory.getImagePatternReferenceProducer());

        AnimationBlockPostProcessingResult animationProcessingResult = animationBlockPostProcessor.process();

        return new BlockTileset(
                imagePatternProducer.getPalette(),
                patternPool.getCache(),
                animationProcessingResult.getBlocks(),
                animationProcessingResult.getAnimations(),
                animationProcessingResult.getAnimationFrames(),
                blockMetrics,
                patternBaseId);
    }
}

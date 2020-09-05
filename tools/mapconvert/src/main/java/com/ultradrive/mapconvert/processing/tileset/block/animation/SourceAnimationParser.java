package com.ultradrive.mapconvert.processing.tileset.block.animation;

import com.ultradrive.mapconvert.processing.tileset.block.Block;
import com.ultradrive.mapconvert.processing.tileset.block.BlockAnimationMetaData;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileMetrics;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.TreeMap;
import java.util.stream.StreamSupport;

import static java.lang.String.format;
import static java.util.stream.Collectors.groupingBy;
import static java.util.stream.Collectors.toList;


class SourceAnimationParser
{
    private final List<Block> blocks;
    private final MetaTileMetrics blockMetrics;

    SourceAnimationParser(List<Block> blocks, MetaTileMetrics blockMetrics)
    {
        this.blocks = blocks;
        this.blockMetrics = blockMetrics;
    }

    public List<SourceAnimation> parseAnimations()
    {
        Map<String, List<Block>> animationBlocksByAnimationId = blocks.stream()
                .filter(Block::hasAnimation)
                .collect(groupingBy(block -> block.getAnimationMetaData().getAnimationId()));

        return animationBlocksByAnimationId.entrySet().stream()
                .map(animation -> createAnimation(animation.getKey(), animation.getValue()))
                .collect(toList());
    }

    private SourceAnimation createAnimation(String animationId, List<Block> animationBlocks)
    {
        verifyAnimationRoots(animationId, animationBlocks);

        List<Block> animationBlocksOrderedByGraphicId = orderBlocksByGraphicId(animationId, animationBlocks);
        int frameCount = getFrameCount(animationId, animationBlocksOrderedByGraphicId);

        SourceAnimationFrameReference lastAnimationFrame = null;
        List<SourceAnimationFrameReference> animationFrames = new ArrayList<>(frameCount);
        for (int frameId = 0; frameId < frameCount; frameId++)
        {
            SourceAnimationFrameReference animationFrame = createFrame(frameId, animationBlocksOrderedByGraphicId);

            if (Objects.equals(lastAnimationFrame, animationFrame))
            {
                lastAnimationFrame = lastAnimationFrame.merge(animationFrame);
                animationFrames.set(animationFrames.size() - 1, lastAnimationFrame);
            }
            else
            {
                lastAnimationFrame = animationFrame;
                animationFrames.add(lastAnimationFrame);
            }
        }

        return new SourceAnimation(animationId, animationBlocksOrderedByGraphicId, animationFrames);
    }

    private void verifyAnimationRoots(String animationId, List<Block> animationBlocks)
    {
        for (Block block : animationBlocks)
        {
            int firstFrameGraphicsId = block.getAnimationMetaData().getFrame(0).getGraphicsId();
            if (getGraphicsId(animationId, block) != firstFrameGraphicsId)
            {
                throw new IllegalArgumentException(
                        format("The first frame of an animation block for animation with id '%s' has a different graphic than the block",
                               animationId));
            }
        }
    }

    private List<Block> orderBlocksByGraphicId(String animationId, List<Block> animationBlocks)
    {
        Map<Integer, List<Block>> blocksByGraphicsId = animationBlocks.stream()
                .collect(groupingBy(animationBlock -> getGraphicsId(animationId, animationBlock), TreeMap::new, toList()));

        return blocksByGraphicsId.entrySet().stream()
                .flatMap(orderedBlockEntry -> {
                    List<Block> orderedBlock = orderedBlockEntry.getValue();
                    if (orderedBlock.size() > 1)
                    {
                        throw new IllegalArgumentException(
                                format("Animation with id '%s' references the same graphic element more than once.",
                                       animationId));
                    }
                    return orderedBlock.stream();
                })
                .collect(toList());
    }

    private int getGraphicsId(String animationId, Block block)
    {
        List<Integer> graphicsIds = StreamSupport.stream(block.spliterator(), false)
                .map(patternReference -> new AnimationBlockPatternReferenceEncoding(blockMetrics, patternReference)
                        .getGraphicsId())
                .distinct()
                .collect(toList());

        if (graphicsIds.size() > 1)
        {
            throw new IllegalArgumentException(
                    format("A single block in animation with id '%s' references different graphic elements",
                            animationId));
        }

        return graphicsIds.get(0);
    }

    private int getFrameCount(String animationId, List<Block> animationBlocks)
    {
        List<Integer> animationFrameCounts = animationBlocks.stream()
                .map(block -> block.getAnimationMetaData().getFrameCount())
                .distinct()
                .collect(toList());

        if (animationFrameCounts.size() > 1)
        {
            throw new IllegalArgumentException(
                    format("Not all blocks of animation with id '%s' have the same amount of animation frames.",
                           animationId));
        }

        int animationFrameCount = animationFrameCounts.get(0);
        if (animationFrameCount == 0)
        {
            throw new IllegalArgumentException(
                    format("Animation with id '%s' does not have any animation frames.",
                            animationId));
        }

        return animationFrameCount;
    }

    private SourceAnimationFrameReference createFrame(int frameId, List<Block> animationBlocks)
    {
        int frameTime = 0;
        List<Integer> frameGraphicIds = new ArrayList<>(animationBlocks.size());
        for (Block block : animationBlocks)
        {
            BlockAnimationMetaData.AnimationFrame sourceFrame = block.getAnimationMetaData().getFrame(frameId);

            frameGraphicIds.add(sourceFrame.getGraphicsId());
            frameTime = Math.max(frameTime, sourceFrame.getFrameTime());
        }

        return new SourceAnimationFrameReference(new SourceAnimationFrame(frameGraphicIds), frameTime);
    }
}

package com.ultradrive.mapconvert.processing.tileset.block.animation;

import com.ultradrive.mapconvert.processing.tileset.block.Block;
import com.ultradrive.mapconvert.processing.tileset.block.image.ImageBlockPatternProducer;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternReference;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileMetrics;

import java.util.*;
import java.util.stream.IntStream;
import java.util.stream.Stream;

import static java.util.stream.Collectors.toList;
import static java.util.stream.Collectors.toSet;


public class AnimationBlockPostProcessor
{
    private static final String FRAME_ID_PREFIX = "FRAME_";

    private final List<Block> blocks;
    private final MetaTileMetrics blockMetrics;
    private final ImageBlockPatternProducer patternProducer;
    private final int patternBaseId;

    public AnimationBlockPostProcessor(List<Block> blocks,
                                       MetaTileMetrics blockMetrics,
                                       int patternBaseId,
                                       ImageBlockPatternProducer patternProducer)
    {
        this.blocks = blocks;
        this.blockMetrics = blockMetrics;
        this.patternBaseId = patternBaseId;
        this.patternProducer = patternProducer;
    }

    public AnimationBlockPostProcessingResult process()
    {
        List<SourceAnimation> sourceAnimations = new SourceAnimationParser(blocks, blockMetrics).parseAnimations();

        Set<SourceAnimationFrame> allSourceAnimationFrames = sourceAnimations.stream()
                .flatMap(sourceAnimation -> sourceAnimation.getAnimationFrameReferences().stream()
                        .map(SourceAnimationFrameReference::getAnimationFrame))
                .collect(toSet());

        Map<SourceAnimationFrame, AnimationFrame> resultAnimationFrameMapping = createResultAnimationFrames(allSourceAnimationFrames);
        Map<SourceAnimation, Animation> resultAnimationMapping = createResultAnimations(sourceAnimations, resultAnimationFrameMapping);
        List<Block> resultBlocks = patchAnimationBlockPatternReferences(resultAnimationMapping);

        return new AnimationBlockPostProcessingResult(
                List.copyOf(resultBlocks),
                List.copyOf(resultAnimationMapping.values()),
                List.copyOf(resultAnimationFrameMapping.values()));
    }


    private Map<SourceAnimationFrame, AnimationFrame> createResultAnimationFrames(Set<SourceAnimationFrame> sourceAnimationFrames)
    {
        int frameId = 0;
        Map<SourceAnimationFrame, AnimationFrame> animationFrameMap = new HashMap<>();
        for (SourceAnimationFrame sourceAnimationFrame : sourceAnimationFrames)
        {
            animationFrameMap.put(sourceAnimationFrame, createAnimationFrame(sourceAnimationFrame, frameId++));
        }
        return animationFrameMap;
    }

    private AnimationFrame createAnimationFrame(SourceAnimationFrame sourceAnimationFrame, int frameId)
    {
        List<Pattern> framePatterns = sourceAnimationFrame.getFrameGraphicIds().stream()
                .flatMap(this::getGraphicPatterns)
                .collect(toList());

        return new AnimationFrame(FRAME_ID_PREFIX + frameId, framePatterns);
    }

    private Stream<Pattern> getGraphicPatterns(int graphicId)
    {
        return IntStream.range(0, blockMetrics.getTotalSubTiles())
                .mapToObj(patternId -> patternProducer.getTilesetImagePattern(graphicId, patternId).getPattern());
    }

    private Map<SourceAnimation, Animation> createResultAnimations(List<SourceAnimation> sourceAnimations, Map<SourceAnimationFrame, AnimationFrame> animationFrameMap)
    {
        Map<SourceAnimation, Animation> resultAnimationMapping = new HashMap<>();

        int currentPatternId = patternBaseId;
        for (SourceAnimation sourceAnimation : sourceAnimations)
        {
            Animation resultAnimation = createResultAnimation(animationFrameMap, currentPatternId, sourceAnimation);
            resultAnimationMapping.put(sourceAnimation, resultAnimation);

            currentPatternId += resultAnimation.getSize();
        }
        return resultAnimationMapping;
    }

    private Animation createResultAnimation(Map<SourceAnimationFrame, AnimationFrame> animationFrameMap, int currentPatternId, SourceAnimation sourceAnimation)
    {
        List<AnimationFrameReference> animationFrames = sourceAnimation.getAnimationFrameReferences().stream()
                .map(sourceAnimationFrameReference -> new AnimationFrameReference(
                        animationFrameMap.get(sourceAnimationFrameReference.getAnimationFrame()),
                        sourceAnimationFrameReference.getFrameTime()))
                .collect(toList());

        return new Animation(sourceAnimation.getAnimationId(), animationFrames, currentPatternId);
    }

    private List<Block> patchAnimationBlockPatternReferences(Map<SourceAnimation, Animation> resultAnimationMapping)
    {
        List<Block> patchedBlocks = new ArrayList<>(blocks);

        resultAnimationMapping.forEach((sourceAnimation, animation) ->
        {
            int currentPatternIndex = animation.getPatternBaseId();
            for (Block block : sourceAnimation.getBlocks())
            {
                List<PatternReference> resultReferences = new ArrayList<>();
                for (PatternReference reference : block)
                {
                    AnimationBlockPatternReferenceEncoding encoding =
                            new AnimationBlockPatternReferenceEncoding(blockMetrics, reference);

                    PatternReference.Builder builder = reference.builder();
                    builder.setReferenceId(currentPatternIndex + encoding.getBlockLocalPatternId());

                    resultReferences.add(builder.build());
                }

                patchedBlocks.set(
                        patchedBlocks.indexOf(block),
                        new Block(block.getCollisionId(), block.getAnimationMetaData(), resultReferences));

                currentPatternIndex += blockMetrics.getTotalSubTiles();
            }
        });

        return patchedBlocks;
    }
}

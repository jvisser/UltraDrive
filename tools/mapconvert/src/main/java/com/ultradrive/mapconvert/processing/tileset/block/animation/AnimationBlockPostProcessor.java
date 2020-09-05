package com.ultradrive.mapconvert.processing.tileset.block.animation;

import com.ultradrive.mapconvert.processing.tileset.block.Block;
import com.ultradrive.mapconvert.processing.tileset.block.image.ImageBlockPatternProducer;
import com.ultradrive.mapconvert.processing.tileset.block.image.ImageBlockPatternReferenceProducer;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternReference;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileMetrics;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.IntStream;
import java.util.stream.Stream;

import static java.util.stream.Collectors.toList;
import static java.util.stream.Collectors.toSet;


public class AnimationBlockPostProcessor
{
    private static final String FRAME_ID_PREFIX = "FRAME_";

    private final List<Block> blocks;
    private final MetaTileMetrics blockMetrics;
    private final ImageBlockPatternProducer imagePatternProducer;
    private final ImageBlockPatternReferenceProducer patternReferenceProducer;

    public AnimationBlockPostProcessor(List<Block> blocks,
                                       MetaTileMetrics blockMetrics,
                                       ImageBlockPatternProducer imagePatternProducer,
                                       ImageBlockPatternReferenceProducer patternReferenceProducer)
    {
        this.blocks = blocks;
        this.blockMetrics = blockMetrics;
        this.imagePatternProducer = imagePatternProducer;
        this.patternReferenceProducer = patternReferenceProducer;
    }

    public AnimationBlockPostProcessingResult process()
    {
        List<SourceAnimation> sourceAnimations = new SourceAnimationParser(blocks, blockMetrics).parseAnimations();

        Set<SourceAnimationFrame> allSourceAnimationFrames = sourceAnimations.stream()
                .flatMap(sourceAnimation -> sourceAnimation.getAnimationFrameReferences().stream()
                        .map(SourceAnimationFrameReference::getAnimationFrame))
                .collect(toSet());

        AnimationOptimizer optimizer = new AnimationOptimizer(
                createAnimations(sourceAnimations, createAnimationFrames(allSourceAnimationFrames)),
                patternReferenceProducer);

        AnimationOptimizationResult optimizedAnimations = optimizer.optimize();

        List<Block> resultBlocks = patchAnimationBlockPatternReferences(optimizedAnimations);

        return new AnimationBlockPostProcessingResult(
                List.copyOf(resultBlocks),
                List.copyOf(optimizedAnimations.getOptimizedAnimations()),
                List.copyOf(optimizedAnimations.getAnimationFrames()));
    }


    private Map<SourceAnimationFrame, AnimationFrame> createAnimationFrames(Set<SourceAnimationFrame> sourceAnimationFrames)
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
                .mapToObj(patternId -> imagePatternProducer.getTilesetImagePattern(graphicId, patternId).getPattern());
    }

    private Map<SourceAnimation, Animation> createAnimations(List<SourceAnimation> sourceAnimations, Map<SourceAnimationFrame, AnimationFrame> animationFrameMap)
    {
        Map<SourceAnimation, Animation> resultAnimationMapping = new HashMap<>();

        int currentPatternId = patternReferenceProducer.getNextPatternId();
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

    private List<Block> patchAnimationBlockPatternReferences(AnimationOptimizationResult optimizedAnimations)
    {
        List<Block> patchedBlocks = new ArrayList<>(blocks);

        optimizedAnimations.getOptimizedAnimationMapping().forEach((sourceAnimation, animation) ->
        {
            List<PatternReference> animationPatternReferences =
                    optimizedAnimations.getAnimationPatternReferences(animation);

            int currentAnimationPatternIndex = 0;
            for (Block block : sourceAnimation.getBlocks())
            {
                List<PatternReference> resultReferences = new ArrayList<>();
                for (PatternReference reference : block)
                {
                    AnimationBlockPatternReferenceEncoding encoding =
                            new AnimationBlockPatternReferenceEncoding(blockMetrics, reference);

                    resultReferences.add(animationPatternReferences
                                                 .get(currentAnimationPatternIndex + encoding.getBlockLocalPatternId())
                                                 .reorient(reference.getOrientation()));
                }

                patchedBlocks.set(
                        patchedBlocks.indexOf(block),
                        new Block(block.getCollisionId(), block.getAnimationMetaData(), resultReferences));

                currentAnimationPatternIndex += blockMetrics.getTotalSubTiles();
            }
        });

        return patchedBlocks;
    }
}

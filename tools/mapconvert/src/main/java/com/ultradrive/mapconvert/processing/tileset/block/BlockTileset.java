package com.ultradrive.mapconvert.processing.tileset.block;

import com.ultradrive.mapconvert.processing.tileset.block.animation.Animation;
import com.ultradrive.mapconvert.processing.tileset.block.animation.AnimationFrame;
import com.ultradrive.mapconvert.processing.tileset.block.image.TilesetImagePalette;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileMetrics;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileset;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Optional;

import static java.lang.String.format;

public class BlockTileset extends MetaTileset<Block>
{
    private final TilesetImagePalette palette;

    private final List<Pattern> staticPatterns;
    private final List<Animation> animations;
    private final List<AnimationFrame> animationFrames;

    private final int patternBaseId;
    private final int totalPatternAllocationSize;

    public BlockTileset(TilesetImagePalette palette, List<Pattern> staticPatterns, List<Block> blocks, List<Animation> animations, List<AnimationFrame> animationFrames, MetaTileMetrics blockMetrics, int patternBaseId)
    {
        super(blocks, blockMetrics);

        this.palette = palette;
        this.staticPatterns = staticPatterns;
        this.animations = animations;
        this.animationFrames = animationFrames;
        this.patternBaseId = patternBaseId;

        this.totalPatternAllocationSize =
                staticPatterns.size() + animations.stream().map(Animation::getSize).reduce(0, Integer::sum);
    }

    public TilesetImagePalette getPalette()
    {
        return palette;
    }

    public List<Pattern> getStaticPatterns()
    {
        return staticPatterns;
    }

    public List<Animation> getAnimations()
    {
        return animations;
    }

    public List<AnimationFrame> getAnimationFrames()
    {
        return animationFrames;
    }

    public int getPatternBaseId()
    {
        return patternBaseId;
    }

    public int getTotalPatternAllocationSize()
    {
        return totalPatternAllocationSize;
    }

    public Pattern getPattern(int referenceId)
    {
        int patternId = referenceId - patternBaseId;
        if (patternId >= 0 && patternId < staticPatterns.size())
        {
            return staticPatterns.get(patternId);
        }

        Optional<Animation> animationOptional = animations.stream()
                .filter(a -> referenceId >= a.getPatternBaseId() && referenceId < a.getPatternBaseId() + a.getSize())
                .findAny();

        if (animationOptional.isPresent())
        {
            Animation animation = animationOptional.get();
            AnimationFrame firstAnimationFrame = animation.getAnimationFrameReference(0).getAnimationFrame();

            return firstAnimationFrame.getPattern(referenceId - animation.getPatternBaseId());
        }

        throw new NoSuchElementException(format("No pattern found in static or animation patterns for pattern id %d", referenceId));
    }
}

package com.ultradrive.mapconvert.processing.tileset.block;

import com.ultradrive.mapconvert.processing.tileset.block.animation.Animation;
import com.ultradrive.mapconvert.processing.tileset.block.animation.AnimationFrame;
import com.ultradrive.mapconvert.processing.tileset.block.image.TilesetImagePalette;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.Pattern;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.allocator.PatternAllocation;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileMetrics;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileset;
import java.util.List;
import java.util.Optional;

public class BlockTileset extends MetaTileset<Block>
{
    private final TilesetImagePalette palette;

    private final PatternAllocation patternAllocation;
    private final List<Animation> animations;
    private final List<AnimationFrame> animationFrames;

    public BlockTileset(List<Block> blocks,
                        MetaTileMetrics blockMetrics,
                        PatternAllocation patternAllocation,
                        TilesetImagePalette palette,
                        List<Animation> animations,
                        List<AnimationFrame> animationFrames)
    {
        super(blocks, blockMetrics);

        this.palette = palette;
        this.patternAllocation = patternAllocation;
        this.animations = animations;
        this.animationFrames = animationFrames;
    }

    public TilesetImagePalette getPalette()
    {
        return palette;
    }

    public PatternAllocation getPatternAllocation()
    {
        return patternAllocation;
    }

    public List<Animation> getAnimations()
    {
        return animations;
    }

    public List<AnimationFrame> getAnimationFrames()
    {
        return animationFrames;
    }

    public Optional<Pattern> getPattern(int referenceId)
    {
        return patternAllocation.getPattern(referenceId).or(() -> {
            Optional<Animation> animationOptional = animations.stream()
                    .filter(a -> referenceId >= a.getPatternBaseId() && referenceId < a.getPatternBaseId() + a.getSize())
                    .findAny();

            if (animationOptional.isPresent())
            {
                Animation animation = animationOptional.get();
                AnimationFrame firstAnimationFrame = animation.getAnimationFrameReference(0).getAnimationFrame();

                return Optional.of(firstAnimationFrame.getPattern(referenceId - animation.getPatternBaseId()));
            }

            return Optional.empty();
        });
    }
}

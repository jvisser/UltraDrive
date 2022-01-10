package com.ultradrive.mapconvert.processing.tileset.block;

import com.ultradrive.mapconvert.common.orientable.OrientableGrid;
import com.ultradrive.mapconvert.common.orientable.Orientation;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternReference;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTile;
import java.util.List;
import java.util.Objects;


public class Block extends MetaTile<Block, BlockReference, PatternReference>
{
    private final int collisionId;
    private final BlockAnimationMetadata animationMetaData;
    private final boolean empty;

    public Block(int collisionId, BlockAnimationMetadata animationMetaData,
                 List<PatternReference> patternReferences)
    {
        super(patternReferences);

        this.collisionId = collisionId;
        this.animationMetaData = animationMetaData;
        this.empty = patternReferences.stream()
                .reduce(true, (result, patternReference) -> result && patternReference.isEmpty(), (a, b) -> a && b);
    }

    private Block(int collisionId, BlockAnimationMetadata animationMetaData,
                  OrientableGrid<PatternReference> patternReferences, boolean empty)
    {
        super(patternReferences);

        this.collisionId = collisionId;
        this.animationMetaData = animationMetaData;
        this.empty = empty;
    }

    @Override
    public Block reorient(Orientation orientation)
    {
        if (orientation == Orientation.DEFAULT)
        {
            return this;
        }

        return new Block(collisionId, animationMetaData, tileReferences.reorient(orientation), empty);
    }

    @Override
    public BlockReference.Builder referenceBuilder()
    {
        BlockReference.Builder builder = new BlockReference.Builder();
        builder.setEmpty(empty);
        return builder;
    }

    @Override
    public boolean equals(Object o)
    {
        if (this == o)
        {
            return true;
        }
        if (o == null || getClass() != o.getClass())
        {
            return false;
        }
        if (!super.equals(o))
        {
            return false;
        }
        final Block that = (Block) o;
        return collisionId == that.collisionId &&
               animationMetaData.equals(that.animationMetaData);
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(super.hashCode(), collisionId, animationMetaData);
    }

    public int getCollisionId()
    {
        return collisionId;
    }

    public boolean hasAnimation()
    {
        return !animationMetaData.isEmpty();
    }

    public BlockAnimationMetadata getAnimationMetaData()
    {
        return animationMetaData;
    }
}

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
    private final BlockAnimationMetaData animationMetaData;

    public Block(int collisionId, BlockAnimationMetaData animationMetaData, List<PatternReference> patternReferences)
    {
        super(patternReferences);

        this.collisionId = collisionId;
        this.animationMetaData = animationMetaData;
    }

    private Block(int collisionId, BlockAnimationMetaData animationMetaData, OrientableGrid<PatternReference> patternReferences)
    {
        super(patternReferences);

        this.collisionId = collisionId;
        this.animationMetaData = animationMetaData;
    }

    @Override
    public Block reorient(Orientation orientation)
    {
        if (orientation == Orientation.DEFAULT)
        {
            return this;
        }

        return new Block(collisionId, animationMetaData, tileReferences.reorient(orientation));
    }

    @Override
    public BlockReference.Builder referenceBuilder()
    {
        return new BlockReference.Builder();
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

    public BlockAnimationMetaData getAnimationMetaData()
    {
        return animationMetaData;
    }
}

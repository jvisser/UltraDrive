package com.ultradrive.mapconvert.processing.tileset.block;

import com.ultradrive.mapconvert.common.OrientableGrid;
import com.ultradrive.mapconvert.common.OrientablePoolable;
import com.ultradrive.mapconvert.common.Orientation;
import com.ultradrive.mapconvert.common.Point;
import com.ultradrive.mapconvert.processing.tileset.block.pattern.PatternReference;

import java.util.Iterator;
import java.util.List;
import java.util.Objects;


public class Block implements OrientablePoolable<Block, BlockReference>, Iterable<PatternReference>
{
    private final int collisionId;
    private final BlockAnimationMetaData animationMetaData;
    private final OrientableGrid<PatternReference> patternReferences;

    public Block(int collisionId, BlockAnimationMetaData animationMetaData, List<PatternReference> patternReferences)
    {
        this.collisionId = collisionId;
        this.animationMetaData = animationMetaData;
        this.patternReferences = new OrientableGrid<>(patternReferences);
    }

    private Block(int collisionId, BlockAnimationMetaData animationMetaData, OrientableGrid<PatternReference> patternReferences)
    {
        this.collisionId = collisionId;
        this.animationMetaData = animationMetaData;
        this.patternReferences = patternReferences;
    }

    @Override
    public Block reorient(Orientation orientation)
    {
        if (orientation == Orientation.DEFAULT)
        {
            return this;
        }

        return new Block(collisionId, animationMetaData, patternReferences.reorient(orientation));
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
        final Block block = (Block) o;
        return collisionId == block.collisionId &&
               animationMetaData.equals(block.animationMetaData) &&
               patternReferences.equals(block.patternReferences);
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(collisionId, animationMetaData, patternReferences);
    }

    public PatternReference getPatternReference(Point point)
    {
        return patternReferences.getValue(point);
    }

    public PatternReference getPatternReference(int patternReferenceId)
    {
        return patternReferences.getValue(patternReferenceId);
    }

    public int getCollisionId()
    {
        return collisionId;
    }

    public Iterator<PatternReference> iterator()
    {
        return patternReferences.iterator();
    }

    public boolean hasAnimation()
    {
        return !animationMetaData.isEmpty();
    }

    public BlockAnimationMetaData getAnimationMetaData()
    {
        return animationMetaData;
    }

    public int getPatternCount()
    {
        return patternReferences.getSize();
    }
}

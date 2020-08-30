package com.ultradrive.mapconvert.processing.tileset.block;

import com.ultradrive.mapconvert.common.Orientation;
import com.ultradrive.mapconvert.processing.tileset.common.TileReference;
import java.util.Objects;


public class BlockReference extends TileReference<BlockReference>
{
    private final BlockSolidity solidity;
    private final int type;

    public static class Builder extends TileReference.Builder<BlockReference>
    {
        private BlockSolidity solidity;
        private int type;

        public Builder()
        {
            solidity = BlockSolidity.NONE;
            type = 0;
        }

        public Builder(BlockReference blockReference)
        {
            super(blockReference);

            solidity = blockReference.solidity;
            type = blockReference.type;
        }

        @Override
        public BlockReference build()
        {
            return new BlockReference(referenceId, orientation, solidity, type);
        }

        public void setSolidity(BlockSolidity solidity)
        {
            this.solidity = solidity;
        }

        public void setType(int type)
        {
            this.type = type;
        }
    }

    public BlockReference(int referenceId, Orientation orientation, BlockSolidity solidity, int type)
    {
        super(referenceId, orientation);

        this.solidity = solidity;
        this.type = type;
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
        final BlockReference that = (BlockReference) o;
        return type == that.type &&
               solidity == that.solidity;
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(super.hashCode(), solidity, type);
    }

    @Override
    public Builder builder()
    {
        return new Builder(this);
    }

    @Override
    public int pack()
    {
        int packedReference = solidity.getValue() | (referenceId & 0x3ff) | ((type & 0x03) << 14);

        if (orientation.isHorizontalFlip())
        {
            packedReference |= 0x0400;
        }

        if (orientation.isVerticalFlip())
        {
            packedReference |= 0x0800;
        }

        return packedReference;
    }

    public BlockSolidity getSolidity()
    {
        return solidity;
    }

    public int getType()
    {
        return type;
    }
}

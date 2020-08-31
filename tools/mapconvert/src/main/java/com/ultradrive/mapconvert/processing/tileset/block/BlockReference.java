package com.ultradrive.mapconvert.processing.tileset.block;

import com.ultradrive.mapconvert.common.BitPacker;
import com.ultradrive.mapconvert.common.Orientation;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileReference;
import com.ultradrive.mapconvert.processing.tileset.common.TileReference;
import java.util.Objects;


public class BlockReference extends MetaTileReference<BlockReference>
{
    private static final int TYPE_BIT_COUNT = 2;

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
    public BitPacker pack()
    {
        return super.pack()
                .add(solidity)
                .add(type, TYPE_BIT_COUNT);
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

package com.ultradrive.mapconvert.processing.tileset.block;

import com.ultradrive.mapconvert.common.BitPacker;
import com.ultradrive.mapconvert.common.orientable.Orientation;
import com.ultradrive.mapconvert.processing.tileset.common.MetaTileReference;
import java.util.Objects;


public class BlockReference extends MetaTileReference<BlockReference>
{
    private static final int REFERENCE_ID_BIT_COUNT = 10;

    private final BlockSolidity solidity;
    private final boolean priority;

    public static class Builder extends MetaTileReference.Builder<BlockReference>
    {
        private BlockSolidity solidity;
        private boolean priority;

        public Builder()
        {
            solidity = BlockSolidity.NONE;
            priority = false;
        }

        public Builder(BlockReference blockReference)
        {
            super(blockReference);

            solidity = blockReference.solidity;
            empty = blockReference.empty;
            priority = blockReference.priority;
        }

        @Override
        public BlockReference build()
        {
            return new BlockReference(referenceId, orientation, solidity, empty, priority);
        }

        public void setSolidity(BlockSolidity solidity)
        {
            this.solidity = solidity;
        }

        public void setEmpty(boolean empty)
        {
            this.empty = empty;
        }

        public void setPriority(boolean priority)
        {
            this.priority = priority;
        }
    }

    public BlockReference(int referenceId, Orientation orientation, BlockSolidity solidity, boolean empty, boolean priority)
    {
        super(referenceId, orientation, empty);

        this.solidity = solidity;
        this.priority = priority;
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
        return priority == that.priority &&
               solidity == that.solidity;
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(super.hashCode(), solidity, priority);
    }

    @Override
    public Builder builder()
    {
        return new Builder(this);
    }

    @Override
    public BitPacker pack()
    {
        return new BitPacker(Short.SIZE)
                .add(referenceId, REFERENCE_ID_BIT_COUNT)
                .add(empty)
                .add(orientation)
                .add(solidity)
                .add(priority);
    }

    public BlockSolidity getSolidity()
    {
        return solidity;
    }

    public boolean isPriority()
    {
        return priority;
    }
}

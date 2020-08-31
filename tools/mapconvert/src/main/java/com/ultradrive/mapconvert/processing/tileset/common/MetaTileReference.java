package com.ultradrive.mapconvert.processing.tileset.common;

import com.ultradrive.mapconvert.common.BitPacker;
import com.ultradrive.mapconvert.common.Orientation;


public abstract class MetaTileReference<T extends TileReference<T>> extends TileReference<T>
{
    private static final int REFERENCE_ID_BIT_COUNT = 10;

    public MetaTileReference(int referenceId, Orientation orientation)
    {
        super(referenceId, orientation);
    }

    @Override
    public BitPacker pack()
    {
        return new BitPacker(Short.SIZE)
                .add(referenceId, REFERENCE_ID_BIT_COUNT)
                .add(orientation.isHorizontalFlip())
                .add(orientation.isVerticalFlip());
    }
}

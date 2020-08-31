package com.ultradrive.mapconvert.processing.tileset.block.pattern;

import com.ultradrive.mapconvert.common.BitPacker;
import com.ultradrive.mapconvert.common.Orientation;
import com.ultradrive.mapconvert.processing.tileset.common.TileReference;
import java.util.Objects;


public class PatternReference extends TileReference<PatternReference>
{
    private static final int REFERENCE_ID_BIT_COUNT = 11;

    private final PatternPaletteId paletteId;
    private final PatternPriority priority;

    public static class Builder extends TileReference.Builder<PatternReference>
    {
        private PatternPaletteId paletteId;
        private PatternPriority priority;

        public Builder()
        {
            paletteId = PatternPaletteId.FIRST;
            priority = PatternPriority.LOW;
        }

        private Builder(PatternReference patternReference)
        {
            super(patternReference);

            paletteId = patternReference.paletteId;
            priority = patternReference.priority;
        }

        @Override
        public PatternReference build()
        {
            return new PatternReference(referenceId, paletteId, priority, orientation);
        }

        public void setPaletteId(PatternPaletteId paletteId)
        {
            this.paletteId = paletteId;
        }

        public void setPriority(PatternPriority priority)
        {
            this.priority = priority;
        }
    }

    public PatternReference(int patternId)
    {
        this(patternId, PatternPaletteId.FIRST, PatternPriority.LOW, Orientation.DEFAULT);
    }

    public PatternReference(int patternId, PatternPaletteId paletteId, PatternPriority priority, Orientation orientation)
    {
        super(patternId, orientation);

        this.paletteId = paletteId;
        this.priority = priority;
    }

    @Override
    public Builder builder()
    {
        return new Builder(this);
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
        final PatternReference reference = (PatternReference) o;
        return paletteId == reference.paletteId &&
               priority == reference.priority;
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(super.hashCode(), paletteId, priority);
    }

    @Override
    public BitPacker pack()
    {
        return new BitPacker(Short.SIZE)
                .add(referenceId, REFERENCE_ID_BIT_COUNT)
                .add(orientation.isHorizontalFlip())
                .add(orientation.isVerticalFlip())
                .add(paletteId)
                .add(priority);
    }

    public PatternPaletteId getPaletteId()
    {
        return paletteId;
    }

    public PatternPriority getPriority()
    {
        return priority;
    }
}

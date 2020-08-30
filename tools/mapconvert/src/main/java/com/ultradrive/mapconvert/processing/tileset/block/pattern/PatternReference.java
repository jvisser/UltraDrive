package com.ultradrive.mapconvert.processing.tileset.block.pattern;

import com.ultradrive.mapconvert.common.Orientation;
import com.ultradrive.mapconvert.processing.tileset.common.TileReference;
import java.util.Objects;


public class PatternReference extends TileReference<PatternReference>
{
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
    public int pack()
    {
        int packedReference = priority.getValue() | paletteId.getValue() | (referenceId & 0x7ff);

        if (orientation.isHorizontalFlip())
        {
            packedReference |= 0x0800;
        }

        if (orientation.isVerticalFlip())
        {
            packedReference |= 0x1000;
        }

        return packedReference;
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

package com.ultradrive.mapconvert.processing.tileset.block.pattern;

import com.ultradrive.mapconvert.common.BitPacker;
import com.ultradrive.mapconvert.common.orientable.Orientation;
import com.ultradrive.mapconvert.processing.tileset.common.TileReference;
import java.util.Objects;


public class PatternReference extends TileReference<PatternReference>
{
    private static final int REFERENCE_ID_BIT_COUNT = 11;

    private final PatternPaletteId paletteId;
    private final PatternPriority priority;
    private final boolean empty;

    public static class Builder extends TileReference.Builder<PatternReference>
    {
        private PatternPaletteId paletteId;
        private PatternPriority priority;
        private boolean empty;

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
            empty = patternReference.empty;
        }

        @Override
        public PatternReference build()
        {
            return new PatternReference(referenceId, paletteId, priority, orientation, empty);
        }

        public void setPaletteId(PatternPaletteId paletteId)
        {
            this.paletteId = paletteId;
        }

        public void setPriority(PatternPriority priority)
        {
            this.priority = priority;
        }

        public void setEmpty(boolean empty)
        {
            this.empty = empty;
        }

        public Integer getReferenceId()
        {
            return referenceId;
        }
    }

    public PatternReference(int patternId)
    {
        this(patternId, PatternPaletteId.FIRST, PatternPriority.LOW, Orientation.DEFAULT, false);
    }

    public PatternReference(int patternId, PatternPaletteId paletteId, PatternPriority priority,
                            Orientation orientation, boolean empty)
    {
        super(patternId, orientation);

        this.paletteId = paletteId;
        this.priority = priority;
        this.empty = empty;
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
        final PatternReference that = (PatternReference) o;
        return empty == that.empty && paletteId == that.paletteId && priority == that.priority;
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(super.hashCode(), paletteId, priority, empty);
    }

    @Override
    public BitPacker pack()
    {
        return new BitPacker(Short.SIZE)
                .add(referenceId, REFERENCE_ID_BIT_COUNT)
                .add(orientation)
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

    public boolean isEmpty()
    {
        return empty;
    }
}

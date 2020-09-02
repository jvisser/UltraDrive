package com.ultradrive.mapconvert.common.orientable;

public interface OrientableReference<S extends OrientableReference<S>> extends Orientable<S>
{
    @Override
    default S reorient(Orientation orientation)
    {
        Builder<S> builder = builder();
        builder.setOrientation(getOrientation().translate(orientation));
        return builder.build();
    }

    int getReferenceId();

    Orientation getOrientation();

    Builder<S> builder();

    interface Builder<R extends OrientableReference<R>>
    {
        void setOrientation(Orientation orientation);

        void setReferenceId(int referenceId);

        R build();
    }
}

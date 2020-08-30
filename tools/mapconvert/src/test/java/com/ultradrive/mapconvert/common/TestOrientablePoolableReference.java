package com.ultradrive.mapconvert.common;

public class TestOrientablePoolableReference implements OrientableReference<TestOrientablePoolableReference>
{
    public TestOrientablePoolableReference(Orientation orientation, int referenceId)
    {
        this.orientation = orientation;
        this.referenceId = referenceId;
    }

    public static class Builder implements OrientableReference.Builder<TestOrientablePoolableReference>
    {
        private Orientation orientation;
        private int referenceId;

        public Builder()
        {
            this.orientation = Orientation.DEFAULT;
            this.referenceId = -1;
        }

        public Builder(TestOrientablePoolableReference testOrientablePoolableReference)
        {
            this.orientation = testOrientablePoolableReference.orientation;
            this.referenceId = testOrientablePoolableReference.referenceId;
        }

        @Override
        public void setOrientation(Orientation orientation)
        {
            this.orientation = orientation;
        }

        @Override
        public void setReferenceId(int referenceId)
        {
            this.referenceId = referenceId;
        }

        @Override
        public TestOrientablePoolableReference build()
        {
            return new TestOrientablePoolableReference(orientation, referenceId);
        }
    }

    private final Orientation orientation;
    private final int referenceId;

    @Override
    public int getReferenceId()
    {
        return referenceId;
    }

    @Override
    public Orientation getOrientation()
    {
        return orientation;
    }

    @Override
    public Builder builder()
    {
        return new Builder(this);
    }
}

package com.ultradrive.mapconvert.datasource.model;


public final class BlockModel
{
    private final int id;
    private final BlockAnimationModel animationModel;
    private final ResourceReference graphicsReference;
    private final ResourceReference collisionReference;
    private final ResourceReference priorityReference;

    public BlockModel(int id,
                      BlockAnimationModel animationModel,
                      ResourceReference graphicsReference,
                      ResourceReference collisionReference,
                      ResourceReference priorityReference)
    {
        this.id = id;
        this.animationModel = animationModel;
        this.graphicsReference = graphicsReference;
        this.collisionReference = collisionReference;
        this.priorityReference = priorityReference;
    }

    public int getId()
    {
        return id;
    }

    public BlockAnimationModel getAnimation()
    {
        return animationModel;
    }

    public boolean hasAnimation()
    {
        return !getAnimation().getAnimationFrames().isEmpty();
    }

    public ResourceReference getGraphicReference()
    {
        return graphicsReference;
    }

    public ResourceReference getCollisionReference()
    {
        return collisionReference;
    }

    public ResourceReference getPriorityReference()
    {
        return priorityReference;
    }
}

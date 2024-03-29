package com.ultradrive.mapconvert.processing.tileset.block.animation;

import com.ultradrive.mapconvert.common.PropertySource;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import javax.annotation.Nonnull;

import static java.util.stream.Collectors.toList;


public class Animation implements PropertySource, Iterable<AnimationFrameReference>
{
    private final String id;
    private final String type;
    private final List<AnimationFrameReference> animationFrames;
    private final Map<String, Object> properties;
    private final int patternBaseId;

    Animation(String id, String type, List<AnimationFrameReference> animationFrames, Map<String, Object> properties)
    {
        this(id, type, animationFrames, properties, 0);
    }

    Animation(String id, String type,
              List<AnimationFrameReference> animationFrames,
              Map<String, Object> properties, int patternBaseId)
    {
        this.id = id;
        this.type = type;
        this.animationFrames = animationFrames;
        this.properties = properties;
        this.patternBaseId = patternBaseId;
    }

    @Override
    @Nonnull
    public Iterator<AnimationFrameReference> iterator()
    {
        return animationFrames.iterator();
    }

    @Override
    public Map<String, Object> getProperties()
    {
        return properties;
    }

    public String getId()
    {
        return id;
    }

    public String getType()
    {
        return type;
    }

    public List<AnimationFrameReference> getAnimationFrameReferences()
    {
        return animationFrames;
    }

    public AnimationFrameReference getAnimationFrameReference(int frameId)
    {
        return animationFrames.get(frameId);
    }

    public int getPatternBaseId()
    {
        return patternBaseId;
    }

    public int getSize()
    {
        return animationFrames.get(0).getAnimationFrame().getSize();
    }

    public int getFrameCount()
    {
        return animationFrames.size();
    }

    Animation remap(Map<AnimationFrame, AnimationFrame> newFrames, int newPatternBaseId)
    {
        return new Animation(id,
                             type,
                             animationFrames.stream()
                                     .map(animationFrameReference -> new AnimationFrameReference(
                                             newFrames.get(animationFrameReference.getAnimationFrame()),
                                             animationFrameReference.getFrameTime()))
                                     .collect(toList()),
                             properties, newPatternBaseId);
    }
}

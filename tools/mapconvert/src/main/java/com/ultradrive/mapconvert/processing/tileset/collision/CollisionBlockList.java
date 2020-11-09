package com.ultradrive.mapconvert.processing.tileset.collision;

import com.ultradrive.mapconvert.datasource.CollisionBlockDataSource;

import java.util.Iterator;
import java.util.Objects;
import javax.annotation.Nonnull;
import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;


public class CollisionBlockList implements Iterable<CollisionBlock>
{
    private final String name;
    private final List<CollisionBlock> collisionBlocks;
    private final int collisionFieldSize;

    public static CollisionBlockList parse(CollisionBlockDataSource collisionBlockDataSource)
    {
        BufferedImage collisionHeightFieldImage = readCollisionHeightFieldImage(collisionBlockDataSource);

        int collisionFieldSize = collisionBlockDataSource.getCollisionBlockFieldSize();
        int collisionImageWidth = collisionHeightFieldImage.getWidth();
        int collisionImageHeight = collisionHeightFieldImage.getHeight();

        int collisionId = 0;
        List<CollisionBlock> collisionBlocks = new ArrayList<>();
        for (int y = 0; y < collisionImageHeight; y += collisionFieldSize)
        {
            for (int x = 0; x < collisionImageWidth; x += collisionFieldSize)
            {
                collisionBlocks.add(
                        new CollisionBlock(getHeightField(collisionHeightFieldImage, y, x, collisionFieldSize),
                                           collisionBlockDataSource.getCollisionBlockMetaData(collisionId).getAngle()));
                collisionId++;
            }
        }

        return new CollisionBlockList(collisionBlockDataSource.getName(), collisionBlocks, collisionFieldSize);
    }

    private static BufferedImage readCollisionHeightFieldImage(CollisionBlockDataSource collisionBlockDataSource)
    {
        try
        {
            return ImageIO.read(collisionBlockDataSource.getCollisionBlockImageSource());
        }
        catch (IOException ioe)
        {
            throw new IllegalArgumentException("Unable to load collision height field image", ioe);
        }
    }

    private static List<Integer> getHeightField(BufferedImage collisionHeightFieldImage, int y, int x,
                                                int collisionFieldSize)
    {
        List<Integer> heightField = new ArrayList<>();
        for (int xx = 0; xx < collisionFieldSize; xx++)
        {
            int height = 0;
            for (int yy = 0; yy < collisionFieldSize; yy++)
            {
                int rgb = collisionHeightFieldImage.getRGB(x + xx, y + collisionFieldSize - yy - 1);
                if (new Color(rgb, true).getTransparency() == Transparency.OPAQUE)
                {
                    height = yy;
                }
            }
            heightField.add(height);
        }
        return heightField;
    }

    public CollisionBlockList(String name, List<CollisionBlock> collisionBlocks, int collisionFieldSize)
    {
        this.name = name;
        this.collisionBlocks = collisionBlocks;
        this.collisionFieldSize = collisionFieldSize;
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
        final CollisionBlockList that = (CollisionBlockList) o;
        return collisionFieldSize == that.collisionFieldSize &&
               name.equals(that.name) &&
               collisionBlocks.equals(that.collisionBlocks);
    }

    @Override
    public int hashCode()
    {
        return Objects.hash(name, collisionBlocks, collisionFieldSize);
    }

    @Nonnull
    @Override
    public Iterator<CollisionBlock> iterator()
    {
        return collisionBlocks.iterator();
    }

    public int getCollisionFieldSize()
    {
        return collisionFieldSize;
    }

    public List<CollisionBlock> getCollisionFields()
    {
        return collisionBlocks;
    }

    public String getName()
    {
        return name;
    }
}

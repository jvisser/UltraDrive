package com.ultradrive.mapconvert.processing.tileset.collision;

import com.ultradrive.mapconvert.datasource.CollisionDataSource;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;


public class CollisionFieldSet
{
    private final List<CollisionField> collisionFields;
    private final int collisionFieldSize;

    public static CollisionFieldSet parse(CollisionDataSource collisionDataSource)
    {
        BufferedImage collisionHeightFieldImage = readCollisionHeightFieldImage(collisionDataSource);

        int collisionFieldSize = collisionDataSource.getCollisionFieldSize();
        int collisionImageWidth = collisionHeightFieldImage.getWidth();
        int collisionImageHeight = collisionHeightFieldImage.getHeight();

        int collisionId = 0;
        List<CollisionField> collisionFields = new ArrayList<>();
        for (int y = 0; y < collisionImageHeight; y += collisionFieldSize)
        {
            for (int x = 0; x < collisionImageWidth; x += collisionFieldSize)
            {
                collisionFields.add(
                        new CollisionField(getHeightField(collisionHeightFieldImage, y, x, collisionFieldSize),
                                           collisionDataSource.getCollisionMetaData(collisionId).getAngle()));
                collisionId++;
            }
        }

        return new CollisionFieldSet(collisionFields, collisionFieldSize);
    }

    private static BufferedImage readCollisionHeightFieldImage(CollisionDataSource collisionDataSource)
    {
        try
        {
            return ImageIO.read(collisionDataSource.getCollisionImageSource());
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

    public CollisionFieldSet(List<CollisionField> collisionFields, int collisionFieldSize)
    {
        this.collisionFields = collisionFields;
        this.collisionFieldSize = collisionFieldSize;
    }

    public int getCollisionFieldSize()
    {
        return collisionFieldSize;
    }

    public List<CollisionField> getCollisionFields()
    {
        return collisionFields;
    }
}

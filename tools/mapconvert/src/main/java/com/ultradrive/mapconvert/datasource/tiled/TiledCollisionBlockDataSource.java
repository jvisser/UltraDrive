package com.ultradrive.mapconvert.datasource.tiled;

import com.ultradrive.mapconvert.common.PropertySource;
import com.ultradrive.mapconvert.datasource.CollisionBlockDataSource;
import com.ultradrive.mapconvert.datasource.model.CollisionBlockMetaData;
import java.io.File;
import java.net.URL;
import java.util.Map;
import org.tiledreader.TiledTile;
import org.tiledreader.TiledTileset;


class TiledCollisionBlockDataSource implements CollisionBlockDataSource, PropertySource
{
    private static final String COLLISION_ANGLE_PROPERTY_NAME = "angle";

    private final TiledTileset collisionTileset;
    private final URL blockCollisionImageSource;
    private final TiledPropertyTransformer propertyTransformer;

    public TiledCollisionBlockDataSource(TiledTileset collisionTileset, URL blockCollisionImageSource,
                                         TiledPropertyTransformer propertyTransformer)
    {
        this.collisionTileset = collisionTileset;
        this.blockCollisionImageSource = blockCollisionImageSource;
        this.propertyTransformer = propertyTransformer;
    }

    @Override
    public Map<String, Object> getProperties()
    {
        return propertyTransformer.getProperties(collisionTileset);
    }

    @Override
    public String getName()
    {
        File file = new File(collisionTileset.getPath());
        return file.getParentFile().getName() + "_" + collisionTileset.getName();
    }

    @Override
    public int getCollisionBlockFieldSize()
    {
        return collisionTileset.getTileWidth();
    }

    @Override
    public URL getCollisionBlockImageSource()
    {
        return blockCollisionImageSource;
    }

    @Override
    public CollisionBlockMetaData getCollisionBlockMetaData(int collisionId)
    {
        TiledTile collisionTile = collisionTileset.getTile(collisionId);
        if (collisionTile == null)
        {
            return CollisionBlockMetaData.empty();
        }

        Float collisionAngle = (Float) collisionTile.getProperty(COLLISION_ANGLE_PROPERTY_NAME);
        if (collisionAngle == null)
        {
            return CollisionBlockMetaData.empty();
        }

        return new CollisionBlockMetaData(collisionAngle);
    }
}

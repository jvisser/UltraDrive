package com.ultradrive.mapconvert.datasource.tiled;

import com.ultradrive.mapconvert.common.PropertySource;
import com.ultradrive.mapconvert.datasource.CollisionDataSource;
import com.ultradrive.mapconvert.datasource.model.CollisionMetaData;
import java.net.URL;
import java.util.Map;
import org.tiledreader.TiledTile;
import org.tiledreader.TiledTileset;


class TiledCollisionDataSource implements CollisionDataSource, PropertySource
{
    private static final String COLLISION_ANGLE_PROPERTY_NAME = "angle";

    private final TiledTileset collisionTileset;
    private final URL blockCollisionImageSource;
    private final TiledPropertyTransformer propertyTransformer;

    public TiledCollisionDataSource(TiledTileset collisionTileset, URL blockCollisionImageSource,
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
    public int getCollisionFieldSize()
    {
        return collisionTileset.getTileWidth();
    }

    @Override
    public URL getCollisionImageSource()
    {
        return blockCollisionImageSource;
    }

    @Override
    public CollisionMetaData getCollisionMetaData(int collisionId)
    {
        TiledTile collisionTile = collisionTileset.getTile(collisionId);
        if (collisionTile == null)
        {
            return CollisionMetaData.empty();
        }

        Float collisionAngle = (Float) collisionTile.getProperty(COLLISION_ANGLE_PROPERTY_NAME);
        if (collisionAngle == null)
        {
            return CollisionMetaData.empty();
        }

        return new CollisionMetaData(collisionAngle);
    }
}

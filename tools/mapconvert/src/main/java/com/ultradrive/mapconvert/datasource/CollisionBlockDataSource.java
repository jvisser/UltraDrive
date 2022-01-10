package com.ultradrive.mapconvert.datasource;

import com.ultradrive.mapconvert.common.PropertySource;
import com.ultradrive.mapconvert.datasource.model.CollisionBlockMetadata;
import java.net.URL;


public interface CollisionBlockDataSource extends PropertySource
{
    String getName();

    int getCollisionBlockFieldSize();

    URL getCollisionBlockImageSource();

    CollisionBlockMetadata getCollisionBlockMetaData(int collisionId);
}

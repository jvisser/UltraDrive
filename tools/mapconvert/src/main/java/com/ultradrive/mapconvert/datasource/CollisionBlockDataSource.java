package com.ultradrive.mapconvert.datasource;

import com.ultradrive.mapconvert.common.PropertySource;
import com.ultradrive.mapconvert.datasource.model.CollisionBlockMetaData;
import java.net.URL;


public interface CollisionBlockDataSource extends PropertySource
{
    String getName();

    int getCollisionBlockFieldSize();

    URL getCollisionBlockImageSource();

    CollisionBlockMetaData getCollisionBlockMetaData(int collisionId);
}

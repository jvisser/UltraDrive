package com.ultradrive.mapconvert.datasource;

import com.ultradrive.mapconvert.common.PropertySource;
import com.ultradrive.mapconvert.datasource.model.CollisionMetaData;
import java.net.URL;


public interface CollisionDataSource extends PropertySource
{
    int getCollisionFieldSize();

    URL getCollisionImageSource();

    CollisionMetaData getCollisionMetaData(int collisionId);
}

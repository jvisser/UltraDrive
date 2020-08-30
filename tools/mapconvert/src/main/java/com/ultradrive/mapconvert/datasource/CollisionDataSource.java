package com.ultradrive.mapconvert.datasource;

import com.ultradrive.mapconvert.datasource.model.CollisionMetaData;

import java.net.URL;


public interface CollisionDataSource
{
    int getCollisionFieldSize();

    URL getCollisionImageSource();

    CollisionMetaData getCollisionMetaData(int collisionId);
}

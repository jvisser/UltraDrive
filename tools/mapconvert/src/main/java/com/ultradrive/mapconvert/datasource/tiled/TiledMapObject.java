package com.ultradrive.mapconvert.datasource.tiled;

import com.ultradrive.mapconvert.common.UID;
import com.ultradrive.mapconvert.datasource.model.MapObject;
import org.tiledreader.TiledObject;


class TiledMapObject extends MapObject
{
    public TiledMapObject(TiledObject tiledObject)
    {
        super(tiledObject.getName(),
              UID.create(),
              tiledObject.getProperties(),
              (int) (tiledObject.getX() +
                     (Integer) tiledObject.getProperties().getOrDefault("objectTypeXCompensation", 0)),
              (int) (tiledObject.getY() +
                     (Integer) tiledObject.getProperties().getOrDefault("objectTypeYCompensation", 0)),
              tiledObject.getTileXFlip(), tiledObject.getTileYFlip());
    }
}
